// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection' show Queue;
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

import 'colors.dart';
import 'constants.dart';
import 'debug.dart';
import 'ink_well.dart';
import 'material.dart';
import 'material_localizations.dart';
import 'text_theme.dart';
import 'theme.dart';

/// Defines the layout and behavior of a [BottomNavigationBar].
///
/// See also:
///
///  * [BottomNavigationBar]
///  * [BottomNavigationBarItem]
///  * <https://material.io/design/components/bottom-navigation.html#specs>
enum BottomNavigationBarType {
  /// The [BottomNavigationBar]'s [BottomNavigationBarItem]s have fixed width.
  fixed,

  /// The location and size of the [BottomNavigationBar] [BottomNavigationBarItem]s
  /// animate and labels fade in when they are tapped.
  shifting,
}

/// A material widget that's displayed at the bottom of an app for selecting
/// among a small number of views, typically between three and five.
///
/// The bottom navigation bar consists of multiple items in the form of
/// text labels, icons, or both, laid out on top of a piece of material. It
/// provides quick navigation between the top-level views of an app. For larger
/// screens, side navigation may be a better fit.
///
/// A bottom navigation bar is usually used in conjunction with a [Scaffold],
/// where it is provided as the [Scaffold.bottomNavigationBar] argument.
///
/// The bottom navigation bar's [type] changes how its [items] are displayed.
/// If not specified, then it's automatically set to
/// [BottomNavigationBarType.fixed] when there are less than four items, and
/// [BottomNavigationBarType.shifting] otherwise.
///
///  * [BottomNavigationBarType.fixed], the default when there are less than
///    four [items]. The selected item is rendered with the
///    [selectedItemColor] if it's non-null, otherwise the theme's
///    [ThemeData.primaryColor] is used. If [backgroundColor] is null, The
///    navigation bar's background color defaults to the [Material] background
///    color, [ThemeData.canvasColor] (essentially opaque white).
///  * [BottomNavigationBarType.shifting], the default when there are four
///    or more [items]. If [selectedItemColor] is null, all items are rendered
///    in white. The navigation bar's background color is the same as the
///    [BottomNavigationBarItem.backgroundColor] of the selected item. In this
///    case it's assumed that each item will have a different background color
///    and that background color will contrast well with white.
///
/// {@tool snippet --template=stateful_widget_material}
/// This example shows a [BottomNavigationBar] as it is used within a [Scaffold]
/// widget. The [BottomNavigationBar] has three [BottomNavigationBarItem]
/// widgets and the [currentIndex] is set to index 0. The selected item is
/// amber. The `_onItemTapped` function changes the selected item's index
/// and displays a corresponding message in the center of the [Scaffold].
///
/// ![A scaffold with a bottom navigation bar containing three bottom navigation
/// bar items. The first one is selected.](https://flutter.github.io/assets-for-api-docs/assets/material/bottom_navigation_bar.png)
///
/// ```dart
/// int _selectedIndex = 0;
/// static const TextStyle optionStyle = TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
/// static const List<Widget> _widgetOptions = <Widget>[
///   Text(
///     'Index 0: Home',
///     style: optionStyle,
///   ),
///   Text(
///      'Index 1: Business',
///      style: optionStyle,
///   ),
///   Text(
///      'Index 2: School',
///      style: optionStyle,
///   ),
/// ];
///
/// void _onItemTapped(int index) {
///   setState(() {
///     _selectedIndex = index;
///   });
/// }
///
/// @override
/// Widget build(BuildContext context) {
///   return Scaffold(
///     appBar: AppBar(
///       title: const Text('BottomNavigationBar Sample'),
///     ),
///     body: Center(
///       child: _widgetOptions.elementAt(_selectedIndex),
///     ),
///     bottomNavigationBar: BottomNavigationBar(
///       items: const <BottomNavigationBarItem>[
///         BottomNavigationBarItem(
///           icon: Icon(Icons.home),
///           title: Text('Home'),
///         ),
///         BottomNavigationBarItem(
///           icon: Icon(Icons.business),
///           title: Text('Business'),
///         ),
///         BottomNavigationBarItem(
///           icon: Icon(Icons.school),
///           title: Text('School'),
///         ),
///       ],
///       currentIndex: _selectedIndex,
///       selectedItemColor: Colors.amber[800],
///       onTap: _onItemTapped,
///     ),
///   );
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [BottomNavigationBarItem]
///  * [Scaffold]
///  * <https://material.io/design/components/bottom-navigation.html>
class BottomNavigationBar extends StatefulWidget {
  /// Creates a bottom navigation bar which is typically used as a
  /// [Scaffold]'s [Scaffold.bottomNavigationBar] argument.
  ///
  /// The length of [items] must be at least two and each item's icon and title
  /// must not be null.
  ///
  /// If [type] is null then [BottomNavigationBarType.fixed] is used when there
  /// are two or three [items], [BottomNavigationBarType.shifting] otherwise.
  ///
  /// The [iconSize], [selectedFontSize], [unselectedFontSize], and [elevation]
  /// arguments must be non-null and non-negative.
  ///
  /// Only one of [selectedItemColor] and [fixedColor] can be specified. The
  /// former is preferred, [fixedColor] only exists for the sake of
  /// backwards compatibility.
  ///
  /// The [showSelectedLabels] argument must not be non-null.
  ///
  /// The [showUnselectedLabels] argument defaults to `true` if [type] is
  /// [BottomNavigationBarType.fixed] and `false` if [type] is
  /// [BottomNavigationBarType.shifting].
  BottomNavigationBar({
    Key key,
    @required this.items,
    this.onTap,
    this.currentIndex = 0,
    this.elevation = 8.0,
    BottomNavigationBarType type,
    Color fixedColor,
    this.backgroundColor,
    this.iconSize = 24.0,
    Color selectedItemColor,
    this.unselectedItemColor,
    this.selectedFontSize = 14.0,
    this.unselectedFontSize = 12.0,
    this.showSelectedLabels = true,
    bool showUnselectedLabels,
  }) : assert(items != null),
       assert(items.length >= 2),
       assert(
        items.every((BottomNavigationBarItem item) => item.title != null) == true,
        'Every item must have a non-null title',
       ),
       assert(0 <= currentIndex && currentIndex < items.length),
       assert(elevation != null && elevation >= 0.0),
       assert(iconSize != null && iconSize >= 0.0),
       assert(
         selectedItemColor != null ? fixedColor == null : true,
         'Either selectedItemColor or fixedColor can be specified, but not both'
       ),
       assert(selectedFontSize != null && selectedFontSize >= 0.0),
       assert(unselectedFontSize != null && unselectedFontSize >= 0.0),
       assert(showSelectedLabels != null),
       type = _type(type, items),
       selectedItemColor = selectedItemColor ?? fixedColor,
       showUnselectedLabels = showUnselectedLabels ?? _defaultShowUnselected(_type(type, items)),
       super(key: key);

  /// Defines the appearance of the button items that are arrayed within the
  /// bottom navigation bar.
  final List<BottomNavigationBarItem> items;

  /// Called when one of the [items] is tapped.
  ///
  /// The stateful widget that creates the bottom navigation bar needs to keep
  /// track of the index of the selected [BottomNavigationBarItem] and call
  /// `setState` to rebuild the bottom navigation bar with the new [currentIndex].
  final ValueChanged<int> onTap;

  /// The index into [items] for the current active [BottomNavigationBarItem].
  final int currentIndex;

  /// The z-coordinate of this [BottomNavigationBar].
  ///
  /// If null, defaults to `8.0`.
  ///
  /// {@macro flutter.material.material.elevation}
  final double elevation;

  /// Defines the layout and behavior of a [BottomNavigationBar].
  ///
  /// See documentation for [BottomNavigationBarType] for information on the
  /// meaning of different types.
  final BottomNavigationBarType type;

  /// The value of [selectedItemColor].
  ///
  /// This getter only exists for backwards compatibility, the
  /// [selectedItemColor] property is preferred.
  Color get fixedColor => selectedItemColor;

  /// The color of the [BottomNavigationBar] itself.
  ///
  /// If [type] is [BottomNavigationBarType.shifting] and the
  /// [items]s, have [BottomNavigationBarItem.backgroundColor] set, the [item]'s
  /// backgroundColor will splash and overwrite this color.
  final Color backgroundColor;

  /// The size of all of the [BottomNavigationBarItem] icons.
  ///
  /// See [BottomNavigationBarItem.icon] for more information.
  final double iconSize;

  /// The color of the selected [BottomNavigationBarItem.icon] and
  /// [BottomNavigationBarItem.label].
  ///
  /// If null then the [ThemeData.primaryColor] is used.
  final Color selectedItemColor;

  /// The color of the unselected [BottomNavigationBarItem.icon] and
  /// [BottomNavigationBarItem.label]s.
  ///
  /// If null then the [TextTheme.caption]'s color is used.
  final Color unselectedItemColor;

  /// The font size of the [BottomNavigationBarItem] labels when they are selected.
  ///
  /// Defaults to `14.0`.
  final double selectedFontSize;

  /// The font size of the [BottomNavigationBarItem] labels when they are not
  /// selected.
  ///
  /// Defaults to `12.0`.
  final double unselectedFontSize;

  /// Whether the labels are shown for the selected [BottomNavigationBarItem].
  final bool showUnselectedLabels;

  /// Whether the labels are shown for the unselected [BottomNavigationBarItem]s.
  final bool showSelectedLabels;

  // Used by the [BottomNavigationBar] constructor to set the [type] parameter.
  //
  // If type is provided, it is returned. Otherwise,
  // [BottomNavigationBarType.fixed] is used for 3 or fewer items, and
  // [BottomNavigationBarType.shifting] is used for 4+ items.
  static BottomNavigationBarType _type(
      BottomNavigationBarType type,
      List<BottomNavigationBarItem> items,
  ) {
    if (type != null) {
      return type;
    }
    return items.length <= 3 ? BottomNavigationBarType.fixed : BottomNavigationBarType.shifting;
  }

  // Used by the [BottomNavigationBar] constructor to set the [showUnselected]
  // parameter.
  //
  // Unselected labels are shown by default for [BottomNavigationBarType.fixed],
  // and hidden by default for [BottomNavigationBarType.shifting].
  static bool _defaultShowUnselected(BottomNavigationBarType type) {
    switch (type) {
      case BottomNavigationBarType.shifting:
        return false;
      case BottomNavigationBarType.fixed:
        return true;
    }
    assert(false);
    return false;
  }

  @override
  _BottomNavigationBarState createState() => _BottomNavigationBarState();
}

// This represents a single tile in the bottom navigation bar. It is intended
// to go into a flex container.
class _BottomNavigationTile extends StatelessWidget {
  const _BottomNavigationTile(
    this.type,
    this.item,
    this.animation,
    this.iconSize, {
    this.onTap,
    this.colorTween,
    this.flex,
    this.selected = false,
    @required this.selectedFontSize,
    @required this.unselectedFontSize,
    this.showSelectedLabels,
    this.showUnselectedLabels,
    this.indexLabel,
    }) : assert(type != null),
         assert(item != null),
         assert(animation != null),
         assert(selected != null),
         assert(selectedFontSize != null && selectedFontSize >= 0),
         assert(unselectedFontSize != null && unselectedFontSize >= 0);

  final BottomNavigationBarType type;
  final BottomNavigationBarItem item;
  final Animation<double> animation;
  final double iconSize;
  final VoidCallback onTap;
  final ColorTween colorTween;
  final double flex;
  final bool selected;
  final double selectedFontSize;
  final double unselectedFontSize;
  final String indexLabel;
  final bool showSelectedLabels;
  final bool showUnselectedLabels;

  @override
  Widget build(BuildContext context) {
    // In order to use the flex container to grow the tile during animation, we
    // need to divide the changes in flex allotment into smaller pieces to
    // produce smooth animation. We do this by multiplying the flex value
    // (which is an integer) by a large number.
    int size;

    double bottomPadding = selectedFontSize / 2.0;
    double topPadding = selectedFontSize / 2.0;

    // Defines the padding for the animating icons + labels.
    //
    // The animations go from "Unselected":
    // =======
    // |      <-- Padding equal to the text height.
    // |  ☆
    // | text <-- Invisible text.
    // =======
    //
    // To "Selected":
    //
    // =======
    // |      <-- Padding equal to 1/2 text height.
    // |  ☆
    // | text
    // |      <-- Padding equal to 1/2 text height.
    // =======
    if (showSelectedLabels && !showUnselectedLabels) {
      bottomPadding = Tween<double>(
        begin: 0.0,
        end: selectedFontSize / 2.0,
      ).evaluate(animation);
      topPadding = Tween<double>(
        begin: selectedFontSize,
        end: selectedFontSize / 2.0,
      ).evaluate(animation);
    }

    // Center all icons if no labels are shown.
    if (!showSelectedLabels && !showUnselectedLabels) {
      bottomPadding = 0.0;
      topPadding = selectedFontSize;
    }

    switch (type) {
      case BottomNavigationBarType.fixed:
        size = 1;
        break;
      case BottomNavigationBarType.shifting:
        size = (flex * 1000.0).round();
        break;
    }

    return Expanded(
      flex: size,
      child: Semantics(
        container: true,
        header: true,
        selected: selected,
        child: Stack(
          children: <Widget>[
            InkResponse(
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _TileIcon(
                      colorTween: colorTween,
                      animation: animation,
                      iconSize: iconSize,
                      selected: selected,
                      item: item,
                    ),
                    _Label(
                      colorTween: colorTween,
                      animation: animation,
                      item: item,
                      selectedFontSize: selectedFontSize,
                      unselectedFontSize: unselectedFontSize,
                      showSelectedLabels: showSelectedLabels,
                      showUnselectedLabels: showUnselectedLabels,
                    ),
                  ],
                ),
              ),
            ),
            Semantics(
              label: indexLabel,
            ),
          ],
        ),
      ),
    );
  }
}


class _TileIcon extends StatelessWidget {
  const _TileIcon({
    Key key,
    @required this.colorTween,
    @required this.animation,
    @required this.iconSize,
    @required this.selected,
    @required this.item,
  }) : assert(selected != null),
       assert(item != null),
       super(key: key);

  final ColorTween colorTween;
  final Animation<double> animation;
  final double iconSize;
  final bool selected;
  final BottomNavigationBarItem item;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = colorTween.evaluate(animation);
    return Align(
      alignment: Alignment.topCenter,
      heightFactor: 1.0,
      child: Container(
        child: IconTheme(
          data: IconThemeData(
            color: iconColor,
            size: iconSize,
          ),
          child: selected ? item.activeIcon : item.icon,
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({
    Key key,
    @required this.colorTween,
    @required this.animation,
    @required this.item,
    @required this.selectedFontSize,
    @required this.unselectedFontSize,
    @required this.showSelectedLabels,
    @required this.showUnselectedLabels,
  }) : assert(colorTween != null),
       assert(animation != null),
       assert(item != null),
       assert(selectedFontSize != null),
       assert(unselectedFontSize != null),
       assert(showSelectedLabels != null),
       assert(showUnselectedLabels != null),
       super(key: key);

  final ColorTween colorTween;
  final Animation<double> animation;
  final BottomNavigationBarItem item;
  final double selectedFontSize;
  final double unselectedFontSize;
  final bool showSelectedLabels;
  final bool showUnselectedLabels;

  @override
  Widget build(BuildContext context) {
    Widget text = DefaultTextStyle.merge(
      style: TextStyle(
        fontSize: selectedFontSize,
        color: colorTween.evaluate(animation),
      ),
      // The font size should grow here when active, but because of the way
      // font rendering works, it doesn't grow smoothly if we just animate
      // the font size, so we use a transform instead.
      child: Transform(
        transform: Matrix4.diagonal3(
          Vector3.all(
            Tween<double>(
              begin: unselectedFontSize / selectedFontSize,
              end: 1.0,
            ).evaluate(animation),
          ),
        ),
        alignment: Alignment.bottomCenter,
        child: item.title,
      ),
    );

    if (!showUnselectedLabels && !showSelectedLabels) {
      // Never show any labels.
      text = Opacity(
        alwaysIncludeSemantics: true,
        opacity: 0.0,
        child: text,
      );
    } else if (!showUnselectedLabels) {
      // Fade selected labels in.
      text = FadeTransition(
        alwaysIncludeSemantics: true,
        opacity: animation,
        child: text,
      );
    } else if (!showSelectedLabels) {
      // Fade selected labels out.
      text = FadeTransition(
        alwaysIncludeSemantics: true,
        opacity: Tween<double>(begin: 1.0, end: 0.0).animate(animation),
        child: text,
      );
    }

    return Align(
      alignment: Alignment.bottomCenter,
      heightFactor: 1.0,
      child: Container(child: text),
    );
  }
}

class _BottomNavigationBarState extends State<BottomNavigationBar> with TickerProviderStateMixin {
  List<AnimationController> _controllers = <AnimationController>[];
  List<CurvedAnimation> _animations;

  // A queue of color splashes currently being animated.
  final Queue<_Circle> _circles = Queue<_Circle>();

  // Last splash circle's color, and the final color of the control after
  // animation is complete.
  Color _backgroundColor;

  static final Animatable<double> _flexTween = Tween<double>(begin: 1.0, end: 1.5);

  void _resetState() {
    for (AnimationController controller in _controllers)
      controller.dispose();
    for (_Circle circle in _circles)
      circle.dispose();
    _circles.clear();

    _controllers = List<AnimationController>.generate(widget.items.length, (int index) {
      return AnimationController(
        duration: kThemeAnimationDuration,
        vsync: this,
      )..addListener(_rebuild);
    });
    _animations = List<CurvedAnimation>.generate(widget.items.length, (int index) {
      return CurvedAnimation(
        parent: _controllers[index],
        curve: Curves.fastOutSlowIn,
        reverseCurve: Curves.fastOutSlowIn.flipped,
      );
    });
    _controllers[widget.currentIndex].value = 1.0;
    _backgroundColor = widget.items[widget.currentIndex].backgroundColor;
  }

  @override
  void initState() {
    super.initState();
    _resetState();
  }

  void _rebuild() {
    setState(() {
      // Rebuilding when any of the controllers tick, i.e. when the items are
      // animated.
    });
  }

  @override
  void dispose() {
    for (AnimationController controller in _controllers)
      controller.dispose();
    for (_Circle circle in _circles)
      circle.dispose();
    super.dispose();
  }

  double _evaluateFlex(Animation<double> animation) => _flexTween.evaluate(animation);

  void _pushCircle(int index) {
    if (widget.items[index].backgroundColor != null) {
      _circles.add(
        _Circle(
          state: this,
          index: index,
          color: widget.items[index].backgroundColor,
          vsync: this,
        )..controller.addStatusListener(
          (AnimationStatus status) {
            switch (status) {
              case AnimationStatus.completed:
                setState(() {
                  final _Circle circle = _circles.removeFirst();
                  _backgroundColor = circle.color;
                  circle.dispose();
                });
                break;
              case AnimationStatus.dismissed:
              case AnimationStatus.forward:
              case AnimationStatus.reverse:
                break;
            }
          },
        ),
      );
    }
  }

  @override
  void didUpdateWidget(BottomNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // No animated segue if the length of the items list changes.
    if (widget.items.length != oldWidget.items.length) {
      _resetState();
      return;
    }

    if (widget.currentIndex != oldWidget.currentIndex) {
      switch (widget.type) {
        case BottomNavigationBarType.fixed:
          break;
        case BottomNavigationBarType.shifting:
          _pushCircle(widget.currentIndex);
          break;
      }
      _controllers[oldWidget.currentIndex].reverse();
      _controllers[widget.currentIndex].forward();
    } else {
      if (_backgroundColor != widget.items[widget.currentIndex].backgroundColor)
        _backgroundColor = widget.items[widget.currentIndex].backgroundColor;
    }
  }

  List<Widget> _createTiles() {
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    assert(localizations != null);

    final ThemeData themeData = Theme.of(context);

    Color themeColor;
    switch (themeData.brightness) {
      case Brightness.light:
        themeColor = themeData.primaryColor;
        break;
      case Brightness.dark:
        themeColor = themeData.accentColor;
        break;
    }

    ColorTween colorTween;
    switch (widget.type) {
      case BottomNavigationBarType.fixed:
        colorTween = ColorTween(
          begin: widget.unselectedItemColor ?? themeData.textTheme.caption.color,
          end: widget.selectedItemColor ?? widget.fixedColor ?? themeColor,
        );
        break;
      case BottomNavigationBarType.shifting:
        colorTween = ColorTween(
          begin: widget.unselectedItemColor ?? Colors.white,
          end: widget.selectedItemColor ?? Colors.white,
        );
        break;
    }

    final List<Widget> tiles = <Widget>[];
    for (int i = 0; i < widget.items.length; i++) {
      tiles.add(_BottomNavigationTile(
        widget.type,
        widget.items[i],
        _animations[i],
        widget.iconSize,
        selectedFontSize: widget.selectedFontSize,
        unselectedFontSize: widget.unselectedFontSize,
        onTap: () {
          if (widget.onTap != null)
            widget.onTap(i);
        },
        colorTween: colorTween,
        flex: _evaluateFlex(_animations[i]),
        selected: i == widget.currentIndex,
        showSelectedLabels: widget.showSelectedLabels,
        showUnselectedLabels: widget.showUnselectedLabels,
        indexLabel: localizations.tabLabel(tabIndex: i + 1, tabCount: widget.items.length),
      ));
    }
    return tiles;
  }

  Widget _createContainer(List<Widget> tiles) {
    return DefaultTextStyle.merge(
      overflow: TextOverflow.ellipsis,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: tiles,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasDirectionality(context));
    assert(debugCheckHasMaterialLocalizations(context));
    assert(debugCheckHasMediaQuery(context));

    // Labels apply up to _bottomMargin padding. Remainder is media padding.
    final double additionalBottomPadding = math.max(MediaQuery.of(context).padding.bottom - widget.selectedFontSize / 2.0, 0.0);
    Color backgroundColor;
    switch (widget.type) {
      case BottomNavigationBarType.fixed:
        backgroundColor = widget.backgroundColor;
        break;
      case BottomNavigationBarType.shifting:
        backgroundColor = _backgroundColor;
        break;
    }
    return Semantics(
      explicitChildNodes: true,
      child: Material(
        elevation: widget.elevation,
        color: backgroundColor,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: kBottomNavigationBarHeight + additionalBottomPadding),
          child: CustomPaint(
            painter: _RadialPainter(
              circles: _circles.toList(),
              textDirection: Directionality.of(context),
            ),
            child: Material( // Splashes.
              type: MaterialType.transparency,
              child: Padding(
                padding: EdgeInsets.only(bottom: additionalBottomPadding),
                child: MediaQuery.removePadding(
                  context: context,
                  removeBottom: true,
                  child: _createContainer(_createTiles()),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Describes an animating color splash circle.
class _Circle {
  _Circle({
    @required this.state,
    @required this.index,
    @required this.color,
    @required TickerProvider vsync,
  }) : assert(state != null),
       assert(index != null),
       assert(color != null) {
    controller = AnimationController(
      duration: kThemeAnimationDuration,
      vsync: vsync,
    );
    animation = CurvedAnimation(
      parent: controller,
      curve: Curves.fastOutSlowIn,
    );
    controller.forward();
  }

  final _BottomNavigationBarState state;
  final int index;
  final Color color;
  AnimationController controller;
  CurvedAnimation animation;

  double get horizontalLeadingOffset {
    double weightSum(Iterable<Animation<double>> animations) {
      // We're adding flex values instead of animation values to produce correct
      // ratios.
      return animations.map<double>(state._evaluateFlex).fold<double>(0.0, (double sum, double value) => sum + value);
    }

    final double allWeights = weightSum(state._animations);
    // These weights sum to the start edge of the indexed item.
    final double leadingWeights = weightSum(state._animations.sublist(0, index));

    // Add half of its flex value in order to get to the center.
    return (leadingWeights + state._evaluateFlex(state._animations[index]) / 2.0) / allWeights;
  }

  void dispose() {
    controller.dispose();
  }
}

// Paints the animating color splash circles.
class _RadialPainter extends CustomPainter {
  _RadialPainter({
    @required this.circles,
    @required this.textDirection,
  }) : assert(circles != null),
       assert(textDirection != null);

  final List<_Circle> circles;
  final TextDirection textDirection;

  // Computes the maximum radius attainable such that at least one of the
  // bounding rectangle's corners touches the edge of the circle. Drawing a
  // circle larger than this radius is not needed, since there is no perceivable
  // difference within the cropped rectangle.
  static double _maxRadius(Offset center, Size size) {
    final double maxX = math.max(center.dx, size.width - center.dx);
    final double maxY = math.max(center.dy, size.height - center.dy);
    return math.sqrt(maxX * maxX + maxY * maxY);
  }

  @override
  bool shouldRepaint(_RadialPainter oldPainter) {
    if (textDirection != oldPainter.textDirection)
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
      final Paint paint = Paint()..color = circle.color;
      final Rect rect = Rect.fromLTWH(0.0, 0.0, size.width, size.height);
      canvas.clipRect(rect);
      double leftFraction;
      switch (textDirection) {
        case TextDirection.rtl:
          leftFraction = 1.0 - circle.horizontalLeadingOffset;
          break;
        case TextDirection.ltr:
          leftFraction = circle.horizontalLeadingOffset;
          break;
      }
      final Offset center = Offset(leftFraction * size.width, size.height / 2.0);
      final Tween<double> radiusTween = Tween<double>(
        begin: 0.0,
        end: _maxRadius(center, size),
      );
      canvas.drawCircle(
        center,
        radiusTween.transform(circle.animation.value),
        paint,
      );
    }
  }
}
