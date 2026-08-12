import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';

import '../../core/auth_service.dart';
import '../../core/vault_service.dart';

class VaultDetailsScreen extends ConsumerStatefulWidget {
  final String vaultId;
  final String vaultName;

  const VaultDetailsScreen({
    super.key,
    required this.vaultId,
    required this.vaultName,
  });

  @override
  ConsumerState<VaultDetailsScreen> createState() => _VaultDetailsScreenState();
}

class _VaultDetailsScreenState extends ConsumerState<VaultDetailsScreen> {
  final TextEditingController _noteController = TextEditingController();

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      final base64String = base64Encode(bytes);

      final currentUser = ref.read(authServiceProvider).currentUser;
      if (currentUser != null) {
        await ref
            .read(vaultServiceProvider)
            .addVaultItem(
              currentUser.uid,
              widget.vaultId,
              imageBase64: base64String,
            );
      }
    }
  }

  Future<void> _addNote() async {
    if (_noteController.text.trim().isEmpty) return;
    final currentUser = ref.read(authServiceProvider).currentUser;
    if (currentUser != null) {
      await ref
          .read(vaultServiceProvider)
          .addVaultItem(
            currentUser.uid,
            widget.vaultId,
            text: _noteController.text.trim(),
          );
      _noteController.clear();
      Navigator.pop(context);
    }
  }

  void _showAddNoteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B1B1E),
        title: const Text(
          'Add Encrypted Note',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: _noteController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Type your secure note...',
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
            ),
            onPressed: _addNote,
            child: const Text(
              'Save Note',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authServiceProvider).currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      appBar: AppBar(
        title: Text(
          widget.vaultName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0F0F12),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.note_add),
            onPressed: _showAddNoteDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add_photo_alternate),
            onPressed: _pickAndUploadImage,
          ),
        ],
      ),
      body: currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: ref
                  .watch(vaultServiceProvider)
                  .getVaultItems(currentUser.uid, widget.vaultId),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return const Center(
                    child: Text(
                      'Error decrypting vault',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());

                final items = snapshot.data?.docs ?? [];
                if (items.isEmpty) {
                  return const Center(
                    child: Text(
                      'Vault is empty. Add a note or image.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final data = items[index].data() as Map<String, dynamic>;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B1B1E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (data['text'] != null)
                            Text(
                              data['text'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          if (data['imageBase64'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  base64Decode(data['imageBase64']),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
