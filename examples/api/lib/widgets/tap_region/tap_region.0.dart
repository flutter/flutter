// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// Flutter code sample for [TapRegion].

void main() => runApp(const TapRegionExampleApp());

class TapRegionExampleApp extends StatelessWidget {
  const TapRegionExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      color: const Color(0xFFFFFFFF),
      builder: (BuildContext context, Widget? child) {
        return const TapRegionExample();
      },
    );
  }
}

class TapRegionExample extends StatefulWidget {
  const TapRegionExample({super.key});

  @override
  State<TapRegionExample> createState() => _TapRegionExampleState();
}

class _TapRegionExampleState extends State<TapRegionExample> {
  String _status = 'Tap inside or outside the outlined area.';

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFFFFFFF),
      child: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: <Widget>[
            TapRegion(
              onTapInside: (PointerDownEvent event) {
                setState(() {
                  _status = 'Tapped inside!';
                });
              },
              onTapOutside: (PointerDownEvent event) {
                setState(() {
                  _status = 'Tapped outside!';
                });
              },
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  border: .all(width: 2, color: const Color(0xFF2196F3)),
                ),
                child: const Center(child: Text('Tap Region')),
              ),
            ),
            const SizedBox(height: 24),
            Text(_status),
          ],
        ),
      ),
    );
  }
}
