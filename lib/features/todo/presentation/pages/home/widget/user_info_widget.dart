import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:taskee/app/extension/size_extension.dart';
import 'package:taskee/app/extension/widget_padding_extension.dart';
import 'package:taskee/app/theme/app_assets.dart';
import 'package:taskee/app/theme/app_colors.dart';
import 'package:taskee/app/theme/app_typography.dart';
import 'package:taskee/features/user/presentation/pages/edit_profile_page.dart';

class UserInfoWidget extends StatefulWidget {
  const UserInfoWidget({super.key});

  @override
  State<UserInfoWidget> createState() => _UserInfoWidgetState();
}

class _UserInfoWidgetState extends State<UserInfoWidget> {
  static const String _displayNameKey = 'user_display_name';
  static const String _defaultDisplayName = 'New User';

  String _displayName = _defaultDisplayName;

  @override
  void initState() {
    super.initState();
    _loadDisplayName();
  }

  Future<void> _loadDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString(_displayNameKey)?.trim();

    if (!mounted) return;

    setState(() {
      _displayName = savedName == null || savedName.isEmpty
          ? _defaultDisplayName
          : savedName;
    });
  }

  Future<void> _navigateToProfileEditor() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const EditProfilePage()));

    if (!mounted) return;
    _loadDisplayName();
  }

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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, Good Morning',
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.kgrey,
                    ),
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 34),
                        child: Text(
                          _displayName,
                          style: AppTypography.h2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 2,
                        child: Material(
                          color: AppColors.accent,
                          shape: const CircleBorder(),
                          elevation: 6,
                          child: InkWell(
                            onTap: _navigateToProfileEditor,
                            customBorder: const CircleBorder(),
                            child: const SizedBox(
                              width: 26,
                              height: 26,
                              child: Icon(
                                Icons.edit,
                                color: Colors.black,
                                size: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ).paddingOnly(left: 20),
      ],
    );
  }
}
