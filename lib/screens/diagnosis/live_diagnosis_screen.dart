import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/app_locale.dart';
import '../../core/theme.dart';
import '../../core/user_store.dart';
import '../../services/gemini_service.dart';
import '../profile/profile_screen.dart';
import 'product_details_screen.dart';
import 'promo_preview_screen.dart';

/// AI Video Call screen — connects the camera, captures a frame on demand,
/// sends it to Gemini for a Syngenta-first diagnosis, and offers the user
/// the option to view product details or generate a personalised promo image.
class LiveDiagnosisScreen extends StatefulWidget {
  const LiveDiagnosisScreen({super.key});

  @override
  State<LiveDiagnosisScreen> createState() => _LiveDiagnosisScreenState();
}

enum _CallStage { idle, connecting, listening, analyzing, result }

class _LiveDiagnosisScreenState extends State<LiveDiagnosisScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _cameraReady = false;
  bool _serviceActive = false;
  bool _isFlashOn = false;
  Timer? _timer;
  int _secondsElapsed = 0;
  final FlutterTts _tts = FlutterTts();

  _CallStage _stage = _CallStage.idle;
  DiagnosisResult? _result;
  String _statusText = '';

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    _tts.stop();
    super.dispose();
  }

  // ────────────── lifecycle controls ──────────────

  Future<void> _startService() async {
    setState(() {
      _serviceActive = true;
      _stage = _CallStage.connecting;
      _statusText = 'connecting_ai'.tr();
    });
    await _initCamera();
    if (!mounted) return;
    setState(() {
      _stage = _CallStage.listening;
      _statusText = 'point_camera'.tr();
    });
    _startTimer();
    await _speak('tts_hello'.tr());
  }

  Future<void> _endCall() async {
    _timer?.cancel();
    await _tts.stop();
    await _controller?.dispose();
    _controller = null;
    if (!mounted) return;
    setState(() {
      _serviceActive = false;
      _stage = _CallStage.idle;
      _cameraReady = false;
      _secondsElapsed = 0;
      _result = null;
    });
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;
      _controller = CameraController(
        _cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _controller!.initialize();
      if (mounted) setState(() => _cameraReady = true);
    } catch (e) {
      debugPrint('Camera init failed: $e');
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _secondsElapsed++);
    });
  }

  Future<void> _speak(String text) async {
    try {
      final ttsLocale = AppLocale.ttsFromName(UserStore.instance.language);
      await _tts.setLanguage(ttsLocale);
      await _tts.setPitch(1.0);
      await _tts.speak(text);
    } catch (_) {}
  }

  String get _formattedTime {
    final m = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsElapsed % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ────────────── analyze flow ──────────────

  Future<void> _analyze() async {
    if (_controller == null || !_cameraReady) return;
    setState(() {
      _stage = _CallStage.analyzing;
      _statusText = 'analyzing_crop'.tr();
    });
    await _speak('tts_analyzing'.tr());

    try {
      final shot = await _controller!.takePicture();
      final file = File(shot.path);
      final result = await GeminiService.instance.diagnoseCrop(file);
      if (!mounted) return;
      setState(() {
        _result = result;
        _stage = _CallStage.result;
        _statusText = '';
      });
      await _speak(
        'I detected ${result.issue} on your ${result.crop}. I recommend ${result.recommendedProduct}.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _CallStage.listening;
        _statusText = 'analysis_failed'.tr();
      });
    }
  }

  void _viewProduct() {
    final r = _result;
    if (r == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailsScreen(productName: r.recommendedProduct),
      ),
    );
  }

  Future<void> _generatePromo() async {
    final r = _result;
    if (r == null || _controller == null || !_cameraReady) return;

    final captureFuture = _controller!.takePicture();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PromoGeneratingDialog(),
    );

    try {
      final selfie = await captureFuture;
      final bytes = await GeminiService.instance.generatePromoImage(
        userPhoto: File(selfie.path),
        productName: r.recommendedProduct,
        crop: r.crop,
      );
      if (!mounted) return;
      Navigator.pop(context); // close dialog

      if (bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Could not generate poster. Make sure GEMINI_API_KEY is set in .env'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }

      final dir = await getTemporaryDirectory();
      final out = File(
          '${dir.path}/promo_${DateTime.now().millisecondsSinceEpoch}.png');
      await out.writeAsBytes(bytes);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PromoPreviewScreen(
            file: out,
            productName: r.recommendedProduct,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error generating poster: $e'),
              backgroundColor: AppTheme.error),
        );
      }
    }
  }

  // ────────────── build ──────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          children: [
            Text('ai_crop_diagnosis'.tr(),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                )),
            Text('live_gemini'.tr(),
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.black),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: _serviceActive ? _buildActiveScreen() : _buildStartScreen(),
    );
  }

  /// Pre-call landing UI — explains what the service does.
  Widget _buildStartScreen() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.videocam_off_rounded,
                        size: 72, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'ai_video_diagnosis'.tr(),
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'ai_video_desc'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 15,
                        color: AppTheme.textSecondary,
                        height: 1.5),
                  ),
                  const SizedBox(height: 28),
                  _featureRow(Icons.local_florist_outlined,
                      'feat_detection'.tr()),
                  const SizedBox(height: 10),
                  _featureRow(Icons.verified_outlined,
                      'feat_syngenta'.tr()),
                  const SizedBox(height: 10),
                  _featureRow(Icons.auto_awesome,
                      'feat_poster'.tr()),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startService,
                icon: const Icon(Icons.videocam_rounded, color: Colors.white),
                label: Text('start_ai_call'.tr(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),      
          ],
        ),
      ),
    );
  }

  Widget _featureRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 14, color: AppTheme.textPrimary)),
        ),
      ],
    );
  }

  // ────────────── active call UI ──────────────

  Widget _buildActiveScreen() {
    return Column(
      children: [
        // status bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.circle,
                  color: _stage == _CallStage.analyzing
                      ? Colors.orange
                      : Colors.green,
                  size: 10),
              const SizedBox(width: 8),
              Text(
                _stage == _CallStage.connecting
                    ? 'connecting_status'.tr()
                    : 'live_status'.tr(),
                style: const TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(_formattedTime,
                  style:
                      TextStyle(color: Colors.grey[700], fontSize: 13)),
            ],
          ),
        ),

        // camera preview
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_cameraReady && _controller != null)
                    CameraPreview(_controller!)
                  else
                    Container(color: Colors.black87),

                  // viewfinder corners
                  Center(
                    child: SizedBox(
                      width: 240,
                      height: 240,
                      child: CustomPaint(painter: _CornerPainter()),
                    ),
                  ),

                  // overlay text
                  if (_statusText.isNotEmpty)
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.energy_savings_leaf,
                                color: Colors.green),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(_statusText,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // flash button
                  Positioned(
                    top: 14,
                    right: 14,
                    child: GestureDetector(
                      onTap: () async {
                        if (_controller == null) return;
                        await _controller!.setFlashMode(
                            _isFlashOn ? FlashMode.off : FlashMode.torch);
                        setState(() => _isFlashOn = !_isFlashOn);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isFlashOn ? Icons.flash_on : Icons.flash_off,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // bottom panel
        if (_stage == _CallStage.result && _result != null)
          _resultPanel(_result!)
        else
          _controlsPanel(),
      ],
    );
  }

  Widget _controlsPanel() {
    final canAnalyze = _stage == _CallStage.listening && _cameraReady;
    final analyzing = _stage == _CallStage.analyzing;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Row(
        children: [
          // end call
          GestureDetector(
            onTap: _endCall,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.call_end, color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: canAnalyze ? _analyze : null,
              icon: analyzing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome, color: Colors.white),
              label: Text(
                analyzing ? 'analyzing'.tr() : 'analyze_crop'.tr(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultPanel(DiagnosisResult r) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.eco, color: AppTheme.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${r.crop} • ${r.issue}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    if (r.isSyngenta)
                      Row(children: [
                        const Icon(Icons.verified,
                            color: AppTheme.primary, size: 14),
                        const SizedBox(width: 4),
                        Text('syngenta_rec'.tr(),
                            style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600)),
                      ]),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () {
                  setState(() {
                    _result = null;
                    _stage = _CallStage.listening;
                    _statusText = 'point_another'.tr();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(r.explanation,
              style:
                  TextStyle(fontSize: 13, color: Colors.grey[800], height: 1.4)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.recommendedProduct,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.primaryDark)),
                const SizedBox(height: 4),
                if (r.dose.isNotEmpty)
                  Text('${'dose_label'.tr()} ${r.dose}',
                      style: const TextStyle(fontSize: 12)),
                if (r.timing.isNotEmpty)
                  Text('${'timing_label'.tr()} ${r.timing}',
                      style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _generatePromo,
                  icon: const Icon(Icons.image_outlined,
                      color: AppTheme.primary),
                  label: Text('generate_poster'.tr(),
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppTheme.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _viewProduct,
                  icon: const Icon(Icons.arrow_forward,
                      color: Colors.white, size: 18),
                  label: Text('view_product'.tr(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    const len = 24.0;
    // top-left
    canvas.drawLine(Offset.zero, const Offset(len, 0), paint);
    canvas.drawLine(Offset.zero, const Offset(0, len), paint);
    // top-right
    canvas.drawLine(
        Offset(size.width, 0), Offset(size.width - len, 0), paint);
    canvas.drawLine(
        Offset(size.width, 0), Offset(size.width, len), paint);
    // bottom-left
    canvas.drawLine(
        Offset(0, size.height), Offset(len, size.height), paint);
    canvas.drawLine(
        Offset(0, size.height), Offset(0, size.height - len), paint);
    // bottom-right
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width - len, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width, size.height - len), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _PromoGeneratingDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppTheme.primary),
            const SizedBox(height: 20),
            Text('generating_poster'.tr(),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Text('Nano Banana is working its magic',
                style: TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}
