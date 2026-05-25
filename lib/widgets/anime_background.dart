import 'package:flutter/material.dart';

class AnimeBackground extends StatelessWidget {
  final Widget child;
  final String? imageAsset;

  const AnimeBackground({
    super.key,
    required this.child,
    this.imageAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        image: imageAsset != null
            ? DecorationImage(
                image: AssetImage(imageAsset!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.75),
                  BlendMode.darken,
                ),
              )
            : null,
      ),
      child: imageAsset == null
          ? Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black,
                    Color(0xFF1E0C0C),
                    Colors.black,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: child,
            )
          : child,
    );
  }
}
