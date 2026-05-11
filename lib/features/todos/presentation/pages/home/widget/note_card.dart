// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:taskee/app/extension/capital_firstletter_extension.dart';
// import 'package:taskee/app/extension/context_extension.dart';
// import 'package:taskee/app/extension/size_extension.dart';
// import 'package:taskee/app/theme/app_colors.dart';
// import 'package:taskee/app/theme/app_typography.dart';
// import 'package:taskee/features/notes/domain/entities/note.dart';

// class NoteCard extends StatelessWidget {
//   final Note note;
//   final VoidCallback onClickItem;
//   final VoidCallback onClickDelete;

//   const NoteCard({
//     super.key,
//     required this.note,
//     required this.onClickDelete,
//     required this.onClickItem,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(20),
//           height: context.screenHeight * .4,
//           width: context.screenWidth * .6,
//           decoration: BoxDecoration(
//             color: AppColors.accent,
//             borderRadius: 20.radius,
//           ),
//           child: Column(
//             children: [
//               Text(
//                 note.note.capitalizeFirst(),
//                 style: AppTypography.h4.copyWith(color: AppColors.kBlack),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//     // Dismissible(
//     //   key: Key("deleted_note_${note.id}"),
//     //   direction: DismissDirection.endToStart,
//     //   onDismissed: (direction) => onClickDelete(),
//     //   background: Container(
//     //     color: Colors.red,
//     //     alignment: Alignment.centerRight,
//     //     padding: const EdgeInsets.only(right: 20),
//     //     child: const Icon(CupertinoIcons.delete, color: Colors.white),
//     //   ),
//     //   child: ListTile(
//     //     onTap: onClickItem,
//     //     title: Text(
//     //       note.note.capitalizeFirst(),
//     //       maxLines: 1,
//     //       overflow: TextOverflow.ellipsis,
//     //       style: AppTypography.h4,
//     //     ),
//     //   ),
//     // );
//   }
// }
