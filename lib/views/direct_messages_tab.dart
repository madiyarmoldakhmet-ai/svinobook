// DirectMessagesTab: Shows list of all users and lets you start a new chat
// Added FloatingActionButton to open a dialog with user list.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/anime_background.dart';
import 'package:intl/intl.dart';

class DirectMessagesTab extends StatelessWidget {
  const DirectMessagesTab({super.key});

  void _openUserDialog(BuildContext context, List<QueryDocumentSnapshot> users) {
    final currentUserId = context.read<AuthService>().currentUser?.uid ?? '';
    final firestore = context.read<FirestoreService>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Select a user to chat'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: users.length,
            itemBuilder: (ctx, i) {
              final data = users[i].data() as Map<String, dynamic>;
              final uid = users[i].id;
              final name = data['name'] ?? data['username'] ?? 'User';
              final photoUrl = data['photoUrl'] as String?;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF8B0000),
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white)) : null,
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                subtitle: Text(uid, style: const TextStyle(color: Colors.white60)),
                onTap: () {
                  final chatId = firestore.getChatRoomId(currentUserId, uid);
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ChatScreen(chatId: chatId, chatName: name)),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthService>().currentUser?.uid ?? '';
    final firestore = context.read<FirestoreService>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.85),
            letterSpacing: 1.2,
          ),
        ),
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
              return Center(child: Text('Error loading users: ${snapshot.error}', style: const TextStyle(color: Colors.white70)));
            }
            final users = snapshot.data?.docs ?? [];
            if (users.isEmpty) {
              return const Center(child: Text('No users found.', style: TextStyle(color: Colors.white70)));
            }
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final data = users[index].data() as Map<String, dynamic>;
                final uid = users[index].id;
                final name = data['name'] ?? data['username'] ?? 'User';
                final photoUrl = data['photoUrl'] as String?;
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
                      child: photoUrl == null ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white)) : null,
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: Text(uid, style: const TextStyle(color: Colors.white60)),
                    onTap: () {
                      final chatId = firestore.getChatRoomId(currentUserId, uid);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ChatScreen(chatId: chatId, chatName: name)),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
