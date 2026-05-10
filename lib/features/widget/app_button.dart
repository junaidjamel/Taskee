import 'package:flutter/material.dart';
import 'package:taskee/app/extension/size_extension.dart';
import 'package:taskee/app/theme/app_colors.dart';
import 'package:taskee/app/theme/app_typography.dart';
import 'package:taskee/features/widget/bouncing_animation.dart';

class AppButton extends StatelessWidget {
  final Color? btnColor;
  final String text;
  final VoidCallback? onTap;
  final Widget? child;
  final double? height;
  final double? width;
  final Color? textColor;
  final Color? borderColor;
  final double? borderRadius;
  final double? fontSize;

  const AppButton({
    super.key,
    this.btnColor,
    required this.text,
    required this.onTap,
    this.child,
    this.height,
    this.width,
    this.textColor,
    this.borderColor,
    this.borderRadius,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Bounce(
      onTap: onTap,
      child: Container(
        height: height ?? 50,
        width: width ?? MediaQuery.sizeOf(context).width,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: 12.radius,
          border: Border.all(color: borderColor ?? Colors.transparent),
        ),
        child:
            child ??
            Text(
              text,
              style: AppTypography.h3.copyWith(
                color: AppColors.kBlack,
                fontSize: fontSize ?? 16,
              ),
            ),
      ),
    );
  }
}
