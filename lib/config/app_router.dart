import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/feed_screen.dart';

class AuthNotifier extends ChangeNotifier {
  AuthNotifier() {
    _subscription = FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<User?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

GoRouter createAppRouter() {
  final authNotifier = AuthNotifier();

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final loggedIn = user != null;
      final location = state.matchedLocation;

      final isLogin = location == '/login';
      final isRegister = location == '/registro';

      if (!loggedIn && !isLogin && !isRegister) {
        return '/login';
      }

      if (loggedIn && location != '/feed') {
        return '/feed';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/registro',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(path: '/feed', builder: (context, state) => const FeedScreen()),
    ],
  );
}
