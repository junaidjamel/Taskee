import 'package:flutter/material.dart';

class AppGradient extends StatelessWidget {
  final Widget child;
  const AppGradient({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF252320), // top-left: warm greying-brown
            Color(0xFF070504), // top-right: near black
            Color(0xFF160D0A), // bottom-left: dark brown
            Color(0xFF48251A), // bottom-right: reddish warm
          ],
          stops: [0.0, 0.35, 0.5, 1.0],
        ),
      ),
      child: child,
    );
  }
}
