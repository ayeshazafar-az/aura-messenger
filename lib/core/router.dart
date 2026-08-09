import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_screen.dart';
import '../features/hub/hub_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/main/main_screen.dart';
import '../features/main/dummy_screens.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => MainScreen(child: child),
        routes: [
          GoRoute(path: '/hub', builder: (context, state) => const HubScreen()),
          GoRoute(
            path: '/status',
            builder: (context, state) => const StatusScreen(),
          ),
          GoRoute(
            path: '/vaults',
            builder: (context, state) => const VaultsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/chat/:uid',
        builder: (context, state) {
          final uid = state.pathParameters['uid']!;
          final name = state.uri.queryParameters['name'] ?? 'Friend';
          return ChatScreen(receiverId: uid, receiverName: name);
        },
      ),
    ],
  );
});
