import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HubScreen extends StatelessWidget {
  const HubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aura Hub'),
        actions: [IconButton(icon: const Icon(Icons.person), onPressed: () {})],
      ),
      body: ListView.builder(
        itemCount: 3,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF3B82F6),
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text('Friend ${index + 1}'),
            subtitle: const Text('Tap to open chat...'),
            trailing: const Icon(
              Icons.lock_clock,
              color: Colors.grey,
              size: 20,
            ),
            onTap: () => context.push('/chat/Friend_${index + 1}'),
          );
        },
      ),
    );
  }
}
