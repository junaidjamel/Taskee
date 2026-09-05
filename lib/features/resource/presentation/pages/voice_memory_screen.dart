import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:taskee/app/theme/app_colors.dart';
import 'package:taskee/app/theme/app_typography.dart';
import 'package:taskee/features/resource/data/cloud_sync_service.dart';
import 'package:taskee/features/resource/data/resource_link_service.dart';
import 'package:taskee/features/resource/data/resource_store.dart';
import 'package:taskee/features/resource/data/voice_capture_service.dart';
import 'package:taskee/features/resource/domain/resource.dart';
import 'package:taskee/features/widget/app_gradient.dart';

class VoiceMemoryScreen extends StatefulWidget {
  const VoiceMemoryScreen({super.key});

  @override
  State<VoiceMemoryScreen> createState() => _VoiceMemoryScreenState();
}

class _VoiceMemoryScreenState extends State<VoiceMemoryScreen> {
  final VoiceCaptureService _capture = VoiceCaptureService();
  Timer? _timer;
  bool _recording = false;
  bool _processing = false;
  Duration _elapsed = Duration.zero;

  Future<void> _toggleRecording() async {
    if (_processing) return;
    if (_recording) {
      final bytes = await _capture.stop();
      _timer?.cancel();
      setState(() {
        _recording = false;
        _elapsed = Duration.zero;
      });
      if (bytes != null && bytes.isNotEmpty) {
        await _saveVoice(
          bytes: bytes,
          fileName: 'voice-memory-${DateTime.now().millisecondsSinceEpoch}.wav',
          contentType: 'audio/wav',
        );
      }
      return;
    }

    final allowed = await _capture.start();
    if (!mounted) return;
    if (!allowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission is needed to record a voice memory.')),
      );
      return;
    }

    setState(() => _recording = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final elapsed = _capture.elapsed;
      if (elapsed >= const Duration(minutes: 5)) {
        _toggleRecording();
        return;
      }
      setState(() => _elapsed = elapsed);
    });
  }

  Future<void> _pickExistingAudio() async {
    if (_processing || _recording) return;
    final result = await FilePicker.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) return;
    await _saveVoice(
      bytes: bytes,
      fileName: file.name,
      contentType: _contentTypeFor(file.name),
    );
  }

  Future<void> _saveVoice({
    required List<int> bytes,
    required String fileName,
    required String contentType,
  }) async {
    if (_processing) return;
    setState(() => _processing = true);

    try {
      AudioResourceAnalysis? analysis;
      if (CloudSyncService.isConfigured && CloudSyncService.isSignedIn) {
        analysis = await CloudSyncService.analyzeAudio(
          bytes: bytes,
          contentType: contentType,
        );
      }

      final now = DateTime.now();
      final extractedUrl = analysis?.url == null
          ? null
          : ResourceLinkService.normalize(analysis!.url)?.toString();
      var resource = Resource(
        id: now.microsecondsSinceEpoch.toString(),
        title: analysis?.title ?? 'Voice memory',
        url: extractedUrl,
        creator: analysis?.creator,
        platform: analysis?.platform ?? 'Voice note',
        summary: analysis?.summary ?? 'A voice note saved for Future You.',
        whyUseful: analysis?.whyUseful ??
            'You recorded this because the idea or reference was worth remembering.',
        useWhen: analysis?.useWhen ??
            'Resurface when a future project overlaps with what you said in this note.',
        transcript: analysis?.transcript,
        type: analysis == null
            ? ResourceType.other
            : _resourceTypeFromName(analysis.resourceType),
        topics: analysis?.topics ?? const ['voice note'],
        technologies: analysis?.technologies ?? const [],
        savedAt: now,
      );

      await ResourceStore.save(resource);

      if (CloudSyncService.isConfigured && CloudSyncService.isSignedIn) {
        final assetPath = await CloudSyncService.uploadAsset(
          resourceId: resource.id,
          fileName: fileName,
          bytes: bytes,
          contentType: contentType,
        );
        if (assetPath != null) {
          resource = resource.copyWith(assetPath: assetPath);
          await ResourceStore.save(resource);
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            analysis == null
                ? 'Saved voice memory.'
                : 'Understood and saved ${resource.title}',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save that voice note: $error')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  ResourceType _resourceTypeFromName(String value) {
    return ResourceType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => ResourceType.other,
    );
  }

  String _contentTypeFor(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.mp3')) return 'audio/mpeg';
    if (lower.endsWith('.m4a') || lower.endsWith('.mp4')) return 'audio/mp4';
    if (lower.endsWith('.ogg') || lower.endsWith('.opus')) return 'audio/ogg';
    if (lower.endsWith('.webm')) return 'audio/webm';
    return 'audio/wav';
  }

  String get _timeLabel {
    final minutes = _elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _capture.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradient(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      IconButton(
                        onPressed: _recording || _processing
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 4),
                      Text('Voice memory', style: AppTypography.h3),
                    ]),
                    const SizedBox(height: 28),
                    Text('Say it before you forget it.', style: AppTypography.h2),
                    const SizedBox(height: 8),
                    Text(
                      'Record an idea or bring in an existing voice memo. Resource Memory will transcribe it, understand what matters, and make it searchable later.',
                      style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppColors.kBorderColor),
                      ),
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _recording
                                  ? AppColors.accent
                                  : AppColors.accentMuted,
                            ),
                            child: Icon(
                              _recording ? Icons.stop_rounded : Icons.mic_none_rounded,
                              size: 42,
                              color: _recording ? Colors.black : AppColors.accent,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            _processing
                                ? 'Understanding your voice note…'
                                : (_recording ? _timeLabel : 'Up to 5 minutes'),
                            style: AppTypography.h3,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _processing
                                ? 'Transcribing, finding tools and topics, and deciding when this should come back.'
                                : (_recording
                                    ? 'Tap stop when you are finished.'
                                    : 'Speak naturally. Mention the project, tool, site, or reason you want to remember it.'),
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _processing ? null : _toggleRecording,
                              icon: _processing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Icon(_recording ? Icons.stop : Icons.mic),
                              label: Text(
                                _processing
                                    ? 'Understanding…'
                                    : (_recording ? 'Stop and save' : 'Record voice note'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _processing || _recording ? null : _pickExistingAudio,
                        icon: const Icon(Icons.audio_file_outlined),
                        label: const Text('Choose an existing voice memo'),
                      ),
                    ),
                    if (CloudSyncService.isConfigured &&
                        !CloudSyncService.isSignedIn) ...[
                      const SizedBox(height: 14),
                      Text(
                        'Voice notes can be saved locally now. Connect Sync Devices to add transcription, automatic understanding, cross-device sync, and the original audio file.',
                        style: AppTypography.bodySm.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                    const SizedBox(height: 28),
                    Text('What gets saved', style: AppTypography.h3),
                    const SizedBox(height: 10),
                    Text(
                      'Original audio • transcript • title • summary • tools and technologies • useful-again trigger',
                      style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
