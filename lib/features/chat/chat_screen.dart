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
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isMe
              ? Theme.of(context).primaryColor
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isMe
                ? const Radius.circular(0)
                : const Radius.circular(16),
            bottomLeft: isMe
                ? const Radius.circular(16)
                : const Radius.circular(0),
          ),
          border: isLocked ? Border.all(color: Colors.amber, width: 2) : null,
          boxShadow: isLocked
              ? [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: isLocked
            ? _buildLockedVault(unlockTime!)
            : Text(
                data['message'] ?? '',
                style: const TextStyle(fontSize: 16, color: Colors.white),
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
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
