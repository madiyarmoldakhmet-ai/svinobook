import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF1E1E1E),
        child: child,
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        String? bgUrl;
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null) {
            bgUrl = data['chatBackgroundUrl'] as String?;
          }
        }

        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            image: (bgUrl != null && bgUrl.trim().isNotEmpty)
                ? DecorationImage(
                    image: NetworkImage(bgUrl.trim()),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.65),
                      BlendMode.darken,
                    ),
                  )
                : null,
          ),
          child: child,
        );
      },
    );
  }
}
