// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import '../utils.dart';
import 'use_cases.dart';

class BadgeUseCase extends UseCase {
  BadgeUseCase();

  @override
  String get name => 'Badge';

  @override
  String get route => '/badge';

  @override
  List<Tag> get tags => <Tag>[Tag.batch1, Tag.core];

  @override
  Widget build(BuildContext context) => const MainWidget();
}

class MainWidget extends StatefulWidget {
  const MainWidget({super.key});

  @override
  State<MainWidget> createState() => MainWidgetState();
}

class MainWidgetState extends State<MainWidget> {
  String pageTitle = getUseCaseName(BadgeUseCase());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Semantics(headingLevel: 1, child: Text('$pageTitle Demo'))),
      body: const Center(
        child: Badge(
          // Use the badge colors from the theme. The hard coded white on green
          // combination only reaches a 2.6:1 contrast ratio, below the 4.5:1
          // required by WCAG AA for normal sized text.
          label: Text('5', semanticsLabel: '5 new messages'),
          child: Icon(Icons.mail, semanticLabel: 'Messages'),
        ),
      ),
    );
  }
}
