// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show Paragraph;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'recording_canvas.dart';

/// Matches objects or functions that paint a display list that matches the
/// canvas calls described by the pattern.
///
/// Specifically, this can be applied to [RenderObject]s, [Finder]s that
/// correspond to a single [RenderObject], and functions that have either of the
/// following signatures:
///
/// ```dart
/// void function(PaintingContext context, Offset offset);
/// void function(Canvas canvas);
/// ```
///
/// In the case of functions that take a [PaintingContext] and an [Offset], the
/// [paints] matcher will always pass a zero offset.
///
/// To specify the pattern, call the methods on the returned object. For example:
///
/// ```dart
///  expect(myRenderObject, paints..circle(radius: 10.0)..circle(radius: 20.0));
/// ```
///
/// This particular pattern would verify that the render object `myRenderObject`
/// paints, among other things, two circles of radius 10.0 and 20.0 (in that
/// order).
///
/// See [PaintPattern] for a discussion of the semantics of paint patterns.
///
/// To match something which paints nothing, see [paintsNothing].
PaintPattern get paints => new _TestRecordingCanvasPatternMatcher();

/// Matches objects or functions that paint an empty display list.
Matcher get paintsNothing => new _TestRecordingCanvasPaintsNothingMatcher();

/// Signature for [PaintPattern.something] predicate argument.
///
/// Used by the [paints] matcher.
///
/// The `methodName` argument is a [Symbol], and can be compared with the symbol
/// literal syntax, for example:
///
/// ```dart
/// if (methodName == #drawCircle) { ... }
/// ```
typedef bool PaintPatternPredicate(Symbol methodName, List<dynamic> arguments);

/// The signature of [RenderObject.paint] functions.
typedef void _ContextPainterFunction(PaintingContext context, Offset offset);

/// The signature of functions that paint directly on a canvas.
typedef void _CanvasPainterFunction(Canvas canvas);

/// Builder interface for patterns used to match display lists (canvas calls).
///
/// The [paints] matcher returns a [PaintPattern] so that you can build the
/// pattern in the [expect] call.
///
/// Patterns are subset matches, meaning that any calls not described by the
/// pattern are ignored. This allows, for instance, transforms to be skipped.
abstract class PaintPattern {
  /// Indicates that a translation transform is expected next.
  ///
  /// Calls are skipped until a call to [Canvas.translate] is found. The call's
  /// arguments are compared to those provided here. If any fail to match, or if
  /// no call to [Canvas.translate] is found, then the matcher fails.
  void translate({ double x, double y });

  /// Indicates that a scale transform is expected next.
  ///
  /// Calls are skipped until a call to [Canvas.scale] is found. The call's
  /// arguments are compared to those provided here. If any fail to match, or if
  /// no call to [Canvas.scale] is found, then the matcher fails.
  void scale({ double x, double y });

  /// Indicates that a rotate transform is expected next.
  ///
  /// Calls are skipped until a call to [Canvas.rotate] is found. If the `angle`
  /// argument is provided here, the call's argument is compared to it. If that
  /// fails to match, or if no call to [Canvas.rotate] is found, then the
  /// matcher fails.
  void rotate({ double angle });

  /// Indicates that a save is expected next.
  ///
  /// Calls are skipped until a call to [Canvas.save] is found. If none is
  /// found, the matcher fails.
  ///
  /// See also: [restore], [saveRestore].
  void save();

  /// Indicates that a restore is expected next.
  ///
  /// Calls are skipped until a call to [Canvas.restore] is found. If none is
  /// found, the matcher fails.
  ///
  /// See also: [save], [saveRestore].
  void restore();

  /// Indicates that a matching pair of save/restore calls is expected next.
  ///
  /// Calls are skipped until a call to [Canvas.save] is found, then, calls are
  /// skipped until the matching [Canvas.restore] call is found. If no matching
  /// pair of calls could be found, the matcher fails.
  ///
  /// See also: [save], [restore].
  void saveRestore();

  /// Indicates that a rectangular clip is expected next.
  ///
  /// The next rectangular clip is examined. Any arguments that are passed to
  /// this method are compared to the actual [Canvas.clipRect] call's argument
  /// and any mismatches result in failure.
  ///
  /// If no call to [Canvas.clipRect] was made, then this results in failure.
  ///
  /// Any calls made between the last matched call (if any) and the
  /// [Canvas.clipRect] call are ignored.
  void clipRect({ Rect rect });

  /// Indicates that a rectangle is expected next.
  ///
  /// The next rectangle is examined. Any arguments that are passed to this
  /// method are compared to the actual [Canvas.drawRect] call's arguments
  /// and any mismatches result in failure.
  ///
  /// If no call to [Canvas.drawRect] was made, then this results in failure.
  ///
  /// Any calls made between the last matched call (if any) and the
  /// [Canvas.drawRect] call are ignored.
  ///
  /// The [Paint]-related arguments (`color`, `strokeWidth`, `hasMaskFilter`,
  /// `style`) are compared against the state of the [Paint] object after the
  /// painting has completed, not at the time of the call. If the same [Paint]
  /// object is reused multiple times, then this may not match the actual
  /// arguments as they were seen by the method.
  void rect({ Rect rect, Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style });

  /// Indicates that a rounded rectangle clip is expected next.
  ///
  /// The next rounded rectangle clip is examined. Any arguments that are passed
  /// to this method are compared to the actual [Canvas.clipRRect] call's
  /// argument and any mismatches result in failure.
  ///
  /// If no call to [Canvas.clipRRect] was made, then this results in failure.
  ///
  /// Any calls made between the last matched call (if any) and the
  /// [Canvas.clipRRect] call are ignored.
  void clipRRect({ RRect rrect });

  /// Indicates that a rounded rectangle is expected next.
  ///
  /// The next rounded rectangle is examined. Any arguments that are passed to
  /// this method are compared to the actual [Canvas.drawRRect] call's arguments
  /// and any mismatches result in failure.
  ///
  /// If no call to [Canvas.drawRRect] was made, then this results in failure.
  ///
  /// Any calls made between the last matched call (if any) and the
  /// [Canvas.drawRRect] call are ignored.
  ///
  /// The [Paint]-related arguments (`color`, `strokeWidth`, `hasMaskFilter`,
  /// `style`) are compared against the state of the [Paint] object after the
  /// painting has completed, not at the time of the call. If the same [Paint]
  /// object is reused multiple times, then this may not match the actual
  /// arguments as they were seen by the method.
  void rrect({ RRect rrect, Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style });

  /// Indicates that a rounded rectangle outline is expected next.
  ///
  /// The next call to [Canvas.drawRRect] is examined. Any arguments that are
  /// passed to this method are compared to the actual [Canvas.drawRRect] call's
  /// arguments and any mismatches result in failure.
  ///
  /// If no call to [Canvas.drawRRect] was made, then this results in failure.
  ///
  /// Any calls made between the last matched call (if any) and the
  /// [Canvas.drawRRect] call are ignored.
  ///
  /// The [Paint]-related arguments (`color`, `strokeWidth`, `hasMaskFilter`,
  /// `style`) are compared against the state of the [Paint] object after the
  /// painting has completed, not at the time of the call. If the same [Paint]
  /// object is reused multiple times, then this may not match the actual
  /// arguments as they were seen by the method.
  void drrect({ RRect outer, RRect inner, Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style });

  /// Indicates that a circle is expected next.
  ///
  /// The next circle is examined. Any arguments that are passed to this method
  /// are compared to the actual [Canvas.drawCircle] call's arguments and any
  /// mismatches result in failure.
  ///
  /// If no call to [Canvas.drawCircle] was made, then this results in failure.
  ///
  /// Any calls made between the last matched call (if any) and the
  /// [Canvas.drawCircle] call are ignored.
  ///
  /// The [Paint]-related arguments (`color`, `strokeWidth`, `hasMaskFilter`,
  /// `style`) are compared against the state of the [Paint] object after the
  /// painting has completed, not at the time of the call. If the same [Paint]
  /// object is reused multiple times, then this may not match the actual
  /// arguments as they were seen by the method.
  void circle({ double x, double y, double radius, Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style });

  /// Indicates that a path is expected next.
  ///
  /// The next path is examined. Any arguments that are passed to this method
  /// are compared to the actual [Canvas.drawPath] call's `paint` argument, and
  /// any mismatches result in failure.
  ///
  /// There is currently no way to check the actual path itself.
  // See https://github.com/flutter/flutter/issues/93 which tracks that issue.
  ///
  /// If no call to [Canvas.drawPath] was made, then this results in failure.
  ///
  /// Any calls made between the last matched call (if any) and the
  /// [Canvas.drawPath] call are ignored.
  ///
  /// The [Paint]-related arguments (`color`, `strokeWidth`, `hasMaskFilter`,
  /// `style`) are compared against the state of the [Paint] object after the
  /// painting has completed, not at the time of the call. If the same [Paint]
  /// object is reused multiple times, then this may not match the actual
  /// arguments as they were seen by the method.
  void path({ Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style });

  /// Indicates that a line is expected next.
  ///
  /// The next line is examined. Any arguments that are passed to this method
  /// are compared to the actual [Canvas.drawLine] call's `paint` argument, and
  /// any mismatches result in failure.
  ///
  /// If no call to [Canvas.drawLine] was made, then this results in failure.
  ///
  /// Any calls made between the last matched call (if any) and the
  /// [Canvas.drawLine] call are ignored.
  ///
  /// The [Paint]-related arguments (`color`, `strokeWidth`, `hasMaskFilter`,
  /// `style`) are compared against the state of the [Paint] object after the
  /// painting has completed, not at the time of the call. If the same [Paint]
  /// object is reused multiple times, then this may not match the actual
  /// arguments as they were seen by the method.
  void line({ Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style });

  /// Indicates that an arc is expected next.
  ///
  /// The next arc is examined. Any arguments that are passed to this method
  /// are compared to the actual [Canvas.drawArc] call's `paint` argument, and
  /// any mismatches result in failure.
  ///
  /// If no call to [Canvas.drawArc] was made, then this results in failure.
  ///
  /// Any calls made between the last matched call (if any) and the
  /// [Canvas.drawArc] call are ignored.
  ///
  /// The [Paint]-related arguments (`color`, `strokeWidth`, `hasMaskFilter`,
  /// `style`) are compared against the state of the [Paint] object after the
  /// painting has completed, not at the time of the call. If the same [Paint]
  /// object is reused multiple times, then this may not match the actual
  /// arguments as they were seen by the method.
  void arc({ Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style });

  /// Indicates that a paragraph is expected next.
  ///
  /// Calls are skipped until a call to [Canvas.drawParagraph] is found. Any
  /// arguments that are passed to this method are compared to the actual
  /// [Canvas.drawParagraph] call's argument, and any mismatches result in failure.
  ///
  /// If no call to [Canvas.drawParagraph] was made, then this results in failure.
  void paragraph({ ui.Paragraph paragraph, Offset offset });

  /// Provides a custom matcher.
  ///
  /// Each method call after the last matched call (if any) will be passed to
  /// the given predicate, along with the values of its (positional) arguments.
  ///
  /// For each one, the predicate must either return a boolean or throw a [String].
  ///
  /// If the predicate returns true, the call is considered a successful match
  /// and the next step in the pattern is examined. If this was the last step,
  /// then any calls that were not yet matched are ignored and the [paints]
  /// [Matcher] is considered a success.
  ///
  /// If the predicate returns false, then the call is considered uninteresting
  /// and the predicate will be called again for the next [Canvas] call that was
  /// made by the [RenderObject] under test. If this was the last call, then the
  /// [paints] [Matcher] is considered to have failed.
  ///
  /// If the predicate throws a [String], then the [paints] [Matcher] is
  /// considered to have failed. The thrown string is used in the message
  /// displayed from the test framework and should be complete sentence
  /// describing the problem.
  void something(PaintPatternPredicate predicate);
}

class _MismatchedCall {
  const _MismatchedCall(this.message, this.callIntroduction, this.call) : assert(call != null);
  final String message;
  final String callIntroduction;
  final RecordedInvocation call;
}

abstract class _TestRecordingCanvasMatcher extends Matcher {
  @override
  bool matches(Object object, Map<dynamic, dynamic> matchState) {
    final TestRecordingCanvas canvas = new TestRecordingCanvas();
    final TestRecordingPaintingContext context = new TestRecordingPaintingContext(canvas);
    final StringBuffer description = new StringBuffer();
    String prefixMessage = 'unexpectedly failed.';
    bool result = false;
    try {
      if (object is _ContextPainterFunction) {
        final _ContextPainterFunction function = object;
        function(context, Offset.zero);
      } else if (object is _CanvasPainterFunction) {
        final _CanvasPainterFunction function = object;
        function(canvas);
      } else {
        if (object is Finder) {
          TestAsyncUtils.guardSync();
          final Finder finder = object;
          object = finder.evaluate().single.renderObject;
        }
        if (object is RenderObject) {
          final RenderObject renderObject = object;
          renderObject.paint(context, Offset.zero);
        } else {
          matchState[this] = 'was not one of the supported objects for the "paints" matcher.';
          return false;
        }
      }
      result = _evaluatePredicates(canvas.invocations, description);
      if (!result)
        prefixMessage = 'did not match the pattern.';
    } catch (error, stack) {
      prefixMessage = 'threw the following exception:';
      description.writeln(error.toString());
      description.write(stack.toString());
      result = false;
    }
    if (!result) {
      if (canvas.invocations.isNotEmpty) {
        description.write('The complete display list was:');
        for (RecordedInvocation call in canvas.invocations)
          description.write('\n  * $call');
      }
      matchState[this] = '$prefixMessage\n$description';
    }
    return result;
  }

  bool _evaluatePredicates(Iterable<RecordedInvocation> calls, StringBuffer description);

  @override
  Description describeMismatch(
    dynamic item,
    Description description,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    return description.add(matchState[this]);
  }
}

class _TestRecordingCanvasPaintsNothingMatcher extends _TestRecordingCanvasMatcher {
  @override
  Description describe(Description description) {
    return description.add('An object or closure that paints nothing.');
  }

  @override
  bool _evaluatePredicates(Iterable<RecordedInvocation> calls, StringBuffer description) {
    if (calls.isEmpty)
      return true;
    description.write(
      'painted something, the first call having the following stack:\n'
      '${calls.first.stackToString(indent: "  ")}\n'
    );
    return false;
  }
}

class _TestRecordingCanvasPatternMatcher extends _TestRecordingCanvasMatcher implements PaintPattern {
  final List<_PaintPredicate> _predicates = <_PaintPredicate>[];

  @override
  void translate({ double x, double y }) {
    _predicates.add(new _FunctionPaintPredicate(#translate, <dynamic>[x, y]));
  }

  @override
  void scale({ double x, double y }) {
    _predicates.add(new _FunctionPaintPredicate(#scale, <dynamic>[x, y]));
  }

  @override
  void rotate({ double angle }) {
    _predicates.add(new _FunctionPaintPredicate(#rotate, <dynamic>[angle]));
  }

  @override
  void save() {
    _predicates.add(new _FunctionPaintPredicate(#save, <dynamic>[]));
  }

  @override
  void restore() {
    _predicates.add(new _FunctionPaintPredicate(#restore, <dynamic>[]));
  }

  @override
  void saveRestore() {
    _predicates.add(new _SaveRestorePairPaintPredicate());
  }

  @override
  void clipRect({ Rect rect }) {
    _predicates.add(new _FunctionPaintPredicate(#clipRect, <dynamic>[rect]));
  }

  @override
  void rect({ Rect rect, Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style }) {
    _predicates.add(new _RectPaintPredicate(rect: rect, color: color, strokeWidth: strokeWidth, hasMaskFilter: hasMaskFilter, style: style));
  }

  @override
  void clipRRect({ RRect rrect }) {
    _predicates.add(new _FunctionPaintPredicate(#clipRRect, <dynamic>[rrect]));
  }

  @override
  void rrect({ RRect rrect, Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style }) {
    _predicates.add(new _RRectPaintPredicate(rrect: rrect, color: color, strokeWidth: strokeWidth, hasMaskFilter: hasMaskFilter, style: style));
  }

  @override
  void drrect({ RRect outer, RRect inner, Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style }) {
    _predicates.add(new _DRRectPaintPredicate(outer: outer, inner: inner, color: color, strokeWidth: strokeWidth, hasMaskFilter: hasMaskFilter, style: style));
  }

  @override
  void circle({ double x, double y, double radius, Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style }) {
    _predicates.add(new _CirclePaintPredicate(x: x, y: y, radius: radius, color: color, strokeWidth: strokeWidth, hasMaskFilter: hasMaskFilter, style: style));
  }

  @override
  void path({ Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style }) {
    _predicates.add(new _PathPaintPredicate(color: color, strokeWidth: strokeWidth, hasMaskFilter: hasMaskFilter, style: style));
  }

  @override
  void line({ Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style }) {
    _predicates.add(new _LinePaintPredicate(color: color, strokeWidth: strokeWidth, hasMaskFilter: hasMaskFilter, style: style));
  }

  @override
  void arc({ Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style }) {
    _predicates.add(new _ArcPaintPredicate(color: color, strokeWidth: strokeWidth, hasMaskFilter: hasMaskFilter, style: style));
  }

  @override
  void paragraph({ ui.Paragraph paragraph, Offset offset }) {
    _predicates.add(new _FunctionPaintPredicate(#drawParagraph, <dynamic>[paragraph, offset]));
  }

  @override
  void something(PaintPatternPredicate predicate) {
    _predicates.add(new _SomethingPaintPredicate(predicate));
  }

  @override
  Description describe(Description description) {
    if (_predicates.isEmpty)
      return description.add('An object or closure and a paint pattern.');
    description.add('Object or closure painting: ');
    return description.addAll(
      '', ', ', '',
      _predicates.map<String>((_PaintPredicate predicate) => predicate.toString()),
    );
  }

  @override
  bool _evaluatePredicates(Iterable<RecordedInvocation> calls, StringBuffer description) {
    if (calls.isEmpty) {
      description.writeln('It painted nothing.');
      return false;
    }
    if (_predicates.isEmpty) {
      description.writeln(
        'It painted something, but you must now add a pattern to the paints matcher '
        'in the test to verify that it matches the important parts of the following.'
      );
      return false;
    }
    final Iterator<_PaintPredicate> predicate = _predicates.iterator;
    final Iterator<RecordedInvocation> call = calls.iterator..moveNext();
    try {
      while (predicate.moveNext()) {
        if (call.current == null) {
          throw 'It painted less on its canvas than the paint pattern expected. '
                'The first missing paint call was: ${predicate.current}';
        }
        predicate.current.match(call);
      }
      assert(predicate.current == null);
      // We allow painting more than expected.
    } on _MismatchedCall catch (data) {
      description.writeln(data.message);
      description.writeln(data.callIntroduction);
      description.writeln(data.call.stackToString(indent: '  '));
      return false;
    } on String catch (s) {
      description.writeln(s);
      if (call.current != null) {
        description.write('The stack of the offending call was:\n${call.current.stackToString(indent: "  ")}\n');
      } else {
        description.write('The stack of the first call was:\n${calls.first.stackToString(indent: "  ")}\n');
      }
      return false;
    }
    return true;
  }
}

abstract class _PaintPredicate {
  void match(Iterator<RecordedInvocation> call);

  @override
  String toString() {
    throw new FlutterError('$runtimeType does not implement toString.');
  }
}

abstract class _DrawCommandPaintPredicate extends _PaintPredicate {
  _DrawCommandPaintPredicate(
    this.symbol, this.name, this.argumentCount, this.paintArgumentIndex,
    { this.color, this.strokeWidth, this.hasMaskFilter, this.style }
  );

  final Symbol symbol;
  final String name;
  final int argumentCount;
  final int paintArgumentIndex;
  final Color color;
  final double strokeWidth;
  final bool hasMaskFilter;
  final PaintingStyle style;

  String get methodName => _symbolName(symbol);

  @override
  void match(Iterator<RecordedInvocation> call) {
    int others = 0;
    final RecordedInvocation firstCall = call.current;
    while (!call.current.invocation.isMethod || call.current.invocation.memberName != symbol) {
      others += 1;
      if (!call.moveNext())
        throw new _MismatchedCall(
          'It called $others other method${ others == 1 ? "" : "s" } on the canvas, '
          'the first of which was $firstCall, but did not '
          'call $methodName at the time where $this was expected.',
          'The stack for the call to $firstCall was:',
          firstCall,
        );
    }
    final int actualArgumentCount = call.current.invocation.positionalArguments.length;
    if (actualArgumentCount != argumentCount)
      throw 'It called $methodName with $actualArgumentCount argument${actualArgumentCount == 1 ? "" : "s"}; expected $argumentCount.';
    verifyArguments(call.current.invocation.positionalArguments);
    call.moveNext();
  }

  @protected
  @mustCallSuper
  void verifyArguments(List<dynamic> arguments) {
    final Paint paintArgument = arguments[paintArgumentIndex];
    if (color != null && paintArgument.color != color)
      throw 'It called $methodName with a paint whose color, ${paintArgument.color}, was not exactly the expected color ($color).';
    if (strokeWidth != null && paintArgument.strokeWidth != strokeWidth)
      throw 'It called $methodName with a paint whose strokeWidth, ${paintArgument.strokeWidth}, was not exactly the expected strokeWidth ($strokeWidth).';
    if (hasMaskFilter != null && (paintArgument.maskFilter != null) != hasMaskFilter) {
      if (hasMaskFilter)
        throw 'It called $methodName with a paint that did not have a mask filter, despite expecting one.';
      else
        throw 'It called $methodName with a paint that did have a mask filter, despite not expecting one.';
    }
    if (style != null && paintArgument.style != style)
      throw 'It called $methodName with a paint whose style, ${paintArgument.style}, was not exactly the expected style ($style).';
  }

  @override
  String toString() {
    final List<String> description = <String>[];
    debugFillDescription(description);
    String result = name;
    if (description.isNotEmpty)
      result += ' with ${description.join(", ")}';
    return result;
  }

  @protected
  @mustCallSuper
  void debugFillDescription(List<String> description) {
    if (color != null)
      description.add('$color');
    if (strokeWidth != null)
      description.add('strokeWidth: $strokeWidth');
    if (hasMaskFilter != null)
      description.add(hasMaskFilter ? 'a mask filter' : 'no mask filter');
    if (style != null)
      description.add('$style');
  }
}

class _OneParameterPaintPredicate<T> extends _DrawCommandPaintPredicate {
  _OneParameterPaintPredicate(Symbol symbol, String name, {
    @required this.expected,
    @required Color color,
    @required double strokeWidth,
    @required bool hasMaskFilter,
    @required PaintingStyle style
  }) : super(
    symbol, name, 2, 1, color: color, strokeWidth: strokeWidth, hasMaskFilter: hasMaskFilter, style: style);

  final T expected;

  @override
  void verifyArguments(List<dynamic> arguments) {
    super.verifyArguments(arguments);
    final T actual = arguments[0];
    if (expected != null && actual != expected)
      throw 'It called $methodName with $T, $actual, which was not exactly the expected $T ($expected).';
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (expected != null) {
      if (expected.toString().contains(T.toString())) {
        description.add('$expected');
      } else {
        description.add('$T: $expected');
      }
    }
  }
}

class _TwoParameterPaintPredicate<T1, T2> extends _DrawCommandPaintPredicate {
  _TwoParameterPaintPredicate(Symbol symbol, String name, {
    @required this.expected1,
    @required this.expected2,
    @required Color color,
    @required double strokeWidth,
    @required bool hasMaskFilter,
    @required PaintingStyle style
  }) : super(
    symbol, name, 3, 2, color: color, strokeWidth: strokeWidth, hasMaskFilter: hasMaskFilter, style: style);

  final T1 expected1;

  final T2 expected2;

  @override
  void verifyArguments(List<dynamic> arguments) {
    super.verifyArguments(arguments);
    final T1 actual1 = arguments[0];
    if (expected1 != null && actual1 != expected1)
      throw 'It called $methodName with its first argument (a $T1), $actual1, which was not exactly the expected $T1 ($expected1).';
    final T2 actual2 = arguments[1];
    if (expected2 != null && actual2 != expected2)
      throw 'It called $methodName with its second argument (a $T2), $actual2, which was not exactly the expected $T2 ($expected2).';
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (expected1 != null) {
      if (expected1.toString().contains(T1.toString())) {
        description.add('$expected1');
      } else {
        description.add('$T1: $expected1');
      }
    }
    if (expected2 != null) {
      if (expected2.toString().contains(T2.toString())) {
        description.add('$expected2');
      } else {
        description.add('$T2: $expected2');
      }
    }
  }
}

class _RectPaintPredicate extends _OneParameterPaintPredicate<Rect> {
  _RectPaintPredicate({ Rect rect, Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style }) : super(
    #drawRect,
    'a rectangle',
    expected: rect,
    color: color,
    strokeWidth: strokeWidth,
    hasMaskFilter: hasMaskFilter,
    style: style,
  );
}

class _RRectPaintPredicate extends _OneParameterPaintPredicate<RRect> {
  _RRectPaintPredicate({ RRect rrect, Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style }) : super(
    #drawRRect,
    'a rounded rectangle',
    expected: rrect,
    color: color,
    strokeWidth: strokeWidth,
    hasMaskFilter: hasMaskFilter,
    style: style,
  );
}

class _DRRectPaintPredicate extends _TwoParameterPaintPredicate<RRect, RRect> {
  _DRRectPaintPredicate({ RRect inner, RRect outer, Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style }) : super(
    #drawDRRect,
    'a rounded rectangle outline',
    expected1: outer,
    expected2: inner,
    color: color,
    strokeWidth: strokeWidth,
    hasMaskFilter: hasMaskFilter,
    style: style,
  );
}

class _CirclePaintPredicate extends _DrawCommandPaintPredicate {
  _CirclePaintPredicate({ this.x, this.y, this.radius, Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style }) : super(
    #drawCircle, 'a circle', 3, 2, color: color, strokeWidth: strokeWidth, hasMaskFilter: hasMaskFilter, style: style
  );

  final double x;
  final double y;
  final double radius;

  @override
  void verifyArguments(List<dynamic> arguments) {
    super.verifyArguments(arguments);
    final Offset pointArgument = arguments[0];
    if (x != null && y != null) {
      final Offset point = new Offset(x, y);
      if (point != pointArgument)
        throw 'It called $methodName with a center coordinate, $pointArgument, which was not exactly the expected coordinate ($point).';
    } else {
      if (x != null && pointArgument.dx != x)
        throw 'It called $methodName with a center coordinate, $pointArgument, whose x-coordinate not exactly the expected coordinate (${x.toStringAsFixed(1)}).';
      if (y != null && pointArgument.dy != y)
        throw 'It called $methodName with a center coordinate, $pointArgument, whose y-coordinate not exactly the expected coordinate (${y.toStringAsFixed(1)}).';
    }
    final double radiusArgument = arguments[1];
    if (radius != null && radiusArgument != radius)
      throw 'It called $methodName with radius, ${radiusArgument.toStringAsFixed(1)}, which was not exactly the expected radius (${radius.toStringAsFixed(1)}).';
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (x != null && y != null) {
      description.add('point ${new Offset(x, y)}');
    } else {
      if (x != null)
        description.add('x-coordinate ${x.toStringAsFixed(1)}');
      if (y != null)
        description.add('y-coordinate ${y.toStringAsFixed(1)}');
    }
    if (radius != null)
      description.add('radius ${radius.toStringAsFixed(1)}');
  }
}

class _PathPaintPredicate extends _DrawCommandPaintPredicate {
  _PathPaintPredicate({ Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style }) : super(
    #drawPath, 'a path', 2, 1, color: color, strokeWidth: strokeWidth, hasMaskFilter: hasMaskFilter, style: style
  );
}

// TODO(ianh): add arguments to test the points, length, angle, that kind of thing
class _LinePaintPredicate extends _DrawCommandPaintPredicate {
  _LinePaintPredicate({ Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style }) : super(
    #drawLine, 'a line', 3, 2, color: color, strokeWidth: strokeWidth, hasMaskFilter: hasMaskFilter, style: style
  );
}

class _ArcPaintPredicate extends _DrawCommandPaintPredicate {
  _ArcPaintPredicate({ Color color, double strokeWidth, bool hasMaskFilter, PaintingStyle style }) : super(
    #drawArc, 'an arc', 5, 4, color: color, strokeWidth: strokeWidth, hasMaskFilter: hasMaskFilter, style: style
  );
}

class _SomethingPaintPredicate extends _PaintPredicate {
  _SomethingPaintPredicate(this.predicate);

  final PaintPatternPredicate predicate;

  @override
  void match(Iterator<RecordedInvocation> call) {
    assert(predicate != null);
    RecordedInvocation currentCall;
    do {
      currentCall = call.current;
      if (currentCall == null)
        throw 'It did not call anything that was matched by the predicate passed to a "something" step of the paint pattern.';
      if (!currentCall.invocation.isMethod)
        throw 'It called $currentCall, which was not a method, when the paint pattern expected a method call';
      call.moveNext();
    } while (!_runPredicate(currentCall.invocation.memberName, currentCall.invocation.positionalArguments));
  }

  bool _runPredicate(Symbol methodName, List<dynamic> arguments) {
    try {
      return predicate(methodName, arguments);
    } on String catch (s) {
      throw 'It painted something that the predicate passed to a "something" step '
            'in the paint pattern considered incorrect:\n      $s\n  ';
    }
  }

  @override
  String toString() => 'a "something" step';
}

class _FunctionPaintPredicate extends _PaintPredicate {
  _FunctionPaintPredicate(this.symbol, this.arguments);

  final Symbol symbol;

  final List<dynamic> arguments;

  @override
  void match(Iterator<RecordedInvocation> call) {
    int others = 0;
    final RecordedInvocation firstCall = call.current;
    while (!call.current.invocation.isMethod || call.current.invocation.memberName != symbol) {
      others += 1;
      if (!call.moveNext())
        throw new _MismatchedCall(
          'It called $others other method${ others == 1 ? "" : "s" } on the canvas, '
          'the first of which was $firstCall, but did not '
          'call ${_symbolName(symbol)}() at the time where $this was expected.',
          'The first method that was called when the call to ${_symbolName(symbol)}() '
          'was expected, $firstCall, was called with the following stack:',
          firstCall,
        );
    }
    if (call.current.invocation.positionalArguments.length != arguments.length)
      throw 'It called ${_symbolName(symbol)} with ${call.current.invocation.positionalArguments.length} arguments; expected ${arguments.length}.';
    for (int index = 0; index < arguments.length; index += 1) {
      final dynamic actualArgument = call.current.invocation.positionalArguments[index];
      final dynamic desiredArgument = arguments[index];
      if (desiredArgument != null && desiredArgument != actualArgument)
        throw 'It called ${_symbolName(symbol)} with argument $index having value ${_valueName(actualArgument)} when ${_valueName(desiredArgument)} was expected.';
    }
    call.moveNext();
  }

  @override
  String toString() {
    final List<String> adjectives = <String>[];
    for (int index = 0; index < arguments.length; index += 1)
      adjectives.add(arguments[index] != null ? _valueName(arguments[index]) : '...');
    return '${_symbolName(symbol)}(${adjectives.join(", ")})';
  }
}

class _SaveRestorePairPaintPredicate extends _PaintPredicate {
  @override
  void match(Iterator<RecordedInvocation> call) {
    int others = 0;
    final RecordedInvocation firstCall = call.current;
    while (!call.current.invocation.isMethod || call.current.invocation.memberName != #save) {
      others += 1;
      if (!call.moveNext())
        throw new _MismatchedCall(
          'It called $others other method${ others == 1 ? "" : "s" } on the canvas, '
          'the first of which was $firstCall, but did not '
          'call save() at the time where $this was expected.',
          'The first method that was called when the call to save() '
          'was expected, $firstCall, was called with the following stack:',
          firstCall,
        );
    }
    int depth = 1;
    while (depth > 0) {
      if (!call.moveNext())
        throw 'It did not have a matching restore() for the save() that was found where $this was expected.';
      if (call.current.invocation.isMethod) {
        if (call.current.invocation.memberName == #save)
          depth += 1;
        else if (call.current.invocation.memberName == #restore)
          depth -= 1;
      }
    }
    call.moveNext();
  }

  @override
  String toString() => 'a matching save/restore pair';
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
