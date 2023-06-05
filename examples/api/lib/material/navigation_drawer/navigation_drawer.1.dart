// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Builds an adaptive navigation widget layout. When the screen width is less than
// 450, A [NavigationBar] will be displayed. Otherwise, a [NavigationRail] will be
// displayed on the left side, and also a button to open the [NavigationDrawer].
// All of these navigation widgets are built from an identical list of data.

import 'package:flutter/material.dart';

/// Flutter code sample for [NavigationDrawer].

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
      ),
      home:  const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drawer Demo'),
      ),
      drawer: NavigationDrawer(
        children: <Widget>[
          Padding(
                padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
                child: Text(
                  'Drawer Header',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.message),
            label: Text('Messages'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.account_circle),
            label: Text('Profile'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.settings),
            label: Text('Settings'),
          ),
        ])
    );
  }
}
