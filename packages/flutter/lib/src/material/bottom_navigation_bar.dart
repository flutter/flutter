// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:collection' show Queue;

import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

import 'colors.dart';
import 'constants.dart';
import 'icon.dart';
import 'icon_theme.dart';
import 'icon_theme_data.dart';
import 'ink_well.dart';
import 'material.dart';
import 'theme.dart';
import 'typography.dart';

const double _kActiveMaxWidth = 168.0;
const double _kInactiveMaxWidth = 96.0;

/// Defines the layout and behavior of a [BottomNavigationBar].
///
/// See also:
///
///  * [BottomNavigationBar]
///  * [DestinationLabel]
///  * <https://material.google.com/components/bottom-navigation.html#bottom-navigation-specs>
enum BottomNavigationBarType {
  /// The [BottomNavigationBar]'s [DestinationLabel]s have fixed width.
  fixed,

  /// The location and size of the [BottomNavigationBar] [DestinationLabel]s
  /// animate larger when they are tapped.
  shifting,
}

/// An interactive destination label within [BottomNavigationBar] with an icon
/// and title.
///
/// See also:
///
///  * [BottomNavigationBar]
///  * <https://material.google.com/components/bottom-navigation.html>
class DestinationLabel {
  /// Creates a label that is used with [BottomNavigationBar.labels].
  ///
  /// The arguments [icon] and [title] should not be null.
  DestinationLabel({
    @required this.icon,
    @required this.title,
    this.backgroundColor
  }) {
    assert(this.icon != null);
    assert(this.title != null);
  }

  /// The icon of the label.
  final Icon icon;

  /// The title of the label.
  final Widget title;

  /// The color of the background radial animation.
  ///
  /// If the navigation bar's type is [BottomNavigationBarType.shifting], then
  /// the entire bar is flooded with the [backgroundColor] when this label is
  /// tapped.
  final Color backgroundColor;
}

/// A material widget displayed at the bottom of an app for selecting among a
/// small number of views.
///
/// The bottom navigation bar consists of multiple destinations in the form of
/// labels laid out on top of a piece of material. It provies quick navigation
/// between top-level views of an app and is typically used on mobile. For
/// larger screens, side navigation may be a better fit.
///
/// A bottom navigation bar is usually used in conjunction with [Scaffold] where
/// it is provided as the [Scaffold.bottomNavigationBar] argument.
///
/// See also:
///
///  * [DestinationLabel]
///  * [Scaffold]
///  * <https://material.google.com/components/bottom-navigation.html>
class BottomNavigationBar extends StatefulWidget {
  /// Creates a bottom navigation bar, typically used in a [Scaffold] where it
  /// is provided as the [Scaffold.bottomNavigationBar] argument.
  ///
  /// The arguments [labels] and [type] should not be null.
  ///
  /// The number of labels passed should be equal or greater than 2.
  ///
  /// Passing a null [fixedColor] will cause a fallback to the theme's primary
  /// color.
  BottomNavigationBar({
    Key key,
    @required this.labels,
    this.onTap,
    this.currentIndex: 0,
    this.type: BottomNavigationBarType.fixed,
    this.fixedColor
  }) : super(key: key) {
    assert(this.labels != null);
    assert(this.labels.length >= 2);
    assert(0 <= currentIndex && currentIndex < this.labels.length);
    assert(this.type != null);
    assert(
      this.type == BottomNavigationBarType.fixed || this.fixedColor == null
    );
  }

  /// The interactive labels laid out within the bottom navigation bar.
  final List<DestinationLabel> labels;

  /// The callback that is called when a label is tapped.
  ///
  /// The widget creating the bottom navigation bar needs to keep track of the
  /// current index and call `setState` to rebuild it with the newly provided
  /// index.
  final ValueChanged<int> onTap;

  /// The index into [labels] of the current active label.
  final int currentIndex;

  /// Defines the layout and behavior of a [BottomNavigationBar].
  final BottomNavigationBarType type;

  /// The color of the selected label when bottom navigation bar is
  /// [BottomNavigationBarType.fixed].
  final Color fixedColor;

  @override
  BottomNavigationBarState createState() => new BottomNavigationBarState();
}

class BottomNavigationBarState extends State<BottomNavigationBar> with TickerProviderStateMixin {
  List<AnimationController> _controllers;
  List<CurvedAnimation> animations;
  double _weight;
  final Queue<_Circle> _circles = new Queue<_Circle>();
  Color _backgroundColor; // Last growing circle's color.

  static final Tween<double> _flexTween = new Tween<double>(
    begin: 1.0,
    end: 1.5
  );

  @override
  void initState() {
    super.initState();
    _controllers = new List<AnimationController>.generate(config.labels.length, (int index) {
      return new AnimationController(
        duration: kThemeAnimationDuration,
        vsync: this,
      )..addListener(_rebuild);
    });
    animations = new List<CurvedAnimation>.generate(config.labels.length, (int index) {
      return new CurvedAnimation(
        parent: _controllers[index],
        curve: Curves.fastOutSlowIn,
        reverseCurve: Curves.fastOutSlowIn.flipped
      );
    });
    _controllers[config.currentIndex].value = 1.0;
    _backgroundColor = config.labels[config.currentIndex].backgroundColor;
  }

  @override
  void dispose() {
    for (AnimationController controller in _controllers)
      controller.dispose();
    for (_Circle circle in _circles)
      circle.dispose();
    super.dispose();
  }

  void _rebuild() {
    setState(() {
      // Rebuilding when any of the controllers tick, i.e. when the labels are
      // animated.
    });
  }

  double get _maxWidth {
    assert(config.type != null);
    switch (config.type) {
      case BottomNavigationBarType.fixed:
        return config.labels.length * _kActiveMaxWidth;
      case BottomNavigationBarType.shifting:
        return _kActiveMaxWidth + (config.labels.length - 1) * _kInactiveMaxWidth;
    }
    return null;
  }

  bool _isAnimating(Animation<double> animation) {
    return animation.status == AnimationStatus.forward ||
           animation.status == AnimationStatus.reverse;
  }

  // Because of non-linear nature of the animations, the animations that are
  // currently animating might not add up to the flex weight we are expecting.
  // (1.5 + N - 1, since the max flex that the animating ones can have is 1.5)
  // This causes instability in the animation when multiple labels are tapped.
  // To solves this, we always store a weight that normalizes animating
  // animations such that their resulting flex values will add up to the desired
  // value.
  void _computeWeight() {
    final Iterable<Animation<double>> animating = animations.where(
      (Animation<double> animation) => _isAnimating(animation)
    );

    if (animating.isNotEmpty) {
      final double sum = animating.fold(0.0, (double sum, Animation<double> animation) {
        return sum + _flexTween.evaluate(animation);
      });
      _weight = (animating.length + 0.5) / sum;
    } else {
      _weight = 1.0;
    }
  }

  double _flex(Animation<double> animation) {
    if (_isAnimating(animation)) {
      assert(_weight != null);
      return _flexTween.evaluate(animation) * _weight;
    } else {
      return _flexTween.evaluate(animation);
    }
  }

  double _xOffset(int index) {
    double weightSum(Iterable<Animation<double>> animations) {
      return animations.map(
        // We're adding flex values instead of animation values to have correct
        // ratios.
        (Animation<double> animation) => _flex(animation)
      ).fold(0.0, (double sum, double value) => sum + value);
    }

    final double allWeights = weightSum(animations);
    // This weight corresponds to the left edge of the indexed label.
    final double leftWeights = weightSum(animations.sublist(0, index));

    // Add half of its flex value in order to get the center.
    return (leftWeights + _flex(animations[index]) / 2.0) / allWeights;
  }

  FractionalOffset cirleOffset(int index) {
    final double iconSize = config.labels[index].icon.size ?? 24.0;
    final Tween<double> yOffsetTween = new Tween<double>(
      begin: (18.0 + iconSize / 2.0) / kBottomNavigationBarHeight, // 18dp + icon center
      end: (6.0 + iconSize / 2.0) / kBottomNavigationBarHeight     // 6dp + icon center
    );

    return new FractionalOffset(
      _xOffset(index),
      yOffsetTween.evaluate(animations[index])
    );
  }

  void _pushCircle(int index) {
    if (config.labels[index].backgroundColor != null)
      _circles.add(
        new _Circle(
          state: this,
          index: index,
          color: config.labels[index].backgroundColor,
          vsync: this,
        )..controller.addStatusListener((AnimationStatus status) {
          if (status == AnimationStatus.completed) {
            setState(() {
              _Circle circle = _circles.removeFirst();
              _backgroundColor = circle.color;
              circle.dispose();
            });
          }
        })
      );
  }

  @override
  void didUpdateConfig(BottomNavigationBar oldConfig) {
    if (config.currentIndex != oldConfig.currentIndex) {
      if (config.type == BottomNavigationBarType.shifting)
        _pushCircle(config.currentIndex);
      _controllers[oldConfig.currentIndex].reverse();
      _controllers[config.currentIndex].forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget bottomNavigation;
    switch (config.type) {
      case BottomNavigationBarType.fixed:
        final List<Widget> children = <Widget>[];
        final ThemeData themeData = Theme.of(context);
        final TextTheme textTheme = themeData.textTheme;
        final ColorTween colorTween = new ColorTween(
          begin: textTheme.caption.color,
          end: config.fixedColor ?? (
            themeData.brightness == Brightness.light ?
                themeData.primaryColor : themeData.accentColor
          )
        );
        for (int i = 0; i < config.labels.length; i += 1) {
          children.add(
            new Flexible(
              child: new InkResponse(
                onTap: () {
                  if (config.onTap != null)
                    config.onTap(i);
                },
                child: new Stack(
                  alignment: FractionalOffset.center,
                  children: <Widget>[
                    new Align(
                      alignment: FractionalOffset.topCenter,
                      child: new Container(
                        margin: new EdgeInsets.only(
                          top: new Tween<double>(
                            begin: 8.0,
                            end: 6.0,
                          ).evaluate(animations[i]),
                        ),
                        child: new IconTheme(
                          data: new IconThemeData(
                            color: colorTween.evaluate(animations[i]),
                          ),
                          child: config.labels[i].icon,
                        ),
                      ),
                    ),
                    new Align(
                      alignment: FractionalOffset.bottomCenter,
                      child: new Container(
                        margin: const EdgeInsets.only(bottom: 10.0),
                        child: new DefaultTextStyle(
                          style: new TextStyle(
                            fontSize: 14.0,
                            color: colorTween.evaluate(animations[i]),
                          ),
                          child: new Transform(
                            transform: new Matrix4.diagonal3(new Vector3.all(
                              new Tween<double>(
                                begin: 0.85,
                                end: 1.0,
                              ).evaluate(animations[i]),
                            )),
                            alignment: FractionalOffset.bottomCenter,
                            child: config.labels[i].title,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        bottomNavigation = new SizedBox(
          width: _maxWidth,
          child: new Row(children: children),
        );
        break;

      case BottomNavigationBarType.shifting:
        final List<Widget> children = <Widget>[];
        _computeWeight();
        for (int i = 0; i < config.labels.length; i += 1) {
          children.add(
            new Flexible(
              // Since Flexible only supports integers, we're using large
              // numbers in order to simulate floating point flex values.
              flex: (_flex(animations[i]) * 1000.0).round(),
              child: new InkResponse(
                onTap: () {
                  if (config.onTap != null)
                    config.onTap(i);
                },
                child: new Stack(
                  alignment: FractionalOffset.center,
                  children: <Widget>[
                    new Align(
                      alignment: FractionalOffset.topCenter,
                      child: new Container(
                        margin: new EdgeInsets.only(
                          top: new Tween<double>(
                            begin: 18.0,
                            end: 6.0,
                          ).evaluate(animations[i]),
                        ),
                        child: new IconTheme(
                          data: new IconThemeData(
                            color: Colors.white
                          ),
                          child: config.labels[i].icon,
                        ),
                      ),
                    ),
                    new Align(
                      alignment: FractionalOffset.bottomCenter,
                      child: new Container(
                        margin: const EdgeInsets.only(bottom: 10.0),
                        child: new FadeTransition(
                          opacity: animations[i],
                          child: new DefaultTextStyle(
                            style: new TextStyle(
                              fontSize: 14.0,
                              color: Colors.white
                            ),
                            child: config.labels[i].title
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        bottomNavigation = new SizedBox(
          width: _maxWidth,
          child: new Row(
            children: children
          )
        );
        break;
    }

    return new Stack(
      children: <Widget>[
        new Positioned.fill(
          child: new Material( // Casts shadow.
            elevation: 8,
            color: config.type == BottomNavigationBarType.shifting ? _backgroundColor : null
          )
        ),
        new SizedBox(
          height: kBottomNavigationBarHeight,
          child: new Center(
            child: new Stack(
              children: <Widget>[
                new Positioned(
                  left: 0.0,
                  top: 0.0,
                  right: 0.0,
                  bottom: 0.0,
                  child: new CustomPaint(
                    painter: new _RadialPainter(
                      circles: _circles.toList()
                    ),
                  ),
                ),
                new Material( // Splashes.
                  type: MaterialType.transparency,
                  child: new Center(
                    child: bottomNavigation
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Circle {
  _Circle({
    this.state,
    this.index,
    this.color,
    @required TickerProvider vsync,
  }) {
    assert(this.state != null);
    assert(this.index != null);
    assert(this.color != null);

    controller = new AnimationController(
      duration: kThemeAnimationDuration,
      vsync: vsync,
    );
    animation = new CurvedAnimation(
      parent: controller,
      curve: Curves.fastOutSlowIn
    );
    controller.forward();
  }

  final BottomNavigationBarState state;
  final int index;
  final Color color;
  AnimationController controller;
  CurvedAnimation animation;

  FractionalOffset get offset {
    return state.cirleOffset(index);
  }

  void dispose() {
    controller.dispose();
  }
}

class _RadialPainter extends CustomPainter {
  _RadialPainter({
    this.circles
  });

  final List<_Circle> circles;

  // Computes the maximum radius attainable such that at least one of the
  // bounding rectangle's corners touches the egde of the circle. Drawing a
  // circle beyond this radius is futile since there is no perceivable
  // difference within the cropped rectangle.
  double _maxRadius(FractionalOffset offset, Size size) {
    final double dx = offset.dx;
    final double dy = offset.dy;
    final double x = (dx > 0.5 ? dx : 1.0 - dx) * size.width;
    final double y = (dy > 0.5 ? dy : 1.0 - dy) * size.height;
    return math.sqrt(x * x + y * y);
  }

  @override
  bool shouldRepaint(_RadialPainter oldPainter) {
    if (circles == oldPainter.circles)
      return false;
    if (circles.length != oldPainter.circles.length)
      return true;

    for (int i = 0; i < circles.length; i += 1)
      if (circles[i] != oldPainter.circles[i])
        return true;

    return false;
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (_Circle circle in circles) {
      final Tween<double> radiusTween = new Tween<double>(
        begin: 0.0,
        end: _maxRadius(circle.offset, size)
      );
      final Paint paint = new Paint()..color = circle.color;
      final Rect rect = new Rect.fromLTWH(0.0, 0.0, size.width, size.height);
      canvas.clipRect(rect);
      canvas.drawCircle(
        circle.offset.withinRect(rect),
        radiusTween.lerp(circle.animation.value),
        paint
      );
    }
  }
}
