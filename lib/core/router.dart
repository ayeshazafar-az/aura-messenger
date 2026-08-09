import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_screen.dart';
import '../features/hub/hub_screen.dart';
import '../features/chat/chat_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/hub', builder: (context, state) => const HubScreen()),
      GoRoute(
        path: '/chat/:name',
        builder: (context, state) =>
            ChatScreen(friendName: state.pathParameters['name'] ?? 'Friend'),
      ),
    ],
  );
});
