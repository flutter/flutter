// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'test_vsync.dart';

/// Test descendent of ScrollPosition.
class TestScrollPosition extends ScrollPosition{
  /// creates instance of [ScrollPosition].
  TestScrollPosition() : super(physics: const ScrollPhysics(), context: _TestScrollContext());

  @override
  Future<void> animateTo(double to, {required Duration duration, required Curve curve}) {   
    throw UnimplementedError();
  }

  @override
  AxisDirection get axisDirection => throw UnimplementedError();

  @override
  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    throw UnimplementedError();
  }

  @override
  ScrollHoldController hold(VoidCallback holdCancelCallback) { 
    throw UnimplementedError();
  }

  @override
  void jumpTo(double value) {}

  @override
  void jumpToWithoutSettling(double value) {}

  @override
  void pointerScroll(double delta) {}

  @override
  ScrollDirection get userScrollDirection => throw UnimplementedError();
}

class _TestScrollContext implements ScrollContext{
  @override
  AxisDirection get axisDirection => throw UnimplementedError();

  @override
  BuildContext? get notificationContext => throw UnimplementedError();

  @override
  void saveOffset(double offset) {}

  @override
  void setCanDrag(bool value) {}

  @override
  void setIgnorePointer(bool value) {}

  @override
  void setSemanticsActions(Set<SemanticsAction> actions) {}

  @override
 
  BuildContext get storageContext =>  _TestBuildContext();

  @override
  TickerProvider get vsync => const TestVSync();
}
 
class _TestBuildContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) {}
}
