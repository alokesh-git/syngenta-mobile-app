import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter_soloud/flutter_soloud.dart';

class AudioOutput {
  var initialized = false;
  AudioSource? stream;
  SoundHandle? handle;
  final int sampleRate = 24000;
  final Channels channels = Channels.mono;
  final BufferType format = BufferType.s16le; // pcm16bits

  Future<void> init() async {
    if (initialized) {
      return;
    }

    /// Initialize the player (singleton).
    await SoLoud.instance.init(sampleRate: sampleRate, channels: channels);
    initialized = true;
  }

  Future<void> dispose() async {
    if (initialized) {
      SoLoud.instance.disposeAllSources();
      SoLoud.instance.deinit();
      initialized = false;
    }
  }

  SoLoud get instance => SoLoud.instance;

  AudioSource? setupNewStream() {
    if (!SoLoud.instance.isInitialized) {
      return null;
    }

    stream = SoLoud.instance.setBufferStream(
      maxBufferSizeBytes:
          1024 * 1024 * 10, // 10MB of max buffer (not allocated)
      bufferingType: BufferingType.released,
      bufferingTimeNeeds: 0,
      sampleRate: sampleRate,
      channels: channels,
      format: format,
      onBuffering: (isBuffering, handle, time) {
        log('Buffering: $isBuffering, Time: $time');
      },
    );
    log("New audio output stream buffer created.");
    return stream;
  }

  Future<AudioSource?> playStream() async {
    var myStream = setupNewStream();
    if (!SoLoud.instance.isInitialized || myStream == null) {
      return null;
    }
    // Play audio stream
    handle = await SoLoud.instance.play(myStream);
    stream = myStream;
    return stream;
  }

  void addDataToAudioStream(Uint8List audioChunk) {
    var currentStream = stream;
    if (currentStream != null) {
      SoLoud.instance.addAudioDataStream(currentStream, audioChunk);
    }
  }

  Future<void> stopStream() async {
    var currentStream = stream;
    var currentHandle = handle;

    // Stream doesn't exist or handle is not valid - so nothing to stop.
    if (currentStream == null ||
        currentHandle == null ||
        !SoLoud.instance.getIsValidVoiceHandle(currentHandle)) {
      return;
    }
    // End data to stream & stop currently playing sound from handle
    SoLoud.instance.setDataIsEnded(currentStream);
    await SoLoud.instance.stop(currentHandle);
  }
}
