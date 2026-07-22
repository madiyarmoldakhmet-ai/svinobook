import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import 'chat_screen.dart';

/// A modern Direct Messages tab.
///
/// Shows every registered user (except the current one) with avatar, name and
/// last status. Tapping a user opens a one-to-one chat.
class DirectMessagesTab extends StatelessWidget {
  const DirectMessagesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final firestore = context.read<FirestoreService>();
    final currentUserId = auth.currentUser?.uid ?? '';
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            // ── Header ──
            Container(
              padding: EdgeInsets.only(
                top: topPad + 16,
                left: 20,
                right: 20,
                bottom: 16,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonCyan.withValues(alpha: 0.3),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.forum_rounded,
                        color: AppColors.bgDarkest),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Messages',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 28,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── User list ──
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.neonCyan),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                          'Error loading users: ${snapshot.error}',
                          style: const TextStyle(
                              color: AppColors.textSecondary)),
                    );
                  }
                  final docs = snapshot.data?.docs ?? [];
                  final users =
                      docs.where((d) => d.id != currentUserId).toList();
                  if (users.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline,
                              size: 64,
                              color: AppColors.neonCyan
                                  .withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text('No other users yet',
                              style:
                                  TextStyle(color: AppColors.textMuted)),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final data =
                          users[index].data() as Map<String, dynamic>;
                      final uid = users[index].id;
                      final name =
                          data['name'] ?? data['username'] ?? 'User';
                      final photoUrl = data['photoUrl'] as String?;
                      final status =
                          (data['status'] as String?)?.isNotEmpty == true
                              ? (data['status'] as String)
                              : 'Available';
                      final chatId =
                          firestore.getChatRoomId(currentUserId, uid);
                      return StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('chats')
                            .doc(chatId)
                            .snapshots(),
                        builder: (context, chatSnap) {
                          int unread = 0;
                          if (chatSnap.hasData &&
                              chatSnap.data != null &&
                              chatSnap.data!.exists) {
                            final dataMap = chatSnap.data!.data()
                                as Map<String, dynamic>?;
                            final counts =
                                dataMap?['unreadCounts'] as Map?;
                            if (counts != null) {
                              unread = (counts[currentUserId] ?? 0) as int;
                            }
                          }
                          return GlassCard(
                            margin: const EdgeInsets.only(bottom: 10),
                            borderRadius: 16,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              leading: GradientAvatar(
                                name: name,
                                radius: 26,
                                backgroundImage: photoUrl != null
                                    ? NetworkImage(photoUrl)
                                    : null,
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  if (unread > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        gradient: AppColors.primaryGradient,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.neonCyan
                                                .withValues(alpha: 0.4),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        '$unread',
                                        style: const TextStyle(
                                          color: AppColors.bgDarkest,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.neonGreen
                                          .withValues(alpha: 0.8),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Text(status,
                                      style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 13)),
                                ],
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                    MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                      chatId: chatId, chatName: name),
                                ));
                              },
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}