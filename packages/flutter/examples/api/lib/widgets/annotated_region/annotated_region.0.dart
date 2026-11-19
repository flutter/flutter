// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Flutter code sample for [AnnotatedRegion].

void main() => runApp(const AnnotatedRegionExampleApp());

class AnnotatedRegionExampleApp extends StatelessWidget {
  const AnnotatedRegionExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      color: const Color(0xFFFFFFFF),
      // WidgetsApp does not install a [DefaultTextStyle], so without this
      // the labels below would be invisible against the white background.
      textStyle: const TextStyle(color: Color(0xFF000000), fontSize: 14.0),
      builder: (BuildContext context, Widget? child) {
        return const AnnotatedRegionExample();
      },
    );
  }
}

class AnnotatedRegionExample extends StatefulWidget {
  const AnnotatedRegionExample({super.key});

  @override
  State<AnnotatedRegionExample> createState() => _AnnotatedRegionExampleState();
}

class _AnnotatedRegionExampleState extends State<AnnotatedRegionExample> {
  int? _lastRegionValue;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text('Tap a region:'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _pane(value: 1, color: const Color(0xFFB3E5FC), label: 'Left'),
              _pane(value: 2, color: const Color(0xFFFFCCBC), label: 'Right'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _lastRegionValue == null
                ? 'No annotation found yet.'
                : 'Last tapped region value: $_lastRegionValue',
          ),
        ],
      ),
    );
  }

  Widget _pane({required int value, required Color color, required String label}) {
    return GestureDetector(
      onTapUp: (TapUpDetails details) {
        final RenderObject? renderObject = context.findRenderObject();
        if (renderObject is! RenderBox) {
          return;
        }
        // Find the annotation for this region by walking the hit-test
        // result for the [RenderAnnotatedRegion] under the tap position.
        final BoxHitTestResult result = BoxHitTestResult();
        renderObject.hitTest(result, position: renderObject.globalToLocal(details.globalPosition));
        for (final HitTestEntry entry in result.path) {
          if (entry.target is RenderAnnotatedRegion<int>) {
            final RenderAnnotatedRegion<int> region =
                entry.target as RenderAnnotatedRegion<int>;
            setState(() {
              _lastRegionValue = region.value;
            });
            return;
          }
        }
        setState(() {
          _lastRegionValue = null;
        });
      },
      child: AnnotatedRegion<int>(
        value: value,
        sized: true,
        child: Container(
          width: 100,
          height: 60,
          color: color,
          alignment: Alignment.center,
          child: Text(label),
        ),
      ),
    );
  }
}
