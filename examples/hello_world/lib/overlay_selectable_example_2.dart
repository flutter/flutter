import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      // Default to the nested location
      // Or for a more realistic use-case, navigate to the url /a/b on the web
      initialLocation: '/root/sub',
      routes: [
        GoRoute(
          path: '/root',
          builder: (_, __) {
            // With selection area here, error will occur
            return const SelectionArea(
              child: Column(
                children: [
                  // Must be at least two selectable texts
                  Text('rootA'),
                  Text('rootB'),
                ],
              ),
            );
          },
          routes: [
            GoRoute(
              path: 'sub',
              builder: (_, __) {
                return const SelectionArea(
                  child: Column(
                    children: [
                      // Must be at least two selectable texts
                      Text('subA'),
                      Text('subB'),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }
}
