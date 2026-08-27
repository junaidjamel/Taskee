import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:taskee/app/theme/app_assets.dart';
import 'package:taskee/app/theme/app_colors.dart';
import 'package:taskee/app/theme/app_typography.dart';
import 'package:taskee/features/widget/app_gradient.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const String _displayNameKey = 'user_display_name';
  static const String _defaultDisplayName = 'New User';

  final TextEditingController _nameController = TextEditingController();
  bool _showDefaultAvatar = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentName();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentName() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString(_displayNameKey)?.trim();

    if (!mounted) return;

    setState(() {
      _nameController.text = savedName == null || savedName.isEmpty
          ? _defaultDisplayName
          : savedName;
      _nameController.selection = TextSelection.fromPosition(
        TextPosition(offset: _nameController.text.length),
      );
    });
  }

  Future<void> _saveDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    final value = _nameController.text.trim();
    final finalName = value.isEmpty ? _defaultDisplayName : value;

    await prefs.setString(_displayNameKey, finalName);

    if (!mounted) return;
    Navigator.pop(context, finalName);
  }

  Widget _buildAvatar() {
    if (_showDefaultAvatar) {
      return ClipOval(
        child: SizedBox(
          width: 120,
          height: 120,
          child: Image.asset(AppAssets.profileImg, fit: BoxFit.cover),
        ),
      );
    }

    final initials = _nameController.text.trim().isEmpty
        ? 'NU'
        : _nameController.text.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).take(2).map((word) => word[0].toUpperCase()).join();

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accent, Color(0xFF7B61FF)],
        ),
      ),
      child: Center(
        child: Text(
          initials.isEmpty ? 'NU' : initials,
          style: AppTypography.h1.copyWith(fontSize: 34, color: Colors.black),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        ),
        title: Text('Edit Profile', style: AppTypography.h3),
      ),
      body: AppGradient(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _buildAvatar(),
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _showDefaultAvatar = !_showDefaultAvatar;
                          });
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accent,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.7),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.black, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  'Your profile picture',
                  style: AppTypography.bodyMd.copyWith(color: AppColors.kgrey),
                ),
                const SizedBox(height: 28),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Name',
                    style: AppTypography.labelMd.copyWith(color: AppColors.kgrey),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _nameController,
                  style: AppTypography.h3.copyWith(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.white10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.white10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.accent),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveDisplayName,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text('Save profile', style: AppTypography.labelLg),
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
