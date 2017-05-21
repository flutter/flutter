// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection' show Queue;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

import 'colors.dart';
import 'constants.dart';
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
///  * [BottomNavigationBarItem]
///  * <https://material.google.com/components/bottom-navigation.html#bottom-navigation-specs>
enum BottomNavigationBarType {
  /// The [BottomNavigationBar]'s [BottomNavigationBarItem]s have fixed width.
  fixed,

  /// The location and size of the [BottomNavigationBar] [BottomNavigationBarItem]s
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
class BottomNavigationBarItem {
  /// Creates an item that is used with [BottomNavigationBar.items].
  ///
  /// The arguments [icon] and [title] should not be null.
  BottomNavigationBarItem({
    @required this.icon,
    @required this.title,
    this.backgroundColor
  }) {
    assert(icon != null);
    assert(title != null);
  }

  /// The icon of the item.
  ///
  /// Typically the icon is an [Icon] or an [ImageIcon] widget. If another type
  /// of widget is provided then it should configure itself to match the current
  /// [IconTheme] size and color.
  final Widget icon;

  /// The title of the item.
  final Widget title;

  /// The color of the background radial animation.
  ///
  /// If the navigation bar's type is [BottomNavigationBarType.shifting], then
  /// the entire bar is flooded with the [backgroundColor] when this item is
  /// tapped.
  final Color backgroundColor;
}

/// A material widget displayed at the bottom of an app for selecting among a
/// small number of views.
///
/// The bottom navigation bar consists of multiple items in the form of
/// labels, icons, or both, laid out on top of a piece of material. It provides
/// quick navigation between the top-level views of an app. For larger screens,
/// side navigation may be a better fit.
///
/// A bottom navigation bar is usually used in conjunction with [Scaffold] where
/// it is provided as the [Scaffold.bottomNavigationBar] argument.
///
/// See also:
///
///  * [BottomNavigationBarItem]
///  * [Scaffold]
///  * <https://material.google.com/components/bottom-navigation.html>
class BottomNavigationBar extends StatefulWidget {
  /// Creates a bottom navigation bar, typically used in a [Scaffold] where it
  /// is provided as the [Scaffold.bottomNavigationBar] argument.
  ///
  /// The arguments [items] and [type] should not be null.
  ///
  /// The number of items passed should be equal or greater than 2.
  ///
  /// Passing a null [fixedColor] will cause a fallback to the theme's primary
  /// color.
  BottomNavigationBar({
    Key key,
    @required this.items,
    this.onTap,
    this.currentIndex: 0,
    this.type: BottomNavigationBarType.fixed,
    this.fixedColor,
    this.iconSize: 24.0,
  }) : super(key: key) {
    assert(items != null);
    assert(items.length >= 2);
    assert(0 <= currentIndex && currentIndex < items.length);
    assert(type != null);
    assert(type == BottomNavigationBarType.fixed || fixedColor == null);
    assert(iconSize != null);
  }

  /// The interactive items laid out within the bottom navigation bar.
  final List<BottomNavigationBarItem> items;

  /// The callback that is called when a item is tapped.
  ///
  /// The widget creating the bottom navigation bar needs to keep track of the
  /// current index and call `setState` to rebuild it with the newly provided
  /// index.
  final ValueChanged<int> onTap;

  /// The index into [items] of the current active item.
  final int currentIndex;

  /// Defines the layout and behavior of a [BottomNavigationBar].
  final BottomNavigationBarType type;

  /// The color of the selected item when bottom navigation bar is
  /// [BottomNavigationBarType.fixed].
  final Color fixedColor;

  /// The size of all of the [BottomNavigationBarItem] icons.
  ///
  /// This value is used to to configure the [IconTheme] for the navigation
  /// bar. When a [BottomNavigationBarItem.icon] widget is not an [Icon] the widget
  /// should configure itself to match the icon theme's size and color.
  final double iconSize;

  @override
  _BottomNavigationBarState createState() => new _BottomNavigationBarState();
}

class _BottomNavigationBarState extends State<BottomNavigationBar> with TickerProviderStateMixin {
  List<AnimationController> _controllers;
  List<CurvedAnimation> _animations;
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
    _controllers = new List<AnimationController>.generate(widget.items.length, (int index) {
      return new AnimationController(
        duration: kThemeAnimationDuration,
        vsync: this,
      )..addListener(_rebuild);
    });
    _animations = new List<CurvedAnimation>.generate(widget.items.length, (int index) {
      return new CurvedAnimation(
        parent: _controllers[index],
        curve: Curves.fastOutSlowIn,
        reverseCurve: Curves.fastOutSlowIn.flipped
      );
    });
    _controllers[widget.currentIndex].value = 1.0;
    _backgroundColor = widget.items[widget.currentIndex].backgroundColor;
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
      // Rebuilding when any of the controllers tick, i.e. when the items are
      // animated.
    });
  }

  double get _maxWidth {
    assert(widget.type != null);
    switch (widget.type) {
      case BottomNavigationBarType.fixed:
        return widget.items.length * _kActiveMaxWidth;
      case BottomNavigationBarType.shifting:
        return _kActiveMaxWidth + (widget.items.length - 1) * _kInactiveMaxWidth;
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
  // This causes instability in the animation when multiple items are tapped.
  // To solves this, we always store a weight that normalizes animating
  // animations such that their resulting flex values will add up to the desired
  // value.
  void _computeWeight() {
    final Iterable<Animation<double>> animating = _animations.where(_isAnimating);

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
      // We're adding flex values instead of animation values to have correct ratios.
      return animations.map(_flex).fold(0.0, (double sum, double value) => sum + value);
    }

    final double allWeights = weightSum(_animations);
    // This weight corresponds to the left edge of the indexed item.
    final double leftWeights = weightSum(_animations.sublist(0, index));

    // Add half of its flex value in order to get the center.
    return (leftWeights + _flex(_animations[index]) / 2.0) / allWeights;
  }

  FractionalOffset _circleOffset(int index) {
    final double iconSize = widget.iconSize;
    final Tween<double> yOffsetTween = new Tween<double>(
      begin: (18.0 + iconSize / 2.0) / kBottomNavigationBarHeight, // 18dp + icon center
      end: (6.0 + iconSize / 2.0) / kBottomNavigationBarHeight     // 6dp + icon center
    );

    return new FractionalOffset(
      _xOffset(index),
      yOffsetTween.evaluate(_animations[index])
    );
  }

  void _pushCircle(int index) {
    if (widget.items[index].backgroundColor != null)
      _circles.add(
        new _Circle(
          state: this,
          index: index,
          color: widget.items[index].backgroundColor,
          vsync: this,
        )..controller.addStatusListener((AnimationStatus status) {
          if (status == AnimationStatus.completed) {
            setState(() {
              final _Circle circle = _circles.removeFirst();
              _backgroundColor = circle.color;
              circle.dispose();
            });
          }
        })
      );
  }

  @override
  void didUpdateWidget(BottomNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      if (widget.type == BottomNavigationBarType.shifting)
        _pushCircle(widget.currentIndex);
      _controllers[oldWidget.currentIndex].reverse();
      _controllers[widget.currentIndex].forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget bottomNavigation;
    switch (widget.type) {
      case BottomNavigationBarType.fixed:
        final List<Widget> children = <Widget>[];
        final ThemeData themeData = Theme.of(context);
        final TextTheme textTheme = themeData.textTheme;
        final ColorTween colorTween = new ColorTween(
          begin: textTheme.caption.color,
          end: widget.fixedColor ?? (
            themeData.brightness == Brightness.light ?
                themeData.primaryColor : themeData.accentColor
          )
        );
        for (int i = 0; i < widget.items.length; i += 1) {
          children.add(
            new Expanded(
              child: new InkResponse(
                onTap: () {
                  if (widget.onTap != null)
                    widget.onTap(i);
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
                          ).evaluate(_animations[i]),
                        ),
                        child: new IconTheme(
                          data: new IconThemeData(
                            color: colorTween.evaluate(_animations[i]),
                            size: widget.iconSize,
                          ),
                          child: widget.items[i].icon,
                        ),
                      ),
                    ),
                    new Align(
                      alignment: FractionalOffset.bottomCenter,
                      child: new Container(
                        margin: const EdgeInsets.only(bottom: 10.0),
                        child: DefaultTextStyle.merge(
                          style: new TextStyle(
                            fontSize: 14.0,
                            color: colorTween.evaluate(_animations[i]),
                          ),
                          child: new Transform(
                            transform: new Matrix4.diagonal3(new Vector3.all(
                              new Tween<double>(
                                begin: 0.85,
                                end: 1.0,
                              ).evaluate(_animations[i]),
                            )),
                            alignment: FractionalOffset.bottomCenter,
                            child: widget.items[i].title,
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
        for (int i = 0; i < widget.items.length; i += 1) {
          children.add(
            new Expanded(
              // Since Flexible only supports integers, we're using large
              // numbers in order to simulate floating point flex values.
              flex: (_flex(_animations[i]) * 1000.0).round(),
              child: new InkResponse(
                onTap: () {
                  if (widget.onTap != null)
                    widget.onTap(i);
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
                          ).evaluate(_animations[i]),
                        ),
                        child: new IconTheme(
                          data: new IconThemeData(
                            color: Colors.white,
                            size: widget.iconSize,
                          ),
                          child: widget.items[i].icon,
                        ),
                      ),
                    ),
                    new Align(
                      alignment: FractionalOffset.bottomCenter,
                      child: new Container(
                        margin: const EdgeInsets.only(bottom: 10.0),
                        child: new FadeTransition(
                          opacity: _animations[i],
                          child: DefaultTextStyle.merge(
                            style: const TextStyle(
                              fontSize: 14.0,
                              color: Colors.white
                            ),
                            child: widget.items[i].title
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
            elevation: 8.0,
            color: widget.type == BottomNavigationBarType.shifting ? _backgroundColor : null
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
                      circles: _circles.toList(),
                      bottomNavMaxWidth: _maxWidth,
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
    @required this.state,
    @required this.index,
    @required this.color,
    @required TickerProvider vsync,
  }) {
    assert(state != null);
    assert(index != null);
    assert(color != null);

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

  final _BottomNavigationBarState state;
  final int index;
  final Color color;
  AnimationController controller;
  CurvedAnimation animation;

  FractionalOffset get offset {
    return state._circleOffset(index);
  }

  void dispose() {
    controller.dispose();
  }
}

class _RadialPainter extends CustomPainter {
  _RadialPainter({
    this.circles,
    this.bottomNavMaxWidth,
  });

  final List<_Circle> circles;
  final double bottomNavMaxWidth;

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
    if (bottomNavMaxWidth != oldPainter.bottomNavMaxWidth)
      return true;

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
      final double navWidth = math.min(bottomNavMaxWidth, size.width);
      final Offset center = new Offset(
        (size.width - navWidth) / 2.0 + circle.offset.dx * navWidth,
        circle.offset.dy * size.height
      );
      canvas.drawCircle(
        center,
        radiusTween.lerp(circle.animation.value),
        paint
      );
    }
  }
}
