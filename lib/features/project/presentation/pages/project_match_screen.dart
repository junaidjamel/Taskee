import 'package:flutter/material.dart';
import 'package:taskee/app/theme/app_colors.dart';
import 'package:taskee/app/theme/app_typography.dart';
import 'package:taskee/features/resource/data/resource_link_service.dart';
import 'package:taskee/features/resource/data/resource_store.dart';
import 'package:taskee/features/resource/domain/resource.dart';
import 'package:taskee/features/widget/app_gradient.dart';

class ProjectMatchScreen extends StatefulWidget {
  const ProjectMatchScreen({super.key});

  @override
  State<ProjectMatchScreen> createState() => _ProjectMatchScreenState();
}

class _ProjectMatchScreenState extends State<ProjectMatchScreen> {
  final TextEditingController _projectController = TextEditingController();
  List<_Match> _matches = const [];
  bool _searched = false;

  static const _stopWords = {
    'the','and','for','with','that','this','from','into','using','use','make','build','building','create','creating','want','need','app','project','system'
  };

  void _findMatches() {
    final query = _projectController.text.trim().toLowerCase();
    if (query.isEmpty) return;
    final terms = query
        .replaceAll(RegExp(r'[^a-z0-9+#. ]'), ' ')
        .split(RegExp(r'\s+'))
        .where((term) => term.length > 2 && !_stopWords.contains(term))
        .toSet();

    final ranked = ResourceStore.getAll().map((resource) {
      final matched = terms.where((term) => resource.searchableText.contains(term)).toList();
      var score = matched.length;
      for (final tech in resource.technologies) {
        if (query.contains(tech.toLowerCase())) score += 2;
      }
      return _Match(resource: resource, score: score, terms: matched);
    }).where((item) => item.score > 0).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    setState(() {
      _searched = true;
      _matches = ranked.take(12).toList();
    });
  }

  Future<void> _open(Resource resource) =>
      ResourceLinkService.open(context, resource.url);

  @override
  void dispose() {
    _projectController.dispose();
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
                  Text('Start a project', style: AppTypography.h3),
                ]),
                const SizedBox(height: 20),
                Text('What are you building?', style: AppTypography.h2),
                const SizedBox(height: 8),
                Text(
                  'Describe it normally. We’ll look through what you already saved.',
                  style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _projectController,
                  minLines: 3,
                  maxLines: 5,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _findMatches(),
                  decoration: InputDecoration(
                    hintText: 'I’m building a Roblox inventory system in Luau.',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: AppColors.kBorderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: AppColors.kBorderColor),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _findMatches,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Find what I already saved'),
                  ),
                ),
                const SizedBox(height: 22),
                if (_searched)
                  Text(
                    _matches.isEmpty
                        ? 'Nothing in your library matches yet.'
                        : 'You already saved ${_matches.length} thing${_matches.length == 1 ? '' : 's'} that may help',
                    style: AppTypography.h3,
                  ),
                if (_searched && _matches.isEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'That is useful too — now you know what you still need to find.',
                    style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
                  ),
                ],
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: _matches.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final match = _matches[index];
                      final resource = match.resource;
                      final hasLink = ResourceLinkService.normalize(resource.url) != null;
                      return InkWell(
                        onTap: hasLink ? () => _open(resource) : null,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.kBorderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(child: Text(resource.title, style: AppTypography.h3)),
                                if (hasLink)
                                  IconButton(
                                    tooltip: 'Open link',
                                    onPressed: () => _open(resource),
                                    icon: const Icon(Icons.open_in_new, size: 18),
                                  ),
                              ]),
                              if (hasLink) ...[
                                const SizedBox(height: 2),
                                Text(
                                  ResourceLinkService.display(resource.url!),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodySm.copyWith(
                                    color: AppColors.accent,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 5),
                              Text(
                                resource.summary,
                                style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
                              ),
                              if (match.terms.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Matched: ${match.terms.join(' · ')}',
                                  style: AppTypography.labelMd.copyWith(color: AppColors.accent),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text(
                                'Use when: ${resource.useWhen}',
                                style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
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

class _Match {
  const _Match({required this.resource, required this.score, required this.terms});
  final Resource resource;
  final int score;
  final List<String> terms;
}
