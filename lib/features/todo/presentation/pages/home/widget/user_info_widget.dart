import 'package:flutter/material.dart';
import 'package:taskee/app/extension/size_extension.dart';
import 'package:taskee/app/extension/widget_padding_extension.dart';
import 'package:taskee/app/theme/app_assets.dart';
import 'package:taskee/app/theme/app_colors.dart';
import 'package:taskee/app/theme/app_typography.dart';

class UserInfoWidget extends StatelessWidget {
  const UserInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Plan your Day !', style: AppTypography.h2).paddingAll(20),
        Row(
          children: [
            SizedBox(
              width: 50,
              height: 50,

              child: ClipRRect(
                borderRadius: BorderRadiusGeometry.only(
                  topLeft: Radius.circular(30),
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                  topRight: Radius.circular(12),
                ),

                child: Image.asset(AppAssets.profileImg, fit: BoxFit.cover),
              ),
            ),
            14.kW,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, Good Morning',
                  style: AppTypography.bodyMd.copyWith(color: AppColors.kgrey),
                ),
                Text('Jacobe', style: AppTypography.h2),
              ],
            ),
            14.kW,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.white54,
                size: 16,
              ),
            ),
          ],
        ).paddingOnly(left: 20),
      ],
    );
  }
}
