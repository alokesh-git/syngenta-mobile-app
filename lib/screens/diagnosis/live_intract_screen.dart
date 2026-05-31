import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'components/bottom_bar.dart';
import 'components/branding.dart';
import 'components/camera_preview.dart';
import 'components/sound_waves.dart';
import 'providers/provider.dart';
import 'utilies/audio_input.dart';

class LiveIntractScreen extends ConsumerStatefulWidget {
  const LiveIntractScreen({super.key});

  @override
  ConsumerState<LiveIntractScreen> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<LiveIntractScreen> {
  // Flag(s) to prevent multiple stream initializations
  bool _audioIsInitialized = false;
  bool _videoIsInitialized = false;
  bool _microphonePermissionDenied = false;
  final LiveGenerativeModel _liveModel =
      FirebaseAI.vertexAI().liveGenerativeModel(
    model: 'gemini-3.1-flash-live-preview',
    systemInstruction: Content.text(
      'You are a plant identifier. Greet the user by telling them that you '
      'are a plant identifier. Ask them to turn on their camera and show '
      'you a plant and you can help them identify plants and flowers. '
      'Your job is to help the user dentify plants and flowers. '
      'When the user asks you to identify a plant or flower, respond '
      'by telling them what it is and along with fun fact about it. '
      'If you\'re unable to identify the plant or flower, you may ask the user '
      'for more information about it or ask for a closer look.',
    ),
    liveGenerationConfig: LiveGenerationConfig(
      speechConfig: SpeechConfig(voiceName: 'fenrir'),
      responseModalities: [ResponseModalities.audio],
    ),
  );
  late LiveSession _session; // Gemini Live Session
  bool _settingUpLiveSession = false; // Session is getting set up
  bool _liveSessionIsOpen = false; // Session is open and ready to go.
  bool _audioStreamIsActive =
      false; // Session is running and with audio input & output streams active
  bool _cameraIsActive = false; // Whether sending video stream to Gemini

  @override
  void initState() {
    super.initState();
    // Load the first frame AND THEN initialize audio & video setup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAudio();
      _initializeVideo();
    });
  }

  @override
  void dispose() {
    super.dispose();
    ref.read(audioInputProvider).dispose();
    ref.read(audioOutputProvider).dispose();
    ref.read(videoInputProvider).dispose();
    if (_liveSessionIsOpen) {
      unawaited(_session.close()); // Ensure session is closed on dispose
    }
  }

  /// AUDIO INPUT & OUTPUT
  Future<void> _initializeAudio() async {
    try {
      await ref.read(audioInputProvider).init(); // Initialize Audio Input
      await ref.read(audioOutputProvider).init(); // Initialize Audio Output

      setState(() {
        _audioIsInitialized = true;
        _microphonePermissionDenied = false;
      });
    } catch (e) {
      log("Error during audio initialization: $e");
      if (!mounted) return;
      print(e);
      
      if (e is MicrophonePermissionDeniedException) {
        setState(() {
          _microphonePermissionDenied = true;
        });
        _showPermissionDialog();
      } else {
        var errorSnackBar = SnackBar(
          content: Text('Oops! Something went wrong with the audio setup : $e'),
          action: SnackBarAction(label: 'Retry', onPressed: _initializeAudio),
        );
        ScaffoldMessenger.of(context).showSnackBar(errorSnackBar);
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          elevation: 8,
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Premium Styled Icon Wrapper
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF81C784)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: const Icon(
                      Icons.mic_off_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Microphone Access Required',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'To talk with the AI Plant Doctor and diagnose crop issues, KisanConnect needs access to your device\'s microphone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                // Core benefits/features container
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    children: [
                      _buildDialogBenefitRow(
                        Icons.voice_chat_outlined,
                        'Voice Assist',
                        'Describe issues naturally in real-time',
                      ),
                      const SizedBox(height: 8),
                      _buildDialogBenefitRow(
                        Icons.auto_awesome_outlined,
                        'AI Plant Doctor',
                        'Get instant audio feedback on solutions',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.of(dialogContext).pop();
                      await Geolocator.openAppSettings();
                    },
                    child: const Text(
                      'Open Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          _initializeAudio();
                        },
                        child: const Text(
                          'Check Again',
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: Text(
                          'Maybe Later',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogBenefitRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF2E7D32)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void toggleAudioStream() async {
    _audioStreamIsActive ? await stopAudioStream() : await startAudioStream();
  }

  Future<void> startAudioStream() async {
    // Start the Gemini Live session
    await _toggleLiveSession();

    final audioInput = ref.read(audioInputProvider);
    final audioOutput = ref.read(audioOutputProvider);

    // Start recording audio input stream
    var audioInputStream = await audioInput.startRecordingStream();
    log('Audio input stream is recording!');

    // Start playing audio output stream
    await audioOutput.playStream();
    log('Audio output stream is playing!');

    setState(() {
      _audioStreamIsActive = true;
    });

    // Wrap input stream audio data in InlineDataPart and send to Gemini session
    _session.sendMediaStream(
      audioInputStream.map((data) {
        return InlineDataPart('audio/pcm', data);
      }),
    );
  }

  Future<void> stopAudioStream() async {
    // If sending video, stop recording & transmitting.
    if (_cameraIsActive) {
      stopVideoStream();
    }
    // Stop recording audio input
    await ref.read(audioInputProvider).stopRecording();

    // Stop playing audio output
    await ref.read(audioOutputProvider).stopStream();

    // End the Gemini live session
    await _toggleLiveSession();

    setState(() {
      _audioStreamIsActive = false;
    });
  }

  Future<void> toggleMuteInput() async {
    await ref.read(audioInputProvider).togglePauseRecording();
  }

  /// VIDEO INPUT
  Future<void> _initializeVideo() async {
    try {
      await ref.read(videoInputProvider).init();
      setState(() {
        _videoIsInitialized = true;
      });
    } catch (e) {
      log("Error during video initialization: $e");
    }
  }

  void startVideoStream() {
    if (!_videoIsInitialized || !_audioStreamIsActive || _cameraIsActive) {
      return;
    }

    Stream<Uint8List> imageStream =
        ref.read(videoInputProvider).startStreamingImages();

    // Wrap video input stream image data in InlineDataPart and send to Gemini session
    _session.sendMediaStream(
      imageStream.map((data) {
        return InlineDataPart("image/jpeg", data);
      }),
    );

    setState(() {
      _cameraIsActive = true;
    });
  }

  void stopVideoStream() async {
    await ref.read(videoInputProvider).stopStreamingImages();
    setState(() {
      _cameraIsActive = false;
    });
  }

  void toggleVideoStream() async {
    _cameraIsActive ? stopVideoStream() : startVideoStream();
  }

  /// Firebase AI Logic
  Future<void> _toggleLiveSession() async {
    setState(() {
      _settingUpLiveSession = true;
    });

    if (!_liveSessionIsOpen) {
      _session = await _liveModel.connect();
      _liveSessionIsOpen = true;
      unawaited(processMessagesContinuously());
    } else {
      await _session.close();
      _liveSessionIsOpen = false;
    }

    setState(() {
      _settingUpLiveSession = false;
    });
  }

  Future<void> processMessagesContinuously() async {
    try {
      await for (final response in _session.receive()) {
        // Process the received message
        LiveServerMessage message = response.message;
        await _handleLiveServerMessage(message);
      }
      log('Live session receive stream completed.');
    } catch (e) {
      log('Error receiving live session messages: $e');
    }
  }

  Future<void> _handleLiveServerMessage(LiveServerMessage response) async {
    if (response is LiveServerContent) {
      if (response.modelTurn != null) {
        await _handleLiveServerContent(response);
      }
      if (response.turnComplete != null && response.turnComplete!) {
        await _handleTurnComplete();
      }
      if (response.interrupted != null && response.interrupted!) {
        log('Interrupted: $response');
      }
    }

    if (response is LiveServerToolCall && response.functionCalls != null) {
      await _handleLiveServerToolCall(response);
    }
  }

  Future<void> _handleLiveServerContent(LiveServerContent response) async {
    final partList = response.modelTurn?.parts;
    if (partList != null) {
      for (final part in partList) {
        switch (part) {
          case TextPart textPart:
            await _handleTextPart(textPart);
          case InlineDataPart inlineDataPart:
            await _handleInlineDataPart(inlineDataPart);
          default:
            log('Received part with type ${part.runtimeType}');
        }
      }
    }
  }

  Future<void> _handleInlineDataPart(InlineDataPart part) async {
    if (part.mimeType.startsWith('audio')) {
      // If DataPart is audio, add it to the output audio stream
      ref.read(audioOutputProvider).addDataToAudioStream(part.bytes);
    }
  }

  Future<void> _handleTextPart(TextPart part) async {
    log('Text message from Gemini: ${part.text}');
  }

  Future<void> _handleTurnComplete() async {
    log('Model is done generating. Turn complete!');
  }

  Future<void> _handleLiveServerToolCall(LiveServerToolCall response) async {
    if (response.functionCalls?.isNotEmpty ?? false) {
      log("Gemini made a function call!");
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioInput = ref.watch(audioInputProvider);
    final videoInput = ref.watch(videoInputProvider);

    return Scaffold(
      // backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leadingWidth: 100,
        leading: LeafAppIcon(),
        title: AppTitle(title: 'FlutterFire AI Demo'),
      ),
      body: _cameraIsActive
          ? Center(
              child: FullCameraPreview(controller: videoInput.cameraController),
            )
          : CenterCircle(
              child: Padding(
                padding: EdgeInsets.all(60),
                child: _settingUpLiveSession
                    ? CircularProgressIndicator()
                    : Icon(size: 54, Icons.waves),
              ),
            ),
      bottomNavigationBar: BottomBar(
        child: Row(
          children: [
            ChatButton(),
            VideoButton(
              isActive: _cameraIsActive,
              onPressed: toggleVideoStream,
            ),
            const Spacer(),
            MuteButton(
              isMuted: audioInput.isPaused,
              onPressed: _audioStreamIsActive ? toggleMuteInput : null,
            ),
            CallButton(
              isActive: _audioStreamIsActive,
              onPressed: _audioIsInitialized
                  ? toggleAudioStream
                  : (_microphonePermissionDenied ? _showPermissionDialog : null),
            ),
          ],
        ),
      ),
    );
  }
}
