import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final String senderName;
  final DateTime timestamp;
  final bool isMe;
  final String? imageUrl;
  final String type;

  const ChatBubble({
    super.key,
    required this.text,
    required this.senderName,
    required this.timestamp,
    required this.isMe,
    this.imageUrl,
    this.type = 'text',
  });

  Widget _buildTextOrCode(BuildContext context) {
    final trimmed = text.trim();
    if (trimmed.startsWith('```') && trimmed.endsWith('```')) {
      final codeContent = trimmed.substring(3, trimmed.length - 3).trim();
      return Container(
        margin: const EdgeInsets.only(top: 4, bottom: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24, width: 0.5),
        ),
        child: Text(
          codeContent,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: Color(0xFF50FA7B), // Dracula Green
          ),
        ),
      );
    }
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        color: isMe ? Colors.white : Colors.black87,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showImage = type == 'image' || (imageUrl != null && imageUrl!.isNotEmpty);
    final displayUrl = imageUrl ?? (type == 'image' ? text : null);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF1877F2) : const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMe)
              Text(
                senderName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            if (!isMe) const SizedBox(height: 4),
            if (showImage && displayUrl != null && displayUrl.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  displayUrl,
                  height: 200,
                  width: 200,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 150,
                      width: 200,
                      color: Colors.black12,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      width: 200,
                      color: Colors.black12,
                      child: const Center(child: Icon(Icons.broken_image, color: Colors.white70)),
                    );
                  },
                ),
              ),
              if (text.isNotEmpty && type != 'image') const SizedBox(height: 6),
            ],
            if (text.isNotEmpty && type != 'image')
              _buildTextOrCode(context),
            const SizedBox(height: 4),
            Text(
              DateFormat.jm().format(timestamp),
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
