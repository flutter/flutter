// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'shadows.dart';
import 'theme.dart';

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
const double _kFlingVelocityScale = 1.0 / 300.0;
const Duration _kBaseSettleDuration = const Duration(milliseconds: 246);
const Duration _kThemeChangeDuration = const Duration(milliseconds: 200);
const Point _kOpenPosition = Point.origin;
const Point _kClosedPosition = const Point(-_kWidth, 0.0);

class _Drawer extends StatelessComponent {

  _Drawer({
    Key key,
    this.child,
    this.level: 3,
    this.performance,
    this.interactive,
    this.route
  }) : super(key: key);

  final Widget child;
  final int level;
  final PerformanceView performance;
  final bool interactive;
  final _DrawerRoute route;

  Widget build(BuildContext context) {
    return new GestureDetector(
      onHorizontalDragStart: (_) {
        if (interactive)
          route._takeControl();
      },
      onHorizontalDragUpdate: (double delta) {
        if (interactive)
          route._moveDrawer(delta);
      },
      onHorizontalDragEnd: (Offset velocity) {
        if (interactive)
          route._settle(velocity);
      },
      child: new Stack(<Widget>[
        // mask
        new GestureDetector(
          onTap: () {
            if (interactive)
              route._close();
          },
          child: new ColorTransition(
            performance: performance,
            color: new AnimatedColorValue(Colors.transparent, end: Colors.black54),
            child: new Container()
          )
        ),
        // drawer
        new Positioned(
          top: 0.0,
          left: 0.0,
          bottom: 0.0,
          child: new SlideTransition(
            performance: performance,
            position: new AnimatedValue<Point>(_kClosedPosition, end: _kOpenPosition),
            child: new AnimatedContainer(
              curve: Curves.ease,
              duration: _kThemeChangeDuration,
              decoration: new BoxDecoration(
                backgroundColor: Theme.of(context).canvasColor,
                boxShadow: shadows[level]),
              width: _kWidth,
              child: child
            )
          )
        )
      ])
    );
  }

}

class _DrawerRoute extends Route {
  _DrawerRoute({ this.child, this.level });

  final Widget child;
  final int level;

  PerformanceView get performance => _performance?.view;
  Performance _performance = new Performance(duration: _kBaseSettleDuration, debugLabel: 'Drawer');

  bool get opaque => false;

  bool _interactive = true;

  Widget build(RouteArguments args) {
    return new Focus(
      key: new GlobalObjectKey(this),
      autofocus: true,
      child: new _Drawer(
        child: child,
        level: level,
        performance: performance,
        interactive: _interactive,
        route: this
      )
    );
  }

  void didPush(NavigatorState navigator) {
    super.didPush(navigator);
    _performance.forward();
  }

  void didPop([dynamic result]) {
    assert(result == null); // because we don't do anything with it, so otherwise it'd be lost
    super.didPop(result);
    if (_performance.status != PerformanceStatus.dismissed)
      _performance.reverse();
    setState(() {
      _interactive = false;
      // TODO(ianh): https://github.com/flutter/engine/issues/1539
    });
  }

  void _takeControl() {
    assert(_interactive);
    _performance.stop();
  }

  void _moveDrawer(double delta) {
    assert(_interactive);
    _performance.progress += delta / _kWidth;
  }

  void _settle(Offset velocity) {
    assert(_interactive);
    if (velocity.dx.abs() >= _kMinFlingVelocity) {
      _performance.fling(velocity: velocity.dx * _kFlingVelocityScale);
    } else if (_performance.progress < 0.5) {
      _close();
    } else {
      _performance.fling(velocity: 1.0);
    }
  }

  void _close() {
    assert(_interactive);
    _performance.fling(velocity: -1.0);
  }
}

void showDrawer({ BuildContext context, Widget child, int level: 3 }) {
  Navigator.of(context).push(new _DrawerRoute(child: child, level: level));
}
