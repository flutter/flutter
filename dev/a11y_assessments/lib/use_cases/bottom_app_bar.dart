// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../utils.dart';
import 'use_cases.dart';

class BottomAppBarUseCase extends UseCase {
  BottomAppBarUseCase();

  @override
  String get name => 'BottomAppBar';

  @override
  String get route => '/bottom-app-bar';

  @override
  List<Tag> get tags => <Tag>[Tag.batch3, Tag.core];

  @override
  Widget build(BuildContext context) => const MainWidget();
}

class MainWidget extends StatefulWidget {
  const MainWidget({super.key});

  @override
  State<MainWidget> createState() => MainWidgetState();
}

class MainWidgetState extends State<MainWidget> {
  final String pageTitle = getUseCaseName(BottomAppBarUseCase());
  String _selectedAction = 'None';

  void _onItemTapped(String action) {
    setState(() {
      _selectedAction = action;
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tapped: $action')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Semantics(headingLevel: 1, child: Text('$pageTitle Demo'))),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: <Widget>[
            IconButton(
              tooltip: 'Open menu',
              icon: const Icon(Icons.menu),
              onPressed: () => _onItemTapped('Menu'),
            ),
            IconButton(
              tooltip: 'Search',
              icon: const Icon(Icons.search),
              onPressed: () => _onItemTapped('Search'),
            ),
            IconButton(
              tooltip: 'Favorite',
              icon: const Icon(Icons.favorite),
              onPressed: () => _onItemTapped('Favorite'),
            ),
          ],
        ),
      ),
      body: Center(child: Text('Selected: $_selectedAction')),
    );
  }
}
