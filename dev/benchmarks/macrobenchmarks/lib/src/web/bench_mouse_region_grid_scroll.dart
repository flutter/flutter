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

/// Creates a grid of mouse regions, then continuously scrolls them up and down.
///
/// Measures our ability to render mouse regions.
class BenchMouseRegionGridScroll extends WidgetRecorder {
  BenchMouseRegionGridScroll() : super(name: benchmarkName);

  static const String benchmarkName = 'bench_mouse_region_grid_scroll';

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

  void _scroll(Offset offset, {Duration duration = const Duration(milliseconds: 100)}) async {
    final int durationMs = duration.inMilliseconds;
    final Duration frameDuration = Duration(seconds: 1) ~/ scrollFrequency;
    final int frameDurationMs = frameDuration.inMilliseconds;

    final int fullFrames = duration.inMilliseconds ~/ frameDurationMs;
    final Offset fullFrameOffset = offset * ((frameDurationMs as double) / durationMs);

    final Duration finalFrameDuration = duration - frameDuration * fullFrames;
    final Offset finalFrameOffset = offset - fullFrameOffset * (fullFrames as double);

    final HitTestResult hitTestResult = HitTestResult();
    RendererBinding.instance.hitTest(hitTestResult, currentLocation);

    // Down event
    RendererBinding.instance.dispatchEvent(
      PointerDownEvent(
        timeStamp: currentTime,
        kind: PointerDeviceKind.mouse,
        position: currentLocation,
        buttons: kPrimaryButton,
      ),
      hitTestResult,
    );
    await Future<void>.delayed(Duration.zero);

    for (int frame = 0; frame < fullFrames; frame += 1) {
      currentLocation += fullFrameOffset;
      RendererBinding.instance.dispatchEvent(
        PointerMoveEvent(
          timeStamp: currentTime,
          kind: PointerDeviceKind.mouse,
          position: currentLocation,
          delta: fullFrameOffset,
          buttons: kPrimaryButton,
        ),
        hitTestResult,
      );
      currentTime += frameDuration;
      await Future<void>.delayed(frameDuration);
      // await Future<void>.delayed(Duration.zero);
    }

    if (finalFrameOffset != Duration.zero) {
      currentLocation += finalFrameOffset;
      RendererBinding.instance.dispatchEvent(
        PointerMoveEvent(
          timeStamp: currentTime,
          kind: PointerDeviceKind.mouse,
          position: currentLocation,
          delta: finalFrameOffset,
          buttons: kPrimaryButton,
        ),
        hitTestResult,
      );
      currentTime += finalFrameDuration;
      await Future<void>.delayed(finalFrameDuration);
      // await Future<void>.delayed(Duration.zero);
    }

    // Up event
    RendererBinding.instance.dispatchEvent(
      PointerUpEvent(
        timeStamp: currentTime,
        kind: PointerDeviceKind.mouse,
        position: currentLocation,
        buttons: 0,
      ),
      hitTestResult,
    );
    await Future<void>.delayed(Duration.zero);
  }

  void startTesting() async {
    await Future<void>.delayed(Duration.zero);
    while (true) {
      await _hoverTo(dragStartLocation);
      await _scroll(dragUpOffset);
      await _hoverTo(dragStartLocation);
      await _scroll(dragDownOffset);
    }
  }
}
