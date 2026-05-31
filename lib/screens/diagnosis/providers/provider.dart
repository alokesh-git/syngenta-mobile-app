import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../utilies/audio_input.dart';
import '../utilies/audio_output.dart';
import '../utilies/video_input.dart';

final audioInputProvider = ChangeNotifierProvider<AudioInput>((ref) {
  return AudioInput();
});

final videoInputProvider = Provider<VideoInput>((ref) {
  return VideoInput();
});

final audioOutputProvider = Provider<AudioOutput>((ref) {
  return AudioOutput();
});
