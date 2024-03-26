// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [NavigationBar] with custom destinations that use [NavigationDestinationInfo] for customizing their contents.
void main() {
  runApp(const MaterialApp(
    home: Scaffold(bottomNavigationBar: _StatefulNavigationBar()),
  ));
}

class _StatefulNavigationBar extends StatefulWidget {
  const _StatefulNavigationBar({super.key});

  @override
  State<_StatefulNavigationBar> createState() => _StatefulNavigationBarState();
}

class _StatefulNavigationBarState extends State<_StatefulNavigationBar> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      animationDuration: const Duration(milliseconds: 1000),
      selectedIndex: selectedIndex,
      destinations: const <Widget>[
        _CustomDestination(Icons.alarm),
        _CustomDestination(Icons.ac_unit),
        _CustomDestination(Icons.adb),
        _CustomDestination(Icons.back_hand),
        _CustomDestination(Icons.wallet),
      ],
      onDestinationSelected: (int i) {
        setState(() {
          selectedIndex = i;
        });
      },
    );
  }
}

class _CustomDestination extends StatelessWidget {
  const _CustomDestination(this.icon, {super.key});

  final IconData icon;

  Widget build(BuildContext context) {
    final NavigationDestinationInfo info =
        NavigationDestinationInfo.of(context);
    return InkWell(
      onTap: info.onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        verticalDirection:
            info.index.isEven ? VerticalDirection.down : VerticalDirection.up,
        children: [
          Icon(icon),
          FadeTransition(
            opacity: info.selectedAnimation,
            child: Text(
               'label ${info.index + 1}/${info.totalNumberOfDestinations}',
             ),
           ),
        ],
      ),
    );
  }
}
