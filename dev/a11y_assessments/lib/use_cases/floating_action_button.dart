// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import '../utils.dart';
import 'use_cases.dart';

class FloatingActionButtonUseCase extends UseCase {
  FloatingActionButtonUseCase();

  @override
  String get name => 'FloatingActionButton';

  @override
  String get route => '/floating-action-button';

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
  String pageTitle = getUseCaseName(FloatingActionButtonUseCase());
  int _tapCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Semantics(headingLevel: 1, child: Text('$pageTitle Demo')),
      ),
      body: Center(child: Text('Tap count: $_tapCount')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _tapCount++;
          });
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
