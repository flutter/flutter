import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../router.gr.dart';

class AppLayout extends StatelessWidget {
  final Widget child;

  const AppLayout({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fortune Wheel Demo'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex:
            context.router.current.name == FortuneWheelRoute.name ? 0 : 1,
        onTap: (index) {
          switch (index) {
            case 0:
              context.router.replace(FortuneWheelRoute());
              break;

            case 1:
              context.router.replace(FortuneBarRoute());
              break;
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.circle),
            label: 'Wheel',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.linear_scale),
            label: 'Bar',
          ),
        ],
      ),
      body: child,
    );
  }
}
