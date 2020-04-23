// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

class FrameRecorder {
  FrameRecorder({@required this.size})
    : assert(size != null);

  final Size size;

  final List<Future<ui.Image>> _recordedFrames = <Future<ui.Image>>[];

  Widget record({
    Key key,
    bool recording,
    Widget child,
  }) {
    return Align(
      alignment: Alignment.topLeft,
      child: _FrameRecorderContainer(
        key: key,
        child: child,
        size: size,
        handleRecorded: recording ? _recordedFrames.add : null,
      ),
    );
  }

  Future<Widget> display({Key key}) async {
    final List<ui.Image> frames = await Future.wait<ui.Image>(_recordedFrames, eagerError: true);
    assert(() {
      for (final ui.Image frame in frames) {
        assert(frame.width == size.width);
        assert(frame.height == size.height);
      }
      return true;
    }());
    return _CellGrid(
      key: key,
      cellSize: size,
      children: frames.map((ui.Image image) => RawImage(
        image: image,
        width: size.width,
        height: size.height,
      )).toList(),
    );
  }
}

typedef _RecordedHandler = void Function(Future<ui.Image> image);

class _FrameRecorderContainer extends StatefulWidget {
  const _FrameRecorderContainer({
    this.handleRecorded,
    this.child,
    this.size,
    Key key,
  }) : super(key: key);

  final _RecordedHandler handleRecorded;
  final Widget child;
  final Size size;

  @override
  State<StatefulWidget> createState() => _FrameRecorderContainerState();
}

class _FrameRecorderContainerState extends State<_FrameRecorderContainer> {
  GlobalKey boundaryKey = GlobalKey();

  void _record(Duration duration) {
    final RenderRepaintBoundary boundary = boundaryKey.currentContext.findRenderObject() as RenderRepaintBoundary;
    widget.handleRecorded(boundary.toImage());
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: widget.size,
      child: RepaintBoundary(
        key: boundaryKey,
        child: _PostFrameCallbacker(
          callback: widget.handleRecorded == null ? null : _record,
          child: widget.child,
        ),
      ),
    );
  }
}

// Calls `callback` and [markNeedsPaint] during the post-frame callback phase of
// every frame.
// 
// If `callback` is non-null, `_PostFrameCallbacker` adds a post-frame callback
// every time it paints, during which it calls the provided `callback` then
// invokes [markNeedsPaint].
// 
// If `callback` is null, `_PostFrameCallbacker` is equivalent to a
// [RenderProxyBox].
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

// A grid of fixed-sized cells that are positioned from top left, horizontal-first,
// until the the entire grid is filled, discarding the remaining children.
class _CellGrid extends MultiChildRenderObjectWidget {
  _CellGrid({
    Key key,
    @required this.cellSize,
    List<Widget> children = const <Widget>[],
  }) : assert(cellSize != null),
       super(key: key, children: children);

  final Size cellSize;

  @override
  _RenderCellGrid createRenderObject(BuildContext context) {
    return _RenderCellGrid(
      cellSize: cellSize,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant _RenderCellGrid renderObject) {
    renderObject
      .cellSize = cellSize;
  }
}

class _CellGridParentData extends ContainerBoxParentData<RenderBox>{
}

class _RenderCellGrid extends RenderBox with ContainerRenderObjectMixin<RenderBox, _CellGridParentData>,
                                             RenderBoxContainerDefaultsMixin<RenderBox, _CellGridParentData> {
  _RenderCellGrid({
    List<RenderBox> children,
    Size cellSize,
  }) : _cellSize = cellSize {
    addAll(children);
  }

  Size get cellSize => _cellSize;
  Size _cellSize;
  set cellSize(Size value) {
    _cellSize = value;
    markNeedsLayout();
  }

  int get _columnNum {
    assert(size != null);
    return (size.width / cellSize.width).floor();
  }

  int get _rowNum {
    assert(size != null);
    return (size.height / cellSize.height).floor();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _CellGridParentData)
      child.parentData = _CellGridParentData();
  }

  @override
  void performResize() {
    size = constraints.biggest;
    final int maxChildrenNum = _columnNum * _rowNum;
    int childrenNum = 0;
    RenderBox child = firstChild;
    double x = 0;
    double y = 0;
    while (child != null && childrenNum < maxChildrenNum) {
      assert(y + cellSize.height < size.height);
      assert(x + cellSize.width < size.width);
      final _CellGridParentData childParentData = child.parentData as _CellGridParentData;
      child.layout(BoxConstraints.tight(cellSize), parentUsesSize: false);
      childParentData.offset = Offset(x, y);
      childrenNum += 1;
      x += cellSize.width;
      if (x >= size.width - cellSize.width) {
        x = 0;
        y += cellSize.height;
      }
      child = childParentData.nextSibling;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
    return;
  }

  @override
  bool get sizedByParent => true;
}