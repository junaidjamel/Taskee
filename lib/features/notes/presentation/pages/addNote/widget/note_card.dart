import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:taskee/app/extension/capital_firstletter_extension.dart';
import 'package:taskee/features/notes/domain/entities/note.dart';

const _kAccentLight = Color(0xFFD8E87C);
const _kGlassBorder = Color(0x44FFFFFF);
const _kTextDark = Color(0xFF1A1A1A);
const _kTextLight = Color(0xFFEFEFEF);

class NoteCard extends StatelessWidget {
  final Note note;
  final bool isLight;
  final double cardW;
  final double cardH;
  final VoidCallback onDelete;

  const NoteCard({
    super.key,
    required this.note,
    required this.isLight,
    required this.cardW,
    required this.cardH,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return isLight ? _lightCard(context) : _glassCard(context);
  }

  // ── Light / accent card (always the front) ──────────────────────────────
  Widget _lightCard(BuildContext context) {
    return Container(
      width: cardW,
      height: cardH,
      decoration: BoxDecoration(
        color: _kAccentLight,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _kAccentLight.withValues(alpha: 0.35),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: _CardContent(
        note: note,
        textColor: _kTextDark,
        tagBg: Colors.black.withValues(alpha: 0.12),
        tagText: _kTextDark.withValues(alpha: 0.7),
        iconColor: _kTextDark.withValues(alpha: 0.5),
        onDelete: onDelete,
      ),
    );
  }

  Widget _glassCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: cardW,
          height: cardH,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.09),
                Colors.white.withValues(alpha: 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _kGlassBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: _CardContent(
            note: note,
            textColor: _kTextLight,
            tagBg: Colors.white.withValues(alpha: 0.12),
            tagText: _kTextLight.withValues(alpha: 0.7),
            iconColor: _kTextLight.withValues(alpha: 0.5),
            onDelete: onDelete,
          ),
        ),
      ),
    );
  }
}

// ─── Card Inner Content ───────────────────────────────────────────────────────

class _CardContent extends StatelessWidget {
  final Note note;
  final Color textColor;
  final Color tagBg;
  final Color tagText;
  final Color iconColor;
  final VoidCallback onDelete;

  const _CardContent({
    required this.note,
    required this.textColor,
    required this.tagBg,
    required this.tagText,
    required this.iconColor,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: icon + delete
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.sticky_note_2_outlined,
                  color: textColor.withValues(alpha: 0.6),
                  size: 18,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Note body
          Expanded(
            child: Text(
              note.note.capitalizeFirst(),
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 17,
                height: 1.55,
                color: textColor,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.1,
              ),
              maxLines: 7,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 16),

          // Tags row (optional — show first 2 words as tags if note has them)
          if (_extractTags(note.note).isNotEmpty)
            Wrap(
              spacing: 6,
              children: _extractTags(note.note)
                  .map((t) => _Tag(label: t, bg: tagBg, textColor: tagText))
                  .toList(),
            ),

          const SizedBox(height: 14),

          // Footer: timestamp + swipe hint
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(note.createdAt),
                style: TextStyle(
                  fontSize: 16,
                  color: textColor.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.swipe_left_alt_rounded,
                      size: 13,
                      color: textColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'swipe',
                      style: TextStyle(
                        fontSize: 11,
                        color: textColor.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<String> _extractTags(String text) {
    // Simple heuristic: hashtags in text, or default to first keyword
    final regex = RegExp(r'#\w+');
    final matches = regex.allMatches(text).map((m) => m.group(0)!).toList();
    if (matches.isNotEmpty) return matches.take(2).toList();
    return [];
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Today';
    final now = DateTime.now();
    if (dt.day == now.day) return 'Today';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ─── Tag Chip ─────────────────────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  final String label;
  final Color bg;
  final Color textColor;

  const _Tag({required this.label, required this.bg, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 24,
          color: textColor,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
