// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import '../utils.dart';
import 'use_cases.dart';

class MenuAnchorUseCase extends UseCase {
  MenuAnchorUseCase();

  @override
  String get name => 'MenuAnchor';

  @override
  String get route => '/menu-anchor';

  @override
  List<Tag> get tags => <Tag>[Tag.batch3, Tag.core];

  @override
  Widget build(BuildContext context) => const _MainWidget();
}

class _MainWidget extends StatelessWidget {
  const _MainWidget();

  @override
  Widget build(BuildContext context) {
    final String pageTitle = getUseCaseName(MenuAnchorUseCase());
    return Scaffold(
      appBar: AppBar(title: Semantics(headingLevel: 1, child: Text('$pageTitle Demo'))),
      body: ListView(
        children: <Widget>[
          Semantics(
            label: 'Enabled menu anchor',
            child: MenuAnchor(
              key: const Key('enabled menu anchor'),
              builder: (BuildContext context, MenuController controller, Widget? child) {
                return ElevatedButton(
                  onPressed: () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  },
                  child: const Text('Open Menu'),
                );
              },
              menuChildren: <Widget>[
                MenuItemButton(onPressed: () {}, child: const Text('Item 1')),
                const MenuItemButton(child: Text('Disabled Item')),
              ],
            ),
          ),
          Semantics(
            label: 'Disabled menu anchor',
            child: MenuAnchor(
              key: const Key('disabled menu anchor'),
              builder: (BuildContext context, MenuController controller, Widget? child) {
                return const ElevatedButton(onPressed: null, child: Text('Disabled Menu Button'));
              },
              menuChildren: const <Widget>[MenuItemButton(child: Text('Disabled Item'))],
            ),
          ),
        ],
      ),
    );
  }
}
