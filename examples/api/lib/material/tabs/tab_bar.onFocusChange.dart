// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [TabBar.onFocusChange].

void main() => runApp(const TabBarApp());

class TabBarApp extends StatelessWidget {
  const TabBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(theme: ThemeData(useMaterial3: true), home: const TabBarExample());
  }
}

class TabBarExample extends StatefulWidget {
  const TabBarExample({super.key});

  @override
  State<TabBarExample> createState() => _TabBarExampleState();
}

class _TabBarExampleState extends State<TabBarExample> {
  int? focusedIndex;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 1,
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('TabBar Sample'),
          bottom: TabBar(
            onFocusChange: (bool value, int index) {
              setState(() {
                focusedIndex = switch (value) {
                  true => index,
                  false => null,
                };
              });
            },
            tabs: <Widget>[
              Tab(icon: Icon(Icons.cloud_outlined, size: focusedIndex == 0 ? 35 : 25)),
              Tab(icon: Icon(Icons.beach_access_sharp, size: focusedIndex == 1 ? 35 : 25)),
              Tab(icon: Icon(Icons.brightness_5_sharp, size: focusedIndex == 2 ? 35 : 25)),
            ],
          ),
        ),
        body: const TabBarView(
          children: <Widget>[
            Center(child: Text("It's cloudy here")),
            Center(child: Text("It's rainy here")),
            Center(child: Text("It's sunny here")),
          ],
        ),
      ),
    );
  }
}
