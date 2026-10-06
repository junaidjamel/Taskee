import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:resource_memory/app/routing/app_route.dart';
import 'package:resource_memory/app/theme/app_colors.dart';
import 'package:resource_memory/app/theme/app_typography.dart';
import 'package:resource_memory/features/resource/data/resource_link_service.dart';
import 'package:resource_memory/features/resource/data/resource_store.dart';
import 'package:resource_memory/features/resource/domain/resource.dart';
import 'package:resource_memory/features/widget/app_gradient.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  ResourceType? _filter;
  @override void dispose() { _searchController.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    return Scaffold(body: AppGradient(child: SafeArea(child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back)),
          const SizedBox(width: 4),
          Expanded(child: Text('Your memory', style: AppTypography.h3)),
          IconButton(tooltip: 'Save something', onPressed: () => context.go('/${Routes.saveResourceScreen}'), icon: const Icon(Icons.add)),
        ]),
        const SizedBox(height: 18),
        Text('Everything you asked NanyNany to remember.', style: AppTypography.h2),
        const SizedBox(height: 6),
        Text('Links, screenshots, voice memories, articles, tools and tab sessions stay together here.', style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
          decoration: InputDecoration(
            hintText: 'What are you trying to find?', prefixIcon: const Icon(Icons.search), filled: true, fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: AppColors.kBorderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: AppColors.kBorderColor)),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(height: 40, child: ListView(scrollDirection: Axis.horizontal, children: [
          _FilterChip(label: 'All', selected: _filter == null, onTap: () => setState(() => _filter = null)),
          _FilterChip(label: 'Tab sessions', selected: _filter == ResourceType.session, onTap: () => setState(() => _filter = ResourceType.session)),
          _FilterChip(label: 'Screenshots', selected: _filter == ResourceType.screenshot, onTap: () => setState(() => _filter = ResourceType.screenshot)),
          _FilterChip(label: 'Web', selected: _filter == ResourceType.website, onTap: () => setState(() => _filter = ResourceType.website)),
          _FilterChip(label: 'Videos', selected: _filter == ResourceType.video, onTap: () => setState(() => _filter = ResourceType.video)),
          _FilterChip(label: 'Articles', selected: _filter == ResourceType.article, onTap: () => setState(() => _filter = ResourceType.article)),
          _FilterChip(label: 'Tools', selected: _filter == ResourceType.tool, onTap: () => setState(() => _filter = ResourceType.tool)),
        ])),
        const SizedBox(height: 12),
        Expanded(child: ValueListenableBuilder<Box<Map>>(
          valueListenable: ResourceStore.box.listenable(),
          builder: (context, _, __) {
            final all = ResourceStore.getAll()..sort((a, b) => b.savedAt.compareTo(a.savedAt));
            final resources = all.where((r) => (_filter == null || r.type == _filter) && (_query.isEmpty || r.searchableText.contains(_query))).toList();
            if (resources.isEmpty) return Center(child: Text(all.isEmpty ? 'Nothing saved yet.\nSave something once and it will live here.' : 'Nothing matches this view.', textAlign: TextAlign.center, style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary)));
            return ListView.separated(itemCount: resources.length, separatorBuilder: (_, __) => const SizedBox(height: 12), itemBuilder: (context, index) => _ResourceCard(resource: resources[index]));
          },
        )),
      ]),
    ))));
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label; final bool selected; final VoidCallback onTap;
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap()));
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({required this.resource});
  final Resource resource;
  Future<void> _openLink(BuildContext context) async {
    await ResourceLinkService.open(context, resource.url);
  }
  void _openMemory(BuildContext context) => context.go('/resource/${resource.id}');
  Future<void> _delete(BuildContext context) async {
    await ResourceStore.remove(resource.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Removed ${resource.title}')));
  }

  @override Widget build(BuildContext context) {
    final hasLink = ResourceLinkService.normalize(resource.url) != null;
    final isSession = resource.type == ResourceType.session;
    final tabCount = resource.session?['tabCount'];
    return InkWell(
      borderRadius: BorderRadius.circular(22), onTap: () => _openMemory(context),
      child: Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.kBorderColor)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(backgroundColor: AppColors.accentMuted, child: Icon(_iconFor(resource.type), color: AppColors.accent)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(resource.title, style: AppTypography.h3)),
              if (hasLink && !isSession) IconButton(tooltip: 'Open original', onPressed: () => _openLink(context), icon: const Icon(Icons.open_in_new, size: 19)),
              const Icon(Icons.chevron_right),
              PopupMenuButton<String>(onSelected: (value) { if (value == 'delete') _delete(context); if (value == 'open') _openMemory(context); }, itemBuilder: (_) => const [PopupMenuItem(value: 'open', child: Text('Open memory')), PopupMenuItem(value: 'delete', child: Text('Delete'))]),
            ]),
            const SizedBox(height: 3),
            Text(isSession ? '${tabCount ?? 'Saved'} tabs · Tab session' : _labelFor(resource), style: AppTypography.labelMd.copyWith(color: AppColors.accent)),
            const SizedBox(height: 7),
            Text(resource.summary, maxLines: 3, overflow: TextOverflow.ellipsis, style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary)),
            if (isSession && resource.topics.isNotEmpty) ...[const SizedBox(height: 10), Text(resource.topics.take(3).join(' · '), maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary))],
            const SizedBox(height: 8),
            Text(_savedLabel(resource.savedAt), style: AppTypography.bodySm.copyWith(color: AppColors.textMuted)),
          ])),
        ]),
      ),
    );
  }

  String _labelFor(Resource resource) => [resource.type.name, resource.creator, resource.platform].whereType<String>().where((e) => e.isNotEmpty).join(' · ');
  String _savedLabel(DateTime date) { final local = date.toLocal(); return 'Saved ${local.month}/${local.day}/${local.year}'; }
  IconData _iconFor(ResourceType type) {
    switch (type) {
      case ResourceType.session: return Icons.tab_rounded;
      case ResourceType.github: return Icons.code;
      case ResourceType.video: return Icons.play_arrow;
      case ResourceType.screenshot: return Icons.image_outlined;
      case ResourceType.tool: return Icons.build_outlined;
      case ResourceType.tutorial: return Icons.school_outlined;
      case ResourceType.article: return Icons.article_outlined;
      case ResourceType.code: return Icons.code_rounded;
      case ResourceType.website: return Icons.language;
      default: return Icons.bookmark_outline;
    }
  }
}
