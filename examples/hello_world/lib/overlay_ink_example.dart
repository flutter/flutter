import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void main() {
  // debugRepaintRainbowEnabled = true;
  // debugPrintMarkNeedsLayoutStacks = true;
  // debugPrintMarkNeedsPaintStacks = true;
  // debugPrintLayouts = true;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      // Default to the nested location
      // Or for a more realistic use-case, navigate to the url /root/sub on the web
      initialLocation: '/root/sub',
      routes: [
        ShellRoute(
          builder: (context, state, navigationShell) {
            return Material(child: navigationShell);
          },
          routes: [
            GoRoute(
              path: '/root',
              builder: (context, __) {
                return Ink(
                  child: InkWell(
                    onTap: () => context.push('/root/sub'),
                    child: Container(width: 111, height: 112, color: Colors.red),
                  ),
                );
              },
              routes: [
                // Must be nested, so layouts are stacked on top
                GoRoute(
                  path: 'sub',
                  builder: (context, __) {
                    return Container(width: 222, height: 223, color: Colors.blue);
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }
}
