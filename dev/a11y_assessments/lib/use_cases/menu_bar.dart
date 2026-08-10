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
  List<Tag> get tags => <Tag>[Tag.core];

  @override
  Widget build(BuildContext context) => const _MainWidget();
}

class _MainWidget extends StatefulWidget {
  const _MainWidget();

  @override
  State<_MainWidget> createState() => _MainWidgetState();
}

class _MainWidgetState extends State<_MainWidget> {
  String _lastSelection = 'None';

  @override
  Widget build(BuildContext context) {
    final String pageTitle = getUseCaseName(MenuBarUseCase());
    return Scaffold(
      appBar: AppBar(title: Semantics(headingLevel: 1, child: Text('$pageTitle Demo'))),
      body: ListView(
        children: <Widget>[
          Semantics(liveRegion: true, child: Text('Last Selection: $_lastSelection')),
          Semantics(
            label: 'Enabled menu bar',
            child: MenuBar(
              key: const Key('enabled menu bar'),
              children: <Widget>[
                SubmenuButton(
                  menuChildren: <Widget>[
                    MenuItemButton(
                      onPressed: () {
                        setState(() {
                          _lastSelection = 'Save';
                        });
                      },
                      child: const Text('Save'),
                    ),
                    const MenuItemButton(child: Text('Disabled Item')),
                  ],
                  child: const Text('File'),
                ),
                SubmenuButton(
                  menuChildren: <Widget>[
                    MenuItemButton(
                      onPressed: () {
                        setState(() {
                          _lastSelection = 'About';
                        });
                      },
                      child: const Text('About'),
                    ),
                    SubmenuButton(
                      menuChildren: <Widget>[
                        MenuItemButton(
                          onPressed: () {
                            setState(() {
                              _lastSelection = 'Documentation';
                            });
                          },
                          child: const Text('Documentation'),
                        ),
                        MenuItemButton(
                          onPressed: () {
                            setState(() {
                              _lastSelection = 'Send Feedback';
                            });
                          },
                          child: const Text('Send Feedback'),
                        ),
                      ],
                      child: const Text('Online Help'),
                    ),
                  ],
                  child: const Text('Help'),
                ),
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
