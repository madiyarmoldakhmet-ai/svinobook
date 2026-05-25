import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_session_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'chat_screen.dart';
import 'package:intl/intl.dart';
import '../widgets/anime_background.dart';

class DirectMessagesTab extends StatelessWidget {
  const DirectMessagesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthService>().currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.85),
        title: const Text(
          'MESSAGES',
          style: TextStyle(
            color: Color(0xFF8B0000),
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1.2,
          ),
        ),
        elevation: 0,
      ),
      body: AnimeBackground(
        child: StreamBuilder<List<ChatSessionModel>>(
          stream: context.read<FirestoreService>().getChatSessionsStream(currentUserId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF8B0000)));
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading messages: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white70),
                ),
              );
            }
            final sessions = snapshot.data ?? [];

            if (sessions.isEmpty) {
              return const Center(
                child: Text(
                  'The world is empty... post something.',
                  style: TextStyle(color: Colors.white60, fontSize: 16, fontStyle: FontStyle.italic),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                int otherIndex = session.participantIds.indexWhere((id) => id != currentUserId);
                String otherName = otherIndex != -1 && session.participantNames.length > otherIndex
                    ? session.participantNames[otherIndex]
                    : 'Unknown';

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
                      child: Text(
                        otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      otherName,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    subtitle: Text(
                      session.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white60),
                    ),
                    trailing: Text(
                      DateFormat.MMMd().format(session.lastUpdated),
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(chatId: session.id, chatName: otherName),
                        ),
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
