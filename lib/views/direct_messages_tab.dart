import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'chat_screen.dart';
import '../widgets/anime_background.dart';

/// A WhatsApp‑style Direct Messages tab.
///
/// Shows every registered user (except the current one) with avatar, name and uid.
/// Tapping a user opens a one‑to‑one chat using a deterministic chat‑room ID
/// (the lower UID first, then an underscore, then the higher UID).
class DirectMessagesTab extends StatelessWidget {
  const DirectMessagesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final firestore = context.read<FirestoreService>();
    final currentUserId = auth.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.85),
        title: const Text('Direct Messages', style: TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: AnimeBackground(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF8B0000)));
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Error loading users: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white70)),
              );
            }
            final docs = snapshot.data?.docs ?? [];
            // Exclude the current user from the list
            final users = docs.where((d) => d.id != currentUserId).toList();
            if (users.isEmpty) {
              return const Center(child: Text('No other users found.', style: TextStyle(color: Colors.white70)));
            }
            return ListView.builder(
              itemCount: users.length,
                itemBuilder: (context, index) {
                  final data = users[index].data() as Map<String, dynamic>;
                  final uid = users[index].id;
                  final name = data['name'] ?? data['username'] ?? 'User';
                  final photoUrl = data['photoUrl'] as String?;
                  final chatId = firestore.getChatRoomId(currentUserId, uid);
                  return StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('chats').doc(chatId).snapshots(),
                    builder: (context, chatSnap) {
                      int unread = 0;
                      if (chatSnap.hasData && chatSnap.data != null) {
                        final dataMap = chatSnap.data!.data() as Map<String, dynamic>?;
                        if (dataMap != null && dataMap['unreadCounts'] != null) {
                          final counts = dataMap['unreadCounts'] as Map<String, dynamic>;
                          unread = (counts[currentUserId] ?? 0) as int;
                        }
                      }
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF8B0000), width: 0.5),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF8B0000),
                            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                            child: photoUrl == null
                                ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.white))
                                : null,
                          ),
                          title: Text(name,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          subtitle: Text(uid, style: const TextStyle(color: Colors.white60)),
                          trailing: unread > 0
                              ? Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$unread',
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                )
                              : null,
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => ChatScreen(chatId: chatId, chatName: name),
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
    );
  }
}
