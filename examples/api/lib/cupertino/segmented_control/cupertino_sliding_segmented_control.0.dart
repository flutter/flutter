// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for CupertinoSlidingSegmentedControl

import 'package:flutter/cupertino.dart';

enum Sky { midnight, viridian, cerulean }

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const String _title = 'CupertinoSlidingSegmentedControl Sample';

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: _title,
      home: SegmentedControlSample(),
    );
  }
}

class SegmentedControlSample extends StatefulWidget {
  const SegmentedControlSample({Key? key}) : super(key: key);

  @override
  State<SegmentedControlSample> createState() => _SegmentedControlSampleState();
}

class _SegmentedControlSampleState extends State<SegmentedControlSample> {
  Sky _selectedSegment = Sky.midnight;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        // This Cupertino segmented control has enum as the type.
        middle: CupertinoSlidingSegmentedControl<Sky>(
          thumbColor: CupertinoColors.activeBlue,
          // This represent a currently selected segmented control.
          groupValue: _selectedSegment,
          // Callback that sets the selected segmented control.
          onValueChanged: (Sky? value) {
            if (value != null) {
              setState(() {
                _selectedSegment = value;
              });
            }
          },
          children: const <Sky, Widget>{
            Sky.midnight: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('Midnight'),
            ),
            Sky.viridian: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('Viridian'),
            ),
            Sky.cerulean: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('Cerulean'),
            ),
          },
        ),
      ),
      child: Center(
        child: Text('Selected Segment: ${_selectedSegment.name}'),
      ),
    );
  }
}
