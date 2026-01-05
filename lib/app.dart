import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/auth/app_state.dart';
import 'features/auth/login_page.dart';
import 'features/auth/register_page.dart';
import 'features/dashboards/role_dashboards.dart';
import 'features/dashboards/role_selector_page.dart';

class ScholesaApp extends StatelessWidget {
  const ScholesaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'Scholesa EDU',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        initialRoute: '/login',
        routes: <String, Object Function(context)>{
          '/login': (Object? context) => const LoginPage(),
          '/register': (Object? context) => const RegisterPage(),
          '/roles': (Object? context) => const RoleSelectorPage(),
          '/dashboard/learner': (Object? context) => const RoleDashboard(role: 'learner'),
          '/dashboard/educator': (Object? context) => const RoleDashboard(role: 'educator'),
          '/dashboard/parent': (Object? context) => const RoleDashboard(role: 'parent'),
          '/dashboard/site': (Object? context) => const RoleDashboard(role: 'site'),
          '/dashboard/partner': (Object? context) => const RoleDashboard(role: 'partner'),
          '/dashboard/hq': (Object? context) => const RoleDashboard(role: 'hq'),
        },
      ),
    );
  }
}