import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      if (mounted)
        setState(() {
          _isPrivate = doc.data()?['isPrivate'] ?? false;
        });
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

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
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
            child: Center(
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  const CircleAvatar(
                    radius: 60,
                    backgroundColor: Color(0xFFF0F2F5),
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: Color(0xFF8B5CF6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    userData?['name'] ?? 'Loading...',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '@${userData?['username'] ?? 'temp'}',
                    style: const TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                  const SizedBox(height: 32),

                  // Privacy Control
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SwitchListTile(
                      title: const Text(
                        'Private Account',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'When your account is private, strangers cannot initiate new chats with you.',
                      ),
                      secondary: Icon(
                        _isPrivate ? Icons.lock : Icons.lock_open,
                        color: const Color(0xFF8B5CF6),
                      ),
                      value: _isPrivate,
                      activeColor: const Color(0xFF8B5CF6),
                      onChanged: (val) => _togglePrivacy(val),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notifications'),
          ),
          const ListTile(
            leading: Icon(Icons.security),
            title: Text('Privacy & Security'),
          ),
          const ListTile(
            leading: Icon(Icons.palette),
            title: Text('Appearance'),
          ),
          const ListTile(
            leading: Icon(Icons.help),
            title: Text('Help & Support'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
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
}
