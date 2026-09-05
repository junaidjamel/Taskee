import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:taskee/app/theme/app_colors.dart';
import 'package:taskee/app/theme/app_typography.dart';
import 'package:taskee/features/resource/data/resource_link_service.dart';
import 'package:taskee/features/resource/data/resource_store.dart';
import 'package:taskee/features/resource/domain/resource.dart';
import 'package:taskee/features/widget/app_gradient.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradient(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 4),
                  Text('Library', style: AppTypography.h3),
                ]),
                const SizedBox(height: 18),
                Text('Your saved resources', style: AppTypography.h2),
                const SizedBox(height: 6),
                Text(
                  'What you save here can come back when your work needs it.',
                  style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search your memory…',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppColors.surface,
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
                const SizedBox(height: 18),
                Expanded(
                  child: ValueListenableBuilder<Box<Map>>(
                    valueListenable: ResourceStore.box.listenable(),
                    builder: (context, _, __) {
                      final all = ResourceStore.getAll();
                      final resources = _query.isEmpty
                          ? all
                          : all.where((r) => r.searchableText.contains(_query)).toList();
                      if (resources.isEmpty) {
                        return Center(
                          child: Text(
                            all.isEmpty ? 'Nothing saved yet.' : 'No resources match that search.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: resources.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _ResourceCard(resource: resources[index]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({required this.resource});
  final Resource resource;

  Future<void> _open(BuildContext context) =>
      ResourceLinkService.open(context, resource.url);

  Future<void> _delete(BuildContext context) async {
    await ResourceStore.remove(resource.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Removed ${resource.title}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasLink = ResourceLinkService.normalize(resource.url) != null;
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: hasLink ? () => _open(context) : null,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.kBorderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: AppColors.accentMuted,
              child: Icon(_iconFor(resource.type), color: AppColors.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(resource.title, style: AppTypography.h3)),
                    if (hasLink)
                      IconButton(
                        tooltip: 'Open link',
                        onPressed: () => _open(context),
                        icon: const Icon(Icons.open_in_new, size: 19),
                      ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') _delete(context);
                        if (value == 'open') _open(context);
                      },
                      itemBuilder: (_) => [
                        if (hasLink)
                          const PopupMenuItem(value: 'open', child: Text('Open link')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ]),
                  if (resource.creator != null || resource.platform != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      [resource.creator, resource.platform].whereType<String>().join(' · '),
                      style: AppTypography.labelMd.copyWith(color: AppColors.accent),
                    ),
                  ],
                  if (hasLink) ...[
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () => _open(context),
                      child: Text(
                        ResourceLinkService.display(resource.url!),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.accent,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 5),
                  Text(
                    resource.summary,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Use when: ${resource.useWhen}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary),
                  ),
                  if (resource.technologies.isNotEmpty || resource.topics.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [...resource.technologies, ...resource.topics].take(5).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.accentMuted,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(tag, style: AppTypography.labelSm.copyWith(color: AppColors.accent)),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(ResourceType type) {
    switch (type) {
      case ResourceType.github:
        return Icons.code;
      case ResourceType.video:
        return Icons.play_arrow;
      case ResourceType.screenshot:
        return Icons.image_outlined;
      case ResourceType.tool:
        return Icons.build_outlined;
      case ResourceType.tutorial:
        return Icons.school_outlined;
      default:
        return Icons.link;
    }
  }
}
