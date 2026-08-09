import 'dart:async';
import 'package:flutter/material.dart';

class Message {
  final String id;
  final String text;
  final bool isMe;
  final DateTime? unlockTime;

  Message({
    required this.id,
    required this.text,
    required this.isMe,
    this.unlockTime,
  });
}

class ChatScreen extends StatefulWidget {
  final String friendName;
  const ChatScreen({super.key, required this.friendName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Message> _messages = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _messages.addAll([
      Message(id: '1', text: 'Hey! Are you ready?', isMe: false),
      Message(id: '2', text: 'Yes, just waiting for the reveal.', isMe: true),
      Message(
        id: '3',
        text: 'I have a surprise for you!',
        isMe: false,
        unlockTime: DateTime.now().add(const Duration(seconds: 15)),
      ),
    ]);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    DateTime? selectedTime;
    final lock = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Time-Locked Vault?'),
        content: const Text(
          'Do you want to lock this message for 10 seconds to test?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (lock == true) {
      selectedTime = DateTime.now().add(const Duration(seconds: 10));
    }

    setState(() {
      _messages.insert(
        0,
        Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: _controller.text,
          isMe: true,
          unlockTime: selectedTime,
        ),
      );
    });
    _controller.clear();
  }

  Widget _buildMessageBubble(Message msg) {
    bool isLocked =
        msg.unlockTime != null && msg.unlockTime!.isAfter(DateTime.now());

    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: msg.isMe
              ? Theme.of(context).primaryColor
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: msg.isMe
                ? const Radius.circular(0)
                : const Radius.circular(16),
            bottomLeft: msg.isMe
                ? const Radius.circular(16)
                : const Radius.circular(0),
          ),
          border: isLocked ? Border.all(color: Colors.amber, width: 2) : null,
        ),
        child: isLocked
            ? _buildLockedVault(msg.unlockTime!)
            : Text(msg.text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildLockedVault(DateTime unlockTime) {
    final diff = unlockTime.difference(DateTime.now());
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.lock, color: Colors.amber),
        const SizedBox(height: 4),
        Text(
          'Unlocks in ${diff.inHours.toString().padLeft(2, '0')}:${(diff.inMinutes % 60).toString().padLeft(2, '0')}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.amber,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.friendName)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(
                  _messages[_messages.length - 1 - index],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
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
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
