import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth_service.dart';

class HubScreen extends ConsumerWidget {
  const HubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authServiceProvider).currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 28),
        ),
        centerTitle: false,
      ),
      body: currentUser == null
          ? const Center(child: Text('Not authenticated'))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Suggested Users',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 110,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .limit(10)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final users = snapshot.data!.docs
                          .where((doc) => doc.id != currentUser.uid)
                          .toList();

                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final u = users[index].data() as Map<String, dynamic>;
                          return GestureDetector(
                            onTap: () {
                              final name =
                                  u['username'] ??
                                  u['email'].toString().split('@')[0];
                              context.push('/chat/${u['uid']}?name=$name');
                            },
                            child: Container(
                              width: 80,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 32,
                                    backgroundColor: Theme.of(
                                      context,
                                    ).primaryColor.withValues(alpha: 0.1),
                                    backgroundImage: u['profileBase64'] != null
                                        ? MemoryImage(
                                            base64Decode(u['profileBase64']),
                                          )
                                        : null,
                                    child: u['profileBase64'] == null
                                        ? Icon(
                                            Icons.person,
                                            color: Theme.of(
                                              context,
                                            ).primaryColor,
                                            size: 32,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    u['name'] ??
                                        u['username'] ??
                                        u['email'].toString().split('@')[0],
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '@${u['username'] ?? u['email'].toString().split('@')[0]}',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
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
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('chat_rooms')
                        .where('users', arrayContains: currentUser.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Error loading active chats'),
                        );
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final rooms = snapshot.data!.docs.toList();

                      rooms.sort((a, b) {
                        final dataA = a.data() as Map<String, dynamic>;
                        final dataB = b.data() as Map<String, dynamic>;
                        final timeA = dataA['lastMessageTime'] as Timestamp?;
                        final timeB = dataB['lastMessageTime'] as Timestamp?;
                        if (timeA == null && timeB == null) return 0;
                        if (timeA == null) return 1;
                        if (timeB == null) return -1;
                        return timeB.compareTo(timeA);
                      });

                      if (rooms.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: Colors.grey.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No Active Chats',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 24),
                        itemCount: rooms.length,
                        itemBuilder: (context, index) {
                          final roomData =
                              rooms[index].data() as Map<String, dynamic>;
                          final List<dynamic> usersArr = roomData['users'];
                          final otherUserId = usersArr.firstWhere(
                            (id) => id != currentUser.uid,
                            orElse: () => '',
                          );

                          if (otherUserId.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(otherUserId)
                                .get(),
                            builder: (context, userSnapshot) {
                              if (!userSnapshot.hasData ||
                                  !userSnapshot.data!.exists) {
                                return const SizedBox.shrink();
                              }

                              final user =
                                  userSnapshot.data!.data()
                                      as Map<String, dynamic>;
                              final bool isPrivate = user['isPrivate'] ?? false;

                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
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
                                    backgroundColor: Theme.of(
                                      context,
                                    ).primaryColor.withValues(alpha: 0.1),
                                    backgroundImage:
                                        user['profileBase64'] != null
                                        ? MemoryImage(
                                            base64Decode(user['profileBase64']),
                                          )
                                        : null,
                                    child: user['profileBase64'] == null
                                        ? Icon(
                                            Icons.person,
                                            color: Theme.of(
                                              context,
                                            ).primaryColor,
                                            size: 30,
                                          )
                                        : null,
                                  ),
                                  title: Text(
                                    user['name'] != null &&
                                            user['name'].toString().isNotEmpty
                                        ? user['name']
                                        : (user['username'] ??
                                              user['email'].toString().split(
                                                '@',
                                              )[0]),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '@${user['username'] ?? user['email'].toString().split('@')[0]}',
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isPrivate
                                            ? 'Private Account'
                                            : 'Tap to open secure chat',
                                        style: TextStyle(
                                          color: isPrivate
                                              ? Colors.redAccent
                                              : Colors.grey,
                                          fontStyle: isPrivate
                                              ? FontStyle.italic
                                              : FontStyle.normal,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isPrivate
                                          ? Icons.lock
                                          : Icons.chat_bubble_rounded,
                                      color: isPrivate
                                          ? Colors.redAccent
                                          : Theme.of(context).primaryColor,
                                      size: 20,
                                    ),
                                  ),
                                  onTap: () {
                                    final name =
                                        user['username'] ??
                                        user['email'].toString().split('@')[0];
                                    if (isPrivate) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Private Account: Your first message will be sent as a Request.',
                                          ),
                                          backgroundColor: Color(0xFF8B5CF6),
                                          duration: Duration(seconds: 3),
                                        ),
                                      );
                                    }
                                    context.push(
                                      '/chat/${user['uid']}?name=$name',
                                    );
                                  },
                                ),
                              );
                            },
                          );
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
