import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../utils/image_picker_helper.dart';
import '../widgets/anime_background.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _nameController = TextEditingController();
  final _backgroundController = TextEditingController();
  final _statusController = TextEditingController();
  Uint8List? _selectedAvatarBytes;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _backgroundController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  void _pickAvatar() async {
    final bytes = await ImagePickerHelper.pickImage();
    if (bytes != null) {
      setState(() {
        _selectedAvatarBytes = bytes;
      });
    }
  }

  void _saveProfile() async {
    final name = _nameController.text.trim();
    final background = _backgroundController.text.trim();
    final status = _statusController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final firestore = context.read<FirestoreService>();
      await firestore.updateProfile(
        name: name,
        avatarBytes: _selectedAvatarBytes,
        chatBackgroundUrl: background,
        status: status,
      );
      
      setState(() {
        _selectedAvatarBytes = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text('Not logged in', style: TextStyle(color: Colors.white)));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.85),
        title: const Text(
          'PROFILE SETTINGS',
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
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF8B0000)));
            }
            if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text('Error loading profile data', style: TextStyle(color: Colors.white70)));
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final currentName = data['name'] ?? data['username'] ?? 'User';
            final photoUrl = data['photoUrl'] as String?;
            final currentBackground = data['chatBackgroundUrl'] as String? ?? '';
            final currentStatus = data['status'] as String? ?? '';

            if (_nameController.text.isEmpty) {
              _nameController.text = currentName;
            }
            if (_backgroundController.text.isEmpty) {
              _backgroundController.text = currentBackground;
            }
            if (_statusController.text.isEmpty) {
              _statusController.text = currentStatus;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 70,
                        backgroundColor: const Color(0xFF8B0000),
                        backgroundImage: _selectedAvatarBytes != null
                            ? MemoryImage(_selectedAvatarBytes!)
                            : (photoUrl != null ? NetworkImage(photoUrl) : null) as ImageProvider?,
                        child: (_selectedAvatarBytes == null && photoUrl == null)
                            ? Text(
                                currentName.isNotEmpty ? currentName[0].toUpperCase() : '?',
                                style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      InkWell(
                        onTap: _pickAvatar,
                        child: const CircleAvatar(
                          radius: 20,
                          backgroundColor: Color(0xFF8B0000),
                          child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF8B0000), width: 0.8),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Display Name',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Enter your name',
                            hintStyle: const TextStyle(color: Colors.white38),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.white30),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF8B0000), width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Custom Status Message',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _statusController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'e.g., Coding, Busy...',
                            hintStyle: const TextStyle(color: Colors.white38),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.white30),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF8B0000), width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Custom Wallpaper URL',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _backgroundController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'https://example.com/image.jpg',
                            hintStyle: const TextStyle(color: Colors.white38),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.white30),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF8B0000), width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Email Address',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: TextEditingController(text: currentUser.email),
                          enabled: false,
                          style: const TextStyle(color: Colors.white70),
                          decoration: InputDecoration(
                            fillColor: Colors.white12,
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.transparent),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B0000),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isSaving ? null : _saveProfile,
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Save Changes',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
