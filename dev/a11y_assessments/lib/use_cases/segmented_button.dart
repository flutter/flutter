// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import '../utils.dart';
import 'use_cases.dart';

class SegmentedButtonUseCase extends UseCase {
  SegmentedButtonUseCase();

  @override
  String get name => 'SegmentedButton';

  @override
  String get route => '/segmented-button';

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
  String pageTitle = getUseCaseName(SegmentedButtonUseCase());
  Set<String> _selected = <String>{'Day'};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Semantics(headingLevel: 1, child: Text('$pageTitle Demo')),
      ),
      body: Center(
        child: SegmentedButton<String>(
          segments: const <ButtonSegment<String>>[
            ButtonSegment<String>(
              value: 'Day',
              label: Text('Day'),
              icon: Icon(Icons.calendar_view_day),
            ),
            ButtonSegment<String>(
              value: 'Week',
              label: Text('Week'),
              icon: Icon(Icons.calendar_view_week),
            ),
            ButtonSegment<String>(
              value: 'Month',
              label: Text('Month'),
              icon: Icon(Icons.calendar_view_month),
            ),
          ],
          selected: _selected,
          onSelectionChanged: (Set<String> newSelection) {
            setState(() {
              _selected = newSelection;
            });
          },
        ),
      ),
    );
  }
}
