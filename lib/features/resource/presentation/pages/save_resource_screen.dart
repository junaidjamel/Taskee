import 'dart:async';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:taskee/app/theme/app_colors.dart';
import 'package:taskee/app/theme/app_typography.dart';
import 'package:taskee/features/resource/data/cloud_sync_service.dart';
import 'package:taskee/features/resource/data/resource_enrichment_service.dart';
import 'package:taskee/features/resource/data/resource_link_service.dart';
import 'package:taskee/features/resource/data/resource_store.dart';
import 'package:taskee/features/resource/domain/resource.dart';
import 'package:taskee/features/widget/app_gradient.dart';

class SaveResourceScreen extends StatefulWidget {
  const SaveResourceScreen({super.key});

  @override
  State<SaveResourceScreen> createState() => _SaveResourceScreenState();
}

class _SaveResourceScreenState extends State<SaveResourceScreen> {
  final TextEditingController _urlController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _saving = false;
  bool _dragging = false;
  bool _pasting = false;
  bool _understandingImage = false;

  Future<void> _saveUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty || _saving) return;
    setState(() => _saving = true);

    try {
      final draft = await ResourceEnrichmentService.enrich(url);
      final now = DateTime.now();
      final resource = Resource(
        id: now.microsecondsSinceEpoch.toString(),
        title: draft.title,
        url: url,
        creator: draft.creator,
        platform: draft.platform,
        summary: draft.summary,
        whyUseful: draft.whyUseful,
        useWhen: draft.useWhen,
        thumbnail: draft.thumbnail,
        type: draft.type,
        topics: draft.topics,
        technologies: draft.technologies,
        savedAt: now,
      );
      await ResourceStore.save(resource);
      if (!mounted) return;
      _urlController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved ${resource.title}')),
      );
    } on FormatException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save that resource. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveScreenshot() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    await _saveFileReference(
      name: image.name,
      path: image.path,
      mimeType: image.mimeType,
      bytes: await image.readAsBytes(),
    );
  }

  Future<void> _pasteImageFromClipboard() async {
    if (_pasting) return;
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image paste is not available in this browser.')),
      );
      return;
    }

    setState(() => _pasting = true);
    try {
      final reader = await clipboard.read();
      final candidates = <(FileFormat, String, String)>[
        (Formats.png, 'png', 'image/png'),
        (Formats.jpeg, 'jpg', 'image/jpeg'),
        (Formats.webp, 'webp', 'image/webp'),
        (Formats.gif, 'gif', 'image/gif'),
      ];

      (FileFormat, String, String)? selected;
      for (final candidate in candidates) {
        if (reader.canProvide(candidate.$1)) {
          selected = candidate;
          break;
        }
      }

      if (selected == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('There is no image in the clipboard.')),
        );
        return;
      }

      final completer = Completer<List<int>>();
      reader.getFile(
        selected.$1,
        (file) async {
          try {
            final bytes = await file.readAll();
            if (!completer.isCompleted) completer.complete(bytes);
          } catch (error, stackTrace) {
            if (!completer.isCompleted) completer.completeError(error, stackTrace);
          }
        },
        onError: (error) {
          if (!completer.isCompleted) completer.completeError(error);
        },
      );

      final bytes = await completer.future;
      if (bytes.isEmpty) throw StateError('Clipboard image was empty.');

      final stamp = DateTime.now().millisecondsSinceEpoch;
      await _saveFileReference(
        name: 'clipboard-image-$stamp.${selected.$2}',
        path: '',
        mimeType: selected.$3,
        bytes: bytes,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not paste that image. Your browser may need clipboard permission.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _pasting = false);
    }
  }

  Future<void> _saveDroppedFiles(DropDoneDetails details) async {
    if (details.files.isEmpty) return;
    setState(() => _dragging = false);

    var saved = 0;
    for (final file in details.files) {
      await _saveFileReference(
        name: file.name,
        path: file.path,
        mimeType: file.mimeType,
        bytes: await file.readAsBytes(),
        showConfirmation: false,
      );
      saved++;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved $saved dropped ${saved == 1 ? 'resource' : 'resources'}')),
    );
  }

  Future<void> _saveFileReference({
    required String name,
    required String path,
    required List<int> bytes,
    String? mimeType,
    bool showConfirmation = true,
  }) async {
    final now = DateTime.now();
    final cleanName = name.trim().isEmpty ? 'Dropped resource' : name.trim();
    final isImage = mimeType?.startsWith('image/') == true ||
        RegExp(r'\.(png|jpe?g|gif|webp|heic)$', caseSensitive: false)
            .hasMatch(cleanName);

    ImageResourceAnalysis? analysis;
    if (isImage &&
        bytes.isNotEmpty &&
        CloudSyncService.isConfigured &&
        CloudSyncService.isSignedIn) {
      if (mounted) setState(() => _understandingImage = true);
      try {
        analysis = await CloudSyncService.analyzeImage(
          bytes: bytes,
          contentType: mimeType ?? 'image/png',
        );
      } catch (_) {
        // Saving still succeeds with the local fallback metadata.
      } finally {
        if (mounted) setState(() => _understandingImage = false);
      }
    }

    final extractedUrl = analysis?.url == null
        ? null
        : ResourceLinkService.normalize(analysis!.url)?.toString();

    var resource = Resource(
      id: now.microsecondsSinceEpoch.toString(),
      title: analysis?.title ?? cleanName,
      url: isImage ? extractedUrl : (path.isEmpty ? null : path),
      creator: analysis?.creator,
      platform: analysis?.platform ?? (isImage ? 'Screenshot' : 'Desktop file'),
      summary: analysis?.summary ??
          (isImage
              ? 'A visual reference saved from your desktop.'
              : 'A file saved from your desktop as a project reference.'),
      whyUseful: analysis?.whyUseful ??
          'Kept because you chose it as something Future You may need again.',
      useWhen: analysis?.useWhen ??
          'Resurface when a project overlaps with this file or visual reference.',
      thumbnail: isImage && path.isNotEmpty ? path : null,
      type: analysis == null
          ? (isImage ? ResourceType.screenshot : ResourceType.other)
          : _resourceTypeFromName(analysis.resourceType),
      topics: analysis?.topics ?? [if (isImage) 'screenshot', 'desktop capture'],
      technologies: analysis?.technologies ?? const [],
      savedAt: now,
    );

    await ResourceStore.save(resource);

    if (CloudSyncService.isSignedIn && CloudSyncService.isConfigured && bytes.isNotEmpty) {
      try {
        final assetPath = await CloudSyncService.uploadAsset(
          resourceId: resource.id,
          fileName: cleanName,
          bytes: bytes,
          contentType: mimeType,
        );
        if (assetPath != null) {
          resource = resource.copyWith(assetPath: assetPath);
          await ResourceStore.save(resource);
        }
      } catch (_) {
        // The local resource stays saved even if the cloud asset upload is interrupted.
      }
    }

    if (showConfirmation && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            analysis == null
                ? 'Saved ${resource.title}'
                : 'Understood and saved ${resource.title}',
          ),
        ),
      );
    }
  }

  ResourceType _resourceTypeFromName(String value) {
    return ResourceType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => ResourceType.screenshot,
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyV, control: true): _pasteImageFromClipboard,
        const SingleActivator(LogicalKeyboardKey.keyV, meta: true): _pasteImageFromClipboard,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: AppGradient(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 800;
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 40 : 20,
                      vertical: 20,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.arrow_back),
                              ),
                              const SizedBox(width: 4),
                              Text('Save something useful', style: AppTypography.h3),
                            ]),
                            const SizedBox(height: 24),
                            Text('Paste a link', style: AppTypography.h2),
                            const SizedBox(height: 8),
                            Text(
                              'Threads, YouTube, GitHub, websites, tutorials — anything Future You should remember.',
                              style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 22),
                            TextField(
                              controller: _urlController,
                              keyboardType: TextInputType.url,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _saveUrl(),
                              decoration: InputDecoration(
                                hintText: 'https://...',
                                filled: true,
                                fillColor: AppColors.surface,
                                prefixIcon: const Icon(Icons.link),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide(color: AppColors.kBorderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide(color: AppColors.kBorderColor),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _saving ? null : _saveUrl,
                                icon: _saving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.auto_awesome),
                                label: Text(_saving ? 'Understanding…' : 'Understand and save'),
                              ),
                            ),
                            const SizedBox(height: 28),
                            Row(children: [
                              Expanded(child: Divider(color: AppColors.kBorderColor)),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text('OR'),
                              ),
                              Expanded(child: Divider(color: AppColors.kBorderColor)),
                            ]),
                            const SizedBox(height: 28),
                            DropTarget(
                              onDragEntered: (_) => setState(() => _dragging = true),
                              onDragExited: (_) => setState(() => _dragging = false),
                              onDragDone: _saveDroppedFiles,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: _understandingImage ? null : _saveScreenshot,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 22,
                                    vertical: isDesktop ? 40 : 22,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _dragging ? AppColors.accentMuted : AppColors.surface,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: _dragging ? AppColors.accent : AppColors.kBorderColor,
                                      width: _dragging ? 2 : 1,
                                    ),
                                  ),
                                  child: Column(children: [
                                    CircleAvatar(
                                      backgroundColor: AppColors.accentMuted,
                                      child: _understandingImage
                                          ? const Padding(
                                              padding: EdgeInsets.all(10),
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : Icon(
                                              _dragging
                                                  ? Icons.file_download_outlined
                                                  : Icons.content_paste_go_outlined,
                                              color: AppColors.accent,
                                            ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _understandingImage
                                          ? 'Understanding this image…'
                                          : _dragging
                                              ? 'Drop it here'
                                              : (isDesktop
                                                  ? 'Drag, upload, or paste an image'
                                                  : 'Upload or paste a screenshot'),
                                      style: AppTypography.h3,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _understandingImage
                                          ? 'Looking for the resource, URL, creator, technologies, and when it will be useful again.'
                                          : (isDesktop
                                              ? 'Drop files here, click to choose an image, or copy an image and press Ctrl+V / Cmd+V.'
                                              : 'Choose an image or use Paste image to capture your clipboard.'),
                                      textAlign: TextAlign.center,
                                      style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
                                    ),
                                    const SizedBox(height: 16),
                                    OutlinedButton.icon(
                                      onPressed: _pasting || _understandingImage
                                          ? null
                                          : _pasteImageFromClipboard,
                                      icon: _pasting
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : const Icon(Icons.content_paste),
                                      label: Text(_pasting ? 'Reading clipboard…' : 'Paste image'),
                                    ),
                                    if (CloudSyncService.isConfigured &&
                                        !CloudSyncService.isSignedIn) ...[
                                      const SizedBox(height: 10),
                                      Text(
                                        'Connect Sync Devices to automatically understand screenshots.',
                                        textAlign: TextAlign.center,
                                        style: AppTypography.bodySm.copyWith(
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ]),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
