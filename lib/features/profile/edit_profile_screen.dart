import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart' as image_picker;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/auth_service.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialUserData;

  const EditProfileScreen({super.key, required this.initialUserData});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _fbController;
  late TextEditingController _instaController;
  late TextEditingController _waController;

  bool _isPrivate = false;
  String? _profileBase64;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialUserData?['name'] ?? '',
    );
    _usernameController = TextEditingController(
      text: widget.initialUserData?['username'] ?? '',
    );
    _bioController = TextEditingController(
      text: widget.initialUserData?['bio'] ?? '',
    );
    _fbController = TextEditingController(
      text: widget.initialUserData?['facebookUrl'] ?? '',
    );
    _instaController = TextEditingController(
      text: widget.initialUserData?['instagramUrl'] ?? '',
    );
    _waController = TextEditingController(
      text: widget.initialUserData?['whatsappUrl'] ?? '',
    );
    _isPrivate = widget.initialUserData?['isPrivate'] ?? false;
    _profileBase64 = widget.initialUserData?['profileBase64'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _fbController.dispose();
    _instaController.dispose();
    _waController.dispose();
    super.dispose();
  }

  Future<void> _updateProfilePicture() async {
    final picker = image_picker.ImagePicker();
    final xFile = await picker.pickImage(
      source: image_picker.ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 600,
      maxHeight: 600,
    );
    if (xFile == null) return;

    final bytes = await File(xFile.path).readAsBytes();
    final base64String = base64Encode(bytes);

    setState(() {
      _profileBase64 = base64String;
    });
  }

  Future<void> _saveChanges() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'name': _nameController.text.trim(),
      'username': _usernameController.text.trim(),
      'bio': _bioController.text.trim(),
      'facebookUrl': _fbController.text.trim(),
      'instagramUrl': _instaController.text.trim(),
      'whatsappUrl': _waController.text.trim(),
      'isPrivate': _isPrivate,
      if (_profileBase64 != null) 'profileBase64': _profileBase64,
    });

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveChanges,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: theme.primaryColor,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _updateProfilePicture,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                    backgroundImage: _profileBase64 != null
                        ? MemoryImage(base64Decode(_profileBase64!))
                        : null,
                    child: _profileBase64 == null
                        ? Icon(
                            Icons.person,
                            size: 50,
                            color: theme.primaryColor,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.scaffoldBackgroundColor,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
                prefixText: '@ ',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: 'Bio',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Social Links',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fbController,
              decoration: const InputDecoration(
                labelText: 'Facebook Link',
                prefixIcon: Icon(Icons.facebook),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _instaController,
              decoration: const InputDecoration(
                labelText: 'Instagram Link',
                prefixIcon: Icon(Icons.camera_alt),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _waController,
              decoration: const InputDecoration(
                labelText: 'WhatsApp Link',
                prefixIcon: Icon(Icons.chat),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text(
                'Private Account',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Only approved followers can see your posts and time-locked vaults.',
              ),
              value: _isPrivate,
              activeThumbColor: theme.primaryColor,
              onChanged: (val) => setState(() => _isPrivate = val),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
