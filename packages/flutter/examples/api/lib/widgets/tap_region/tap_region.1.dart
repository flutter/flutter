// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// Flutter code sample for [TapRegion] demonstrating [TapRegion.groupId].

void main() => runApp(const TapRegionGroupExampleApp());

class TapRegionGroupExampleApp extends StatelessWidget {
  const TapRegionGroupExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      color: const Color(0xFFFFFFFF),
      builder: (BuildContext context, Widget? child) {
        return TapRegionGroupExample();
      },
    );
  }
}

class TapRegionGroupExample extends StatefulWidget {
  const TapRegionGroupExample({super.key});

  @override
  State<TapRegionGroupExample> createState() => _TapRegionGroupExampleState();
}

class _TapRegionGroupExampleState extends State<TapRegionGroupExample> {
  String _box1Status = '-';
  String _box2Status = '-';

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFFFFFFF),
      child: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: <Widget>[
            Row(
              mainAxisAlignment: .center,
              children: <Widget>[
                TapRegion(
                  groupId: 'panel-group',
                  onTapInside: (PointerDownEvent event) {
                    setState(() => _box1Status = 'inside');
                  },
                  onTapOutside: (PointerDownEvent event) {
                    setState(() => _box1Status = 'outside');
                  },
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      border: .all(width: 2, color: const Color(0xFF2196F3)),
                    ),
                    child: const Center(child: Text('Box 1')),
                  ),
                ),
                const SizedBox(width: 32),
                TapRegion(
                  groupId: 'panel-group',
                  onTapInside: (PointerDownEvent event) {
                    setState(() => _box2Status = 'inside');
                  },
                  onTapOutside: (PointerDownEvent event) {
                    setState(() => _box2Status = 'outside');
                  },
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      border: .all(width: 2, color: const Color(0xFF4CAF50)),
                    ),
                    child: const Center(child: Text('Box 2')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Box 1: $_box1Status'),
            Text('Box 2: $_box2Status'),
          ],
        ),
      ),
    );
  }
}
