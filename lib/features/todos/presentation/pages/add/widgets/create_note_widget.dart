import 'package:flutter/material.dart';
import 'package:taskee/app/theme/app_typography.dart';

class NoteWidget extends StatelessWidget {
  const NoteWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.note_alt_outlined, size: 64, color: Colors.white38),
          const SizedBox(height: 16),
          Text(
            'No notes yet',
            style: AppTypography.h2.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap here to start writing your note',
            style: TextStyle(fontSize: 14, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}
