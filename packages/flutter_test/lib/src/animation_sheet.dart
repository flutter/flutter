// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records the frames of an animating widget, and later displays it in an
/// animation sheet.
///
/// This class does not support Web, because taking screenshots is unsupported,
/// which is necessary to build an animation sheet. Tests thatuse this class must
/// be noted with `skip: isBrowser`.
/// (https://github.com/flutter/flutter/issues/56001)
///
/// Using this class takes the following steps:
///
///  * Create an instance of this class.
///  * Pump frames that render the target widget wrapped in [record]. Every frame
///    that has `recording` being true will be recorded.
///  * Optionally, adjust the size of the test view port to the
///    [sheetSize].
///  * Pump a frame that renders [display], which shows all recorded frames in an
///    animation sheet, and can be matched against the golden test.
///
/// {@tool snippet}
/// The following example shows how to record an animation sheet of an [Inkwell]
/// being pressed then released.
///
/// ```dart
/// testWidgets('Inkwell animation sheet', (WidgetTester tester) async {
///   // Create instance
///   final AnimationSheetBuilder animationSheet = AnimationSheetBuilder(size: const Size(48, 24));
///
///   final Widget target = Material(
///     child: Directionality(
///       textDirection: TextDirection.ltr,
///       child: InkWell(
///         splashColor: Colors.blue,
///         onTap: () {},
///       ),
///     ),
///   );
///
///   // Optional: setup before recording (`recording` is false)
///   await tester.pumpWidget(animationSheet.record(
///     recording: false,
///     child: target,
///   ));
///
///   final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(InkWell)));
///
///   // Start recording (`recording` is true)
///   await tester.pumpFrames(animationSheet.record(
///     target,
///     recording: true,
///   ), const Duration(seconds: 1));
///
///   await gesture.up();
///
///   await tester.pumpFrames(animationSheet.record(
///     target,
///     recording: true,
///   ), const Duration(seconds: 1));
///
///   // Optional: adjust view port size
///   tester.binding.setSurfaceSize(animationSheet.sheetSize());
///
///   // Display
///   final Widget display = await animationSheet.display();
///   await tester.pumpWidget(display);
///
///   // Compare against golden file
///   expect(
///     find.byWidget(display),
///     matchesGoldenFile('inkwell.press.animation.png'),
///   );
/// }, skip: isBrowser); // Animation sheet does not support browser https://github.com/flutter/flutter/issues/56001
/// ```
/// {@end-tool}
class AnimationSheetBuilder {
  /// Starts a session of building an animation sheet.
  ///
  /// The [size] is a tight constraint for the child to be recorded, and must not
  /// be null.
  AnimationSheetBuilder({@required this.size}) : assert(size != null);

  /// The size of the child to be recorded.
  ///
  /// This size is applied as a tight layout constraint for the child, and is
  /// fixed throughout the building session.
  final Size size;

  final List<Future<ui.Image>> _recordedFrames = <Future<ui.Image>>[];
  Future<List<ui.Image>> get _frames async {
    final List<ui.Image> frames = await Future.wait<ui.Image>(_recordedFrames, eagerError: true);
    assert(() {
      for (final ui.Image frame in frames) {
        assert(frame.width == size.width);
        assert(frame.height == size.height);
      }
      return true;
    }());
    return frames;
  }

  /// Returns a widget that renders a widget in a box that can be recorded.
  ///
  /// The returned widget wraps `child` in a box with a fixed size specified by
  /// [size]. The `key` is also applied to the returned widget.
  ///
  /// The `recording` defaults to true, which means the painted result of each
  /// frame will be stored and later available for [display]. If `recording` is
  /// false, then frames are not recorded. This is useful during the setup phase
  /// that shouldn't be recorded; if the target widget isn't wrapped in [record]
  /// during the setup phase, the states will be lost when it starts recording.
  ///
  /// The `child` must not be null.
  ///
  /// See also:
  ///
  ///  * [WidgetTester.pumpFrames], which renders a widget in a series of frames
  ///    with a fixed time interval.
  Widget record(Widget child, {
    Key key,
    bool recording = true,
  }) {
    assert(child != null);
    return _FrameRecorderRecorder(
      key: key,
      child: child,
      size: size,
      handleRecorded: recording ? _recordedFrames.add : null,
    );
  }

  /// Constructs a widget that renders the recorded frames in an animation sheet.
  ///
  /// The resulting widget takes as much space as its parent allows, which is
  /// usually the screen size, and is then filled with the recorded frames, each
  /// having a size specified by [size], chronologically from top-left to
  /// bottom-right in a row-major order.
  ///
  /// If too many frames have be recorded, overflow errors might be thrown,
  /// therefore it is recommended to adjust the screen size to [sheetSize] before
  /// calling this method.
  ///
  /// The `key` is applied to the root widget.
  ///
  /// This method can only be called if at least one frame has been recorded.
  Future<Widget> display({Key key}) async {
    assert(_recordedFrames.isNotEmpty);
    final List<ui.Image> frames = await _frames;
    return _CellSheet(
      key: key,
      cellSize: size,
      children: frames.map((ui.Image image) => RawImage(
        image: image,
        width: size.width,
        height: size.height,
      )).toList(),
    );
  }

  /// Returns the smallest size that can contain all recorded frames.
  ///
  /// The [sheetSize] tries to place the recorded frames, each having a size
  /// specified by [size], in a row-major grid with a maximum width specified by
  /// `maxWidth`, and returns the size of that grid.
  ///
  /// The `maxWidth defaults to the width of the default view port, 800.0.
  ///
  /// This method can only be called if at least one frame has been recorded.
  ///
  /// See also:
  ///
  ///  * [TestWidgetsFlutterBinding.setSurfaceSize], which artificially changes
  ///    the screen size during a widget test.
  ///  * [WidgetTester.binding], which returns the [TestWidgetsFlutterBinding]
  ///    during a widget test.
  Size sheetSize({double maxWidth = _kDefaultTestViewportWidth}) {
    assert(_recordedFrames.isNotEmpty);
    final int cellsPerRow = (maxWidth / size.width).floor();
    final int rowNum = (_recordedFrames.length / cellsPerRow).ceil();
    final double width = math.min(cellsPerRow, _recordedFrames.length) * size.width;
    return Size(width, size.height * rowNum);
  }

  // The width of _kDefaultTestViewportSize in [TestViewConfiguration].
  static const double _kDefaultTestViewportWidth = 800.0;
}

typedef _RecordedHandler = void Function(Future<ui.Image> image);

class _FrameRecorderRecorder extends StatefulWidget {
  const _FrameRecorderRecorder({
    this.handleRecorded,
    this.child,
    this.size,
    Key key,
  }) : super(key: key);

  final _RecordedHandler handleRecorded;
  final Widget child;
  final Size size;

  @override
  State<StatefulWidget> createState() => _FrameRecorderRecorderState();
}

class _FrameRecorderRecorderState extends State<_FrameRecorderRecorder> {
  GlobalKey boundaryKey = GlobalKey();

  void _record(Duration duration) {
    final RenderRepaintBoundary boundary = boundaryKey.currentContext.findRenderObject() as RenderRepaintBoundary;
    widget.handleRecorded(boundary.toImage());
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: SizedBox.fromSize(
        size: widget.size,
        child: RepaintBoundary(
          key: boundaryKey,
          child: _PostFrameCallbacker(
            callback: widget.handleRecorded == null ? null : _record,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// Invokes `callback` and [markNeedsPaint] during the post-frame callback phase
// of every frame.
//
// If `callback` is non-null, `_PostFrameCallbacker` adds a post-frame callback
// every time it paints, during which it calls the provided `callback` then
// invokes [markNeedsPaint].
//
// If `callback` is null, `_PostFrameCallbacker` is equivalent to a proxy box.
class _PostFrameCallbacker extends SingleChildRenderObjectWidget {
  const _PostFrameCallbacker({
    Key key,
    Widget child,
    this.callback,
  }) : super(key: key, child: child);

  final FrameCallback callback;

  @override
  _RenderPostFrameCallbacker createRenderObject(BuildContext context) => _RenderPostFrameCallbacker(
    callback: callback,
  );

  @override
  void updateRenderObject(BuildContext context, _RenderPostFrameCallbacker renderObject) {
    renderObject.callback = callback;
  }
}

class _RenderPostFrameCallbacker extends RenderProxyBox {
  _RenderPostFrameCallbacker({
    FrameCallback callback,
  }) : _callback = callback;

  FrameCallback get callback => _callback;
  FrameCallback _callback;
  set callback(FrameCallback value) {
    _callback = value;
    if (value != null) {
      markNeedsPaint();
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (callback != null) {
      SchedulerBinding.instance.addPostFrameCallback(callback == null ? null : (Duration duration) {
        callback(duration);
        markNeedsPaint();
      });
    }
    super.paint(context, offset);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('callback', value: callback != null, ifTrue: 'has a callback'));
  }
}

// Layout children in a grid of fixed-sized cells.
//
// The sheet fills up as much space as the parent allows. The cells are
// positioned from top left to bottom right in a row-major order.
class _CellSheet extends StatelessWidget {
  _CellSheet({
    Key key,
    @required this.cellSize,
    @required this.children,
  }) : assert(cellSize != null),
       assert(children != null && children.isNotEmpty),
       super(key: key);

  final Size cellSize;
  final List<Widget> children;

  @override
  Widget build(BuildContext _context) {
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
      final double rowWidth = constraints.biggest.width;
      final int cellsPerRow = (rowWidth / cellSize.width).floor();
      final List<Widget> rows = <Widget>[];
      for (int rowStart = 0; rowStart < children.length; rowStart += cellsPerRow) {
        final Iterable<Widget> rowTargets = children.sublist(rowStart, math.min(rowStart + cellsPerRow, children.length));
        rows.add(Row(
          textDirection: TextDirection.ltr,
          children: rowTargets.map((Widget target) => SizedBox.fromSize(
            size: cellSize,
            child: target,
          )).toList(),
        ));
      }
      return Column(
        textDirection: TextDirection.ltr,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows,
      );
    });
  }
}