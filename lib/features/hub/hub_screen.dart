import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class HubScreen extends StatelessWidget {
  const HubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 28),
        ),
        centerTitle: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(child: Text('Error loading users'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index].data() as Map<String, dynamic>;
              final bool isPrivate = user['isPrivate'] ?? false;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(
                      0xFF0084FF,
                    ).withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.person,
                      color: Color(0xFF0084FF),
                      size: 30,
                    ),
                  ),
                  title: Text(
                    '@${user['username'] ?? user['email'].toString().split('@')[0]}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    isPrivate ? 'Private Account' : 'Tap to open secure chat',
                    style: TextStyle(
                      color: isPrivate ? Colors.redAccent : Colors.black54,
                      fontStyle: isPrivate
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isPrivate ? Icons.lock : Icons.chat_bubble_rounded,
                      color: isPrivate
                          ? Colors.redAccent
                          : const Color(0xFF0084FF),
                      size: 20,
                    ),
                  ),
                  onTap: () {
                    final name =
                        user['username'] ??
                        user['email'].toString().split('@')[0];
                    if (isPrivate) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Private Account: Your first message will be sent as a Request.',
                          ),
                          backgroundColor: Color(0xFF0084FF),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                    context.push('/chat/${user['uid']}?name=$name');
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
