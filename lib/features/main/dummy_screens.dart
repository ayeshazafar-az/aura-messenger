import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart' as image_picker;
import '../profile/edit_profile_screen.dart';
import 'create_modal.dart';
import '../../core/auth_service.dart';
import '../../core/story_service.dart';
import '../../core/post_service.dart';
import '../../core/theme_provider.dart';
import '../../core/vault_service.dart';
import '../vaults/vault_details_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Future<void> _uploadStory() async {
    final picker = image_picker.ImagePicker();
    final xFile = await picker.pickImage(
      source: image_picker.ImageSource.gallery,
    );
    if (xFile == null) return;

    final currentUserId = ref.read(authServiceProvider).currentUser!.uid;

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Uploading Story...')));
    }

    await ref
        .read(storyServiceProvider)
        .uploadStory(currentUserId, File(xFile.path), 'My story via Aura');
  }

  Future<void> _uploadPost() async {
    final picker = image_picker.ImagePicker();
    final xFile = await picker.pickImage(
      source: image_picker.ImageSource.gallery,
    );
    if (xFile == null) return;

    if (!mounted) return;
    final TextEditingController captionController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
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
                  if (mounted) {
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
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Share'),
            ),
          ],
        );
      },
    );
  }

  void _showCreateMenu() {
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
                  _uploadPost();
                },
              ),
              ListTile(
                leading: const Icon(Icons.data_usage_rounded, size: 28),
                title: const Text('Story', style: TextStyle(fontSize: 16)),
                onTap: () {
                  Navigator.pop(context);
                  _uploadStory();
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
                  if (video != null && mounted) {
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

  Widget _buildPostCard(QueryDocumentSnapshot postDoc) {
    final theme = Theme.of(context);
    final post = postDoc.data() as Map<String, dynamic>;
    final postId = postDoc.id;
    final currentUserId = ref.read(authServiceProvider).currentUser?.uid;
    final isOwner = post['uploaderId'] == currentUserId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(post['uploaderId'])
              .get(),
          builder: (context, userSnap) {
            final userData = userSnap.hasData && userSnap.data!.exists
                ? userSnap.data!.data() as Map<String, dynamic>
                : null;
            final displayName =
                userData?['name'] ??
                userData?['username'] ??
                post['uploaderId'].toString().substring(0, 6);
            final username = userData?['username'];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                backgroundImage: userData?['profileBase64'] != null
                    ? MemoryImage(base64Decode(userData!['profileBase64']))
                    : null,
                child: userData?['profileBase64'] == null
                    ? Icon(Icons.person, color: theme.primaryColor)
                    : null,
              ),
              title: Text(
                displayName.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: username != null
                  ? Text(
                      '@$username',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    )
                  : null,
              trailing: isOwner
                  ? PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'delete') {
                          await FirebaseFirestore.instance
                              .collection('posts')
                              .doc(postId)
                              .delete();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Post deleted')),
                            );
                          }
                        } else if (value == 'edit') {
                          final TextEditingController editController =
                              TextEditingController(text: post['caption']);
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Edit Caption'),
                              content: TextField(
                                controller: editController,
                                maxLines: 3,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    await FirebaseFirestore.instance
                                        .collection('posts')
                                        .doc(postId)
                                        .update({
                                          'caption': editController.text.trim(),
                                        });
                                  },
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit Caption'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Delete Post',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    )
                  : const Icon(Icons.more_vert),
            );
          },
        ),
        GestureDetector(
          onTap: () => showDialog(
            context: context,
            builder: (_) => GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Scaffold(
                backgroundColor: Colors.black,
                appBar: AppBar(
                  backgroundColor: Colors.black,
                  iconTheme: const IconThemeData(color: Colors.white),
                  title: const Text(
                    'Photo',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                body: Center(
                  child: InteractiveViewer(
                    child: Image.memory(
                      base64Decode(post['imageBase64']),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
          child: AspectRatio(
            aspectRatio: 1.0,
            child: Image.memory(
              base64Decode(post['imageBase64']),
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: const [
              Icon(Icons.favorite_border, size: 28),
              SizedBox(width: 16),
              Icon(Icons.chat_bubble_outline, size: 26),
              SizedBox(width: 16),
              Icon(Icons.send, size: 26),
              Spacer(),
              Icon(Icons.bookmark_border, size: 28),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '${post['likes'] ?? 0} likes',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              children: [
                TextSpan(
                  text:
                      '${post['uploaderName'] ?? post['uploaderId'].toString().substring(0, 6)} ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: post['caption'] ?? ''),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Aura',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add_box_outlined,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () => showGlobalCreateMenu(context, ref),
          ),
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(ref.read(authServiceProvider).currentUser?.uid ?? '')
                .snapshots(),
            builder: (context, snap) {
              final data = snap.data?.data() as Map<String, dynamic>?;
              final requestCount =
                  (data?['followRequests'] as List?)?.length ?? 0;
              return Badge(
                isLabelVisible: requestCount > 0,
                label: Text('$requestCount'),
                child: IconButton(
                  icon: Icon(
                    Icons.favorite_border,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ActivityScreen()),
                    );
                  },
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.send, color: Theme.of(context).iconTheme.color),
            onPressed: () => context.push('/hub'),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: StreamBuilder<QuerySnapshot>(
              stream: ref.watch(storyServiceProvider).getActiveStories(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text(
                    'Err: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 110,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final allStories = snapshot.data?.docs ?? [];
                final user = ref.read(authServiceProvider).currentUser;
                final myStories = allStories
                    .where(
                      (doc) =>
                          (doc.data() as Map<String, dynamic>)['uploaderId'] ==
                          user?.uid,
                    )
                    .toList();
                final otherStories = allStories
                    .where(
                      (doc) =>
                          (doc.data() as Map<String, dynamic>)['uploaderId'] !=
                          user?.uid,
                    )
                    .toList();

                return Container(
                  height: 120,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: (() {
                      final distinct = <String>{};
                      for (final d in otherStories) {
                        distinct.add(
                          (d.data() as Map<String, dynamic>)['uploaderId']
                              as String,
                        );
                      }
                      return distinct.length + 1;
                    })(),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Container(
                          width: 80,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                children: [
                                  GestureDetector(
                                    onTap: myStories.isNotEmpty
                                        ? () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => Scaffold(
                                                backgroundColor: Colors.black,
                                                appBar: AppBar(
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  elevation: 0,
                                                  iconTheme:
                                                      const IconThemeData(
                                                        color: Colors.white,
                                                      ),
                                                ),
                                                extendBodyBehindAppBar: true,
                                                body: PageView.builder(
                                                  itemCount: myStories.length,
                                                  itemBuilder: (context, pageIndex) {
                                                    // Reverse the order so the oldest active story plays first
                                                    final storyDoc =
                                                        myStories[(myStories
                                                                    .length -
                                                                1) -
                                                            pageIndex];
                                                    final base64String =
                                                        (storyDoc.data()
                                                            as Map<
                                                              String,
                                                              dynamic
                                                            >)['imageBase64'];
                                                    return Stack(
                                                      fit: StackFit.expand,
                                                      children: [
                                                        Center(
                                                          child: Image.memory(
                                                            base64Decode(
                                                              base64String,
                                                            ),
                                                          ),
                                                        ),
                                                        Positioned(
                                                          bottom: 40,
                                                          right: 16,
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              GestureDetector(
                                                                onTap: () {
                                                                  final viewers = List<String>.from(
                                                                    (storyDoc.data()
                                                                            as Map<
                                                                              String,
                                                                              dynamic
                                                                            >)['viewers'] ??
                                                                        [],
                                                                  );
                                                                  if (viewers
                                                                      .isEmpty) {
                                                                    return;
                                                                  }
                                                                  showModalBottomSheet(
                                                                    context:
                                                                        context,
                                                                    backgroundColor:
                                                                        Theme.of(
                                                                          context,
                                                                        ).scaffoldBackgroundColor,
                                                                    shape: const RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.vertical(
                                                                            top: Radius.circular(
                                                                              20,
                                                                            ),
                                                                          ),
                                                                    ),
                                                                    builder: (context) => ListView.builder(
                                                                      padding:
                                                                          const EdgeInsets.all(
                                                                            16,
                                                                          ),
                                                                      itemCount:
                                                                          viewers
                                                                              .length,
                                                                      itemBuilder:
                                                                          (
                                                                            context,
                                                                            idx,
                                                                          ) =>
                                                                              FutureBuilder<
                                                                                DocumentSnapshot
                                                                              >(
                                                                                future: FirebaseFirestore.instance
                                                                                    .collection(
                                                                                      'users',
                                                                                    )
                                                                                    .doc(
                                                                                      viewers[idx],
                                                                                    )
                                                                                    .get(),
                                                                                builder:
                                                                                    (
                                                                                      context,
                                                                                      userSnap,
                                                                                    ) {
                                                                                      if (!userSnap.hasData) {
                                                                                        return const ListTile(
                                                                                          title: Text(
                                                                                            'Loading...',
                                                                                          ),
                                                                                        );
                                                                                      }
                                                                                      final u =
                                                                                          userSnap.data!.data()
                                                                                              as Map<
                                                                                                String,
                                                                                                dynamic
                                                                                              >;
                                                                                      final name =
                                                                                          u['name'] ??
                                                                                          u['username'] ??
                                                                                          u['email'].toString().split(
                                                                                            '@',
                                                                                          )[0];
                                                                                      final handle =
                                                                                          u['username'] ??
                                                                                          u['email'].toString().split(
                                                                                            '@',
                                                                                          )[0];
                                                                                      return ListTile(
                                                                                        leading: CircleAvatar(
                                                                                          backgroundImage:
                                                                                              u['profileBase64'] !=
                                                                                                  null
                                                                                              ? MemoryImage(
                                                                                                  base64Decode(
                                                                                                    u['profileBase64'],
                                                                                                  ),
                                                                                                )
                                                                                              : null,
                                                                                        ),
                                                                                        title: Text(
                                                                                          name,
                                                                                          style: const TextStyle(
                                                                                            fontWeight: FontWeight.bold,
                                                                                          ),
                                                                                        ),
                                                                                        subtitle: Text(
                                                                                          '@$handle',
                                                                                        ),
                                                                                      );
                                                                                    },
                                                                              ),
                                                                    ),
                                                                  );
                                                                },
                                                                child: Row(
                                                                  children: [
                                                                    const Icon(
                                                                      Icons
                                                                          .visibility,
                                                                      color: Colors
                                                                          .white,
                                                                      size: 24,
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 6,
                                                                    ),
                                                                    Text(
                                                                      "${(storyDoc.data() as Map<String, dynamic>)['viewers']?.length ?? 0}",
                                                                      style: const TextStyle(
                                                                        color: Colors
                                                                            .white,
                                                                        fontSize:
                                                                            16,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        shadows: [
                                                                          Shadow(
                                                                            blurRadius:
                                                                                4,
                                                                            color:
                                                                                Colors.black54,
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 16,
                                                              ),
                                                              Text(
                                                                "${pageIndex + 1} / ${myStories.length}",
                                                                style: const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  shadows: [
                                                                    Shadow(
                                                                      blurRadius:
                                                                          4,
                                                                      color: Colors
                                                                          .black54,
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 16,
                                                              ),
                                                              IconButton(
                                                                icon: const Icon(
                                                                  Icons
                                                                      .delete_outline,
                                                                  color: Colors
                                                                      .white,
                                                                  size: 32,
                                                                ),
                                                                onPressed: () async {
                                                                  await FirebaseFirestore
                                                                      .instance
                                                                      .collection(
                                                                        'stories',
                                                                      )
                                                                      .doc(
                                                                        storyDoc
                                                                            .id,
                                                                      )
                                                                      .delete();
                                                                  if (context
                                                                          .mounted &&
                                                                      myStories
                                                                              .length ==
                                                                          1) {
                                                                    Navigator.pop(
                                                                      context,
                                                                    );
                                                                  }
                                                                },
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                ),
                                              ),
                                            );
                                          }
                                        : _showCreateMenu,
                                    child: myStories.isEmpty
                                        ? CircleAvatar(
                                            radius: 32,
                                            backgroundColor: Theme.of(context)
                                                .primaryColor
                                                .withValues(alpha: 0.1),
                                            child: Icon(
                                              Icons.person,
                                              color: Theme.of(
                                                context,
                                              ).primaryColor,
                                              size: 34,
                                            ),
                                          )
                                        : Container(
                                            padding: const EdgeInsets.all(3),
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: LinearGradient(
                                                colors: [
                                                  Color(0xFF8B5CF6),
                                                  Color(0xFFF43F5E),
                                                ],
                                              ),
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Theme.of(
                                                  context,
                                                ).scaffoldBackgroundColor,
                                              ),
                                              child: CircleAvatar(
                                                radius: 28,
                                                backgroundImage: MemoryImage(
                                                  base64Decode(
                                                    (myStories.first.data()
                                                        as Map<
                                                          String,
                                                          dynamic
                                                        >)['imageBase64'],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: _showCreateMenu,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Theme.of(
                                              context,
                                            ).scaffoldBackgroundColor,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Your Story',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Group other stories by uploader
                      final Map<String, List<QueryDocumentSnapshot>> grouped =
                          {};
                      for (final doc in otherStories) {
                        final uid =
                            (doc.data() as Map<String, dynamic>)['uploaderId']
                                as String;
                        grouped.putIfAbsent(uid, () => []).add(doc);
                      }
                      final uploaderIds = grouped.keys.toList();
                      final storyIndex = index - 1;
                      final uploaderId = uploaderIds[storyIndex];
                      final uploaderStories = grouped[uploaderId]!;
                      final firstData =
                          uploaderStories.first.data() as Map<String, dynamic>;
                      final base64String = firstData['imageBase64'];

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(uploaderId)
                            .get(),
                        builder: (context, userSnap) {
                          final userData =
                              userSnap.hasData && userSnap.data!.exists
                              ? userSnap.data!.data() as Map<String, dynamic>
                              : null;
                          final displayName =
                              userData?['name'] ??
                              userData?['username'] ??
                              uploaderId.substring(0, 5);

                          return GestureDetector(
                            onTap: () async {
                              if (user?.uid != null) {
                                for (final doc in uploaderStories) {
                                  await doc.reference
                                      .update({
                                        'viewers': FieldValue.arrayUnion([
                                          user!.uid,
                                        ]),
                                      })
                                      .catchError((_) => null);
                                }
                              }
                              if (!context.mounted) return;

                              showDialog(
                                context: context,
                                builder: (context) => Scaffold(
                                  backgroundColor: Colors.black,
                                  appBar: AppBar(
                                    backgroundColor: Colors.black,
                                    elevation: 0,
                                    iconTheme: const IconThemeData(
                                      color: Colors.white,
                                    ),
                                  ),
                                  body: Stack(
                                    children: [
                                      PageView.builder(
                                        itemCount: uploaderStories.length,
                                        itemBuilder: (context, pageIndex) {
                                          final storyDoc =
                                              uploaderStories[pageIndex];
                                          final storyData =
                                              storyDoc.data()
                                                  as Map<String, dynamic>;
                                          return Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              Center(
                                                child: Image.memory(
                                                  base64Decode(
                                                    storyData['imageBase64'],
                                                  ),
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                              Positioned(
                                                top: 60,
                                                left: 16,
                                                child: Row(
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 20,
                                                      backgroundImage:
                                                          userData?['profileBase64'] !=
                                                              null
                                                          ? MemoryImage(
                                                              base64Decode(
                                                                userData!['profileBase64'],
                                                              ),
                                                            )
                                                          : null,
                                                      child:
                                                          userData?['profileBase64'] ==
                                                              null
                                                          ? const Icon(
                                                              Icons.person,
                                                              color:
                                                                  Colors.white,
                                                            )
                                                          : null,
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          displayName
                                                              .toString(),
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            shadows: [
                                                              Shadow(
                                                                blurRadius: 4,
                                                                color: Colors
                                                                    .black54,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        if (uploaderStories
                                                                .length >
                                                            1)
                                                          Text(
                                                            '${pageIndex + 1} / ${uploaderStories.length}',
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .white70,
                                                                  fontSize: 12,
                                                                ),
                                                          ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: 80,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Stack(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFF8B5CF6),
                                              Color(0xFFF43F5E),
                                            ],
                                          ),
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Theme.of(
                                              context,
                                            ).scaffoldBackgroundColor,
                                          ),
                                          child: CircleAvatar(
                                            radius: 28,
                                            backgroundImage: MemoryImage(
                                              base64Decode(base64String),
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (uploaderStories.length > 1)
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 5,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF8B5CF6),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${uploaderStories.length}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    displayName.toString(),
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: Divider(height: 1)),
          StreamBuilder<QuerySnapshot>(
            stream: ref.watch(postServiceProvider).getFeedPosts(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final posts = snapshot.data!.docs;
              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return _buildPostCard(posts[index]);
                }, childCount: posts.length),
              );
            },
          ),
        ],
      ),
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Search Reels & Users...',
              hintStyle: TextStyle(color: Colors.white70),
              prefixIcon: Icon(Icons.search, color: Colors.white),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: _searchQuery.isNotEmpty
          ? StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                final q = _searchQuery.toLowerCase();
                final users = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final uname = (data['username'] ?? '')
                      .toString()
                      .toLowerCase();
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  return uname.contains(q) || name.contains(q);
                }).toList();

                if (users.isEmpty) {
                  return const Center(
                    child: Text(
                      'No users found',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 100),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final u = users[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.white24,
                        backgroundImage: u['profileBase64'] != null
                            ? MemoryImage(base64Decode(u['profileBase64']))
                            : null,
                        child: u['profileBase64'] == null
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      title: Text(
                        u['name'] ?? u['username'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '@${u['username'] ?? ''}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProfileScreen(targetUserId: users[index].id),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }
                final posts = snapshot.data!.docs;
                if (posts.isEmpty) {
                  return const Center(
                    child: Text(
                      'No Reels Yet',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                return PageView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index].data() as Map<String, dynamic>;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(
                          base64Decode(post['imageBase64']),
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.7),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          left: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProfileScreen(
                                        targetUserId: post['uploaderId'],
                                      ),
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.white24,
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '@${post['uploaderId'].toString().substring(0, 5)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        shadows: [Shadow(blurRadius: 2)],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                post['caption'] ??
                                    'Just dropped a new vibe ✨ #aura',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  shadows: [Shadow(blurRadius: 2)],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          right: 16,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildIconBtn(
                                Icons.favorite,
                                '${post['likes'] ?? 0}',
                              ),
                              const SizedBox(height: 16),
                              _buildIconBtn(Icons.comment, '0'),
                              const SizedBox(height: 16),
                              _buildIconBtn(Icons.share, 'Share'),
                              const SizedBox(height: 16),
                              _buildIconBtn(Icons.more_vert, ''),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildIconBtn(IconData icon, String label) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 32,
          shadows: const [Shadow(blurRadius: 4, color: Colors.black)],
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(blurRadius: 2)],
            ),
          ),
        ],
      ],
    );
  }
}

class VaultsScreen extends ConsumerStatefulWidget {
  const VaultsScreen({super.key});
  @override
  ConsumerState<VaultsScreen> createState() => _VaultsScreenState();
}

class _VaultsScreenState extends ConsumerState<VaultsScreen> {
  final TextEditingController _setupPinController = TextEditingController();

  void _showPinGate(String vaultId, String title) {
    String currentPin = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void onNumberPress(int number) async {
              if (currentPin.length < 4) {
                setState(() => currentPin += number.toString());
                if (currentPin.length == 4) {
                  final user = ref.read(authServiceProvider).currentUser;
                  if (user != null) {
                    bool isValid = await ref
                        .read(vaultServiceProvider)
                        .verifyPin(user.uid, currentPin);
                    if (isValid) {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VaultDetailsScreen(
                            vaultId: vaultId,
                            vaultName: title,
                          ),
                        ),
                      );
                    } else {
                      setState(() => currentPin = ''); // Reset
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Invalid Security PIN',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    }
                  }
                }
              }
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.lock, color: Colors.white, size: 60),
                  const SizedBox(height: 16),
                  Text(
                    'Decrypting $title',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter 4-Digit Security PIN',
                    style: TextStyle(
                      color: Colors.grey,
                      fontFamily: 'Roboto',
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      4,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index < currentPin.length
                              ? Colors.white
                              : Colors.transparent,
                          border: Border.all(
                            color: index < currentPin.length
                                ? Colors.white
                                : Colors.grey.shade700,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.5,
                        ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      if (index == 9) return const SizedBox.shrink();
                      if (index == 11) {
                        return IconButton(
                          icon: const Icon(
                            Icons.backspace,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            if (currentPin.isNotEmpty) {
                              setState(
                                () => currentPin = currentPin.substring(
                                  0,
                                  currentPin.length - 1,
                                ),
                              );
                            }
                          },
                        );
                      }
                      final number = index == 10 ? 0 : index + 1;
                      return InkWell(
                        onTap: () => onNumberPress(number),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white12,
                          ),
                          child: Center(
                            child: Text(
                              '$number',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Roboto',
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSetupPinModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B1B1E),
        title: const Text(
          'Setup Vault Security',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Create a 4-Digit Master PIN to securely encrypt your localized Vaults ecosystem.',
              style: TextStyle(color: Colors.white70, fontFamily: 'Roboto'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _setupPinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                letterSpacing: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                counterText: '',
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
            ),
            onPressed: () async {
              if (_setupPinController.text.length == 4) {
                final user = ref.read(authServiceProvider).currentUser;
                if (user != null) {
                  await ref
                      .read(vaultServiceProvider)
                      .setupMasterPin(user.uid, _setupPinController.text);
                  Navigator.pop(context);
                  setState(() {}); // Refresh Stream
                }
              }
            },
            child: const Text(
              'Secure Vault',
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
    if (currentUser == null) {
      return const Scaffold(backgroundColor: Colors.black);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      appBar: AppBar(
        title: const Text(
          'Encrypted Vaults',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 26,
            color: Colors.white,
            letterSpacing: -0.5,
            fontFamily: 'Roboto',
          ),
        ),
        backgroundColor: const Color(0xFF0F0F12),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.white, size: 28),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  final TextEditingController nameController =
                      TextEditingController();
                  return AlertDialog(
                    backgroundColor: const Color(0xFF1B1B1E),
                    title: const Text(
                      'New Vault',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Vault Name',
                        hintStyle: TextStyle(color: Colors.white54),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.isNotEmpty) {
                            await ref
                                .read(vaultServiceProvider)
                                .createVault(
                                  currentUser.uid,
                                  nameController.text,
                                );
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('Create'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<bool>(
        future: ref.watch(vaultServiceProvider).hasPinSetup(currentUser.uid),
        builder: (context, pinSnapshot) {
          if (pinSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final bool hasPin = pinSnapshot.data ?? false;
          if (!hasPin) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showSetupPinModal();
            });
            return const Center(
              child: Text(
                'Initializing Security Protocol...',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            stream: ref
                .watch(vaultServiceProvider)
                .getUserVaults(currentUser.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final vaults = snapshot.data?.docs ?? [];

              if (vaults.isEmpty) {
                return const Center(
                  child: Text(
                    'No vaults created yet.',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                itemCount: vaults.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 0.82,
                ),
                itemBuilder: (context, index) {
                  final data = vaults[index].data() as Map<String, dynamic>;
                  final title = data['name'] ?? 'Vault';
                  final vaultId = vaults[index].id;

                  return GestureDetector(
                    onTap: () => _showPinGate(vaultId, title),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B1B1E),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 15,
                            offset: Offset(0, 8),
                          ),
                        ],
                        border: Border.all(color: Colors.white12, width: 1.5),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFFF43F5E)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF8B5CF6,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.enhanced_encryption,
                              size: 36,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              title,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Colors.white,
                                fontFamily: 'Roboto',
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Secured',
                              style: TextStyle(
                                color: Color(0xFF34D399),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                fontFamily: 'Roboto',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class ProfileScreen extends ConsumerStatefulWidget {
  final String? targetUserId;
  const ProfileScreen({super.key, this.targetUserId});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isPrivate = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  String get _uid =>
      widget.targetUserId ?? ref.read(authServiceProvider).currentUser!.uid;
  bool get _isSelf =>
      widget.targetUserId == null ||
      widget.targetUserId == ref.read(authServiceProvider).currentUser!.uid;

  Future<void> _loadPrivacySettings() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .get();
    if (mounted) {
      setState(() {
        _isPrivate = doc.data()?['isPrivate'] ?? false;
      });
    }
  }

  Future<void> _togglePrivacy(bool val) async {
    if (!_isSelf) return;
    await FirebaseFirestore.instance.collection('users').doc(_uid).update({
      'isPrivate': val,
    });
    if (mounted) setState(() => _isPrivate = val);
  }

  Future<void> _handleFollow(Map<String, dynamic>? targetData) async {
    if (_isSelf || targetData == null) return;
    final currentUserId = ref.read(authServiceProvider).currentUser!.uid;

    final followers = List<String>.from(targetData['followers'] ?? []);
    final followRequests = List<String>.from(
      targetData['followRequests'] ?? [],
    );

    if (followers.contains(currentUserId)) {
      // Unfollow
      await FirebaseFirestore.instance.collection('users').doc(_uid).update({
        'followers': FieldValue.arrayRemove([currentUserId]),
      });
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .update({
            'following': FieldValue.arrayRemove([_uid]),
          });
    } else if (followRequests.contains(currentUserId)) {
      // Cancel Request
      await FirebaseFirestore.instance.collection('users').doc(_uid).update({
        'followRequests': FieldValue.arrayRemove([currentUserId]),
      });
    } else {
      // Follow / Request to Follow
      if (targetData['isPrivate'] == true) {
        await FirebaseFirestore.instance.collection('users').doc(_uid).update({
          'followRequests': FieldValue.arrayUnion([currentUserId]),
        });
      } else {
        await FirebaseFirestore.instance.collection('users').doc(_uid).update({
          'followers': FieldValue.arrayUnion([currentUserId]),
        });
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .update({
              'following': FieldValue.arrayUnion([_uid]),
            });
      }
    }
  }

  String _getFollowButtonText(Map<String, dynamic>? data) {
    if (data == null) return 'Follow';
    final currentUserId = ref.read(authServiceProvider).currentUser!.uid;
    final followers = List<String>.from(data['followers'] ?? []);
    final followRequests = List<String>.from(data['followRequests'] ?? []);
    if (followers.contains(currentUserId)) return 'Following';
    if (followRequests.contains(currentUserId)) return 'Requested';
    return 'Follow';
  }

  Future<void> _updateField(
    String fieldTitle,
    String firestoreField,
    String currentValue,
  ) async {
    final TextEditingController controller = TextEditingController(
      text: currentValue,
    );
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit $fieldTitle',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter your new $fieldTitle',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          autofocus: true,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.black54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != currentValue) {
      final user = ref.read(authServiceProvider).currentUser;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({firestoreField: result});
    }
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

    final user = ref.read(authServiceProvider).currentUser;
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'profileBase64': base64String,
    });
  }

  void _showEditProfileSheet(Map<String, dynamic>? userData) {
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
                'Edit Profile',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const Divider(height: 32),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Change Name'),
                onTap: () {
                  Navigator.pop(context);
                  _updateField('Name', 'name', userData?['name'] ?? '');
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Change Bio'),
                onTap: () {
                  Navigator.pop(context);
                  _updateField('Bio', 'bio', userData?['bio'] ?? '');
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Update Profile Picture'),
                onTap: () {
                  Navigator.pop(context);
                  _updateProfilePicture();
                },
              ),
              ListTile(
                leading: Icon(_isPrivate ? Icons.lock : Icons.lock_open),
                title: Text(
                  _isPrivate ? 'Make Account Public' : 'Make Account Private',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _togglePrivacy(!_isPrivate);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        !_isPrivate
                            ? 'Account is now Private 🔒'
                            : 'Account is now Public 🌍',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileAvatar(Map<String, dynamic>? data) {
    return Center(
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFF43F5E)],
              ),
            ),
            child: CircleAvatar(
              radius: 70,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 66,
                backgroundColor: const Color(0xFFF1F5F9),
                backgroundImage: data != null && data['profileBase64'] != null
                    ? MemoryImage(base64Decode(data['profileBase64']))
                    : null,
                child: data == null || data['profileBase64'] == null
                    ? const Icon(
                        Icons.person,
                        size: 60,
                        color: Color(0xFF8B5CF6),
                      )
                    : null,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 4,
            child: GestureDetector(
              onTap: _updateProfilePicture,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF43F5E),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: Colors.black45, size: 28),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit, size: 20, color: Color(0xFF8B5CF6)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              _isPrivate ? Icons.lock : Icons.lock_open,
              size: 16,
              color: theme.iconTheme.color,
            ),
            const SizedBox(width: 8),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(_uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Text('profile');
                final name = snapshot.data!.data() as Map<String, dynamic>?;
                return Text(
                  name?['username'] ?? name?['name'] ?? 'profile',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add_box_outlined,
              color: theme.iconTheme.color,
              size: 28,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.menu, color: theme.iconTheme.color, size: 28),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(_uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    final userData =
                        snapshot.data!.data() as Map<String, dynamic>?;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  CircleAvatar(
                                    radius: 42,
                                    backgroundColor: theme.primaryColor
                                        .withValues(alpha: 0.1),
                                    backgroundImage:
                                        userData?['profileBase64'] != null
                                        ? MemoryImage(
                                            base64Decode(
                                              userData!['profileBase64'],
                                            ),
                                          )
                                        : null,
                                    child: userData?['profileBase64'] == null
                                        ? Icon(
                                            Icons.person,
                                            color: theme.primaryColor,
                                            size: 40,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    userData?['name'] ?? 'User',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (userData?['username'] != null &&
                                      userData!['username']
                                          .toString()
                                          .isNotEmpty)
                                    Text(
                                      '@${userData['username']}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection('posts')
                                          .where(
                                            'uploaderId',
                                            isEqualTo: user?.uid,
                                          )
                                          .snapshots(),
                                      builder: (context, snapshot) {
                                        final postCount = snapshot.hasData
                                            ? snapshot.data!.docs.length
                                            : 0;
                                        return Column(
                                          children: [
                                            Text(
                                              postCount.toString(),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                              ),
                                            ),
                                            const Text(
                                              'posts',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        final list = List<String>.from(
                                          userData?['followers'] ?? [],
                                        );
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => UserListScreen(
                                              title: 'Followers',
                                              userIds: list,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Column(
                                        children: [
                                          Text(
                                            (userData?['followers'] as List?)
                                                    ?.length
                                                    .toString() ??
                                                '0',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          ),
                                          const Text(
                                            'followers',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        final list = List<String>.from(
                                          userData?['following'] ?? [],
                                        );
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => UserListScreen(
                                              title: 'Following',
                                              userIds: list,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Column(
                                        children: [
                                          Text(
                                            (userData?['following'] as List?)
                                                    ?.length
                                                    .toString() ??
                                                '0',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          ),
                                          const Text(
                                            'following',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            userData?['bio'] ?? 'Available\n✨',
                            style: const TextStyle(fontSize: 14, height: 1.4),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: !_isSelf
                                ? ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          _getFollowButtonText(userData) ==
                                              'Following'
                                          ? Colors.grey.shade800
                                          : Theme.of(context).primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 0,
                                    ),
                                    onPressed: () => _handleFollow(userData),
                                    child: Text(
                                      _getFollowButtonText(userData),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () =>
                                        _showEditProfileSheet(userData),
                                    child: const Text(
                                      'Edit Profile',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        if (userData != null &&
                            ((userData['facebookUrl'] != null &&
                                    userData['facebookUrl']
                                        .toString()
                                        .isNotEmpty) ||
                                (userData['instagramUrl'] != null &&
                                    userData['instagramUrl']
                                        .toString()
                                        .isNotEmpty) ||
                                (userData['whatsappUrl'] != null &&
                                    userData['whatsappUrl']
                                        .toString()
                                        .isNotEmpty)))
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              top: 12,
                            ),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (userData['facebookUrl'] != null &&
                                    userData['facebookUrl']
                                        .toString()
                                        .isNotEmpty)
                                  ActionChip(
                                    avatar: const Icon(
                                      Icons.facebook,
                                      size: 16,
                                      color: Colors.blue,
                                    ),
                                    label: const Text(
                                      'Facebook',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    onPressed: () {},
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                if (userData['instagramUrl'] != null &&
                                    userData['instagramUrl']
                                        .toString()
                                        .isNotEmpty)
                                  ActionChip(
                                    avatar: const Icon(
                                      Icons.camera_alt,
                                      size: 16,
                                      color: Colors.pink,
                                    ),
                                    label: const Text(
                                      'Instagram',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    onPressed: () {},
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                if (userData['whatsappUrl'] != null &&
                                    userData['whatsappUrl']
                                        .toString()
                                        .isNotEmpty)
                                  ActionChip(
                                    avatar: const Icon(
                                      Icons.chat,
                                      size: 16,
                                      color: Colors.green,
                                    ),
                                    label: const Text(
                                      'WhatsApp',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    onPressed: () {},
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              const Text(
                                'Theme:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ...[
                                {
                                  'p': const Color(0xFF8B5CF6),
                                  's': const Color(0xFFF43F5E),
                                },
                                {
                                  'p': Colors.pinkAccent,
                                  's': Colors.orangeAccent,
                                },
                                {
                                  'p': const Color(0xFF2563EB),
                                  's': const Color(0xFF38BDF8),
                                },
                                {
                                  'p': const Color(0xFF10B981),
                                  's': const Color(0xFF34D399),
                                },
                              ].map(
                                (c) => GestureDetector(
                                  onTap: () {
                                    ref
                                        .read(themeProvider.notifier)
                                        .setCustomTheme(
                                          c['p'] as Color,
                                          c['s'] as Color,
                                          Theme.of(context).brightness ==
                                              Brightness.dark,
                                        );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: c['p'] as Color,
                                      border: Border.all(
                                        color: theme.scaffoldBackgroundColor,
                                        width: 2,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: theme.cardColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                  ),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditProfileScreen(
                                        initialUserData: userData,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Edit profile',
                                    style: TextStyle(
                                      color: theme.textTheme.bodyMedium?.color,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: theme.cardColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                  ),
                                  onPressed: () {
                                    final username =
                                        userData?['username'] ??
                                        user?.uid ??
                                        'me';
                                    Share.share(
                                      'Connect with me on Aura Context-Aware Messenger! 🚀\n\nhttps://aura.app/@$username',
                                    );
                                  },
                                  child: Text(
                                    'Share profile',
                                    style: TextStyle(
                                      color: theme.textTheme.bodyMedium?.color,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: theme.cardColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  minimumSize: const Size(40, 40),
                                  padding: EdgeInsets.zero,
                                ),
                                onPressed: () {},
                                child: Icon(
                                  Icons.person_add_outlined,
                                  color: theme.iconTheme.color,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    indicatorColor: theme.iconTheme.color,
                    labelColor: theme.iconTheme.color,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(icon: Icon(Icons.grid_on)),
                      Tab(icon: Icon(Icons.video_library_outlined)),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .where('uploaderId', isEqualTo: user?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final posts = snapshot.data?.docs ?? [];
                  if (posts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.primaryColor,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.camera_alt_outlined,
                              size: 48,
                              color: theme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Posts Yet',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(1),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final data = posts[index].data() as Map<String, dynamic>;
                      return Image.memory(
                        base64Decode(data['imageBase64']),
                        fit: BoxFit.cover,
                      );
                    },
                  );
                },
              ),
              const Center(
                child: Text(
                  'No Reels Yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
        ),
        elevation: 0,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          ListTile(
            leading: _buildIcon(Icons.notifications, Colors.orange),
            title: const Text(
              'Notifications',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () =>
                _navigateTo(context, const NotificationsSettingsScreen()),
          ),
          ListTile(
            leading: _buildIcon(Icons.security, Colors.blue),
            title: const Text(
              'Privacy & Security',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _navigateTo(context, const PrivacySettingsScreen()),
          ),
          ListTile(
            leading: _buildIcon(Icons.palette, Colors.purple),
            title: const Text(
              'Appearance',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _navigateTo(context, const AppearanceSettingsScreen()),
          ),
          ListTile(
            leading: _buildIcon(Icons.help, Colors.green),
            title: const Text(
              'Help & Support',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _navigateTo(context, const HelpSupportScreen()),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Divider(height: 1),
          ),
          ListTile(
            leading: _buildIcon(Icons.logout, Colors.redAccent),
            title: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color),
    );
  }
}

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});
  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  bool push = true;
  bool sounds = true;
  bool vibrates = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive alerts for new messages'),
            value: push,
            onChanged: (v) => setState(() => push = v),
            activeThumbColor: const Color(0xFF8B5CF6),
          ),
          SwitchListTile(
            title: const Text('Message Sounds'),
            value: sounds,
            onChanged: (v) => setState(() => sounds = v),
            activeThumbColor: const Color(0xFF8B5CF6),
          ),
          SwitchListTile(
            title: const Text('In-App Vibrations'),
            value: vibrates,
            onChanged: (v) => setState(() => vibrates = v),
            activeThumbColor: const Color(0xFF8B5CF6),
          ),
        ],
      ),
    );
  }
}

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});
  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool readReceipts = true;
  bool activityStatus = true;
  bool biometrics = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Security')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Message Controls',
              style: TextStyle(
                color: Color(0xFF8B5CF6),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Read Receipts'),
            subtitle: const Text(
              'Let others know when you have read their messages.',
            ),
            value: readReceipts,
            onChanged: (v) => setState(() => readReceipts = v),
            activeThumbColor: const Color(0xFF8B5CF6),
          ),
          SwitchListTile(
            title: const Text('Activity Status'),
            subtitle: const Text('Let others see when you are online.'),
            value: activityStatus,
            onChanged: (v) => setState(() => activityStatus = v),
            activeThumbColor: const Color(0xFF8B5CF6),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Security',
              style: TextStyle(
                color: Color(0xFF8B5CF6),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('App Lock (Biometrics)'),
            subtitle: const Text(
              'Require Face ID or Fingerprint to open Aura.',
            ),
            value: biometrics,
            onChanged: (v) => setState(() => biometrics = v),
            activeThumbColor: const Color(0xFF8B5CF6),
          ),
        ],
      ),
    );
  }
}

class AppearanceSettingsScreen extends ConsumerStatefulWidget {
  const AppearanceSettingsScreen({super.key});
  @override
  ConsumerState<AppearanceSettingsScreen> createState() =>
      _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState
    extends ConsumerState<AppearanceSettingsScreen> {
  int _themeMode = 1;
  int _accentColor = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(
        children: [
          RadioListTile(
            title: const Text('Light Mode'),
            value: 1,
            groupValue: _themeMode,
            onChanged: (v) {
              setState(() => _themeMode = 1);
              ref.read(themeProvider.notifier).setLightMode();
            },
            activeColor: Theme.of(context).primaryColor,
          ),
          RadioListTile(
            title: const Text('Dark Mode'),
            value: 2,
            groupValue: _themeMode,
            onChanged: (v) {
              setState(() => _themeMode = 2);
              ref.read(themeProvider.notifier).setDarkMode();
            },
            activeColor: Theme.of(context).primaryColor,
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Accent Color',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF8B5CF6),
              radius: 12,
            ),
            title: const Text('Aura Violet (Default)'),
            trailing: _accentColor == 1
                ? const Icon(Icons.check, color: Color(0xFF8B5CF6))
                : null,
            onTap: () {
              setState(() => _accentColor = 1);
              ref
                  .read(themeProvider.notifier)
                  .setCustomTheme(
                    const Color(0xFF8B5CF6),
                    const Color(0xFFF43F5E),
                    _themeMode == 2,
                  );
            },
          ),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.pinkAccent,
              radius: 12,
            ),
            title: const Text('Hot Pink'),
            trailing: _accentColor == 2
                ? const Icon(Icons.check, color: Colors.pinkAccent)
                : null,
            onTap: () {
              setState(() => _accentColor = 2);
              ref
                  .read(themeProvider.notifier)
                  .setCustomTheme(
                    Colors.pinkAccent,
                    Colors.orangeAccent,
                    _themeMode == 2,
                  );
            },
          ),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.deepPurple,
              radius: 12,
            ),
            title: const Text('Deep Purple'),
            trailing: _accentColor == 3
                ? const Icon(Icons.check, color: Colors.deepPurple)
                : null,
            onTap: () {
              setState(() => _accentColor = 3);
              ref
                  .read(themeProvider.notifier)
                  .setCustomTheme(
                    Colors.deepPurple,
                    Colors.pinkAccent,
                    _themeMode == 2,
                  );
            },
          ),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF2563EB), // Cyber Blue
              radius: 12,
            ),
            title: const Text('Cyber Blue'),
            trailing: _accentColor == 4
                ? const Icon(Icons.check, color: Color(0xFF2563EB))
                : null,
            onTap: () {
              setState(() => _accentColor = 4);
              ref
                  .read(themeProvider.notifier)
                  .setCustomTheme(
                    const Color(0xFF2563EB),
                    const Color(0xFF38BDF8),
                    _themeMode == 2,
                  );
            },
          ),
        ],
      ),
    );
  }
}

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(
              Icons.help_center_outlined,
              color: Color(0xFF8B5CF6),
            ),
            title: const Text('Help Center'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.mail_outline, color: Color(0xFF8B5CF6)),
            title: const Text('Contact Us'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ContactUsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.article_outlined,
              color: Color(0xFF8B5CF6),
            ),
            title: const Text('Terms and Privacy Policy'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TermsPrivacyScreen()),
              );
            },
          ),
          Divider(),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.bubble_chart, size: 48, color: Color(0xFF8B5CF6)),
                  SizedBox(height: 16),
                  Text(
                    'Aura Messenger',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    'Version 1.0.0 (Release build)',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help Center')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text(
            'Frequently Asked Questions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          _HelpFaqItem(
            question: 'How do I upload a Story?',
            answer:
                'Go to the Home tab and tap the "+" icon on the "Your Story" circle at the top of the screen. You can add images from your gallery.',
          ),
          _HelpFaqItem(
            question: 'What are Secure Vaults?',
            answer:
                'Vaults allow you to save encrypted media and text locally. You can lock them and even send them into a chat session with an unlock timer!',
          ),
          _HelpFaqItem(
            question: 'How do I change my theme?',
            answer:
                'Go to Profile -> Settings -> Appearance. You can pick between Light and Dark mode, and change your primary accent color.',
          ),
          _HelpFaqItem(
            question: 'Who can see my profile?',
            answer:
                'By default, your profile is public. You can switch to a private account under Privacy Settings so only approved followers can see your content.',
          ),
        ],
      ),
    );
  }
}

class _HelpFaqItem extends StatelessWidget {
  final String question;
  final String answer;
  const _HelpFaqItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(height: 4),
          Text(answer, style: const TextStyle(height: 1.4, fontSize: 14)),
        ],
      ),
    );
  }
}

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Us')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.support_agent, size: 64, color: Color(0xFF8B5CF6)),
            const SizedBox(height: 24),
            const Text(
              'We\'d love to hear from you!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'If you have any questions, encounter a bug, or just want to give us feedback, feel free to reach out to the development team.',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.5, fontSize: 16),
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: ListTile(
                leading: const Icon(Icons.email, color: Color(0xFF8B5CF6)),
                title: const Text('Email Support'),
                subtitle: const Text('support@auraapp.com'),
                onTap: () {},
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: ListTile(
                leading: const Icon(Icons.public, color: Color(0xFF8B5CF6)),
                title: const Text('Developer Website'),
                subtitle: const Text('https://aura-messenger.com'),
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TermsPrivacyScreen extends StatelessWidget {
  const TermsPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Privacy')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text(
            'Terms of Service',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B5CF6),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Welcome to Aura Messenger. By using our application, you agree to these terms. Aura is a platform for secure communication, media sharing, and vaults. You agree not to misuse our services or help anyone else do so. You are responsible for the content you post.',
            style: TextStyle(height: 1.5),
          ),
          SizedBox(height: 24),
          Text(
            'Privacy Policy',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B5CF6),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Data Collection:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            'We collect information you provide directly, such as when you create an account, update your profile, or send messages. We use base64 encoding to store images in standard Firestore structures.',
            style: TextStyle(height: 1.5),
          ),
          SizedBox(height: 8),
          Text('Data Security:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(
            'We use industry standard mechanics to protect your data. "Vaults" provide an extra layer of privacy by visually obscuring secure texts until intentionally unlocked via the UI.',
            style: TextStyle(height: 1.5),
          ),
          SizedBox(height: 8),
          Text('Sharing:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(
            'We do not sell your personal data to non-affiliated third parties. Your chat contexts and messages remain between you and your participants.',
            style: TextStyle(height: 1.5),
          ),
          SizedBox(height: 40),
          Center(
            child: Text(
              'Last updated: August 2026',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class UserListScreen extends StatelessWidget {
  final String title;
  final List<String> userIds;

  const UserListScreen({super.key, required this.title, required this.userIds});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: userIds.isEmpty
          ? Center(
              child: Text(
                'No $title yet.',
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: userIds.length,
              itemBuilder: (context, index) {
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(userIds[index])
                      .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const SizedBox.shrink();
                    }
                    final user = snapshot.data!.data() as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.white12,
                        backgroundImage: user['profileBase64'] != null
                            ? MemoryImage(base64Decode(user['profileBase64']))
                            : null,
                        child: user['profileBase64'] == null
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      title: Text(
                        user['name'] ?? user['username'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '@${user['username'] ?? 'user'}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProfileScreen(targetUserId: userIds[index]),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.read(authServiceProvider).currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Activity',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null) return const Center(child: Text('No data'));

          final rawRequests = data['followRequests'] as List<dynamic>? ?? [];
          final followRequests = rawRequests.map((e) => e.toString()).toList();

          if (followRequests.isEmpty) {
            return const Center(
              child: Text(
                'No new follow requests.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: followRequests.length,
            itemBuilder: (context, index) {
              final targetUid = followRequests[index];
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(targetUid)
                    .get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData || !userSnap.data!.exists) {
                    return const SizedBox.shrink();
                  }
                  final u = userSnap.data!.data() as Map<String, dynamic>;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.white12,
                      backgroundImage: u['profileBase64'] != null
                          ? MemoryImage(base64Decode(u['profileBase64']))
                          : null,
                      child: u['profileBase64'] == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(
                      u['name'] ?? u['username'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Requested to follow you'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(currentUserId)
                                .update({
                                  'followRequests': FieldValue.arrayRemove([
                                    targetUid,
                                  ]),
                                  'followers': FieldValue.arrayUnion([
                                    targetUid,
                                  ]),
                                });
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(targetUid)
                                .update({
                                  'following': FieldValue.arrayUnion([
                                    currentUserId,
                                  ]),
                                });
                          },
                          child: const Text('Accept'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(currentUserId)
                                .update({
                                  'followRequests': FieldValue.arrayRemove([
                                    targetUid,
                                  ]),
                                });
                          },
                          child: const Text(
                            'Decline',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
