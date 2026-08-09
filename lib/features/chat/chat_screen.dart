import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth_service.dart';
import '../../core/chat_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Force UI rebuild every second for countdown locks
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final currentUserId = ref.read(authServiceProvider).currentUser!.uid;
    final chatService = ref.read(chatServiceProvider);

    DateTime? selectedTime;

    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        int tempSeconds = 15;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Send Time-Locked Vault?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Select how long this message will remain locked:',
                  ),
                  const SizedBox(height: 16),
                  DropdownButton<int>(
                    value: tempSeconds,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 5, child: Text('5 Seconds')),
                      DropdownMenuItem(value: 15, child: Text('15 Seconds')),
                      DropdownMenuItem(value: 30, child: Text('30 Seconds')),
                      DropdownMenuItem(value: 60, child: Text('1 Minute')),
                      DropdownMenuItem(value: 300, child: Text('5 Minutes')),
                      DropdownMenuItem(value: 3600, child: Text('1 Hour')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => tempSeconds = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, -1),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, 0),
                  child: const Text('Send Normally'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, tempSeconds),
                  child: const Text('Lock & Send'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || result == -1) return;

    if (result > 0) {
      selectedTime = DateTime.now().add(Duration(seconds: result));
    }

    await chatService.sendMessage(
      widget.receiverId,
      _controller.text,
      selectedTime,
      currentUserId,
    );
    _controller.clear();
  }

  Widget _buildMessageBubble(Map<String, dynamic> data, bool isMe) {
    DateTime? unlockTime;
    if (data['unlockTime'] != null) {
      unlockTime = DateTime.fromMillisecondsSinceEpoch(data['unlockTime']);
    }

    bool isLocked = unlockTime != null && unlockTime.isAfter(DateTime.now());

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isLocked
              ? const Color(0xFF1E1E1E)
              : isMe
              ? const Color(0xFF007AFF) // iMessage Blue
              : const Color(0xFFE5E5EA), // Soft Grey
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: isMe
                ? const Radius.circular(4)
                : const Radius.circular(20),
            bottomLeft: isMe
                ? const Radius.circular(20)
                : const Radius.circular(4),
          ),
          border: isLocked
              ? Border.all(color: Colors.amberAccent, width: 1.5)
              : null,
          boxShadow: isLocked
              ? [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: isLocked
            ? _buildLockedVault(unlockTime!)
            : Text(
                data['message'] ?? '',
                style: TextStyle(
                  fontSize: 16,
                  color: isMe ? Colors.white : Colors.black87,
                ),
              ),
      ),
    );
  }

  Widget _buildLockedVault(DateTime unlockTime) {
    final diff = unlockTime.difference(DateTime.now());
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.lock, color: Colors.amber, size: 28),
        const SizedBox(height: 8),
        const Text(
          'SECURE VAULT',
          style: TextStyle(fontSize: 10, letterSpacing: 2, color: Colors.amber),
        ),
        Text(
          '${diff.inHours.toString().padLeft(2, '0')}:${(diff.inMinutes % 60).toString().padLeft(2, '0')}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.amber,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authServiceProvider).currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(widget.receiverName)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: ref
                  .watch(chatServiceProvider)
                  .getMessages(widget.receiverId, currentUser!.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return const Center(child: Text('Error'));
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());

                final msgs = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: msgs.length,
                  itemBuilder: (context, index) {
                    final data = msgs[index].data() as Map<String, dynamic>;
                    bool isMe = data['senderId'] == currentUser.uid;
                    return _buildMessageBubble(data, isMe);
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: const BoxDecoration(color: Colors.white),
            child: SafeArea(
              // iOS padding support
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'iMessage',
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E5EA),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E5EA),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: Color(0xFF007AFF),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(0xFF007AFF),
                      child: Icon(
                        Icons.arrow_upward,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
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
