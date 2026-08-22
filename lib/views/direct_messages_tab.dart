import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import 'chat_screen.dart';

/// Direct message directory in the classic compact social layout.
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

    return Scaffold(
      backgroundColor: AppColors.bgDarkest,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(16, topPad + 14, 16, 12),
            color: AppColors.surfaceDark,
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Messages',
                    style: TextStyle(
                      color: AppColors.onDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                ),
                const Icon(Icons.forum_outlined, color: Colors.white, size: 21),
              ],
            ),
          ),
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
            child: const Text(
              'All conversations',
              style: TextStyle(color: AppColors.neonCyan, fontSize: 13),
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
                    child: CircularProgressIndicator(color: AppColors.neonCyan),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading users: ${snapshot.error}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }
                final docs = snapshot.data?.docs ?? [];
                final users = docs.where((d) => d.id != currentUserId).toList();
                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: AppColors.neonCyan.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No other users yet',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final data = users[index].data() as Map<String, dynamic>;
                    final uid = users[index].id;
                    final name = data['name'] ?? data['username'] ?? 'User';
                    final photoUrl = data['photoUrl'] as String?;
                    final status =
                        (data['status'] as String?)?.isNotEmpty == true
                        ? (data['status'] as String)
                        : 'Available';
                    final chatId = firestore.getChatRoomId(currentUserId, uid);
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
                          final dataMap =
                              chatSnap.data!.data() as Map<String, dynamic>?;
                          final counts = dataMap?['unreadCounts'] as Map?;
                          if (counts != null) {
                            unread = (counts[currentUserId] ?? 0) as int;
                          }
                        }
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: AppColors.bgMid,
                            border: Border.all(color: AppColors.glassBorder),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            leading: GradientAvatar(
                              name: name,
                              radius: 22,
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
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(90),
                                    ),
                                    child: Text(
                                      '$unread',
                                      style: const TextStyle(
                                        color: Colors.white,
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
                                    color: AppColors.neonGreen.withValues(
                                      alpha: 0.8,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Text(
                                  status,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                              onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    chatId: chatId,
                                    chatName: name,
                                  ),
                                ),
                              );
                              },
                            ),
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
    );
  }
}
