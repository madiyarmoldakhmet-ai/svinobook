import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import '../utils/app_theme.dart';

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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.1), width: 0.5),
        ),
        child: Text(
          codeContent,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: AppColors.neonGreen, // Dracula Green
          ),
        ),
      );
    }
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        color: isMe ? Colors.white : AppColors.textPrimary,
        height: 1.4,
      ),
    );
  }

  BorderRadius _radiusFor(bool isMe) => BorderRadius.circular(3).copyWith(
        bottomRight:
            isMe ? const Radius.circular(4) : const Radius.circular(18),
        bottomLeft:
            isMe ? const Radius.circular(18) : const Radius.circular(4),
      );

  @override
  Widget build(BuildContext context) {
    final showVideo = type == 'video';
    final showImage = !showVideo && (type == 'image' || (imageUrl != null && imageUrl!.isNotEmpty));
    final displayUrl = imageUrl ?? (type == 'image' ? text : null);

    final bgColor = isMe
        ? AppColors.neonCyan.withValues(alpha: 0.15)
        : AppColors.glassBg;
    final borderColor = isMe
        ? AppColors.neonCyan.withValues(alpha: 0.35)
        : AppColors.glassBorder;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: _radiusFor(isMe),
          boxShadow: [
            if (isMe)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: _radiusFor(isMe),
          child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                border: Border.all(color: borderColor, width: 1),
                borderRadius: _radiusFor(isMe),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        senderName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: AppColors.neonCyan.withValues(alpha: 0.8),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  if (showImage &&
                      displayUrl != null &&
                      displayUrl.isNotEmpty) ...[
                    if (showVideo)
                      _VideoAttachment(url: displayUrl)
                    else ClipRRect(
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
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.neonCyan,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 150,
                            width: 200,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(Icons.broken_image,
                                  color: AppColors.textMuted),
                            ),
                          );
                        },
                      ),
                    ),
                    if (text.isNotEmpty && type != 'image')
                      const SizedBox(height: 6),
                  ],
                  if (text.isNotEmpty && type != 'image')
                    _buildTextOrCode(context),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      DateFormat.jm().format(timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }
}

class _VideoAttachment extends StatefulWidget {
  final String? url;
  const _VideoAttachment({this.url});
  @override
  State<_VideoAttachment> createState() => _VideoAttachmentState();
}

class _VideoAttachmentState extends State<_VideoAttachment> {
  VideoPlayerController? _controller;
  @override
  void initState() { super.initState(); if (widget.url != null) { _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url!))..initialize().then((_) { if (mounted) setState(() {}); }); } }
  @override
  void dispose() { _controller?.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return const SizedBox(width: 220, height: 160, child: Center(child: CircularProgressIndicator()));
    return Stack(alignment: Alignment.center, children: [SizedBox(width: 220, height: 160, child: VideoPlayer(controller)), IconButton(onPressed: () => setState(() => controller.value.isPlaying ? controller.pause() : controller.play()), icon: Icon(controller.value.isPlaying ? Icons.pause_circle : Icons.play_circle, color: Colors.white, size: 48))]);
  }
}