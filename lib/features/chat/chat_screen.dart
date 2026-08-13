import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
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
  int? _selectedLockMinutes;

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

    final currentUserId = ref.read(authServiceProvider).currentUser!.uid;
    final chatService = ref.read(chatServiceProvider);

    DateTime? unlockDate;
    if (_selectedLockMinutes != null) {
      unlockDate = DateTime.now().add(Duration(minutes: _selectedLockMinutes!));
    }

    await chatService.sendMessage(
      widget.receiverId,
      _controller.text.trim(),
      unlockDate,
      currentUserId,
    );
    _controller.clear();
    setState(() => _selectedLockMinutes = null);
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
                leading: const Icon(Icons.delete, color: Colors.grey),
                title: const Text('Delete for me'),
                onTap: () async {
                  Navigator.pop(context);
                  final currentUser = ref.read(authServiceProvider).currentUser;
                  await doc.reference.update({
                    'deletedFor': FieldValue.arrayUnion([currentUser!.uid]),
                  });
                },
              ),
              if (isMe)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'Delete for everyone',
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

  Widget _buildMessageBubble(
    QueryDocumentSnapshot doc,
    bool isMe,
    String chatTheme,
  ) {
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
          return _buildBubbleUI(doc, isMe, isLocked, unlockTime, chatTheme);
        },
      );
    }
    return _buildBubbleUI(doc, isMe, false, unlockTime, chatTheme);
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
    String chatTheme,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    final timeString = data['timestamp'] != null
        ? DateFormat('h:mm a').format((data['timestamp'] as Timestamp).toDate())
        : '';

    Gradient? bubbleGradient;
    Color? bubbleColor;

    if (isMe && !isLocked) {
      if (chatTheme == 'sunset') {
        bubbleGradient = const LinearGradient(
          colors: [Color(0xFFFF512F), Color(0xFFDD2476)],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        );
      } else if (chatTheme == 'ocean') {
        bubbleGradient = const LinearGradient(
          colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        );
      } else if (chatTheme == 'forest') {
        bubbleGradient = const LinearGradient(
          colors: [Color(0xFF134E5E), Color(0xFF71B280)],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        );
      } else if (chatTheme == 'monochrome') {
        bubbleColor = Colors.grey.shade800;
      } else if (chatTheme == 'solid_black') {
        bubbleColor = const Color(0xFF262626);
      } else if (chatTheme == 'solid_crimson') {
        bubbleColor = const Color(0xFFDC143C);
      } else if (chatTheme == 'solid_navy') {
        bubbleColor = const Color(0xFF000080);
      } else if (chatTheme == 'solid_green') {
        bubbleColor = const Color(0xFF25D366);
      } else {
        bubbleGradient = const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFF43F5E)],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        );
      }
    } else if (!isLocked) {
      bubbleColor = Theme.of(context).cardColor;
    }

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
            gradient: bubbleGradient,
            color: isLocked ? const Color(0xFF1E1E1E) : bubbleColor,
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
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              isLocked
                  ? _buildLockedVault(unlockTime!)
                  : data['imageBase64'] != null
                  ? (data['viewLimit'] != null
                        ? _buildViewOnceCover(data, isMe)
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.65,
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => GestureDetector(
                                      onTap: () => Navigator.pop(context),
                                      child: Scaffold(
                                        backgroundColor: Colors.black,
                                        appBar: AppBar(
                                          backgroundColor: Colors.black,
                                          iconTheme: const IconThemeData(
                                            color: Colors.white,
                                          ),
                                          title: const Text(
                                            'Photo',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        body: Center(
                                          child: InteractiveViewer(
                                            child: Image.memory(
                                              base64Decode(data['imageBase64']),
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: SizedBox(
                                  height: 220,
                                  child: Image.memory(
                                    base64Decode(data['imageBase64']),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                ),
                              ),
                            ),
                          ))
                  : Column(
                      crossAxisAlignment: isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (data['isVaultMessage'] == true)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.lock,
                                  size: 12,
                                  color: Colors.amberAccent,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Vault Message',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.amberAccent,
                                    letterSpacing: 1.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Text(
                          data['message'] ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            fontStyle: data['isVaultMessage'] == true
                                ? FontStyle.italic
                                : FontStyle.normal,
                            fontFamily: data['isVaultMessage'] == true
                                ? 'monospace'
                                : null,
                            color: data['isVaultMessage'] == true
                                ? Colors.amberAccent.shade100
                                : (isMe
                                      ? Colors.white
                                      : Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.color ??
                                            Colors.black87),
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
              const SizedBox(height: 4),
              Text(
                timeString,
                style: TextStyle(
                  fontSize: 10,
                  color: isLocked
                      ? Colors.amber.withOpacity(0.7)
                      : (isMe ? Colors.white70 : Colors.black45),
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
      decoration: BoxDecoration(color: Theme.of(context).cardColor),
      child: SafeArea(
        child: Row(
          children: [
            GestureDetector(
              onTap: _sendImage,
              child: Icon(
                Icons.add_circle,
                color: Theme.of(context).primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 4),
            PopupMenuButton<int>(
              icon: Icon(
                Icons.lock_clock,
                color: _selectedLockMinutes != null
                    ? Colors.amber
                    : Theme.of(context).primaryColor,
                size: 28,
              ),
              onSelected: (val) {
                setState(() => _selectedLockMinutes = val == 0 ? null : val);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 0, child: Text('No Time Lock')),
                const PopupMenuItem(value: 1, child: Text('Lock for 1 Minute')),
                const PopupMenuItem(
                  value: 5,
                  child: Text('Lock for 5 Minutes'),
                ),
                const PopupMenuItem(value: 60, child: Text('Lock for 1 Hour')),
              ],
            ),
            const SizedBox(width: 4),
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Message',
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _sendMessage,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context).primaryColor,
                child: const Icon(
                  Icons.arrow_upward,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteChat(String currentUserId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat?'),
        content: const Text(
          'This will permanently delete all messages in this conversation for both of you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              Navigator.pop(context);
              await ref
                  .read(chatServiceProvider)
                  .deleteEntireChat(currentUserId, widget.receiverId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showThemeSelector(String currentUserId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final Map<String, Color> themes = {
          'default': Theme.of(context).scaffoldBackgroundColor,
          'solid_green': const Color(0xFF128C7E),
          'solid_navy': const Color(0xFF0A192F),
          'solid_crimson': const Color(0xFF4A0E17),
          'solid_black': Colors.black,
          'monochrome': Colors.grey.shade900,
          'sunset': const Color(0xFF4A192C),
          'ocean': const Color(0xFF0F172A),
          'forest': const Color(0xFF132A13),
        };

        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Chat Theme',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: themes.entries
                    .map(
                      (e) => GestureDetector(
                        onTap: () {
                          ref
                              .read(chatServiceProvider)
                              .updateChatTheme(
                                currentUserId,
                                widget.receiverId,
                                e.key,
                              );
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: e.value,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: 2),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authServiceProvider).currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: ref
          .watch(chatServiceProvider)
          .getRoomStatus(currentUser!.uid, widget.receiverId),
      builder: (context, roomSnapshot) {
        final roomData = roomSnapshot.data?.data() as Map<String, dynamic>?;
        final chatTheme = roomData?['theme'] ?? 'default';

        Color bgColor = Theme.of(context).scaffoldBackgroundColor;
        if (chatTheme == 'monochrome') bgColor = Colors.grey.shade900;
        if (chatTheme == 'sunset') bgColor = const Color(0xFF4A192C);
        if (chatTheme == 'ocean') bgColor = const Color(0xFF0F172A);
        if (chatTheme == 'forest') bgColor = const Color(0xFF132A13);
        if (chatTheme == 'solid_black') bgColor = Colors.black;
        if (chatTheme == 'solid_crimson') bgColor = const Color(0xFF4A0E17);
        if (chatTheme == 'solid_navy') bgColor = const Color(0xFF0A192F);
        if (chatTheme == 'solid_green') bgColor = const Color(0xFF128C7E);

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            title: Text(widget.receiverName),
            backgroundColor: bgColor,
            foregroundColor: (chatTheme != 'default') ? Colors.white : null,
            iconTheme: IconThemeData(
              color: (chatTheme != 'default')
                  ? Colors.white
                  : Theme.of(context).primaryColor,
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.call, color: Theme.of(context).primaryColor),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MockCallScreen(
                      isVideo: false,
                      name: widget.receiverName,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.videocam,
                  color: Theme.of(context).primaryColor,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MockCallScreen(
                      isVideo: true,
                      name: widget.receiverName,
                    ),
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: Theme.of(context).primaryColor,
                ),
                onSelected: (val) {
                  if (val == 'delete') {
                    _confirmDeleteChat(currentUser.uid);
                  }
                  if (val == 'theme') {
                    _showThemeSelector(currentUser.uid);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'theme',
                    child: Text(
                      'Change Wallpaper',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete Chat',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
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
                      .getMessages(widget.receiverId, currentUser.uid),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(child: Text('Error'));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final msgs = snapshot.data!.docs;

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      itemCount: msgs.length,
                      itemBuilder: (context, index) {
                        final data = msgs[index].data() as Map<String, dynamic>;
                        if (data['deletedFor'] != null &&
                            (data['deletedFor'] as List).contains(
                              currentUser.uid,
                            )) {
                          return const SizedBox.shrink();
                        }
                        bool isMe = data['senderId'] == currentUser.uid;
                        return _buildMessageBubble(
                          msgs[index],
                          isMe,
                          chatTheme,
                        );
                      },
                    );
                  },
                ),
              ),
              StreamBuilder<DocumentSnapshot>(
                stream: ref
                    .watch(chatServiceProvider)
                    .getRoomStatus(currentUser.uid, widget.receiverId),
                builder: (context, snapshot) {
                  return _buildInputArea(snapshot.data, currentUser.uid);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
