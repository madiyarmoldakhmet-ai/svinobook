import 'package:flutter/material.dart';

class AnimeBackground extends StatelessWidget {
  final Widget child;

  const AnimeBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF1E1E1E),
      child: child,
    );
  }
}
