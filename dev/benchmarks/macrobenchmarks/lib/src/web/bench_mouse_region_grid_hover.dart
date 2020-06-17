// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/scheduler.dart';

import 'recorder.dart';
import 'test_data.dart';

/// Creates a grid of mouse regions, then continuously hover over them.
///
/// Measures our ability to hit test mouse regions.
class BenchMouseRegionGridHover extends WidgetRecorder {
  BenchMouseRegionGridHover() : super(name: benchmarkName);

  static const String benchmarkName = 'bench_mouse_region_grid_hover';

  final _Tester tester = _Tester();

  // Use a non-trivial border to force Web to switch painter
  Border _getBorder(int columnIndex, int rowIndex) {
    const BorderSide defaultBorderSide = BorderSide();

    return Border(
      left: columnIndex == 0 ? defaultBorderSide : BorderSide.none,
      top: rowIndex == 0 ? defaultBorderSide : BorderSide.none,
      right: defaultBorderSide,
      bottom: defaultBorderSide,
    );
  }

  bool started = false;

  @override
  void frameDidDraw() {
    if (!started) {
      started = true;
      SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) async {
        tester.startTesting();
      });
    }
    super.frameDidDraw();
  }

  @override
  Widget createWidget() {
    const int rowsCount = 60;
    const int columnsCount = 20;
    const double containerSize = 20;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          key: const ValueKey<String>('scrollable'),
          width: 400,
          height: 400,
          child: ListView.builder(
            itemCount: rowsCount,
            cacheExtent: rowsCount * containerSize,
            physics: const ClampingScrollPhysics(),
            itemBuilder: (BuildContext context, int rowIndex) => Row(
              children: List<Widget>.generate(
                columnsCount,
                (int columnIndex) => MouseRegion(
                  onEnter: (_) => {},
                  child: Container(
                    decoration: BoxDecoration(
                      border: _getBorder(columnIndex, rowIndex),
                      color: Color.fromARGB(255, rowIndex * 20 % 256, 127, 127),
                    ),
                    width: containerSize,
                    height: containerSize,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tester {
  static const scrollFrequency = 60;
  static const dragStartLocation = const Offset(200, 200);
  static const dragUpOffset = const Offset(0, 200);
  static const dragDownOffset = const Offset(0, -200);

  Duration currentTime = Duration.zero;
  Offset currentLocation = Offset.zero;

  void _hoverTo(Offset location, {Duration duration = const Duration(milliseconds: 20)}) async {
    currentTime += duration;
    Offset delta = location - currentLocation;
    currentLocation = location;

    RendererBinding.instance.dispatchEvent(
      PointerHoverEvent(
        timeStamp: currentTime,
        kind: PointerDeviceKind.mouse,
        position: location,
        delta: delta,
        buttons: 0,
      ),
      null,
    );
    // await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(duration);
  }

  void startTesting() async {
    await Future<void>.delayed(Duration.zero);
    while (true) {
      await _hoverTo(const Offset(10, 10));
      await _hoverTo(const Offset(10, 390));
      await _hoverTo(const Offset(390, 390));
      await _hoverTo(const Offset(390, 10));
    }
  }
}
