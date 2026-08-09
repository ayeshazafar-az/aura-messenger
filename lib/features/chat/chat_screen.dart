import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/auth_service.dart';
import '../../core/chat_service.dart';

class MockCallScreen extends StatefulWidget {
  final bool isVideo;
  final String name;
  const MockCallScreen({super.key, required this.isVideo, required this.name});
  @override
  State<MockCallScreen> createState() => _MockCallScreenState();
}

class _MockCallScreenState extends State<MockCallScreen> {
  int seconds = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() => seconds++);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isVideo ? Colors.black : const Color(0xFF1E1E1E),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),
            if (!widget.isVideo) ...[
              const CircleAvatar(
                radius: 60,
                backgroundColor: Color(0xFF8B5CF6),
                child: Icon(Icons.person, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              widget.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}',
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            Expanded(
              child: widget.isVideo
                  ? const Center(
                      child: Icon(
                        Icons.videocam_off,
                        color: Colors.white24,
                        size: 100,
                      ),
                    )
                  : const SizedBox(),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 64),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.mic_off, color: Colors.white, size: 32),
                  ),
                  if (widget.isVideo)
                    const CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white24,
                      child: Icon(
                        Icons.switch_camera,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.redAccent,
                      child: Icon(
                        Icons.call_end,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _promptMediaOptions() {
    int tempSeconds = 0;
    int viewLimit = 0;
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Secure Media Options'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Select restrictions for this media:'),
                  const SizedBox(height: 16),
                  DropdownButton<int>(
                    value: tempSeconds,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('No Time Lock')),
                      DropdownMenuItem(
                        value: 5,
                        child: Text('Lock for 5 Seconds'),
                      ),
                      DropdownMenuItem(
                        value: 15,
                        child: Text('Lock for 15 Seconds'),
                      ),
                      DropdownMenuItem(
                        value: 30,
                        child: Text('Lock for 30 Seconds'),
                      ),
                      DropdownMenuItem(
                        value: 300,
                        child: Text('Lock for 5 Minutes'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => tempSeconds = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButton<int>(
                    value: viewLimit,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 0,
                        child: Text('Unlimited Views'),
                      ),
                      DropdownMenuItem(value: 1, child: Text('View Once ')),
                      DropdownMenuItem(value: 2, child: Text('View Twice')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => viewLimit = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, {
                    'seconds': tempSeconds,
                    'viewLimit': viewLimit > 0 ? viewLimit : null,
                  }),
                  child: const Text('Send Media'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    // Regular text messages don't prompt time locks unless requested. We'll skip time locks on simple text to mirror Insta.
    final currentUserId = ref.read(authServiceProvider).currentUser!.uid;
    final chatService = ref.read(chatServiceProvider);

    await chatService.sendMessage(
      widget.receiverId,
      _controller.text.trim(),
      null, // text messages don't have time lock anymore for speed
      currentUserId,
    );
    _controller.clear();
  }

  void _sendImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (xFile == null) return;

    final result = await _promptMediaOptions();
    if (result == null) return;

    DateTime? selectedTime;
    if (result['seconds'] > 0) {
      selectedTime = DateTime.now().add(Duration(seconds: result['seconds']));
    }

    final currentUserId = ref.read(authServiceProvider).currentUser!.uid;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading Secure Image...')),
      );
    }

    await ref
        .read(chatServiceProvider)
        .sendImageMessage(
          widget.receiverId,
          File(xFile.path),
          selectedTime,
          currentUserId,
          result['viewLimit'],
        );
  }

  void _showMessageOptions(
    QueryDocumentSnapshot doc,
    Map<String, dynamic> data,
    bool isMe,
  ) {
    if (!isMe) return;

    bool isTextOnly = data['imageBase64'] == null;
    bool canEdit = false;

    if (isTextOnly && data['timestamp'] != null) {
      DateTime sentTime = (data['timestamp'] as Timestamp).toDate();
      if (DateTime.now().difference(sentTime).inMinutes <= 15) {
        canEdit = true;
      }
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canEdit)
                ListTile(
                  leading: const Icon(Icons.edit, color: Color(0xFF8B5CF6)),
                  title: const Text('Edit Message'),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditDialog(doc, data['message']);
                  },
                ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Unsend Message',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await doc.reference.delete();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog(QueryDocumentSnapshot doc, String currentText) {
    final TextEditingController editController = TextEditingController(
      text: currentText,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: editController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter new message...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (editController.text.trim().isNotEmpty &&
                  editController.text.trim() != currentText) {
                await doc.reference.update({
                  'message': editController.text.trim(),
                  'isEdited': true,
                });
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _openViewOnceMedia(
    QueryDocumentSnapshot doc,
    Map<String, dynamic> data,
    bool isMe,
  ) async {
    int maxLimit = data['viewLimit'] ?? 0;
    int currentViews = data['timesViewed'] ?? 0;

    if (!isMe && currentViews >= maxLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This media has expired and cannot be viewed again.'),
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            isMe ? 'Media (You sent)' : 'View Once Media',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        body: Center(
          child: InteractiveViewer(
            child: Image.memory(base64Decode(data['imageBase64'])),
          ),
        ),
      ),
    );

    if (!isMe) {
      await doc.reference.update({'timesViewed': FieldValue.increment(1)});
    }
  }

  Widget _buildMessageBubble(QueryDocumentSnapshot doc, bool isMe) {
    final data = doc.data() as Map<String, dynamic>;
    DateTime? unlockTime;
    if (data['unlockTime'] != null) {
      unlockTime = DateTime.fromMillisecondsSinceEpoch(data['unlockTime']);
    }

    if (unlockTime != null && unlockTime.isAfter(DateTime.now())) {
      return StreamBuilder(
        stream: Stream.periodic(const Duration(seconds: 1)),
        builder: (context, _) {
          bool isLocked = unlockTime!.isAfter(DateTime.now());
          return _buildBubbleUI(doc, isMe, isLocked, unlockTime);
        },
      );
    }
    return _buildBubbleUI(doc, isMe, false, unlockTime);
  }

  Widget _buildViewOnceCover(Map<String, dynamic> data, bool isMe) {
    int maxLimit = data['viewLimit'] ?? 0;
    int currentViews = data['timesViewed'] ?? 0;
    bool isExhausted =
        !isMe &&
        currentViews >=
            maxLimit; // The sender can always look at the lock icon logic

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isExhausted ? Icons.visibility_off : Icons.visibility,
            color: isExhausted
                ? Colors.grey
                : (isMe ? Colors.white : const Color(0xFF8B5CF6)),
            size: 30,
          ),
          const SizedBox(height: 8),
          Text(
            isExhausted ? 'Opened' : 'View Media',
            style: TextStyle(
              color: isExhausted
                  ? Colors.grey
                  : (isMe ? Colors.white : const Color(0xFF8B5CF6)),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubbleUI(
    QueryDocumentSnapshot doc,
    bool isMe,
    bool isLocked,
    DateTime? unlockTime,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    return GestureDetector(
      onLongPress: () => _showMessageOptions(doc, data, isMe),
      onTap: () {
        if (data['viewLimit'] != null &&
            data['imageBase64'] != null &&
            !isLocked) {
          _openViewOnceMedia(doc, data, isMe);
        }
      },
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          padding:
              data['imageBase64'] != null &&
                  !isLocked &&
                  data['viewLimit'] == null
              ? const EdgeInsets.all(4)
              : const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            gradient: isLocked
                ? null
                : isMe
                ? const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFF43F5E)],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  )
                : null,
            color: isLocked
                ? const Color(0xFF1E1E1E)
                : isMe
                ? null
                : Colors.white,
            borderRadius: BorderRadius.circular(22).copyWith(
              bottomRight: isMe
                  ? const Radius.circular(6)
                  : const Radius.circular(22),
              bottomLeft: isMe
                  ? const Radius.circular(22)
                  : const Radius.circular(6),
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
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: isLocked
              ? _buildLockedVault(unlockTime!)
              : data['imageBase64'] != null
              ? (data['viewLimit'] != null
                    ? _buildViewOnceCover(data, isMe)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.memory(
                          base64Decode(data['imageBase64']),
                          width: 250,
                          fit: BoxFit.cover,
                        ),
                      ))
              : Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data['message'] ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        color: isMe ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (data['isEdited'] == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          ' (edited)',
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe ? Colors.white70 : Colors.black45,
                          ),
                        ),
                      ),
                  ],
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

  Widget _buildInputArea(DocumentSnapshot? roomDoc, String currentUserId) {
    if (roomDoc != null && roomDoc.exists) {
      final data = roomDoc.data() as Map<String, dynamic>;
      if (data['status'] == 'requested' && data['initiator'] != currentUserId) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFF0F2F5))),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Message Request',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                const Text(
                  'This user wants to connect. Sending a reply will allow them to call you and see information like your Activity Status.',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                        ),
                        child: const Text(
                          'Block',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => ref
                            .read(chatServiceProvider)
                            .acceptRequest(currentUserId, widget.receiverId),
                        child: const Text('Accept'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: const BoxDecoration(color: Colors.white),
      child: SafeArea(
        child: Row(
          children: [
            GestureDetector(
              onTap: _sendImage,
              child: const Icon(
                Icons.add_circle,
                color: Color(0xFF8B5CF6),
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Message',
                  filled: true,
                  fillColor: const Color(0xFFFAFAFA),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: Color(0xFF8B5CF6),
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
                backgroundColor: Color(0xFF8B5CF6),
                child: Icon(Icons.arrow_upward, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authServiceProvider).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName),
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: Color(0xFF8B5CF6)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    MockCallScreen(isVideo: false, name: widget.receiverName),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.videocam, color: Color(0xFF8B5CF6)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    MockCallScreen(isVideo: true, name: widget.receiverName),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
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
                    return _buildMessageBubble(msgs[index], isMe);
                  },
                );
              },
            ),
          ),
          StreamBuilder<DocumentSnapshot>(
            stream: ref
                .watch(chatServiceProvider)
                .getRoomStatus(currentUser!.uid, widget.receiverId),
            builder: (context, snapshot) {
              return _buildInputArea(snapshot.data, currentUser.uid);
            },
          ),
        ],
      ),
    );
  }
}
