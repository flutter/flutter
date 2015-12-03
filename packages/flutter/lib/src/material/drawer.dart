// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'material.dart';

// TODO(eseidel): Draw width should vary based on device size:
// http://www.google.com/design/spec/layout/structure.html#structure-side-nav

// Mobile:
// Width = Screen width − 56 dp
// Maximum width: 320dp
// Maximum width applies only when using a left nav. When using a right nav,
// the panel can cover the full width of the screen.

// Desktop/Tablet:
// Maximum width for a left nav is 400dp.
// The right nav can vary depending on content.

const double _kWidth = 304.0;
const double _kEdgeDragWidth = 20.0;
const double _kMinFlingVelocity = 365.0;
const Duration _kBaseSettleDuration = const Duration(milliseconds: 246);

class Drawer extends StatelessComponent {
  Drawer({
    Key key,
    this.elevation: 16,
    this.child
  }) : super(key: key);

  final int elevation;
  final Widget child;

  Widget build(BuildContext context) {
    return new ConstrainedBox(
      constraints: const BoxConstraints.expand(width: _kWidth),
      child: new Material(
        elevation: elevation,
        child: child
      )
    );
  }
}

class DrawerController extends StatefulComponent {
  DrawerController({
    GlobalKey key,
    this.child
  }) : super(key: key);

  final Widget child;

  DrawerControllerState createState() => new DrawerControllerState();
}

class DrawerControllerState extends State<DrawerController> {
  void initState() {
    super.initState();
    _performance = new Performance(duration: _kBaseSettleDuration)
      ..addListener(_performanceChanged)
      ..addStatusListener(_performanceStatusChanged);
  }

  void dispose() {
    _performance
      ..removeListener(_performanceChanged)
      ..removeStatusListener(_performanceStatusChanged)
      ..stop();
    super.dispose();
  }

  void _performanceChanged() {
    setState(() {
      // The performance's state is our build state, and it changed already.
    });
  }

  LocalHistoryEntry _historyEntry;

  void _ensureHistoryEntry() {
    if (_historyEntry == null) {
      ModalRoute route = ModalRoute.of(context);
      if (route != null) {
        _historyEntry = new LocalHistoryEntry(onRemove: _handleHistoryEntryRemoved);
        route.addLocalHistoryEntry(_historyEntry);
      }
    }
  }

  void _performanceStatusChanged(PerformanceStatus status) {
    switch (status) {
      case PerformanceStatus.forward:
        _ensureHistoryEntry();
        break;
      case PerformanceStatus.reverse:
        _historyEntry?.remove();
        _historyEntry = null;
        break;
      case PerformanceStatus.dismissed:
        break;
      case PerformanceStatus.completed:
        break;
    }
  }

  void _handleHistoryEntryRemoved() {
    _historyEntry = null;
    close();
  }

  Performance _performance;
  double _width = _kEdgeDragWidth;

  void _handleSizeChanged(Size newSize) {
    setState(() {
      _width = newSize.width;
    });
  }

  void _handlePointerDown(_) {
    _performance.stop();
    _ensureHistoryEntry();
  }

  void _move(double delta) {
    _performance.progress += delta / _width;
  }

  void _settle(Offset velocity) {
    if (_performance.isDismissed)
      return;
    if (velocity.dx.abs() >= _kMinFlingVelocity) {
      _performance.fling(velocity: velocity.dx / _width);
    } else if (_performance.progress < 0.5) {
      close();
    } else {
      open();
    }
  }

  void open() {
    _performance.fling(velocity: 1.0);
  }

  void close() {
    _performance.fling(velocity: -1.0);
  }

  final AnimatedColorValue _color = new AnimatedColorValue(Colors.transparent, end: Colors.black54);

  Widget build(BuildContext context) {
    HitTestBehavior behavior;
    Widget child;
    if (_performance.status == PerformanceStatus.dismissed) {
      behavior = HitTestBehavior.translucent;
      child = new Align(
        alignment: const FractionalOffset(0.0, 0.5),
        widthFactor: 1.0,
        child: new Container(width: _kEdgeDragWidth)
      );
    } else {
      _performance.updateVariable(_color);
      child = new RepaintBoundary(
        child: new Stack(<Widget>[
          new GestureDetector(
            onTap: close,
            child: new DecoratedBox(
              decoration: new BoxDecoration(
                backgroundColor: _color.value
              ),
              child: new Container()
            )
          ),
          new Align(
            alignment: const FractionalOffset(0.0, 0.5),
            child: new Listener(
              onPointerDown: _handlePointerDown,
              child: new Align(
                alignment: const FractionalOffset(1.0, 0.5),
                widthFactor: _performance.progress,
                child: new SizeObserver(
                  onSizeChanged: _handleSizeChanged,
                  child: new RepaintBoundary(
                    child: new Focus(
                      key: new GlobalObjectKey(config.key),
                      child: config.child
                    )
                  )
                )
              )
            )
          )
        ])
      );
    }
    return new GestureDetector(
      onHorizontalDragUpdate: _move,
      onHorizontalDragEnd: _settle,
      behavior: behavior,
      child: child
    );
  }
}
