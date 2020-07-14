// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/src/rendering/layer.dart';

/// An [Invocation] and the [stack] trace that led to it.
///
/// Used by [TestRecordingCanvas] to trace canvas calls.
class RecordedInvocation {
  /// Create a record for an invocation list.
  const RecordedInvocation(this.invocation, { this.stack });

  /// The method that was called and its arguments.
  ///
  /// The arguments preserve identity, but not value. Thus, if two invocations
  /// were made with the same [Paint] object, but with that object configured
  /// differently each time, then they will both have the same object as their
  /// argument, and inspecting that object will return the object's current
  /// values (mostly likely those passed to the second call).
  final Invocation invocation;

  /// The stack trace at the time of the method call.
  final StackTrace stack;

  @override
  String toString() => _describeInvocation(invocation);

  /// Converts [stack] to a string using the [FlutterError.defaultStackFilter] logic.
  String stackToString({ String indent = '' }) {
    assert(indent != null);
    return indent + FlutterError.defaultStackFilter(
      stack.toString().trimRight().split('\n')
    ).join('\n$indent');
  }
}

/// A [Canvas] for tests that records its method calls.
///
/// This class can be used in conjunction with [TestRecordingPaintingContext]
/// to record the [Canvas] method calls made by a renderer. For example:
///
/// ```dart
/// RenderBox box = tester.renderObject(find.text('ABC'));
/// TestRecordingCanvas canvas = TestRecordingCanvas();
/// TestRecordingPaintingContext context = TestRecordingPaintingContext(canvas);
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
  final List<RecordedInvocation> invocations = <RecordedInvocation>[];

  int _saveCount = 0;

  @override
  int getSaveCount() => _saveCount;

  @override
  void save() {
    _saveCount += 1;
    invocations.add(RecordedInvocation(_MethodCall(#save), stack: StackTrace.current));
  }

  @override
  void saveLayer(Rect bounds, Paint paint) {
    _saveCount += 1;
    invocations.add(RecordedInvocation(_MethodCall(#saveLayer, <dynamic>[bounds, paint]), stack: StackTrace.current));
  }

  @override
  void restore() {
    _saveCount -= 1;
    assert(_saveCount >= 0);
    invocations.add(RecordedInvocation(_MethodCall(#restore), stack: StackTrace.current));
  }

  @override
  void noSuchMethod(Invocation invocation) {
    invocations.add(RecordedInvocation(invocation, stack: StackTrace.current));
  }
}

class MultiplexingCanvas extends Canvas {
  MultiplexingCanvas(PictureRecorder recorder, this.observer) : super(recorder);

  final Canvas observer;

  @override
  void clipPath(Path path, {bool doAntiAlias = true}) {
    super.clipPath(path, doAntiAlias: doAntiAlias);
    observer.clipPath(path, doAntiAlias: doAntiAlias);
  }

  @override
  void clipRRect(RRect rrect, {bool doAntiAlias = true}) {
    super.clipRRect(rrect, doAntiAlias: doAntiAlias);
    observer.clipRRect(rrect, doAntiAlias: doAntiAlias);
  }

  @override
  void clipRect(Rect rect, {ClipOp clipOp = ClipOp.intersect, bool doAntiAlias = true}) {
    super.clipRect(rect, clipOp: clipOp, doAntiAlias: doAntiAlias);
    observer.clipRect(rect, clipOp: clipOp, doAntiAlias: doAntiAlias);
  }

  @override
  void drawArc(Rect rect, double startAngle, double sweepAngle, bool useCenter, Paint paint) {
    super.drawArc(rect, startAngle, sweepAngle, useCenter, paint);
    observer.drawArc(rect, startAngle, sweepAngle, useCenter, paint);
  }

  @override
  void drawAtlas(Image atlas, List<RSTransform> transforms, List<Rect> rects, List<Color> colors, BlendMode blendMode, Rect cullRect, Paint paint) {
    super.drawAtlas(atlas, transforms, rects, colors, blendMode, cullRect, paint);
    observer.drawAtlas(atlas, transforms, rects, colors, blendMode, cullRect, paint);
  }

  @override
  void drawCircle(Offset c, double radius, Paint paint) {
    super.drawCircle(c, radius, paint);
    observer.drawCircle(c, radius, paint);
  }

  @override
  void drawColor(Color color, BlendMode blendMode) {
    super.drawColor(color, blendMode);
    observer.drawColor(color, blendMode);
  }

  @override
  void drawDRRect(RRect outer, RRect inner, Paint paint) {
    super.drawDRRect(outer, inner, paint);
    observer.drawDRRect(outer, inner, paint);
  }

  @override
  void drawImage(Image image, Offset offset, Paint paint) {
    super.drawImage(image, offset, paint);
    observer.drawImage(image, offset, paint);
  }

  @override
  void drawImageNine(Image image, Rect center, Rect dst, Paint paint) {
    super.drawImageNine(image, center, dst, paint);
    observer.drawImageNine(image, center, dst, paint);
  }

  @override
  void drawImageRect(Image image, Rect src, Rect dst, Paint paint) {
    super.drawImageRect(image, src, dst, paint);
    observer.drawImageRect(image, src, dst, paint);
  }

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) {
    super.drawLine(p1, p2, paint);
    observer.drawLine(p1, p2, paint);
  }

  @override
  void drawOval(Rect rect, Paint paint) {
    super.drawOval(rect, paint);
    observer.drawOval(rect, paint);
  }

  @override
  void drawPaint(Paint paint) {
    super.drawPaint(paint);
    observer.drawPaint(paint);
  }

  @override
  void drawParagraph(Paragraph paragraph, Offset offset) {
    super.drawParagraph(paragraph, offset);
    observer.drawParagraph(paragraph, offset);
  }

  @override
  void drawPath(Path path, Paint paint) {
    super.drawPath(path, paint);
    observer.drawPath(path, paint);
  }

  @override
  void drawPicture(Picture picture) {
    super.drawPicture(picture);
    observer.drawPicture(picture);
  }

  @override
  void drawPoints(PointMode pointMode, List<Offset> points, Paint paint) {
    super.drawPoints(pointMode, points, paint);
    observer.drawPoints(pointMode, points, paint);
  }

  @override
  void drawRRect(RRect rrect, Paint paint) {
    super.drawRRect(rrect, paint);
    observer.drawRRect(rrect, paint);
  }

  @override
  void drawRawAtlas(Image atlas, Float32List rstTransforms, Float32List rects, Int32List colors, BlendMode blendMode, Rect cullRect, Paint paint) {
    super.drawRawAtlas(atlas, rstTransforms, rects, colors, blendMode, cullRect, paint);
    observer.drawRawAtlas(atlas, rstTransforms, rects, colors, blendMode, cullRect, paint);
  }

  @override
  void drawRawPoints(PointMode pointMode, Float32List points, Paint paint) {
    super.drawRawPoints(pointMode, points, paint);
    observer.drawRawPoints(pointMode, points, paint);
  }

  @override
  void drawRect(Rect rect, Paint paint) {
    super.drawRect(rect, paint);
    observer.drawRect(rect, paint);
  }

  @override
  void drawShadow(Path path, Color color, double elevation, bool transparentOccluder) {
    super.drawShadow(path, color, elevation, transparentOccluder);
    observer.drawShadow(path, color, elevation, transparentOccluder);
  }

  @override
  void drawVertices(Vertices vertices, BlendMode blendMode, Paint paint) {
    super.drawVertices(vertices, blendMode, paint);
    observer.drawVertices(vertices, blendMode, paint);
  }

  @override
  int getSaveCount() {
    final int saveCount = super.getSaveCount();
    observer.getSaveCount();
    return saveCount;
  }

  @override
  void restore() {
    super.restore();
    observer.restore();
  }

  @override
  void rotate(double radians) {
    super.rotate(radians);
    observer.rotate(radians);
  }

  @override
  void save() {
    super.save();
    observer.save();
  }

  @override
  void saveLayer(Rect bounds, Paint paint) {
    super.saveLayer(bounds, paint);
    observer.saveLayer(bounds, paint);
  }

  @override
  void scale(double sx, [double sy]) {
    super.scale(sx, sy);
    observer.scale(sx, sy);
  }

  @override
  void skew(double sx, double sy) {
    super.skew(sx, sy);
    observer.skew(sx, sy);
  }

  @override
  void transform(Float64List matrix4) {
    super.transform(matrix4);
    observer.transform(matrix4);
  }

  @override
  void translate(double dx, double dy) {
    super.translate(dx, dy);
    observer.translate(dx, dy);
  }
}

/// A [PaintingContext] for tests that use [TestRecordingCanvas].
///
/// This can be set as the painting context to be used by the Flutter framework
/// by setting the value of the [createPaintingContext] test variable, like so:
///
/// ```dart
/// testWidgets('...', (WidgetTester tester) async {
///   final TestRecordingCanvas canvas = TestRecordingCanvas();
///   createPaintingContext = ({ContainerLayer layer, Rect paintBounds}) {
///     return TestRecordingPaintingContext(layer, paintBounds, canvas);
///   };
///
///   // Run your test body, inspecting the properties of `canvas`
///
///   createPaintingContext = null;
/// });
/// ```
class TestRecordingPaintingContext<T extends TestRecordingCanvas> extends PaintingContext {
  /// Creates a [PaintingContext] for tests that use [TestRecordingCanvas].
  TestRecordingPaintingContext(
    ContainerLayer containerLayer,
    Rect estimatedBounds,
    T canvas,
  ) : _canvas = canvas,
      super(containerLayer, estimatedBounds);

  final T _canvas;

  @override
  Canvas createCanvas(PictureRecorder recorder) {
    return MultiplexingCanvas(recorder, _canvas);
  }

  @override
  PaintingContext createChildContext(ContainerLayer childLayer, Rect bounds) {
    return TestRecordingPaintingContext<T>(childLayer, bounds, _canvas);
  }
}

/// A [PaintingContext] for tests that use [TestRecordingCanvas].
///
/// Callers should prefer the more modern [TestRecordingPaintingContext].
class LegacyTestRecordingPaintingContext extends ClipContext implements PaintingContext {
  /// Creates a [PaintingContext] for tests that use [TestRecordingCanvas].
  LegacyTestRecordingPaintingContext(this.canvas);

  @override
  final Canvas canvas;

  @override
  void paintChild(RenderObject child, Offset offset) {
    child.paint(this, offset);
  }

  @override
  ClipRectLayer pushClipRect(
    bool needsCompositing,
    Offset offset,
    Rect clipRect,
    PaintingContextCallback painter, {
    Clip clipBehavior = Clip.hardEdge,
    ClipRectLayer oldLayer,
  }) {
    clipRectAndPaint(clipRect.shift(offset), clipBehavior, clipRect.shift(offset), () => painter(this, offset));
    return null;
  }

  @override
  ClipRRectLayer pushClipRRect(
    bool needsCompositing,
    Offset offset,
    Rect bounds,
    RRect clipRRect,
    PaintingContextCallback painter, {
    Clip clipBehavior = Clip.antiAlias,
    ClipRRectLayer oldLayer,
  }) {
    assert(clipBehavior != null);
    clipRRectAndPaint(clipRRect.shift(offset), clipBehavior, bounds.shift(offset), () => painter(this, offset));
    return null;
  }

  @override
  ClipPathLayer pushClipPath(
    bool needsCompositing,
    Offset offset,
    Rect bounds,
    Path clipPath,
    PaintingContextCallback painter, {
    Clip clipBehavior = Clip.antiAlias,
    ClipPathLayer oldLayer,
  }) {
    clipPathAndPaint(clipPath.shift(offset), clipBehavior, bounds.shift(offset), () => painter(this, offset));
    return null;
  }

  @override
  TransformLayer pushTransform(
    bool needsCompositing,
    Offset offset,
    Matrix4 transform,
    PaintingContextCallback painter, {
    TransformLayer oldLayer,
  }) {
    canvas.save();
    canvas.transform(transform.storage);
    painter(this, offset);
    canvas.restore();
    return null;
  }

  @override
  OpacityLayer pushOpacity(Offset offset, int alpha, PaintingContextCallback painter,
      { OpacityLayer oldLayer }) {
    canvas.saveLayer(null, null); // TODO(ianh): Expose the alpha somewhere.
    painter(this, offset);
    canvas.restore();
    return null;
  }

  @override
  void pushLayer(Layer childLayer, PaintingContextCallback painter, Offset offset,
      { Rect childPaintBounds }) {
    painter(this, offset);
  }

  @override
  void noSuchMethod(Invocation invocation) { }
}

class _MethodCall implements Invocation {
  _MethodCall(this._name, [ this._arguments = const <dynamic>[], this._typeArguments = const <Type> []]);
  final Symbol _name;
  final List<dynamic> _arguments;
  final List<Type> _typeArguments;
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
  @override
  List<Type> get typeArguments => _typeArguments;
}

String _valueName(Object value) {
  if (value is double)
    return value.toStringAsFixed(1);
  return value.toString();
}

// Workaround for https://github.com/dart-lang/sdk/issues/28372
String _symbolName(Symbol symbol) {
  // WARNING: Assumes a fixed format for Symbol.toString which is *not*
  // guaranteed anywhere.
  final String s = '$symbol';
  return s.substring(8, s.length - 2);
}

// Workaround for https://github.com/dart-lang/sdk/issues/28373
String _describeInvocation(Invocation call) {
  final StringBuffer buffer = StringBuffer();
  buffer.write(_symbolName(call.memberName));
  if (call.isSetter) {
    buffer.write(call.positionalArguments[0].toString());
  } else if (call.isMethod) {
    buffer.write('(');
    buffer.writeAll(call.positionalArguments.map<String>(_valueName), ', ');
    String separator = call.positionalArguments.isEmpty ? '' : ', ';
    call.namedArguments.forEach((Symbol name, Object value) {
      buffer.write(separator);
      buffer.write(_symbolName(name));
      buffer.write(': ');
      buffer.write(_valueName(value));
      separator = ', ';
    });
    buffer.write(')');
  }
  return buffer.toString();
}
