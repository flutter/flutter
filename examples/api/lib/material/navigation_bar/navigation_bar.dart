// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for NavigationBar

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Material(child: Center(child: NavigationExample())),
    );
  }
}

class NavigationExample extends StatefulWidget {
  const NavigationExample({Key? key}) : super(key: key);

  @override
  State<NavigationExample> createState() => _NavigationExampleState();
}

class _NavigationExampleState extends State<NavigationExample> {
  int _currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> buildBody = <Widget>[
      Container(
          color: Colors.red,
          alignment: Alignment.center,
          child: const Text('Page 1')),
      Container(
          color: Colors.green,
          alignment: Alignment.center,
          child: const Text('Page 2')),
      Container(
          color: Colors.blue,
          alignment: Alignment.center,
          child: const Text('Page 3')),
    ];

    return Scaffold(
        bottomNavigationBar: NavigationBar(
            onDestinationSelected: (int index) {
              setState(() {
                _currentPageIndex = index;
              });
            },
            selectedIndex: _currentPageIndex,
            destinations: const <Widget>[
              NavigationDestination(
                icon: Icon(Icons.explore),
                label: 'Explore',
              ),
              NavigationDestination(
                icon: Icon(Icons.commute),
                label: 'Commute',
              ),
              NavigationDestination(
                selectedIcon: Icon(Icons.bookmark),
                icon: Icon(Icons.bookmark_border),
                label: 'Saved',
              ),
            ]),
        body: buildBody.elementAt(_currentPageIndex));
  }
}
