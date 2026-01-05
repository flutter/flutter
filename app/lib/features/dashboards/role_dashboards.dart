import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/app_state.dart';
import '../auth/auth_service.dart';

class RoleDashboard extends StatelessWidget {
  const RoleDashboard({super.key, required this.role});

  final String role;

  String get title {
    switch (role) {
      case 'learner':
        return 'Learner Dashboard';
      case 'educator':
        return 'Educator Dashboard';
      case 'parent':
        return 'Parent Dashboard';
      case 'site':
        return 'Site Lead Dashboard';
      case 'partner':
        return 'Partner Dashboard';
      case 'hq':
        return 'HQ Dashboard';
      default:
        return 'Dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currentRole = appState.role ?? role;
    if (FirebaseAuth.instance.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              AuthService().signOut();
              appState.clearRole();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          )
        ],
      ),
      body: Center(
        child: Text('Placeholder for $title (role: $currentRole)'),
      ),
    );
  }
}
