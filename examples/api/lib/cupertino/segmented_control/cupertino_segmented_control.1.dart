// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';

/// Flutter code sample for [CupertinoSegmentedControl].

enum Sky { midnight, viridian, cerulean }

Map<Sky, Color> skyColors = <Sky, Color>{
  Sky.midnight: const Color(0xff191970),
  Sky.viridian: const Color(0xff40826d),
  Sky.cerulean: const Color(0xff007ba7),
};

void main() => runApp(const SegmentedControlApp());

class SegmentedControlApp extends StatelessWidget {
  const SegmentedControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      theme: CupertinoThemeData(brightness: Brightness.light),
      home: SegmentedControlExample(),
    );
  }
}

class SegmentedControlExample extends StatefulWidget {
  const SegmentedControlExample({super.key});

  @override
  State<SegmentedControlExample> createState() => _SegmentedControlExampleState();
}

class _SegmentedControlExampleState extends State<SegmentedControlExample> {
  Sky _selectedSegment = Sky.midnight;
  bool _toggleOne = false;
  bool _toggleAll = true;
  Map<int, bool> _segments = <int, bool>{
    0: true,
    1: true,
    2: true,
  };

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: skyColors[_selectedSegment],
      navigationBar: CupertinoNavigationBar(
        // This Cupertino segmented control has the enum "Sky" as the type.
        middle: CupertinoSegmentedControl<Sky>(
          segmentStates: _segments,
          selectedColor: skyColors[_selectedSegment],
          borderColor: CupertinoColors.transparent,
          pressedColor: CupertinoColors.systemFill,
          unselectedColor: CupertinoColors.systemGrey4,
          // Provide horizontal padding around the children.
          padding: const EdgeInsets.symmetric(horizontal: 12),
          // This represents a currently selected segmented control.
          groupValue: _selectedSegment,
          // Callback that sets the selected segmented control.
          onValueChanged: (Sky value) {
            setState(() {
              _selectedSegment = value;
            });
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Selected Segment: ${_selectedSegment.name}',
              style: const TextStyle(color: CupertinoColors.white),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Disable one segment', style: TextStyle(color: CupertinoColors.white)),
                CupertinoSwitch(
                  value: _toggleOne,
                  onChanged: (value) {
                    setState(() {
                      _toggleOne = value;
                      _toggleAll = false;
                      _segments = <int, bool>{
                        0: false,
                        1: true,
                        2: true,
                      };
                    });
                  },
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Toggle all segments', style: TextStyle(color: CupertinoColors.white)),
                CupertinoSwitch(
                  value: _toggleAll,
                  onChanged: (value) {
                    setState(() {
                      _toggleAll = value;
                      _toggleOne = false;
                      if (value) {
                        _segments = <int, bool>{
                          0: true,
                          1: true,
                          2: true,
                        };
                      } else {
                        _segments = <int, bool>{
                          0: false,
                          1: false,
                          2: false,
                        };
                      }
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
