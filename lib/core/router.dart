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
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SearchScreen()),
          ),
          GoRoute(
            path: '/hub',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HubScreen()),
          ),
          GoRoute(
            path: '/vaults',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: VaultsScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileScreen()),
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
