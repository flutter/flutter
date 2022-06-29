// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library page_transitions_theme;

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

part 'package:flutter/src/material/animated_raster.dart';

void main() {
  testWidgets('AnimatedRaster disposes its child image when disposed', (WidgetTester tester) async {
    final TestDelegate delegate = TestDelegate();

    await tester.pumpWidget(_AnimatedRaster(
      animation: const AlwaysStoppedAnimation<double>(0.5),
      delegate: delegate,
      child: Container(color: Colors.red, width: 100, height: 100),
    ));

    expect(delegate.lastImage, isNotNull);


    await tester.pumpWidget(const SizedBox());

    expect(delegate.lastImage!.debugDisposed, isTrue);
  }, skip: kIsWeb); // TODO(yjbanov): https://github.com/flutter/flutter/issues/106689

  testWidgets('AnimatedRaster does not create image if willPaint returns false', (WidgetTester tester) async {
    final TestDelegate delegate = TestDelegate()..useRasterValue = false;

    await tester.pumpWidget(_AnimatedRaster(
      animation: const AlwaysStoppedAnimation<double>(0.5),
      delegate: delegate,
      child: Container(color: Colors.red, width: 100, height: 100),
    ));

    expect(delegate.lastImage, isNull);
    delegate.lastImage = null;
  }, skip: kIsWeb); // TODO(yjbanov): https://github.com/flutter/flutter/issues/106689

  testWidgets('AnimatedRaster uses the media query dpr to scale up the provided image', (WidgetTester tester) async {
    final TestDelegate delegate = TestDelegate();

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData.fromWindow(tester.binding.window).copyWith(devicePixelRatio: 3.0),
        child: Center(
          child: _AnimatedRaster(
          animation: const AlwaysStoppedAnimation<double>(0.5),
          delegate: delegate,
          child: Container(color: Colors.red, width: 100, height: 100),
        ),
      ),
    ));

    expect(delegate.lastPixelRatio, 3.0);
    expect(delegate.lastImage?.width, 100 * 3.0);
    expect(delegate.lastImage?.height, 100 * 3.0);
  }, skip: kIsWeb); // TODO(yjbanov): https://github.com/flutter/flutter/issues/106689

  testWidgets('RenderAnimatedRaster removes and then reattaches animation listener if attached/detached', (WidgetTester tester) async {
    final TestDelegate delegate = TestDelegate();
    final TestAnimation animation = TestAnimation();
    final PipelineOwner owner = PipelineOwner();
    final _RenderAnimatedRaster animatedRaster = _RenderAnimatedRaster(animation, delegate, 1.0);
    animatedRaster.attach(owner);

    expect(animation.listeners, contains(animatedRaster.markNeedsPaint));
    expect(animation.statusListeners, hasLength(1));

    animatedRaster.detach();

    expect(animation.listeners, isEmpty);
    expect(animation.statusListeners, isEmpty);

    animatedRaster.attach(owner);

    expect(animation.listeners, contains(animatedRaster.markNeedsPaint));
    expect(animation.statusListeners, hasLength(1));
  }, skip: kIsWeb); // TODO(yjbanov): https://github.com/flutter/flutter/issues/106689
}

// ignore: must_be_immutable
class TestDelegate extends _AnimatedRasterDelegate {
  ui.Image? lastImage;
  double? lastPixelRatio;
  bool useRasterValue = true;

  @override
  bool useRaster(Animation<double> animation) {
    return useRasterValue;
  }

  @override
  void paint(PaintingContext context, Animation<double> animation, ui.Rect area, PaintingContextCallback callback) { }

  @override
  void paintRaster(PaintingContext context, ui.Image image, double pixelRatio, Animation<double> animation) {
    lastImage = image;
    lastPixelRatio = pixelRatio;
  }
}

class TestAnimation extends Animation<double> {
  final List<ui.VoidCallback> listeners = <ui.VoidCallback>[];
  final List<AnimationStatusListener> statusListeners = <AnimationStatusListener>[];

  @override
  void addListener(ui.VoidCallback listener) {
    listeners.add(listener);
  }

  @override
  void addStatusListener(AnimationStatusListener listener) {
    statusListeners.add(listener);
  }

  @override
  void removeListener(ui.VoidCallback listener) {
    listeners.remove(listener);
  }

  @override
  void removeStatusListener(AnimationStatusListener listener) {
    statusListeners.remove(listener);
  }

  @override
  AnimationStatus get status => AnimationStatus.forward;

  @override
  double get value => 0.5;
}
