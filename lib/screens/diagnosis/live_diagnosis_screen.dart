import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
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

  /// Broadcasts whether an AI video call is currently active so the
  /// surrounding shell (e.g. HomeScreen) can hide chrome like the nav bar.
  static final ValueNotifier<bool> serviceActiveNotifier =
      ValueNotifier<bool>(false);

  @override
  State<LiveDiagnosisScreen> createState() => _LiveDiagnosisScreenState();
}

enum _CallStage { idle, connecting, listening, analyzing, result }

enum _AiState { idle, listening, thinking, speaking }

class _ChatTurn {
  final bool fromUser;
  final String text;
  final String? productMention;
  _ChatTurn(this.fromUser, this.text, [this.productMention]);
}

class _LiveDiagnosisScreenState extends State<LiveDiagnosisScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _cameraReady = false;
  bool _serviceActive = false;
  bool _videoEnabled = false; // camera on/off mid-call (audio always on)
  bool _isFlashOn = false;
  bool _isMuted = false;
  Timer? _timer;
  int _secondsElapsed = 0;
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _sttAvailable = false;
  bool _listeningVoice = false;
  String _heardText = '';

  _CallStage _stage = _CallStage.idle;
  DiagnosisResult? _result;
  String _statusText = '';

  // Realtime conversation state
  _AiState _aiState = _AiState.idle;
  final List<_ChatTurn> _turns = [];
  String _liveReply = ''; // streaming AI reply in progress
  bool _autoConversation = true; // auto-resume listening after AI speaks

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
      _videoEnabled = false;
      _stage = _CallStage.connecting;
      _statusText = 'connecting_ai'.tr();
      _turns.clear();
      _liveReply = '';
      _autoConversation = true;
    });
    LiveDiagnosisScreen.serviceActiveNotifier.value = true;
    GeminiService.instance.resetConversation();

    _sttAvailable = await _stt.initialize(
      onStatus: (status) {
        // status: "notListening" indicates the user has stopped speaking
        if (status == 'notListening' && _listeningVoice) {
          _onUserFinishedSpeaking();
        }
      },
      onError: (_) {
        if (mounted) setState(() => _listeningVoice = false);
      },
    );

    // Auto-restart listening after the AI finishes speaking
    _tts.setCompletionHandler(() {
      if (!mounted) return;
      setState(() => _aiState = _AiState.idle);
      if (_autoConversation && _serviceActive && _stage != _CallStage.analyzing) {
        _startListening();
      }
    });

    if (!mounted) return;
    setState(() {
      _stage = _CallStage.listening;
      _statusText = 'Connected. Just start talking…';
    });
    _startTimer();
    final greeting = UserStore.instance.name.isEmpty
        ? 'Hello! I am your KisanConnect AI assistant. How can I help your crops today?'
        : 'Hello ${UserStore.instance.name.split(' ').first}! How can I help your crops today?';
    await _speakAndWait(greeting);
  }

  Future<void> _toggleVideo() async {
    if (_videoEnabled) {
      // turn camera off
      await _controller?.dispose();
      _controller = null;
      if (!mounted) return;
      setState(() {
        _videoEnabled = false;
        _cameraReady = false;
        _isFlashOn = false;
      });
    } else {
      setState(() => _videoEnabled = true);
      await _initCamera();
    }
  }

  /// Mic button — toggles between Listening and Muted. In auto mode, the
  /// mic restarts itself after every AI reply; tapping here just pauses it.
  Future<void> _toggleVoice() async {
    if (!_sttAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission denied')),
      );
      return;
    }
    if (_listeningVoice) {
      // user wants to interrupt and send what's been heard so far
      setState(() => _autoConversation = false);
      await _stt.stop();
      _onUserFinishedSpeaking();
    } else {
      setState(() => _autoConversation = true);
      await _tts.stop(); // barge-in: cut AI off if it's still talking
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    if (!_sttAvailable || _listeningVoice) return;
    setState(() {
      _heardText = '';
      _listeningVoice = true;
      _aiState = _AiState.listening;
      _statusText = 'Listening…';
    });
    await _stt.listen(
      onResult: (r) => setState(() => _heardText = r.recognizedWords),
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 2), // shorter for snappier turn-taking
      localeId: 'en_IN',
    );
  }

  /// Called when STT ends (timeout or pause) — sends the heard text.
  void _onUserFinishedSpeaking() {
    if (!mounted) return;
    final spoken = _heardText.trim();
    setState(() => _listeningVoice = false);
    if (spoken.isEmpty) {
      // nothing heard — if auto mode, restart listening
      if (_autoConversation && _serviceActive) _startListening();
      return;
    }
    setState(() {
      _turns.add(_ChatTurn(true, spoken));
      _heardText = '';
    });
    _streamAiReply(spoken);
  }

  Future<void> _streamAiReply(String userText) async {
    setState(() {
      _aiState = _AiState.thinking;
      _statusText = 'Thinking…';
      _liveReply = '';
      _stage = _CallStage.analyzing;
    });

    final buffer = StringBuffer();
    try {
      await for (final chunk
          in GeminiService.instance.streamReply(userText)) {
        if (!mounted) return;
        buffer.write(chunk);
        setState(() => _liveReply = buffer.toString());
      }
    } catch (_) {}

    final full = buffer.toString().trim();
    if (full.isEmpty) {
      if (mounted) setState(() => _aiState = _AiState.idle);
      if (_autoConversation && _serviceActive) _startListening();
      return;
    }

    final product = GeminiService.instance.extractProductMention(full);
    if (!mounted) return;
    setState(() {
      _turns.add(_ChatTurn(false, full, product));
      _liveReply = '';
      _stage = _CallStage.listening;
      _aiState = _AiState.speaking;
      _statusText = '';
      if (product != null) {
        _result = DiagnosisResult(
          crop: 'Crop',
          issue: 'Recommendation',
          explanation: full,
          recommendedProduct: product,
          dose: '',
          timing: '',
          isSyngenta: true,
        );
      }
    });
    await _speakAndWait(full);
  }

  Future<void> _speakAndWait(String text) async {
    try {
      setState(() => _aiState = _AiState.speaking);
      await _tts.setLanguage('en-IN');
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.5);
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> _endCall() async {
    _autoConversation = false;
    _timer?.cancel();
    await _tts.stop();
    _tts.setCompletionHandler(() {});
    await _stt.stop();
    GeminiService.instance.resetConversation();
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
    LiveDiagnosisScreen.serviceActiveNotifier.value = false;
  }

  @override
  void deactivate() {
    // Safety: if the screen is being torn down while active, restore chrome.
    if (_serviceActive) {
      LiveDiagnosisScreen.serviceActiveNotifier.value = false;
    }
    super.deactivate();
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
                icon: const Icon(Icons.phone_in_talk_rounded, color: Colors.white),
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

        // main viewport: camera if video on, else audio call visual
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_videoEnabled && _cameraReady && _controller != null)
                    CameraPreview(_controller!)
                  else if (_videoEnabled)
                    Container(color: Colors.black87)
                  else
                    _audioVisual(),

                  // viewfinder corners (video only)
                  if (_videoEnabled)
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

                  // flash button (video only)
                  if (_videoEnabled && _cameraReady)
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
    final analyzing = _stage == _CallStage.analyzing;
    final canAnalyze =
        _stage == _CallStage.listening && _videoEnabled && _cameraReady;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        children: [
          // Top row: round toggles (mic, video, end)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _circleControl(
                icon: _listeningVoice ? Icons.mic : Icons.mic_none,
                label: _listeningVoice ? 'Listening' : 'Tap to speak',
                color: _listeningVoice ? AppTheme.primary : Colors.grey.shade800,
                onTap: _toggleVoice,
                active: _listeningVoice,
              ),
              _circleControl(
                icon: _videoEnabled ? Icons.videocam : Icons.videocam_off,
                label: _videoEnabled ? 'Video on' : 'Video off',
                color: _videoEnabled ? AppTheme.primary : Colors.grey.shade800,
                onTap: _toggleVideo,
                active: _videoEnabled,
              ),
              _circleControl(
                icon: Icons.call_end,
                label: 'End',
                color: Colors.red,
                onTap: _endCall,
                active: true,
              ),
            ],
          ),
          // Analyze button — only meaningful when video is on
          if (_videoEnabled) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
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
                  disabledBackgroundColor:
                      AppTheme.primary.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _circleControl({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool active,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: active ? color : Colors.grey.shade200,
              shape: BoxShape.circle,
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Icon(icon,
                color: active ? Colors.white : Colors.grey.shade700, size: 26),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(
                fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }

  /// Audio-only viewport — animated AI avatar, status, and realtime captions.
  Widget _audioVisual() {
    final stateLabel = switch (_aiState) {
      _AiState.listening => 'Listening',
      _AiState.thinking => 'Thinking',
      _AiState.speaking => 'Speaking',
      _AiState.idle => 'Connected',
    };
    final stateColor = switch (_aiState) {
      _AiState.listening => Colors.lightGreenAccent,
      _AiState.thinking => Colors.amberAccent,
      _AiState.speaking => Colors.white,
      _AiState.idle => Colors.white70,
    };

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryDark,
            AppTheme.primary,
            AppTheme.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          _PulseAvatar(
            active: _aiState == _AiState.listening ||
                _aiState == _AiState.speaking,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: stateColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                stateLabel,
                style: TextStyle(
                  color: stateColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // realtime caption — what the user is saying OR AI's streaming reply
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: ListView(
                reverse: true,
                physics: const BouncingScrollPhysics(),
                children: [
                  if (_listeningVoice && _heardText.isNotEmpty)
                    _bubble(text: _heardText, fromUser: true, live: true),
                  if (_liveReply.isNotEmpty)
                    _bubble(text: _liveReply, fromUser: false, live: true),
                  ..._turns.reversed.map(
                    (t) => _bubble(text: t.text, fromUser: t.fromUser),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble({required String text, required bool fromUser, bool live = false}) {
    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: fromUser
              ? Colors.white.withValues(alpha: 0.9)
              : Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(fromUser ? 16 : 4),
            bottomRight: Radius.circular(fromUser ? 4 : 16),
          ),
          border: live
              ? Border.all(color: Colors.white.withValues(alpha: 0.6))
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: fromUser ? AppTheme.textPrimary : Colors.white,
            fontSize: 14,
            height: 1.35,
          ),
        ),
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

class _PulseAvatar extends StatefulWidget {
  final bool active;
  const _PulseAvatar({required this.active});

  @override
  State<_PulseAvatar> createState() => _PulseAvatarState();
}

class _PulseAvatarState extends State<_PulseAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        return SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.active) ...[
                _ring(t, 0.0),
                _ring(t, 0.33),
                _ring(t, 0.66),
              ],
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.smart_toy_rounded,
                    color: Colors.white, size: 56),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _ring(double t, double phase) {
    final value = ((t + phase) % 1.0);
    final size = 110.0 + value * 90;
    final opacity = (1.0 - value).clamp(0.0, 1.0) * 0.4;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border:
            Border.all(color: Colors.white.withValues(alpha: opacity), width: 2),
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
