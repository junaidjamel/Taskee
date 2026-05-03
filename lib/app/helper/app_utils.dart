import 'package:flutter/material.dart';

class AppUtils {
  static void showSnackBar(
      {required BuildContext context,
      required String message,
      required String label,
      required Function onPress}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: label,
          onPressed: () => {onPress()},
        ),
      ));
  }
}
