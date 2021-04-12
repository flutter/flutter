// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /*
   * Here lies tests for packages/flutter_test/lib/src/animation_sheet.dart
   * because [matchesGoldenFile] does not use Skia Gold in its native package.
   */

  testWidgets('correctly records frames', (WidgetTester tester) async {
    final AnimationSheetBuilder builder = AnimationSheetBuilder(frameSize: _DecuplePixels.size);

    await tester.pumpFrames(
      builder.record(
        const _DecuplePixels(Duration(seconds: 1)),
      ),
      const Duration(milliseconds: 200),
      const Duration(milliseconds: 100),
    );

    await tester.pumpFrames(
      builder.record(
        const _DecuplePixels(Duration(seconds: 1)),
        recording: false,
      ),
      const Duration(milliseconds: 200),
      const Duration(milliseconds: 100),
    );

    await tester.pumpFrames(
      builder.record(
        const _DecuplePixels(Duration(seconds: 1)),
        recording: true,
      ),
      const Duration(milliseconds: 400),
      const Duration(milliseconds: 100),
    );

    final Widget display = await builder.display();
    await tester.binding.setSurfaceSize(builder.sheetSize());
    await tester.pumpWidget(display);

    await expectLater(find.byWidget(display), matchesGoldenFile('test.animation_sheet_builder.records.png'));
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/42767

  testWidgets('correctly wraps a row', (WidgetTester tester) async {
    final AnimationSheetBuilder builder = AnimationSheetBuilder(frameSize: _DecuplePixels.size);

    const Duration duration = Duration(seconds: 2);
    await tester.pumpFrames(
      builder.record(const _DecuplePixels(duration)),
      duration,
      const Duration(milliseconds: 200),
    );

    final Widget display = await builder.display();
    await tester.binding.setSurfaceSize(builder.sheetSize(maxWidth: 80));
    await tester.pumpWidget(display);

    await expectLater(find.byWidget(display), matchesGoldenFile('test.animation_sheet_builder.wraps.png'));
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/42767
}

// An animation of a yellow pixel moving from left to right, in a container of
// (10, 1) with a 1-pixel-wide black border.
class _DecuplePixels extends StatefulWidget {
  const _DecuplePixels(this.duration);

  static const Size size = Size(12, 3);

  final Duration duration;

  @override
  State<StatefulWidget> createState() => _DecuplePixelsState();
}

class _DecuplePixelsState extends State<_DecuplePixels> with SingleTickerProviderStateMixin<_DecuplePixels> {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller.view,
      builder: (BuildContext context, Widget? child) {
        return CustomPaint(
          painter: _PaintDecuplePixels(_controller.value),
        );
      },
    );
  }
}

class _PaintDecuplePixels extends CustomPainter {
  _PaintDecuplePixels(this.value);

  final double value;

  @override
  bool shouldRepaint(_PaintDecuplePixels oldDelegate) {
    return oldDelegate.value != value;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    final Rect rect = RectTween(
      begin: const Rect.fromLTWH(1, 1, 1, 1),
      end: const Rect.fromLTWH(11, 1, 1, 1),
    ).transform(value)!;
    canvas.drawRect(rect, Paint()..color = Colors.yellow);
    final Paint black = Paint()..color = Colors.black;
    canvas
      // Top border
      ..drawRect(const Rect.fromLTRB(0, 0, 12, 1), black)
      // Bottom border
      ..drawRect(const Rect.fromLTRB(0, 2, 12, 3), black)
      // Left border
      ..drawRect(const Rect.fromLTRB(0, 0, 1, 3), black)
      // Right border
      ..drawRect(const Rect.fromLTRB(11, 0, 12, 3), black);

    canvas.restore();
  }
}
