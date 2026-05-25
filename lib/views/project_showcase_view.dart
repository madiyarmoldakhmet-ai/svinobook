import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../widgets/anime_background.dart';

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

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF121212),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF8B0000), width: 1.5),
          ),
          title: const Text(
            'Share Achievement',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    labelStyle: TextStyle(color: Colors.white60),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8B0000))),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(color: Colors.white60),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8B0000))),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _imageUrlController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    labelStyle: TextStyle(color: Colors.white60),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8B0000))),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B0000),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _saveProject,
              child: const Text('Post', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
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
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
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
        const SnackBar(content: Text('Project shared!')),
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.85),
        elevation: 0,
        title: const Text(
          'NEXUS DISCOVER',
          style: TextStyle(
            color: Color(0xFF8B0000),
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1.5,
            fontFamily: 'Oswald',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate, color: Color(0xFF8B0000), size: 28),
            onPressed: _showAddProjectDialog,
          ),
        ],
      ),
      body: AnimeBackground(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('projects')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF8B0000)));
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading showcase: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white70),
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  'The world is empty... post something.',
                  style: TextStyle(color: Colors.white60, fontSize: 16, fontStyle: FontStyle.italic),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final title = data['title'] ?? 'Untitled';
                final desc = data['description'] ?? '';
                final imageUrl = data['imageUrl'] as String?;
                final userName = data['userName'] ?? 'Unknown';
                final userPhotoUrl = data['userPhotoUrl'] as String?;
                final likes = data['likes'] ?? 0;
                final timestamp = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

                return Card(
                  color: Colors.black.withOpacity(0.75),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFF8B0000), width: 0.8),
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFF8B0000),
                              backgroundImage: userPhotoUrl != null && userPhotoUrl.isNotEmpty
                                  ? NetworkImage(userPhotoUrl)
                                  : null,
                              child: userPhotoUrl == null || userPhotoUrl.isEmpty
                                  ? Text(
                                      userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                                      style: const TextStyle(color: Colors.white),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                Text(
                                  DateFormat.yMMMd().add_jm().format(timestamp),
                                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (imageUrl != null && imageUrl.isNotEmpty)
                        ClipRRect(
                          child: Image.network(
                            imageUrl,
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              height: 120,
                              color: Colors.white12,
                              child: const Center(child: Icon(Icons.broken_image, color: Colors.white60)),
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
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              desc,
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.white24, height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.local_fire_department, color: Color(0xFF8B0000)),
                              onPressed: () => _supportProject(doc.id, likes),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$likes Support',
                              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
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
