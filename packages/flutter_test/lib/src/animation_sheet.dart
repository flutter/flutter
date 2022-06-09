// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Records the frames of an animating widget, and later displays the frames as a
/// grid in an animation sheet.
///
/// This class does not support Web, because the animation sheet utilizes taking
/// screenshots, which is unsupported on the Web. Tests that use this class must
/// be noted with `skip: isBrowser`.
/// (https://github.com/flutter/flutter/issues/56001)
///
/// Using this class includes the following steps:
///
///  * Create an instance of this class.
///  * Pump frames that render the target widget wrapped in [record]. Every frame
///    that has `recording` being true will be recorded.
///  * Acquire the output image with [collate] and compare against the golden
///    file.
///
/// {@tool snippet}
/// The following example shows how to record an animation sheet of an [InkWell]
/// being pressed then released.
///
/// ```dart
/// testWidgets('Inkwell animation sheet', (WidgetTester tester) async {
///   // Create instance
///   final AnimationSheetBuilder animationSheet = AnimationSheetBuilder(frameSize: const Size(48, 24));
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
///     target,
///     recording: false,
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
///   // Compare against golden file
///   await expectLater(
///     animationSheet.collate(800),
///     matchesGoldenFile('inkwell.press.animation.png'),
///   );
/// }, skip: isBrowser); // Animation sheet does not support browser https://github.com/flutter/flutter/issues/56001
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [GoldenFileComparator], which introduces Golden File Testing.
class AnimationSheetBuilder {
  /// Starts a session of building an animation sheet.
  ///
  /// The [frameSize] is a tight constraint for the child to be recorded, and must not
  /// be null.
  ///
  /// The [allLayers] controls whether to record elements drawn out of the subtree,
  /// and defaults to false.
  AnimationSheetBuilder({
    required this.frameSize,
    this.allLayers = false,
  }) : assert(!kIsWeb), // Does not support Web. See [AnimationSheetBuilder].
       assert(frameSize != null);

  /// The size of the child to be recorded.
  ///
  /// This size is applied as a tight layout constraint for the child, and is
  /// fixed throughout the building session.
  final Size frameSize;

  /// Whether the captured image comes from the entire tree, or only the
  /// subtree of [record].
  ///
  /// If [allLayers] is false, then the [record] widget will capture the image
  /// composited by its subtree.  If [allLayers] is true, then the [record] will
  /// capture the entire tree composited and clipped by [record]'s region.
  ///
  /// The two modes are identical if there is nothing in front of [record].
  /// But in rare cases, what needs to be captured has to be rendered out of
  /// [record]'s subtree in its front. By setting [allLayers] to true, [record]
  /// captures everything within its region even if drawn outside of its
  /// subtree.
  ///
  /// Defaults to false.
  final bool allLayers;

  final List<Future<ui.Image>> _recordedFrames = <Future<ui.Image>>[];
  Future<List<ui.Image>> get _frames async {
    final List<ui.Image> frames = await Future.wait<ui.Image>(_recordedFrames, eagerError: true);
    assert(() {
      for (final ui.Image frame in frames) {
        assert(frame.width == frameSize.width && frame.height == frameSize.height,
          'Unexpected size mismatch: frame has (${frame.width}, ${frame.height}) '
          'while `frameSize` is $frameSize.'
        );
      }
      return true;
    }());
    return frames;
  }

  /// Returns a widget that renders a widget in a box that can be recorded.
  ///
  /// The returned widget wraps `child` in a box with a fixed size specified by
  /// [frameSize]. The `key` is also applied to the returned widget.
  ///
  /// The frame is only recorded if the `recording` argument is true, or during
  /// a procedure that is wrapped within [recording]. In either case, the
  /// painted result of each frame will be stored and later available for
  /// [display]. If neither condition is met, the frames are not recorded, which
  /// is useful during setup phases.
  ///
  /// The `child` must not be null.
  ///
  /// See also:
  ///
  ///  * [WidgetTester.pumpFrames], which renders a widget in a series of frames
  ///    with a fixed time interval.
  Widget record(Widget child, {
    Key? key,
    bool recording = true,
  }) {
    assert(child != null);
    return _AnimationSheetRecorder(
      key: key,
      size: frameSize,
      allLayers: allLayers,
      handleRecorded: recording ? _recordedFrames.add : null,
      child: child,
    );
  }

  /// Constructs a widget that renders the recorded frames in an animation sheet.
  ///
  /// The resulting widget takes as much space as its parent allows, which is
  /// usually the screen size. It is then filled with all recorded frames, each
  /// having a size specified by [frameSize], chronologically from top-left to
  /// bottom-right in a row-major order.
  ///
  /// This widget does not check whether its size fits all recorded frames.
  /// Having too many frames can cause overflow errors, while having too few can
  /// waste the size of golden files. Therefore you should usually adjust the
  /// viewport size to [sheetSize] before calling this method.
  ///
  /// The `key` is applied to the root widget.
  ///
  /// This method can only be called if at least one frame has been recorded.
  ///
  /// The [display] is the legacy way of acquiring the output for comparison.
  /// It is not recommended because it requires more boilerplate, and produces
  /// a much large image than necessary: each pixel is rendered in 3x3 pixels
  /// without higher definition. Use [collate] instead.
  ///
  /// Using this way includes the following steps:
  ///
  ///  * Create an instance of this class.
  ///  * Pump frames that render the target widget wrapped in [record]. Every frame
  ///    that has `recording` being true will be recorded.
  ///  * Adjust the size of the test viewport to the [sheetSize] (see the
  ///    documentation of [sheetSize] for more information).
  ///  * Pump a frame that renders [display], which shows all recorded frames in an
  ///    animation sheet, and can be matched against the golden test.
  ///
  /// {@tool snippet}
  /// The following example shows how to record an animation sheet of an [InkWell]
  /// being pressed then released.
  ///
  /// ```dart
  /// testWidgets('Inkwell animation sheet', (WidgetTester tester) async {
  ///   // Create instance
  ///   final AnimationSheetBuilder animationSheet = AnimationSheetBuilder(frameSize: const Size(48, 24));
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
  ///     target,
  ///     recording: false,
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
  ///   // Adjust view port size
  ///   tester.binding.setSurfaceSize(animationSheet.sheetSize());
  ///
  ///   // Display
  ///   final Widget display = await animationSheet.display();
  ///   await tester.pumpWidget(display);
  ///
  ///   // Compare against golden file
  ///   await expectLater(
  ///     find.byWidget(display),
  ///     matchesGoldenFile('inkwell.press.animation.png'),
  ///   );
  /// }, skip: isBrowser); // Animation sheet does not support browser https://github.com/flutter/flutter/issues/56001
  /// ```
  /// {@end-tool}
  @Deprecated(
    'Use AnimationSheetBuilder.collate instead. '
    'This feature was deprecated after v2.3.0-13.0.pre.',
  )
  Future<Widget> display({Key? key}) async {
    assert(_recordedFrames.isNotEmpty);
    final List<ui.Image> frames = await _frames;
    return _CellSheet(
      key: key,
      cellSize: frameSize,
      children: frames.map((ui.Image image) => RawImage(
        image: image.clone(),
        width: frameSize.width,
        height: frameSize.height,
        // Disable quality enhancement because the point of this class is to
        // precisely record what the widget looks like.
        filterQuality: ui.FilterQuality.none,
      )).toList(),
    );
  }

  /// Returns an result image by putting all frames together in a table.
  ///
  /// This method returns a table of captured frames, `cellsPerRow` images
  /// per row, from left to right, top to bottom.
  ///
  /// An example of using this method can be found at [AnimationSheetBuilder].
  Future<ui.Image> collate(int cellsPerRow) async {
    final List<ui.Image> frames = await _frames;
    assert(frames.isNotEmpty,
      'No frames are collected. Have you forgot to set `recording` to true?');
    return _collateFrames(frames, frameSize, cellsPerRow);
  }

  /// Returns the smallest size that can contain all recorded frames.
  ///
  /// This is used to adjust the viewport during unit tests, i.e. the size of
  /// virtual screen. Having too many frames recorded than the default viewport
  /// size can contain will lead to overflow errors, while having too few frames
  /// means the golden file might be larger than necessary.
  ///
  /// The [sheetSize] returns the smallest possible size by placing the
  /// recorded frames, each of which has a size specified by [frameSize], in a
  /// row-major grid with a maximum width specified by `maxWidth`, and returns
  /// the size of that grid.
  ///
  /// Setting the viewport size during a widget test usually involves
  /// [TestWidgetsFlutterBinding.setSurfaceSize] and [WidgetTester.binding].
  ///
  /// The `maxWidth` defaults to the width of the default viewport, 800.0.
  ///
  /// This method can only be called if at least one frame has been recorded.
  @Deprecated(
    'The `sheetSize` is only useful for `display`, which should be migrated to `collate`. '
    'This feature was deprecated after v2.3.0-13.0.pre.',
  )
  Size sheetSize({double maxWidth = _kDefaultTestViewportWidth}) {
    assert(_recordedFrames.isNotEmpty);
    final int cellsPerRow = (maxWidth / frameSize.width).floor();
    final int rowNum = (_recordedFrames.length / cellsPerRow).ceil();
    final double width = math.min(cellsPerRow, _recordedFrames.length) * frameSize.width;
    return Size(width, frameSize.height * rowNum);
  }

  // The width of _kDefaultTestViewportSize in [TestViewConfiguration].
  static const double _kDefaultTestViewportWidth = 800.0;
}

typedef _RecordedHandler = void Function(Future<ui.Image> image);

class _AnimationSheetRecorder extends StatefulWidget {
  const _AnimationSheetRecorder({
    this.handleRecorded,
    required this.child,
    required this.size,
    required this.allLayers,
    super.key,
  });

  final _RecordedHandler? handleRecorded;
  final Widget child;
  final Size size;
  final bool allLayers;

  @override
  State<StatefulWidget> createState() => _AnimationSheetRecorderState();
}

class _AnimationSheetRecorderState extends State<_AnimationSheetRecorder> {
  GlobalKey boundaryKey = GlobalKey();

  void _record(Duration duration) {
    assert(widget.handleRecorded != null);
    final _RenderRootableRepaintBoundary boundary = boundaryKey.currentContext!.findRenderObject()! as _RenderRootableRepaintBoundary;
    if (widget.allLayers) {
      widget.handleRecorded!(boundary.allLayersToImage());
    } else {
      widget.handleRecorded!(boundary.toImage());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: SizedBox.fromSize(
        size: widget.size,
        child: _RootableRepaintBoundary(
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
    super.child,
    this.callback,
  });

  final FrameCallback? callback;

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
    FrameCallback? callback,
  }) : _callback = callback;

  FrameCallback? get callback => _callback;
  FrameCallback? _callback;
  set callback(FrameCallback? value) {
    _callback = value;
    if (value != null) {
      markNeedsPaint();
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (callback != null) {
      SchedulerBinding.instance.addPostFrameCallback((Duration duration) {
        callback!(duration);
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

Future<ui.Image> _collateFrames(List<ui.Image> frames, Size frameSize, int cellsPerRow) async {
  final int rowNum = (frames.length / cellsPerRow).ceil();

  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, frameSize.width * cellsPerRow, frameSize.height * rowNum),
  );
  for (int i = 0; i < frames.length; i += 1) {
    canvas.drawImage(
      frames[i],
      Offset(frameSize.width * (i % cellsPerRow), frameSize.height * (i / cellsPerRow).floor()),
      Paint(),
    );
  }
  return recorder.endRecording().toImage(
    (frameSize.width * cellsPerRow).toInt(),
    (frameSize.height * rowNum).toInt(),
  );
}

// Layout children in a grid of fixed-sized cells.
//
// The sheet fills up as much space as the parent allows. The cells are
// positioned from top left to bottom right in a row-major order.
class _CellSheet extends StatelessWidget {
  _CellSheet({
    super.key,
    required this.cellSize,
    required this.children,
  }) : assert(cellSize != null),
       assert(children != null && children.isNotEmpty);

  final Size cellSize;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
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

class _RenderRootableRepaintBoundary extends RenderRepaintBoundary {
  // Like [toImage], but captures an image of all layers (composited by
  // RenderView and its children) clipped by the region of this object.
  Future<ui.Image> allLayersToImage() {
    final TransformLayer rootLayer = _rootLayer();
    final Matrix4 rootTransform = (rootLayer.transform ?? Matrix4.identity()).clone();
    final Matrix4 transform = rootTransform.multiplied(getTransformTo(null));
    final Rect rect = MatrixUtils.transformRect(transform, Offset.zero & size);
    // The scale was used to fit the actual device. Revert it since the target
    // is the logical display. Take transform[0] as the scale.
    return rootLayer.toImage(rect, pixelRatio: 1 / transform[0]);
  }

  TransformLayer _rootLayer() {
    Layer layer = this.layer!;
    while (layer.parent != null) {
      layer = layer.parent!;
    }
    return layer as TransformLayer;
  }
}

// A [RepaintBoundary], except that its render object has a `fullscreenToImage` method.
class _RootableRepaintBoundary extends SingleChildRenderObjectWidget {
  /// Creates a widget that isolates repaints.
  const _RootableRepaintBoundary({ super.key, super.child });

  @override
  _RenderRootableRepaintBoundary createRenderObject(BuildContext context) => _RenderRootableRepaintBoundary();
}
