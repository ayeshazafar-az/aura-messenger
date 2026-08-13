import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class CallScreen extends StatelessWidget {
  final String
  callId; // Room ID, should be unique for this conversation (e.g. sorted uid combined)
  final String localUserId;
  final String localUserName;
  final bool isVideoCall;

  const CallScreen({
    super.key,
    required this.callId,
    required this.localUserId,
    required this.localUserName,
    required this.isVideoCall,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ZegoUIKitPrebuiltCall(
          appID: 945759070,
          appSign:
              '9a708c3fbbb8ae0f5729b39965eabed3f6f52ff0f233bd5bd1f5a43699ed2fae',
          userID: localUserId,
          userName: localUserName,
          callID: callId,
          config: isVideoCall
              ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
              : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall(),
        ),
      ),
    );
  }
}
