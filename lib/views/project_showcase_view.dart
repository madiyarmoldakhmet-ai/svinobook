import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task_card_model.dart';
import '../services/firestore_service.dart';
import '../utils/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/task_card.dart';

class ProjectShowcaseView extends StatefulWidget {
  const ProjectShowcaseView({super.key});

  @override
  State<ProjectShowcaseView> createState() => _ProjectShowcaseViewState();
}

class _ProjectShowcaseViewState extends State<ProjectShowcaseView> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _imageUrlController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _showAddProjectDialog() {
    _titleController.clear();
    _descController.clear();
    _imageUrlController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.bgMid,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.glassBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Share an Achievement',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Inspire the community with your work.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  controller: _titleController,
                  hintText: 'Title',
                  prefixIcon: const Icon(Icons.title,
                      color: AppColors.neonCyan, size: 20),
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: _descController,
                  hintText: 'Description',
                  prefixIcon: const Icon(Icons.description,
                      color: AppColors.neonCyan, size: 20),
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: _imageUrlController,
                  hintText: 'Image URL (optional)',
                  keyboardType: TextInputType.url,
                  prefixIcon: const Icon(Icons.link,
                      color: AppColors.neonCyan, size: 20),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _saveProject,
                        child: const Text('Post'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveProject() async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    final imgUrl = _imageUrlController.text.trim();

    if (title.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out title and description')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Fetch user details
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    String name = user.email?.split('@')[0] ?? 'User';
    String? avatarUrl;
    if (userDoc.exists) {
      final data = userDoc.data();
      if (data != null) {
        name = data['name'] ?? data['username'] ?? name;
        avatarUrl = data['photoUrl'];
      }
    }

    await FirebaseFirestore.instance.collection('projects').add({
      'title': title,
      'description': desc,
      'imageUrl': imgUrl.isNotEmpty ? imgUrl : null,
      'userId': user.uid,
      'userName': name,
      'userPhotoUrl': avatarUrl,
      'likes': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project shared! 🎉')),
      );
    }
  }

  void _supportProject(String docId, int currentLikes) async {
    await FirebaseFirestore.instance.collection('projects').doc(docId).update({
      'likes': currentLikes + 1,
    });
  }

  @override
  Widget build(BuildContext context) {
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
                    child: const Icon(Icons.explore_rounded,
                        color: AppColors.bgDarkest),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Discover',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 28,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _showAddProjectDialog,
                    icon: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.neonCyan.withValues(alpha: 0.3),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: AppColors.bgDarkest, size: 24),
                    ),
                  ),
                ],
              ),
            ),

            // ── Feed ──
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('projects')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
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
                        'Error loading showcase: ${snapshot.error}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  final firestore = context.read<FirestoreService>();

                  return StreamBuilder<List<TaskCardModel>>(
                    stream: firestore.getTasksStream(),
                    builder: (context, taskSnapshot) {
                      final tasks = taskSnapshot.data ?? [];

                      if (docs.isEmpty && tasks.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome,
                                  size: 64,
                                  color: AppColors.neonCyan.withValues(alpha: 0.3)),
                              const SizedBox(height: 16),
                              Text(
                                'Nothing here yet',
                                style: TextStyle(
                                    color: AppColors.textMuted, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Be the first to share!',
                                style: TextStyle(
                                    color: AppColors.neonCyan
                                        .withValues(alpha: 0.6),
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        );
                      }

                      final combined = <Widget>[];

                      for (final doc in docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final title = data['title'] ?? 'Untitled';
                        final desc = data['description'] ?? '';
                        final imageUrl = data['imageUrl'] as String?;
                        final userName = data['userName'] ?? 'Unknown';
                        final userPhotoUrl = data['userPhotoUrl'] as String?;
                        final likes = data['likes'] ?? 0;
                        final timestamp =
                            (data['createdAt'] as Timestamp?)?.toDate() ??
                                DateTime.now();

                        combined.add(
                          GlassCard(
                            margin: const EdgeInsets.only(bottom: 16),
                            borderRadius: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      GradientAvatar(
                                        name: userName,
                                        radius: 20,
                                        backgroundImage: (userPhotoUrl != null &&
                                                userPhotoUrl.isNotEmpty)
                                            ? NetworkImage(userPhotoUrl)
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              userName,
                                              style: const TextStyle(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15,
                                              ),
                                            ),
                                            Text(
                                              DateFormat.yMMMd()
                                                  .add_jm()
                                                  .format(timestamp),
                                              style: TextStyle(
                                                  color: AppColors.textMuted,
                                                  fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (imageUrl != null && imageUrl.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        bottom: Radius.circular(0)),
                                    child: Image.network(
                                      imageUrl,
                                      width: double.infinity,
                                      height: 220,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (c, e, s) => Container(
                                        height: 200,
                                        color: AppColors.glassBg,
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                              color: AppColors.neonCyan),
                                        ),
                                      ),
                                      errorBuilder: (c, e, s) => Container(
                                        height: 120,
                                        color: AppColors.glassBg,
                                        child: const Center(
                                            child: Icon(Icons.broken_image,
                                                color: AppColors.textMuted)),
                                      ),
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        desc,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Divider(
                                    color: AppColors.glassBorder, height: 1),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.local_fire_department,
                                            color: AppColors.neonCyan
                                                .withValues(alpha: 0.8)),
                                        onPressed: () => _supportProject(
                                            doc.id, likes),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$likes Support',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      for (final task in tasks) {
                        combined.add(TaskCard(task: task));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                        itemCount: combined.length,
                        itemBuilder: (context, index) => combined[index],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}