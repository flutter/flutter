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
const double _kMinFlingVelocity = 365.0;
const Duration _kBaseSettleDuration = const Duration(milliseconds: 246);

class _Drawer extends StatelessComponent {
  _Drawer({ Key key, this.route }) : super(key: key);

  final _DrawerRoute route;

  Widget build(BuildContext context) {
    return new Focus(
      key: new GlobalObjectKey(route),
      child: new ConstrainedBox(
        constraints: const BoxConstraints.expand(width: _kWidth),
        child: new Material(
          elevation: route.elevation,
          child: route.child
        )
      )
    );
  }
}

enum _DrawerState {
  showing,
  popped,
  closed,
}

class _DrawerRoute extends OverlayRoute {
  _DrawerRoute({ this.child, this.elevation });

  final Widget child;
  final int elevation;

  List<WidgetBuilder> get builders => <WidgetBuilder>[ _build ];

  final GlobalKey<_DrawerControllerState> _drawerKey = new GlobalKey<_DrawerControllerState>();
  _DrawerState _state = _DrawerState.showing;

  Widget _build(BuildContext context) {
    return new RepaintBoundary(
      child: new _DrawerController(
        key: _drawerKey,
        settleDuration: _kBaseSettleDuration,
        onClosed: () {
          _DrawerState previousState = _state;
          _state = _DrawerState.closed;
          switch (previousState) {
            case _DrawerState.showing:
              Navigator.pop(context);
              break;
            case _DrawerState.popped:
              finished();
              break;
            case _DrawerState.closed:
              assert(false);
              break;
          }
        },
        child: new _Drawer(route: this)
      )
    );
  }

  bool didPop(dynamic result) {
    // we don't call the superclass because we want to control the timing of the
    // call to finished().
    switch (_state) {
      case _DrawerState.showing:
        _drawerKey.currentState?._close();
        _state = _DrawerState.popped;
        break;
      case _DrawerState.popped:
        assert(false);
        break;
      case _DrawerState.closed:
        finished();
        break;
    }
    return true;
  }
}

class _DrawerController extends StatefulComponent {
  _DrawerController({
    Key key,
    this.settleDuration,
    this.onClosed,
    this.child
  }) : super(key: key);

  final Duration settleDuration;
  final Widget child;
  final VoidCallback onClosed;

  _DrawerControllerState createState() => new _DrawerControllerState();
}

class _DrawerControllerState extends State<_DrawerController> {
  void initState() {
    super.initState();
    _performance = new Performance(duration: config.settleDuration)
      ..addListener(_performanceChanged)
      ..addStatusListener(_performanceStatusChanged)
      ..play();
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

  void _performanceStatusChanged(PerformanceStatus status) {
    if (status == PerformanceStatus.dismissed && config.onClosed != null)
      config.onClosed();
  }

  Performance _performance;
  double _width;

  final AnimatedColorValue _color = new AnimatedColorValue(Colors.transparent, end: Colors.black54);

  void _handleSizeChanged(Size newSize) {
    setState(() {
      _width = newSize.width;
    });
  }

  void _handlePointerDown(_) {
    _performance.stop();
  }

  void _move(double delta) {
    _performance.progress += delta / _width;
  }

  void _settle(Offset velocity) {
    if (velocity.dx.abs() >= _kMinFlingVelocity) {
      _performance.fling(velocity: velocity.dx / _width);
    } else if (_performance.progress < 0.5) {
      _close();
    } else {
      _performance.fling(velocity: 1.0);
    }
  }

  void _close() {
    _performance.fling(velocity: -1.0);
  }

  Widget build(BuildContext context) {
    _performance.updateVariable(_color);
    return new GestureDetector(
      onHorizontalDragUpdate: _move,
      onHorizontalDragEnd: _settle,
      child: new Stack(<Widget>[
        new GestureDetector(
          onTap: _close,
          child: new DecoratedBox(
            decoration: new BoxDecoration(
              backgroundColor: _color.value
            ),
            child: new Container()
          )
        ),
        new Positioned(
          top: 0.0,
          left: 0.0,
          bottom: 0.0,
          child: new Listener(
            onPointerDown: _handlePointerDown,
            child: new Align(
              alignment: const FractionalOffset(1.0, 0.5),
              widthFactor: _performance.progress,
              child: new SizeObserver(
                onSizeChanged: _handleSizeChanged,
                child: new RepaintBoundary(
                  child: config.child
                )
              )
            )
          )
        )
      ])
    );
  }
}

void showDrawer({ BuildContext context, Widget child, int elevation: 16 }) {
  Navigator.push(context, new _DrawerRoute(child: child, elevation: elevation));
}
