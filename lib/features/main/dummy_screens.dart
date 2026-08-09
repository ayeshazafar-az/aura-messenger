import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart' as image_picker;
import '../../core/auth_service.dart';
import '../../core/story_service.dart';
import '../../core/post_service.dart';
import '../../core/theme_provider.dart';

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
      imageQuality: 50,
      maxWidth: 800,
      maxHeight: 800,
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
      imageQuality: 50,
    );
    if (xFile == null) return;

    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      await ref
          .read(postServiceProvider)
          .uploadPost(user.uid, File(xFile.path), 'Just sharing some vibes ✨');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post uploaded successfully 📸'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.primaryColor.withOpacity(0.1),
            child: Icon(Icons.person, color: theme.primaryColor),
          ),
          title: Text(
            post['uploaderId'].toString().substring(0, 5),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: const Icon(Icons.more_vert),
        ),
        Image.memory(
          base64Decode(post['imageBase64']),
          width: double.infinity,
          fit: BoxFit.cover,
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
                  text: '${post['uploaderId'].toString().substring(0, 5)} ',
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
            icon: const Icon(Icons.add_box_outlined, color: Colors.black87),
            onPressed: _uploadPost,
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                onTap: _uploadStory,
                contentPadding: EdgeInsets.zero,
                leading: Stack(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Color(0xFFF1F5F9),
                      child: Icon(
                        Icons.person,
                        color: Color(0xFF8B5CF6),
                        size: 30,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                title: const Text(
                  'My Story',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: const Text(
                  'Tap to add a story update',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
              child: Text(
                'Recent Updates',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: ref.watch(storyServiceProvider).getActiveStories(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const SliverToBoxAdapter(
                  child: Center(child: Text('Error loading stories')),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final stories = snapshot.data!.docs;

              if (stories.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No recent updates.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final data = stories[index].data() as Map<String, dynamic>;

                  return ListTile(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => Scaffold(
                          backgroundColor: Colors.black,
                          appBar: AppBar(
                            backgroundColor: Colors.black,
                            title: const Text(
                              'Viewing Story',
                              style: TextStyle(color: Colors.white),
                            ),
                            iconTheme: const IconThemeData(color: Colors.white),
                          ),
                          body: Center(
                            child: Image.memory(
                              base64Decode(data['imageBase64']),
                            ),
                          ),
                        ),
                      );
                    },
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFFF43F5E)],
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: const Color(0xFFF1F5F9),
                          backgroundImage: MemoryImage(
                            base64Decode(data['imageBase64']),
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      data['uploaderId'].toString().substring(0, 5),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    subtitle: const Text(
                      'Recently',
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }, childCount: stories.length),
              );
            },
          ),
          SliverToBoxAdapter(
            child: StreamBuilder<QuerySnapshot>(
              stream: ref.watch(postServiceProvider).getFeedPosts(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final posts = snapshot.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index].data() as Map<String, dynamic>;
                    return _buildPostCard(post);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const TextField(
            decoration: InputDecoration(
              hintText: 'Search',
              prefixIcon: Icon(Icons.search, color: Colors.black54),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: 30,
        itemBuilder: (context, index) {
          return Container(
            color: Colors.grey.withOpacity((index % 5) * 0.1 + 0.1),
            child: const Icon(Icons.image, color: Colors.white54),
          );
        },
      ),
    );
  }
}

class VaultsScreen extends StatelessWidget {
  const VaultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Active Vaults',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            margin: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  Icons.lock_clock,
                  size: 48,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Zero Active Vaults',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'When someone sends you a time-locked payload, it will appear here bridging full encryption.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_moderator),
                  label: const Text('Create New Vault'),
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.shield, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text(
                  'End-to-End Encrypted',
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
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

  Future<void> _loadPrivacySettings() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (mounted) {
        setState(() {
          _isPrivate = doc.data()?['isPrivate'] ?? false;
        });
      }
    }
  }

  Future<void> _togglePrivacy(bool val) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'isPrivate': val},
      );
      if (mounted) setState(() => _isPrivate = val);
    }
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final userData = snapshot.data!.data() as Map<String, dynamic>?;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _buildProfileAvatar(userData),
                const SizedBox(height: 32),

                _buildListTile(
                  'Name',
                  userData?['name'] ?? 'Add your name',
                  Icons.person,
                  () => _updateField('Name', 'name', userData?['name'] ?? ''),
                ),
                const Divider(indent: 72, height: 1),

                _buildListTile(
                  'About',
                  userData?['bio'] ?? 'Available',
                  Icons.info_outline,
                  () => _updateField(
                    'About',
                    'bio',
                    userData?['bio'] ?? 'Available',
                  ),
                ),
                const Divider(indent: 72, height: 1),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.alternate_email,
                        color: Colors.black45,
                        size: 28,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Username',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '@${userData?['username'] ?? 'temp'}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Container(color: const Color(0xFFF1F5F9), height: 12),
                const SizedBox(height: 16),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Privacy & Safety',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF8B5CF6),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  title: const Text(
                    'Private Account',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Strangers will need to request to text you.',
                  ),
                  secondary: Icon(
                    _isPrivate ? Icons.lock : Icons.lock_open,
                    color: const Color(0xFF8B5CF6),
                  ),
                  value: _isPrivate,
                  activeColor: const Color(0xFFF43F5E),
                  onChanged: (val) => _togglePrivacy(val),
                ),
              ],
            ),
          );
        },
      ),
    );
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
        color: color.withOpacity(0.1),
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
            activeColor: const Color(0xFF8B5CF6),
          ),
          SwitchListTile(
            title: const Text('Message Sounds'),
            value: sounds,
            onChanged: (v) => setState(() => sounds = v),
            activeColor: const Color(0xFF8B5CF6),
          ),
          SwitchListTile(
            title: const Text('In-App Vibrations'),
            value: vibrates,
            onChanged: (v) => setState(() => vibrates = v),
            activeColor: const Color(0xFF8B5CF6),
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
            activeColor: const Color(0xFF8B5CF6),
          ),
          SwitchListTile(
            title: const Text('Activity Status'),
            subtitle: const Text('Let others see when you are online.'),
            value: activityStatus,
            onChanged: (v) => setState(() => activityStatus = v),
            activeColor: const Color(0xFF8B5CF6),
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
            activeColor: const Color(0xFF8B5CF6),
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
              backgroundColor: Color(0xFFF43F5E),
              radius: 12,
            ),
            title: const Text('Rose Pink'),
            trailing: _accentColor == 2
                ? const Icon(Icons.check, color: Color(0xFFF43F5E))
                : null,
            onTap: () {
              setState(() => _accentColor = 2);
              ref
                  .read(themeProvider.notifier)
                  .setCustomTheme(
                    const Color(0xFFF43F5E),
                    const Color(0xFF8B5CF6),
                    _themeMode == 2,
                  );
            },
          ),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.teal,
              radius: 12,
            ),
            title: const Text('Emerald Teal'),
            trailing: _accentColor == 3
                ? const Icon(Icons.check, color: Colors.teal)
                : null,
            onTap: () {
              setState(() => _accentColor = 3);
              ref
                  .read(themeProvider.notifier)
                  .setCustomTheme(
                    Colors.teal,
                    Colors.tealAccent,
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
        children: const [
          ListTile(
            leading: Icon(Icons.help_center_outlined, color: Color(0xFF8B5CF6)),
            title: Text('Help Center'),
            trailing: Icon(Icons.open_in_new, size: 16),
          ),
          ListTile(
            leading: Icon(Icons.mail_outline, color: Color(0xFF8B5CF6)),
            title: Text('Contact Us'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
          ),
          ListTile(
            leading: Icon(Icons.article_outlined, color: Color(0xFF8B5CF6)),
            title: Text('Terms and Privacy Policy'),
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
                    style: TextStyle(color: Colors.black54),
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
