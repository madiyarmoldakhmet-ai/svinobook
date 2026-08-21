import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_theme.dart';

/// A modern animated gradient background.
///
/// If the signed-in user has set a custom wallpaper URL it will be used as a
/// dimmed cover image, otherwise a smooth animated gradient is shown.
class AnimeBackground extends StatelessWidget {
  final Widget child;

  const AnimeBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _gradientBase(null, child);
    }

    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        String? bgUrl;
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null) {
            bgUrl = data['chatBackgroundUrl'] as String?;
          }
        }
        return _gradientBase(bgUrl, child);
      },
    );
  }

  Widget _gradientBase(String? bgUrl, Widget child) {
    final hasBg = bgUrl != null && bgUrl.trim().isNotEmpty;
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.backgroundGradient,
        image: hasBg
            ? DecorationImage(
                image: NetworkImage(bgUrl.trim()),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  AppColors.bgDarkest.withValues(alpha: 0.72),
                  BlendMode.darken,
                ),
              )
            : null,
      ),
      child: child,
    );
  }
}