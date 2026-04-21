// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import '../utils.dart';
import 'use_cases.dart';

class PopupMenuButtonUseCase extends UseCase {
  PopupMenuButtonUseCase();

  @override
  String get name => 'PopupMenuButton';

  @override
  String get route => '/popup-menu-button';

  @override
  List<Tag> get tags => <Tag>[Tag.batch2, Tag.core];

  @override
  Widget build(BuildContext context) => const MainWidget();
}

class MainWidget extends StatefulWidget {
  const MainWidget({super.key});

  @override
  State<MainWidget> createState() => MainWidgetState();
}

class MainWidgetState extends State<MainWidget> {
  String pageTitle = getUseCaseName(PopupMenuButtonUseCase());
  String _selectedItem = 'None';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Semantics(headingLevel: 1, child: Text('$pageTitle Demo')),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Selected: $_selectedItem'),
            PopupMenuButton<String>(
              tooltip: 'Show menu',
              onSelected: (String item) {
                setState(() {
                  _selectedItem = item;
                });
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(value: 'Item 1', child: Text('Item 1')),
                const PopupMenuItem<String>(value: 'Item 2', child: Text('Item 2')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
