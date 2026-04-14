// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import '../utils.dart';
import 'use_cases.dart';

class SwitchListTileUseCase extends UseCase {
  SwitchListTileUseCase() : super(useCaseCategory: UseCaseCategory.core);

  @override
  String get name => 'SwitchListTile';

  @override
  String get route => '/switch-list-tile';

  @override
  Widget build(BuildContext context) => const SwitchListTileExample();
}

class SwitchListTileExample extends StatefulWidget {
  const SwitchListTileExample({super.key});

  @override
  State<SwitchListTileExample> createState() => _SwitchListTileExampleState();
}

class _SwitchListTileExampleState extends State<SwitchListTileExample> {
  bool _lights1 = false;
  bool _lights2 = false;

  String pageTitle = getUseCaseName(SwitchListTileUseCase());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Semantics(headingLevel: 1, child: Text('$pageTitle Demo')),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            SwitchListTile(
              title: const Text('Lights'),
              value: _lights1,
              onChanged: (bool value) {
                setState(() {
                  _lights1 = value;
                });
              },
              secondary: const Icon(Icons.lightbulb_outline),
            ),
            SwitchListTile(
              title: const Text('Lights'),
              subtitle: const Text('Subtitle'),
              value: _lights2,
              onChanged: (bool value) {
                setState(() {
                  _lights2 = value;
                });
              },
              secondary: const Icon(Icons.lightbulb_outline),
            ),
          ],
        ),
      ),
    );
  }
}
