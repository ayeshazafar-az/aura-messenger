import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart' as image_picker;
import '../../core/auth_service.dart';

class StatusScreen extends StatelessWidget {
  const StatusScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Status')),
    body: const Center(
      child: Text(
        'Status & Stories (Coming Soon)',
        style: TextStyle(color: Colors.grey),
      ),
    ),
  );
}

class VaultsScreen extends StatelessWidget {
  const VaultsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My Vaults')),
    body: const Center(
      child: Text(
        'Active Locked Vaults (Coming Soon)',
        style: TextStyle(color: Colors.grey),
      ),
    ),
  );
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
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
                              style: const TextStyle(
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
        ),
        backgroundColor: Colors.white,
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

class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(
        children: [
          RadioListTile(
            title: const Text('System Default'),
            value: 1,
            groupValue: 1,
            onChanged: (v) {},
            activeColor: const Color(0xFF8B5CF6),
          ),
          RadioListTile(
            title: const Text('Light Mode'),
            value: 2,
            groupValue: 1,
            onChanged: (v) {},
            activeColor: const Color(0xFF8B5CF6),
          ),
          RadioListTile(
            title: const Text('Dark Mode'),
            value: 3,
            groupValue: 1,
            onChanged: (v) {},
            activeColor: const Color(0xFF8B5CF6),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Accent Color',
              style: TextStyle(
                color: Color(0xFF8B5CF6),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(0xFF8B5CF6),
              radius: 12,
            ),
            title: Text('Aura Violet (Default)'),
          ),
          const ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(0xFFF43F5E),
              radius: 12,
            ),
            title: Text('Rose Pink'),
          ),
          const ListTile(
            leading: CircleAvatar(backgroundColor: Colors.black, radius: 12),
            title: Text('True Black (Premium)'),
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
