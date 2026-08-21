import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message_model.dart';
import '../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/security_alert_card.dart';
import '../utils/image_picker_helper.dart';
import '../utils/app_theme.dart';
import '../models/security_alert_model.dart';
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

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

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
        await firestore.sendGlobalMessage(
            user.uid, username, text, _selectedImageBytes);
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
      delegate: UserSearchDelegate(
          firestore: firestore, currentUserId: currentUserId),
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
                right: 12,
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
                    child: const Icon(Icons.public_rounded,
                        color: AppColors.bgDarkest),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Global Chat',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Everyone, everywhere',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Search Users',
                    onPressed: _showUserSearch,
                    icon: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.glassBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.glassBorder, width: 1),
                      ),
                      child: const Icon(Icons.search_rounded,
                          color: AppColors.neonCyan, size: 22),
                    ),
                  ),
                ],
              ),
            ),

            // ── Messages ──
            Expanded(
              child: StreamBuilder<List<ChatMessageModel>>(
                stream:
                    context.read<FirestoreService>().getGlobalChatStream(),
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
                        'Error loading chat: ${snapshot.error}',
                        style:
                            const TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }
                  final messages = snapshot.data ?? [];

                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.forum_rounded,
                              size: 56,
                              color: AppColors.neonCyan
                                  .withValues(alpha: 0.3)),
                          const SizedBox(height: 12),
                          Text('No messages yet',
                              style:
                                  TextStyle(color: AppColors.textMuted)),
                          const SizedBox(height: 4),
                          Text('Start the conversation!',
                              style: TextStyle(
                                  color: AppColors.neonCyan
                                      .withValues(alpha: 0.6),
                                  fontSize: 13)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      if (msg.type == 'security_alert') {
                        final alert = SecurityAlertModel(
                          title: msg.alertType ?? 'Security Alert',
                          description: msg.alertDetails ?? msg.text,
                          severity: (msg.alertStatus ?? 'warning').toLowerCase(),
                          source: msg.alertSource ?? msg.senderName,
                          type: msg.alertType ?? 'security_alert',
                          createdAt: msg.timestamp,
                        );
                        return SecurityAlertCard(alert: alert);
                      }

                      return ChatBubble(
                        text: msg.text,
                        senderName: msg.senderName,
                        timestamp: msg.timestamp,
                        isMe: msg.senderId == currentUserId,
                        imageUrl: msg.imageUrl,
                        type: msg.type,
                      );
                    },
                  );
                },
              ),
            ),

            // ── Input bar ──
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedImageBytes != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.glassBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.glassBorder, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        _selectedImageBytes!,
                        height: 60,
                        width: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _removeSelectedImage,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: const Icon(Icons.close,
                            color: AppColors.danger, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 1,
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.neonCyan.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.photo_outlined,
                              color: AppColors.neonCyan
                                  .withValues(alpha: 0.7),
                              size: 20),
                        ),
                        onPressed: _pickImage,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(
                                color: AppColors.textMuted, fontSize: 15),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _isSending
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.neonCyan,
                                ),
                              ),
                            )
                          : GestureDetector(
                              onTap: _sendMessage,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x59129CFF),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.send_rounded,
                                    color: AppColors.bgDarkest, size: 20),
                              ),
                            ),
                    ],
                  ),
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

  UserSearchDelegate(
      {required this.firestore, required this.currentUserId});

  @override
  String? get searchFieldLabel => 'Search users...';

  @override
  TextStyle? get searchFieldStyle =>
      const TextStyle(color: AppColors.textPrimary);

  @override
  ThemeData appBarTheme(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgDark,
        foregroundColor: AppColors.textPrimary,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: AppColors.textMuted),
        border: InputBorder.none,
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container(
      color: AppColors.bgDarkest,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child:
                    CircularProgressIndicator(color: AppColors.neonCyan));
          }
          final docs = snapshot.data!.docs
              .where((d) => d.id != currentUserId)
              .toList();
          final users = docs
              .map((d) => UserModel.fromMap(
                  d.data() as Map<String, dynamic>, d.id))
              .toList();
          final filtered = query.isEmpty
              ? users
              : users
                  .where((u) =>
                      u.name.toLowerCase().contains(query.toLowerCase()))
                  .toList();
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final user = filtered[index];
              return GlassCard(
                margin: const EdgeInsets.only(bottom: 10),
                borderRadius: 14,
                child: ListTile(
                  leading: GradientAvatar(
                    name: user.name,
                    radius: 22,
                    backgroundImage: user.photoUrl != null
                        ? NetworkImage(user.photoUrl!)
                        : null,
                  ),
                  title: Text(user.name,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600)),
                  subtitle: Text(user.id,
                      style:
                          const TextStyle(color: AppColors.textMuted)),
                  onTap: () => close(context, user),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget buildResults(BuildContext context) => const SizedBox.shrink();

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: AppColors.neonCyan),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: AppColors.neonCyan),
      onPressed: () => close(context, null),
    );
  }
}