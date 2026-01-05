import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/auth/app_state.dart';
import 'features/auth/login_page.dart';
import 'features/auth/register_page.dart';
import 'features/landing/landing_page.dart';
import 'features/dashboards/role_dashboards.dart';
import 'features/dashboards/role_selector_page.dart';
import 'theme.dart';

class ScholesaApp extends StatelessWidget {
  const ScholesaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          context.read<AppState>().setUser(snapshot.data);
          return MaterialApp(
            title: 'Scholesa EDU',
            theme: AppTheme.light(),
            initialRoute: '/',
            routes: <String, WidgetBuilder>{
              '/': (context) => const LandingPage(),
              '/login': (context) => const LoginPage(),
              '/register': (context) => const RegisterPage(),
              '/roles': (context) => const RoleSelectorPage(),
              '/dashboard/learner': (context) => const RoleDashboard(role: 'learner'),
              '/dashboard/educator': (context) => const RoleDashboard(role: 'educator'),
              '/dashboard/parent': (context) => const RoleDashboard(role: 'parent'),
              '/dashboard/site': (context) => const RoleDashboard(role: 'site'),
              '/dashboard/partner': (context) => const RoleDashboard(role: 'partner'),
              '/dashboard/hq': (context) => const RoleDashboard(role: 'hq'),
            },
          );
        },
      ),
    );
  }
}