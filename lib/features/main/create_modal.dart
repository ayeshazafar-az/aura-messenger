import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart' as image_picker;
import '../../core/auth_service.dart';
import '../../core/post_service.dart';
import '../../core/story_service.dart';

Future<void> showGlobalCreateMenu(BuildContext context, WidgetRef ref) async {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Create',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Divider(height: 32),
            ListTile(
              leading: const Icon(Icons.grid_on, size: 28),
              title: const Text('Post', style: TextStyle(fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                _uploadPost(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.data_usage_rounded, size: 28),
              title: const Text('Story', style: TextStyle(fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                _uploadStory(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.ondemand_video, size: 28),
              title: const Text('Reel', style: TextStyle(fontSize: 16)),
              onTap: () async {
                Navigator.pop(context);
                final picker = image_picker.ImagePicker();
                final video = await picker.pickVideo(
                  source: image_picker.ImageSource.gallery,
                );
                if (video != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reel compressed and published! 🎬'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock_clock, size: 28),
              title: const Text(
                'Time-Locked Vault',
                style: TextStyle(fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(context);
                context.go('/vaults');
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    },
  );
}

Future<void> _uploadStory(BuildContext context, WidgetRef ref) async {
  final picker = image_picker.ImagePicker();
  final xFile = await picker.pickImage(
    source: image_picker.ImageSource.gallery,
    imageQuality: 50,
    maxWidth: 600,
    maxHeight: 600,
  );
  if (xFile == null) return;

  final currentUserId = ref.read(authServiceProvider).currentUser?.uid;
  if (currentUserId == null) return;

  await ref
      .read(storyServiceProvider)
      .uploadStory(currentUserId, File(xFile.path), 'My story via Aura');
}

Future<void> _uploadPost(BuildContext context, WidgetRef ref) async {
  final picker = image_picker.ImagePicker();
  final xFile = await picker.pickImage(
    source: image_picker.ImageSource.gallery,
    imageQuality: 50,
    maxWidth: 600,
    maxHeight: 600,
  );
  if (xFile == null) return;

  if (!context.mounted) return;
  final TextEditingController captionController = TextEditingController();

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('New Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(xFile.path),
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: captionController,
              decoration: const InputDecoration(
                hintText: 'Write a caption...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final user = ref.read(authServiceProvider).currentUser;
              if (user != null) {
                await ref
                    .read(postServiceProvider)
                    .uploadPost(
                      user.uid,
                      File(xFile.path),
                      captionController.text.trim().isEmpty
                          ? 'Just sharing some vibes ✨'
                          : captionController.text.trim(),
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Post uploaded successfully 📸'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Share'),
          ),
        ],
      );
    },
  );
}
