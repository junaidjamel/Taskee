import 'package:flutter/material.dart';

extension ContextExtension on BuildContext {
  // Screen size
  double get screenHeight => MediaQuery.of(this).size.height;
  double get screenWidth => MediaQuery.of(this).size.width;

  // Theme
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;

  // Navigation
  void pop() => Navigator.of(this).pop();
  void push(Widget page) =>
      Navigator.of(this).push(MaterialPageRoute(builder: (_) => page));
}
