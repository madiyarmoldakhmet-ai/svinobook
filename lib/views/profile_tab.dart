import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../utils/image_picker_helper.dart';
import '../utils/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
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
          const SnackBar(content: Text('Profile updated successfully! ✨')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _signOut() async {
    final auth = context.read<AuthService>();
    await auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final topPad = MediaQuery.of(context).padding.top;

    if (currentUser == null) {
      return Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: const Center(
          child: Text(
            'Not logged in',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.neonCyan),
              );
            }
            if (snapshot.hasError ||
                !snapshot.hasData ||
                !snapshot.data!.exists) {
              return const Center(
                child: Text(
                  'Error loading profile data',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              );
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final currentName = data['name'] ?? data['username'] ?? 'User';
            final photoUrl = data['photoUrl'] as String?;
            final currentBackground =
                data['chatBackgroundUrl'] as String? ?? '';
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

            final avatarImage = _selectedAvatarBytes != null
                ? MemoryImage(_selectedAvatarBytes!)
                : (photoUrl != null ? NetworkImage(photoUrl) : null)
                      as ImageProvider?;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 120),
              child: Column(
                children: [
                  // ── Header ──
                  Row(
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
                        child: const Icon(
                          Icons.person_rounded,
                          color: AppColors.bgDarkest,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Profile',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontFamily: 'Copernicus',
                          fontFamilyFallback: [
                            'Tiempos Headline',
                            'Cormorant Garamond',
                            'serif',
                          ],
                          fontWeight: FontWeight.w400,
                          fontSize: 28,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _signOut,
                        tooltip: 'Sign out',
                        icon: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.danger.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.logout_rounded,
                            color: AppColors.danger,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Avatar ──
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                          image: avatarImage != null
                              ? DecorationImage(
                                  image: avatarImage,
                                  fit: BoxFit.cover,
                                )
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.neonCyan.withValues(alpha: 0.4),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: avatarImage == null
                            ? Center(
                                child: Text(
                                  currentName.isNotEmpty
                                      ? currentName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 48,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      InkWell(
                        onTap: _pickAvatar,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.bgDarkest,
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: AppColors.bgDarkest,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ── Form card ──
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    borderRadius: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Display Name',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: _nameController,
                          hintText: 'Enter your name',
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            color: AppColors.neonCyan,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Status Message',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: _statusController,
                          hintText: 'e.g., Coding, Busy...',
                          prefixIcon: const Icon(
                            Icons.chat_bubble_outline,
                            color: AppColors.neonCyan,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Custom Wallpaper URL',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: _backgroundController,
                          hintText: 'https://example.com/image.jpg',
                          keyboardType: TextInputType.url,
                          prefixIcon: const Icon(
                            Icons.wallpaper,
                            color: AppColors.neonCyan,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Email Address',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.glassBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.glassBorder,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.mail_outline,
                                color: AppColors.textMuted,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  currentUser.email ?? '',
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    text: 'Save Changes',
                    onPressed: _saveProfile,
                    isLoading: _isSaving,
                    icon: Icons.check_rounded,
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
