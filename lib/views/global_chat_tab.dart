import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../widgets/chat_bubble.dart';
import '../utils/image_picker_helper.dart';
import '../widgets/anime_background.dart';

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
                        "The world is empty... post something.",
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
