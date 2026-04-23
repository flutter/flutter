// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import '../utils.dart';
import 'use_cases.dart';

class AboutListTileUseCase extends UseCase {
  AboutListTileUseCase();

  @override
  String get name => 'AboutListTile';

  @override
  String get route => '/about-list-tile';

  @override
  List<Tag> get tags => <Tag>[Tag.batch2, Tag.core];

  @override
  Widget build(BuildContext context) => const MainWidget();
}

class MainWidget extends StatelessWidget {
  const MainWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final String pageTitle = getUseCaseName(AboutListTileUseCase());
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Semantics(headingLevel: 1, child: Text('$pageTitle Demo')),
      ),
      body: ListView(
        children: const <Widget>[
          AboutListTile(
            icon: Icon(Icons.info),
            applicationName: 'A11y Assessment',
            applicationVersion: '1.0.0',
            applicationIcon: FlutterLogo(),
            applicationLegalese: '© 2026 The Flutter Authors',
            aboutBoxChildren: <Widget>[Text('This is a test app for accessibility.')],
          ),
        ],
      ),
    );
  }
}
