import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_session_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'chat_screen.dart';
import 'package:intl/intl.dart';

class DirectMessagesTab extends StatelessWidget {
  const DirectMessagesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthService>().currentUser?.uid ?? '';

    return StreamBuilder<List<ChatSessionModel>>(
      stream: context.read<FirestoreService>().getChatSessionsStream(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading messages'));
        }
        final sessions = snapshot.data ?? [];

        if (sessions.isEmpty) {
          return const Center(child: Text('No active chats. Start a new one!'));
        }

        return ListView.builder(
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            // Find the other participant's name
            int otherIndex = session.participantIds.indexWhere((id) => id != currentUserId);
            String otherName = otherIndex != -1 && session.participantNames.length > otherIndex
                ? session.participantNames[otherIndex]
                : 'Unknown';

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF1877F2),
                child: Text(
                  otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(
                otherName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                session.lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                DateFormat.MMMd().format(session.lastUpdated),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(chatId: session.id, chatName: otherName),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
