// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import '../utils.dart';
import 'use_cases.dart';

class FilledButtonUseCase extends UseCase {
  FilledButtonUseCase();

  @override
  String get name => 'FilledButton';

  @override
  String get route => '/filled-button';

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
  String pageTitle = getUseCaseName(FilledButtonUseCase());

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
            FilledButton(onPressed: () {}, child: const Text('Filled Button')),
            const FilledButton(
              onPressed: null, // Disabled
              child: Text('Disabled FilledButton'),
            ),
          ],
        ),
      ),
    );
  }
}
