import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

class AudioInput extends ChangeNotifier {
  final _recorder = AudioRecorder();
  RecordConfig recordConfig = RecordConfig(
    encoder: AudioEncoder.pcm16bits,
    sampleRate: 24000,
    numChannels: 1,
    echoCancel: true,
    noiseSuppress: true,
    androidConfig: AndroidRecordConfig(
      audioSource: AndroidAudioSource.voiceCommunication,
    ),
    iosConfig: IosRecordConfig(categoryOptions: []),
  );
  bool isRecording = false;
  bool isPaused = false;

  Future<void> init() async {
    await checkPermission();
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> checkPermission() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw MicrophonePermissionDeniedException(
        'This app does not have microphone permissions. Please enable it.',
      );
    }
  }

  Future<Stream<Uint8List>> startRecordingStream() async {
    final devices = await _recorder.listInputDevices();
    log(devices.toString());
    // Make audioStream a local variable and convert to a broadcast stream.
    final audioStream = (await _recorder.startStream(
      recordConfig,
    )).asBroadcastStream();
    isRecording = true;
    //print("${isRecording ? "Is" : "Not"} Recording");
    notifyListeners();
    return audioStream;
  }

  Future<void> stopRecording() async {
    await _recorder.stop();
    isRecording = false;
    //print("${isRecording ? "Is" : "Not"} Recording");
    notifyListeners();
  }

  Future<void> togglePauseRecording() async {
    isPaused ? await _recorder.resume() : await _recorder.pause();
    isPaused = !isPaused;
    notifyListeners();
    return;
  }
}

/// An exception thrown when microphone permission is denied or not granted.
class MicrophonePermissionDeniedException implements Exception {
  /// The optional message associated with the permission denial.
  final String? message;

  /// Creates a new [MicrophonePermissionDeniedException] with an optional [message].
  MicrophonePermissionDeniedException([this.message]);

  @override
  String toString() {
    if (message == null) {
      return 'MicrophonePermissionDeniedException';
    }
    return 'MicrophonePermissionDeniedException: $message';
  }
}
