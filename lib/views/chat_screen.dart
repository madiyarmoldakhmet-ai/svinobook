import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../widgets/chat_bubble.dart';
import '../utils/image_picker_helper.dart';
import 'call_screen.dart';

const _bgDark = Color(0xFFE7EEF5);
const _bgMid = Color(0xFFFFFFFF);
const _neonCyan = Color(0xFF4A76A8);
const _neonBlue = Color(0xFF527DA8);
const _glassBg = Color(0xFFFFFFFF);
const _glassBorder = Color(0xFFC7D5E0);

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String chatName;

  const ChatScreen({super.key, required this.chatId, required this.chatName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  Uint8List? _selectedImageBytes;
  bool _isSending = false;
  bool _isTypingStatus = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
    // Reset unread counter after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final firestore = Provider.of<FirestoreService>(context, listen: false);
      final auth = Provider.of<AuthService>(context, listen: false);
      final currentUserId = auth.currentUser?.uid ?? '';
      if (currentUserId.isNotEmpty) {
        firestore.resetUnreadCount(widget.chatId, currentUserId);
      }
    });
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _setTypingStatus(false);
    super.dispose();
  }

  void _onTextChanged() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUserId.isEmpty) return;

    final isTextEmpty = _messageController.text.trim().isEmpty;
    if (isTextEmpty && _isTypingStatus) {
      _setTypingStatus(false);
    } else if (!isTextEmpty && !_isTypingStatus) {
      _setTypingStatus(true);
    }
  }

  void _setTypingStatus(bool typing) async {
    _isTypingStatus = typing;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUserId.isNotEmpty) {
      FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set({
        'typing': {
          currentUserId: typing,
        }
      }, SetOptions(merge: true));
    }
  }

  Future<void> _pickImage() async {
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _selectedImageBytes == null) return;

    setState(() => _isSending = true);
    final firestore = context.read<FirestoreService>();
    final currentUser = FirebaseAuth.instance.currentUser;
    final senderId = currentUser?.uid ?? '';
    final senderName = currentUser?.displayName ??
        currentUser?.email?.split('@')[0] ??
        'User';

    try {
      await firestore.sendMessage(
        chatRoomId: widget.chatId,
        text: text,
        chatImageBytes: _selectedImageBytes,
        isGroup: false,
        senderId: senderId,
        senderName: senderName,
      );
      _messageController.clear();
      _removeSelectedImage();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _startCall() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CallScreen(
        channelId: widget.chatId,
        chatName: widget.chatName,
      ),
    ));
  }

  //  BUILD — compact personal chat layout
  // ═══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserId = currentUser?.uid ?? '';
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _bgDark,
      body: Container(
        color: _bgDark,
        child: Column(
          children: [
            // ── Custom Antigravity Header (SafeArea-safe) ──
            _buildHeader(topPad),

            // ── Messages area ──
            Expanded(
              child: _buildMessageArea(currentUserId),
            ),

            // ── Typing indicator ──
            _buildTypingIndicator(currentUserId),

            // ── Floating input field ──
            _buildFloatingInput(),
          ],
        ),
      ),
    );
  }

  // ── HEADER: Glassmorphic top bar, pushed below browser chrome ──
  Widget _buildHeader(double topPad) {
    return Container(
      padding: EdgeInsets.only(
        top: topPad + 10, // push below SafeArea / browser address bar
        left: 8,
        right: 8,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: _neonCyan,
        border: Border(
          bottom: BorderSide(
            color: _neonCyan.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: Row(
            children: [
              // Back button — always visible and clickable
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _glassBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: _glassBorder, width: 1),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: _neonCyan,
                    size: 18,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 4),
              // Avatar placeholder
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_neonCyan, _neonBlue],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _neonCyan.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.chatName.isNotEmpty
                        ? widget.chatName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name + status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.chatName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        letterSpacing: 0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: _neonCyan.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _neonCyan.withValues(alpha: 0.5),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Online',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Call button
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _glassBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: _glassBorder, width: 1),
                  ),
                  child: const Icon(Icons.phone, color: _neonCyan, size: 20),
                ),
                onPressed: _startCall,
              ),
            ],
      ),
    );
  }

  // ── MESSAGES: Animated floating bubbles ──
  Widget _buildMessageArea(String currentUserId) {
    return StreamBuilder<List<ChatMessageModel>>(
      stream: context.read<FirestoreService>().getDirectMessagesStream(widget.chatId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    color: _neonCyan.withValues(alpha: 0.6),
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading messages...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading chat: ${snapshot.error}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
          );
        }
        final messages = snapshot.data ?? [];
        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  color: _neonCyan.withValues(alpha: 0.2),
                  size: 56,
                ),
                const SizedBox(height: 12),
                Text(
                  'No messages yet',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontStyle: FontStyle.italic,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Send the first message!',
                  style: TextStyle(
                    color: _neonCyan.withValues(alpha: 0.3),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index];
            // ── Float-up animation for each bubble ──
            return TweenAnimationBuilder<double>(
              key: ValueKey(msg.text + msg.timestamp.toIso8601String()),
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 350 + (index.clamp(0, 5) * 40)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1.0 - value)),
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: ChatBubble(
                text: msg.text,
                senderName: msg.senderName,
                timestamp: msg.timestamp,
                isMe: msg.senderId == currentUserId,
                imageUrl: msg.imageUrl,
                type: msg.type,
              ),
            );
          },
        );
      },
    );
  }

  // ── TYPING INDICATOR ──
  Widget _buildTypingIndicator(String currentUserId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null && data['typing'] != null) {
            final typingMap = data['typing'] as Map<String, dynamic>;
            final otherTyping = typingMap.entries
                .where((e) => e.key != currentUserId && e.value == true)
                .isNotEmpty;
            if (otherTyping) {
              return Container(
                padding: const EdgeInsets.only(left: 24, bottom: 6),
                alignment: Alignment.centerLeft,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 300),
                  builder: (context, val, child) {
                    return Opacity(
                      opacity: val,
                      child: Transform.translate(
                        offset: Offset(0, 8 * (1.0 - val)),
                        child: child,
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: _neonCyan.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.chatName} is typing...',
                        style: TextStyle(
                          color: _neonCyan.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          }
        }
        return const SizedBox.shrink();
      },
    );
  }

  // ── FLOATING INPUT FIELD: Glassmorphic, detached from edges ──
  Widget _buildFloatingInput() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image preview
            if (_selectedImageBytes != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _glassBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _glassBorder, width: 1),
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
                          color: Colors.red.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: const Icon(Icons.close, color: Colors.red, size: 16),
                      ),
                    ),
                  ],
                ),
              ),

            // ── The floating glass input bar ──
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
                    boxShadow: [
                      BoxShadow(
                        color: _neonCyan.withValues(alpha: 0.06),
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: const Offset(0, -2),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
                      // Attach image button
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _neonCyan.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.photo_outlined,
                            color: _neonCyan.withValues(alpha: 0.7),
                            size: 20,
                          ),
                        ),
                        onPressed: _pickImage,
                      ),
                      // Text field
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Send button
                      _isSending
                          ? Padding(
                              padding: const EdgeInsets.all(12),
                              child: SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _neonCyan.withValues(alpha: 0.6),
                                ),
                              ),
                            )
                          : GestureDetector(
                              onTap: _sendMessage,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [_neonCyan, _neonBlue],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _neonCyan.withValues(alpha: 0.35),
                                      blurRadius: 10,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.send_rounded,
                                  color: _bgDark,
                                  size: 20,
                                ),
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
