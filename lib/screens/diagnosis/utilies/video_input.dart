import 'dart:developer';
import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class VideoInput extends ChangeNotifier {
  late List<CameraDescription> _cameras;
  late CameraController _cameraController;
  Timer? _captureTimer; // Timer for periodic capture
  StreamController<Uint8List> _imageStreamController = StreamController();
  bool _isStreaming = false;

  Future<void> init() async {
    try {
      _cameras = await availableCameras();
      _cameraController = CameraController(
        _cameras[0],
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _cameraController.initialize();
      notifyListeners();
    } catch (e) {
      log('Error initializing camera: $e');
    }
  }

  CameraController get cameraController => _cameraController;

  Stream<Uint8List> startStreamingImages() {
    _captureTimer = Timer.periodic(
      Duration(seconds: 1), // Capture images at 1 frame per second
      (timer) async {
        if (!_cameraController.value.isInitialized || !_isStreaming) {
          log("Stopping timer due to invalid state.");
          stopStreamingImages();
          return;
        }

        try {
          // Prevent taking picture if already taking one
          if (_cameraController.value.isTakingPicture) {
            return;
          }
          log("Taking picture...");
          final XFile imageFile = await _cameraController.takePicture();
          Uint8List imageBytes = await imageFile.readAsBytes();
          _imageStreamController.add(imageBytes);
        } catch (e) {
          log('Error taking picture: $e');
        }
      },
    );
    _isStreaming = true;
    return _imageStreamController.stream;
  }

  /// Stops the periodic image capture and closes the stream.
  Future<void> stopStreamingImages() async {
    if (!_isStreaming) {
      return; // Nothing to stop
    }
    _captureTimer?.cancel();
    await _imageStreamController.close();
    _imageStreamController = StreamController();
    _cameraController.dispose();
    init(); // Reinitialize the camera for reuse later
    _isStreaming = false;
  }

  @override
  void dispose() {
    super.dispose();
    stopStreamingImages();
    _cameraController.dispose();
  }
}
