import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

class VoiceCaptureService {
  final AudioRecorder _recorder = AudioRecorder();
  final List<int> _pcmBytes = [];
  StreamSubscription<Uint8List>? _subscription;
  Completer<void>? _streamDone;
  DateTime? _startedAt;

  static const int sampleRate = 16000;
  static const int channels = 1;
  static const int bitsPerSample = 16;

  bool get isRecording => _startedAt != null;
  Duration get elapsed => _startedAt == null
      ? Duration.zero
      : DateTime.now().difference(_startedAt!);

  Future<bool> start() async {
    if (isRecording) return true;
    if (!await _recorder.hasPermission()) return false;

    _pcmBytes.clear();
    _streamDone = Completer<void>();
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: channels,
        echoCancel: true,
        noiseSuppress: true,
      ),
    );
    _subscription = stream.listen(
      _pcmBytes.addAll,
      onDone: () {
        final done = _streamDone;
        if (done != null && !done.isCompleted) done.complete();
      },
      onError: (_) {
        final done = _streamDone;
        if (done != null && !done.isCompleted) done.complete();
      },
      cancelOnError: false,
    );
    _startedAt = DateTime.now();
    return true;
  }

  Future<Uint8List?> stop() async {
    if (!isRecording) return null;

    // On Safari/iOS PWA the recorder can deliver its last (or only) audio
    // chunk when stop() closes the MediaRecorder stream. Do not cancel the
    // subscription immediately or those bytes are lost and nothing is saved.
    await _recorder.stop();
    try {
      await _streamDone?.future.timeout(const Duration(seconds: 2));
    } on TimeoutException {
      // Keep whatever chunks have arrived; this also prevents a hung stop.
    }
    await _subscription?.cancel();
    _subscription = null;
    _streamDone = null;
    _startedAt = null;

    if (_pcmBytes.isEmpty) return null;
    return _wavFromPcm(Uint8List.fromList(_pcmBytes));
  }

  Future<void> cancel() async {
    if (isRecording) await _recorder.cancel();
    await _subscription?.cancel();
    _subscription = null;
    _streamDone = null;
    _startedAt = null;
    _pcmBytes.clear();
  }

  Future<void> dispose() async {
    await cancel();
    await _recorder.dispose();
  }

  Uint8List _wavFromPcm(Uint8List pcm) {
    const headerSize = 44;
    final out = Uint8List(headerSize + pcm.length);
    final data = ByteData.sublistView(out);

    void ascii(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        out[offset + i] = value.codeUnitAt(i);
      }
    }

    final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
    final blockAlign = channels * bitsPerSample ~/ 8;

    ascii(0, 'RIFF');
    data.setUint32(4, 36 + pcm.length, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, channels, Endian.little);
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, byteRate, Endian.little);
    data.setUint16(32, blockAlign, Endian.little);
    data.setUint16(34, bitsPerSample, Endian.little);
    ascii(36, 'data');
    data.setUint32(40, pcm.length, Endian.little);
    out.setRange(headerSize, out.length, pcm);
    return out;
  }
}
