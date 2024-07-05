// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'use_cases.dart';

class HeadingsUseCase extends UseCase {

  @override
  String get name => 'Headings';

  @override
  String get route => '/headings';

  @override
  Widget build(BuildContext context) => _MainWidget();
}

class _MainWidget extends StatefulWidget {
  @override
  State<_MainWidget> createState() => _MainWidgetState();
}

class _MainWidgetState extends State<_MainWidget> {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<TextStyle> textStyles = [
      theme.textTheme.headlineLarge!,
      theme.textTheme.headlineMedium!,
      theme.textTheme.headlineSmall!,
      theme.textTheme.titleLarge!,
      theme.textTheme.titleMedium!,
      theme.textTheme.titleSmall!,
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Headings')),
      body: ListView(
        children: <Widget>[
          for (int i = 1; i <= 6; i++)
            Semantics(
              headingLevel: i,
              child: Text('Heading level $i', style: textStyles[i - 1]),
            ),
          const Text('This is not a heading'),
        ],
      ),
    );
  }
}
