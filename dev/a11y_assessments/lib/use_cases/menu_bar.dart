// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import '../utils.dart';
import 'use_cases.dart';

class MenuBarUseCase extends UseCase {
  MenuBarUseCase();

  @override
  String get name => 'MenuBar';

  @override
  String get route => '/menu-bar';

  @override
  List<Tag> get tags => <Tag>[Tag.batch3, Tag.core];

  @override
  Widget build(BuildContext context) => const _MainWidget();
}

class _MainWidget extends StatelessWidget {
  const _MainWidget();

  @override
  Widget build(BuildContext context) {
    final String pageTitle = getUseCaseName(MenuBarUseCase());
    return Scaffold(
      appBar: AppBar(title: Semantics(headingLevel: 1, child: Text('$pageTitle Demo'))),
      body: ListView(
        children: <Widget>[
          Semantics(
            label: 'Enabled menu bar',
            child: MenuBar(
              key: const Key('enabled menu bar'),
              children: <Widget>[
                SubmenuButton(
                  menuChildren: <Widget>[
                    MenuItemButton(onPressed: () {}, child: const Text('Save')),
                    const MenuItemButton(child: Text('Disabled Item')),
                  ],
                  child: const Text('File'),
                ),
                MenuItemButton(onPressed: () {}, child: const Text('Help')),
              ],
            ),
          ),
          Semantics(
            label: 'Disabled menu bar',
            child: const MenuBar(
              key: Key('disabled menu bar'),
              children: <Widget>[
                SubmenuButton(menuChildren: <Widget>[], child: Text('Disabled File')),
                MenuItemButton(child: Text('Disabled Help')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
