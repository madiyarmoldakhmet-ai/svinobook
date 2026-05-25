import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message_model.dart';
import '../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../widgets/chat_bubble.dart';
import '../utils/image_picker_helper.dart';
import '../widgets/anime_background.dart';
import 'chat_screen.dart';

class GlobalChatTab extends StatefulWidget {
  const GlobalChatTab({super.key});

  @override
  State<GlobalChatTab> createState() => _GlobalChatTabState();
}

class _GlobalChatTabState extends State<GlobalChatTab> {
  final _messageController = TextEditingController();
  Uint8List? _selectedImageBytes;
  bool _isSending = false;

  void _pickImage() async {
    final bytes = await ImagePickerHelper.pickImage();
    if (bytes != null) {
      setState(() {
        _selectedImageBytes = bytes;
      });
    }
  }

  void _removeSelectedImage() {
    setState(() {
      _selectedImageBytes = null;
    });
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _selectedImageBytes == null) return;

    setState(() => _isSending = true);

    final auth = context.read<AuthService>();
    final firestore = context.read<FirestoreService>();
    final user = auth.currentUser;

    if (user != null) {
      final username = user.email?.split('@')[0] ?? 'User';
      try {
        await firestore.sendGlobalMessage(user.uid, username, text, _selectedImageBytes);
        _messageController.clear();
        setState(() {
          _selectedImageBytes = null;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sending message: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSending = false);
        }
      }
    }
  }

  void _showUserSearch() {
    final firestore = context.read<FirestoreService>();
    final currentUserId = context.read<AuthService>().currentUser?.uid ?? '';
    showSearch<UserModel?>(
      context: context,
      delegate: UserSearchDelegate(firestore: firestore, currentUserId: currentUserId),
    ).then((selected) {
      if (selected != null) {
        final chatId = firestore.getChatRoomId(currentUserId, selected.id);
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ChatScreen(chatId: chatId, chatName: selected.name),
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthService>().currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.85),
        title: const Text(
          'GLOBAL NEXUS CHAT',
          style: TextStyle(
            color: Color(0xFF8B0000),
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Search Users',
            icon: const Icon(Icons.search, color: Color(0xFF8B0000)),
            onPressed: _showUserSearch,
          ),
        ],
        elevation: 0,
      ),
      body: AnimeBackground(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<ChatMessageModel>>(
                stream: context.read<FirestoreService>().getGlobalChatStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF8B0000)));
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading chat: ${snapshot.error}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    );
                  }
                  final messages = snapshot.data ?? [];
                  
                  if (messages.isEmpty) {
                    return const Center(
                      child: Text(
                        "No chats yet",
                        style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return ChatBubble(
                        text: msg.text,
                        senderName: msg.senderName,
                        timestamp: msg.timestamp,
                        isMe: msg.senderId == currentUserId,
                        imageUrl: msg.imageUrl,
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              color: Colors.black.withOpacity(0.85),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedImageBytes != null) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF8B0000)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  _selectedImageBytes!,
                                  height: 80,
                                  width: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const CircleAvatar(
                                backgroundColor: Colors.black54,
                                radius: 10,
                                child: Icon(Icons.close, color: Colors.white, size: 12),
                              ),
                              onPressed: _removeSelectedImage,
                            ),
                          ],
                        ),
                      ),
                    ],
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.photo, color: Color(0xFF8B0000)),
                          onPressed: _pickImage,
                        ),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white24),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextField(
                              controller: _messageController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: "Type a message...",
                                hintStyle: TextStyle(color: Colors.white38),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _isSending
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8B0000)),
                              )
                            : IconButton(
                                icon: const Icon(Icons.send, color: Color(0xFF8B0000)),
                                onPressed: _sendMessage,
                              ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------------
// SearchDelegate for finding users and opening a direct chat
// -------------------------------------------------------------------------
class UserSearchDelegate extends SearchDelegate<UserModel?> {
  final FirestoreService firestore;
  final String currentUserId;

  UserSearchDelegate({required this.firestore, required this.currentUserId});

  @override
  String? get searchFieldLabel => 'Search users...';

  @override
  TextStyle? get searchFieldStyle => const TextStyle(color: Colors.white);

  @override
  ThemeData appBarTheme(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return theme.copyWith(
      primaryColor: Colors.black.withOpacity(0.85),
      primaryIconTheme: const IconThemeData(color: Color(0xFF8B0000)),
      textTheme: const TextTheme(titleLarge: TextStyle(color: Colors.white, fontSize: 18)),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white54),
        border: InputBorder.none,
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF8B0000)));
        }
        final docs = snapshot.data!.docs.where((d) => d.id != currentUserId).toList();
        final users = docs.map((d) => UserModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
        final filtered = query.isEmpty
            ? users
            : users.where((u) => u.name.toLowerCase().contains(query.toLowerCase())).toList();
        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final user = filtered[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF8B0000),
                backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                child: user.photoUrl == null ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white)) : null,
              ),
              title: Text(user.name, style: const TextStyle(color: Colors.white)),
              subtitle: Text(user.id, style: const TextStyle(color: Colors.white70)),
              onTap: () => close(context, user),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) => const SizedBox.shrink();

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: Color(0xFF8B0000)),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Color(0xFF8B0000)),
      onPressed: () => close(context, null),
    );
  }
}
