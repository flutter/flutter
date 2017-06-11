// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';

/// A [Canvas] for tests that records its method calls.
///
/// This class can be used in conjuction with [TestRecordingPaintingContext]
/// to record the [Canvas] method calls made by a renderer. For example:
///
/// ```dart
/// RenderBox box = tester.renderObject(find.text('ABC'));
/// TestRecordingCanvas canvas = new TestRecordingCanvas();
/// TestRecordingPaintingContext context = new TestRecordingPaintingContext(canvas);
/// box.paint(context, Offset.zero);
/// // Now test the expected canvas.invocations.
/// ```
///
/// In some cases it may be useful to define a subclass that overrides the
/// [Canvas] methods the test is checking and squirrels away the parameters
/// that the test requires.
///
/// For simple tests, consider using the [paints] matcher, which overlays a
/// pattern matching API over [TestRecordingCanvas].
class TestRecordingCanvas implements Canvas {
  /// All of the method calls on this canvas.
  final List<Invocation> invocations = <Invocation>[];

  int _saveCount = 0;

  @override
  int getSaveCount() => _saveCount;

  @override
  void save() {
    _saveCount += 1;
    invocations.add(new _MethodCall(#save));
  }

  @override
  void saveLayer(Rect bounds, Paint paint) {
    _saveCount += 1;
    invocations.add(new _MethodCall(#saveLayer, <dynamic>[bounds, paint]));
  }

  @override
  void restore() {
    _saveCount -= 1;
    assert(_saveCount >= 0);
    invocations.add(new _MethodCall(#restore));
  }

  @override
  void noSuchMethod(Invocation invocation) {
    invocations.add(invocation);
  }
}

/// A [PaintingContext] for tests that use [TestRecordingCanvas].
class TestRecordingPaintingContext implements PaintingContext {
  /// Creates a [PaintingContext] for tests that use [TestRecordingCanvas].
  TestRecordingPaintingContext(this.canvas);

  @override
  final Canvas canvas;

  @override
  void paintChild(RenderObject child, Offset offset) {
    child.paint(this, offset);
  }

  @override
  void pushClipRect(bool needsCompositing, Offset offset, Rect clipRect, PaintingContextCallback painter) {
    canvas.save();
    canvas.clipRect(clipRect.shift(offset));
    painter(this, offset);
    canvas.restore();
  }

  @override
  void noSuchMethod(Invocation invocation) { }
}

class _MethodCall implements Invocation {
  _MethodCall(this._name, [ this._arguments = const <dynamic>[] ]);
  final Symbol _name;
  final List<dynamic> _arguments;
  @override
  bool get isAccessor => false;
  @override
  bool get isGetter => false;
  @override
  bool get isMethod => true;
  @override
  bool get isSetter => false;
  @override
  Symbol get memberName => _name;
  @override
  Map<Symbol, dynamic> get namedArguments => <Symbol, dynamic>{};
  @override
  List<dynamic> get positionalArguments => _arguments;
}
