// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../scheduler.dart';

/// TODO
class NavigationRail extends StatefulWidget {
  /// TODO
  NavigationRail({
    this.backgroundColor,
    this.extended,
    this.leading,
    this.trailing,
    @required this.destinations,
    this.currentIndex = 0,
    this.onDestinationSelected,
    this.elevation,
    this.groupAlignment,
    this.labelType,
    this.unselectedLabelTextStyle,
    this.selectedLabelTextStyle,
    this.unselectedIconTheme,
    this.selectedIconTheme,
    this.preferredWidth = _railWidth,
    this.extendedWidth = _extendedRailWidth,
  }) :  assert(destinations != null && destinations.isNotEmpty),
        assert(0 <= currentIndex && currentIndex < destinations.length),
        assert(extendedWidth >= _railWidth);
       // TODO: assert that extended has to be labelType none

  /// Sets the color of the Container that holds all of the [NavigationRail]'s
  /// contents.
  final Color backgroundColor;

  /// Indicates of the [NavigationRail] should be in the extended state.
  ///
  /// The rail will implicitly animate between the extended and normal state.
  ///
  /// If the rail is going to be in the extended state, then the [labelType]
  /// should be set to [NavigationRailLabelType.none].
  final bool extended;

  /// The leading widget in the rail that is placed above the destinations.
  ///
  /// This is commonly a [FloatingActionButton], but may also be a non-button,
  /// such as a logo.
  final Widget leading;

  /// The trailing widget in the rail that is placed below the destinations.
  ///
  /// This is commonly a list of additional options or destinations that is
  /// usually only rendered when [extended] is true.
  final Widget trailing;

  /// Defines the appearance of the button items that are arrayed within the
  /// navigation rail.
  final List<NavigationRailDestination> destinations;

  /// The index into [destinations] for the current active
  /// [NavigationRailDestination].
  final int currentIndex;

  /// Called when one of the [destinations] is selected.
  ///
  /// The stateful widget that creates the navigation rail needs to keep
  /// track of the index of the selected [NavigationRailDestination] and call
  /// `setState` to rebuild the navigation rail with the new [currentIndex].
  final ValueChanged<int> onDestinationSelected;

  /// The elevation for the inner side of the rail.
  ///
  /// The shadow only shows on the inner side of the rail.
  ///
  /// In LTR configurations, the inner side is the right side, and in RTL
  /// configurations, it is the left side.
  final double elevation;

  /// The alignment for the [NavigationRailDestination]s as they are positioned
  /// within the [NavigationRail].
  ///
  /// Navigation rail destinations can be aligned as a group to the [top],
  /// [bottom], or [center] of a layout.
  final NavigationRailGroupAlignment groupAlignment;

  /// Defines the layout and behavior of the labels in the [NavigationRail].
  ///
  /// See also:
  ///
  ///   * [NavigationRailLabelType] for information on the meaning of different
  ///   types.
  final NavigationRailLabelType labelType;

  /// The [TextStyle] of the unselected [NavigationRailDestination] labels.
  ///
  /// When the [NavigationRailDestination] is selected, the
  /// [selectedLabelTextStyle] will be used instead.
  final TextStyle unselectedLabelTextStyle;

  /// The [TextStyle] of the [NavigationRailDestination] labels when they are
  /// selected.
  ///
  /// When the [NavigationRailDestination] is not selected,
  /// [unselectedLabelTextStyle] will be used.
  final TextStyle selectedLabelTextStyle;

  /// The default size, opacity, and color of the icon in the
  /// [NavigationRailDestination].
  ///
  /// If this field is not provided, or provided with any null properties, then
  /// a copy of the [IconThemeData.fallback] with a custom [NavigationRail]
  /// specific color will be used.
  final IconThemeData unselectedIconTheme;

  /// The size, opacity, and color of the icon in the selected
  /// [NavigationRailDestination].
  ///
  /// When the [NavigationRailDestination] is not selected,
  /// [unselectedIconTheme] will be used.
  final IconThemeData selectedIconTheme;

  /// The smallest possible width for the rail regardless of the destination
  /// content size.
  ///
  /// The default is 72.
  ///
  /// This value also defines the min width and min height of the destination
  /// boxes.
  ///
  /// To make a compact rail, set this to 56 and use
  /// [NavigationRailLabelType.none].
  final double preferredWidth;

  /// The final width when the animation is complete for setting [extended] to
  /// true.
  ///
  /// The default value is 256.
  final double extendedWidth;

  /// Returns the animation that controls the [NavigationRail.extended] state.
  ///
  /// This can be used to synchronize animations in the [leading] or [trailing]
  /// widget, such as an animated menu or a [FloatingActionButton] animation.
  static Animation<double> extendedAnimation(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ExtendedNavigationRailAnimation>().animation;
  }

  @override
  _NavigationRailState createState() => _NavigationRailState();
}

class _NavigationRailState extends State<NavigationRail> with TickerProviderStateMixin {
  List<AnimationController> _destinationControllers = <AnimationController>[];
  List<Animation<double>> _destinationAnimations;
  AnimationController _extendedController;
  Animation<double> _extendedAnimation;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  void didUpdateWidget(NavigationRail oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.extended != oldWidget.extended) {
      if (widget.extended) {
        _extendedController.forward();
      } else {
        _extendedController.reverse();
      }
    }

    // No animated segue if the length of the items list changes.
    if (widget.destinations.length != oldWidget.destinations.length) {
      _resetState();
      return;
    }

    if (widget.currentIndex != oldWidget.currentIndex) {
      _destinationControllers[oldWidget.currentIndex].reverse();
      _destinationControllers[widget.currentIndex].forward();
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final NavigationRailThemeData navigationRailTheme = Theme.of(context).navigationRailTheme;
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);

    final Color backgroundColor = widget.backgroundColor ?? navigationRailTheme.backgroundColor ?? Theme.of(context).colorScheme.surface;
    final double elevation = widget.elevation ?? navigationRailTheme.elevation ?? 0;
    final Color baseSelectedColor = Theme.of(context).colorScheme.primary;
    final Color baseColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.64);
    final IconThemeData unselectedIconTheme = const IconThemeData.fallback().copyWith(color: baseColor).merge(widget.unselectedIconTheme ?? navigationRailTheme.unselectedIconTheme);
    final IconThemeData selectedIconTheme = const IconThemeData.fallback().copyWith(color: baseSelectedColor).merge(widget.selectedIconTheme ?? navigationRailTheme.selectedIconTheme);
    final TextStyle unselectedLabelTextStyle = TextStyle(color: baseColor, fontSize: 14.0).merge(widget.unselectedLabelTextStyle ?? navigationRailTheme.unselectedLabelTextStyle);
    final TextStyle selectedLabelTextStyle = TextStyle(color: baseSelectedColor, fontSize: 14.0).merge(widget.selectedLabelTextStyle ?? navigationRailTheme.selectedLabelTextStyle);
    final NavigationRailGroupAlignment groupAlignment = widget.groupAlignment ?? navigationRailTheme.groupAlignment ?? NavigationRailGroupAlignment.top;
    final NavigationRailLabelType labelType = widget.labelType ?? navigationRailTheme.labelType ?? NavigationRailLabelType.none;
    final MainAxisAlignment destinationsAlignment = _resolveGroupAlignment(groupAlignment);

    return _ExtendedNavigationRailAnimation(
      animation: _extendedAnimation,
      child: Semantics(
        explicitChildNodes: true,
        child: Material(
          elevation: elevation,
          color: backgroundColor,
          child: Column(
            children: <Widget>[
              _verticalSpacer,
              if (widget.leading != null)
                ...<Widget>[
                  if (_extendedAnimation.value > 0)
                    SizedBox(
                      width: lerpDouble(widget.preferredWidth, widget.extendedWidth, _extendedAnimation.value),
                      child: widget.leading,
                    )
                  else
                    widget.leading,
                  _verticalSpacer,
                ],
              Expanded(
                child: Column(
                  mainAxisAlignment: destinationsAlignment,
                  children: <Widget>[
                    for (int i = 0; i < widget.destinations.length; i++)
                      _RailDestinationBox(
                        width: widget.preferredWidth,
                        extendedWidth: widget.extendedWidth,
                        extendedTransitionAnimation: _extendedAnimation,
                        selected: widget.currentIndex == i,
                        icon: widget.currentIndex == i ? widget.destinations[i].activeIcon : widget.destinations[i].icon,
                        label: widget.destinations[i].label,
                        destinationAnimation: _destinationAnimations[i],
                        labelType: labelType,
                        iconTheme: widget.currentIndex == i ? selectedIconTheme : unselectedIconTheme,
                        labelTextStyle: widget.currentIndex == i ? selectedLabelTextStyle : unselectedLabelTextStyle,
                        onTap: () {
                          widget.onDestinationSelected(i);
                        },
                        indexLabel: localizations.tabLabel(
                          tabIndex: i + 1,
                          tabCount: widget.destinations.length,
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.trailing != null)
                if (_extendedAnimation.value > 0)
                  SizedBox(
                    width: lerpDouble(widget.preferredWidth, widget.extendedWidth, _extendedAnimation.value),
                    child: widget.trailing,
                  )
                else
                  widget.trailing,
            ],
          ),
        ),
      ),
    );
  }

  MainAxisAlignment _resolveGroupAlignment(NavigationRailGroupAlignment groupAlignment) {
    switch (groupAlignment) {
      case NavigationRailGroupAlignment.top:
        return MainAxisAlignment.start;
      case NavigationRailGroupAlignment.center:
        return MainAxisAlignment.center;
      case NavigationRailGroupAlignment.bottom:
        return MainAxisAlignment.end;
    }
    return MainAxisAlignment.start;
  }

  void _disposeControllers() {
    for (final AnimationController controller in _destinationControllers)
      controller.dispose();
    _extendedController.dispose();
  }

  void _initControllers() {
    _destinationControllers = List<AnimationController>.generate(widget.destinations.length, (int index) {
      return AnimationController(
        duration: kThemeAnimationDuration,
        vsync: this,
      )..addListener(_rebuild);
    });
    _destinationAnimations = _destinationControllers.map((AnimationController controller) => controller.view).toList();
    _destinationControllers[widget.currentIndex].value = 1.0;
    _extendedController = AnimationController(
      duration: kThemeAnimationDuration,
      vsync: this,

    );
    _extendedAnimation = CurvedAnimation(
      parent: _extendedController,
      curve: Curves.easeInOut,
    );
    _extendedController.addListener(() {
      setState(() {
        // Rebuild.
      });
    });
  }

  void _resetState() {
    _disposeControllers();
    _initControllers();
  }

  void _rebuild() {
    setState(() {
      // Rebuilding when any of the controllers tick, i.e. when the items are
      // animated.
    });
  }
}

class _RailDestinationBox extends StatelessWidget {
  _RailDestinationBox({
    @required this.width,
    this.extendedWidth,
    @required this.icon,
    @required this.label,
    @required this.destinationAnimation,
    @required this.extendedTransitionAnimation,
    @required this.labelType,
    @required this.selected,
    @required this.iconTheme,
    @required this.labelTextStyle,
    @required this.onTap,
    this.indexLabel,
  }) : assert(width != null),
       assert(icon != null),
       assert(label != null),
       assert(destinationAnimation != null),
       assert(extendedTransitionAnimation != null),
       assert(labelType != null),
       assert(selected != null),
       assert(iconTheme != null),
       assert(labelTextStyle != null),
       assert(onTap != null),
       _positionAnimation = CurvedAnimation(
          parent: ReverseAnimation(destinationAnimation),
          curve: Curves.easeInOut,
          reverseCurve: Curves.easeInOut.flipped,
       );

  final double width;
  final double extendedWidth;
  final Widget icon;
  final Widget label;
  final Animation<double> destinationAnimation;
  final NavigationRailLabelType labelType;
  final bool selected;
  final Animation<double> extendedTransitionAnimation;
  final IconThemeData iconTheme;
  final TextStyle labelTextStyle;
  final VoidCallback onTap;
  final String indexLabel;

  final Animation<double> _positionAnimation;
  
  @override
  Widget build(BuildContext context) {
    final Widget themedIcon = IconTheme(
      data: iconTheme,
      child: icon,
    );
    final Widget styledLabel = DefaultTextStyle.merge(
      style: labelTextStyle,
      child: label,
    );
    Widget content;
    switch (labelType) {
      case NavigationRailLabelType.none:
        if (extendedTransitionAnimation.value == 0) {
          content = Stack(
            children: <Widget>[
              SizedBox(
                width: width,
                height: width,
                child: themedIcon,
              ),
              // For semantics when label is not showing,
              SizedBox(
                width: 0,
                height: 0,
                child: Opacity(
                  alwaysIncludeSemantics: true,
                  opacity: 0.0,
                  child: label,
                ),
              ),
            ]
          );
        } else {
          final TextDirection textDirection = Directionality.of(context);
          content = SizedBox(
            width: lerpDouble(width, extendedWidth, extendedTransitionAnimation.value),
            child: Stack(
              children: <Widget>[
                Positioned(
                  child: SizedBox(
                    width: width,
                    height: width,
                    child: themedIcon,
                  ),
                ),
                Positioned.directional(
                  textDirection: textDirection,
                  start: width,
                  height: width,
                  child: Opacity(
                    alwaysIncludeSemantics: true,
                    opacity: _extendedLabelFadeValue(),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: styledLabel,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        break;
      case NavigationRailLabelType.selected:
        final double appearingAnimationValue = 1 - _positionAnimation.value;
        final double lerpedPadding = lerpDouble(_verticalDestinationPaddingNoLabel, _verticalDestinationPaddingWithLabel, appearingAnimationValue);
        content = Container(
          constraints: BoxConstraints(
            minWidth: width,
            minHeight: width,
          ),
          padding: const EdgeInsets.symmetric(horizontal: _horizontalDestinationPadding),
          child: ClipRect(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(height: lerpedPadding),
                themedIcon,
                Align(
                  alignment: Alignment.topCenter,
                  heightFactor: appearingAnimationValue,
                  widthFactor: 1.0,
                  child: Opacity(
                    alwaysIncludeSemantics: true,
                    opacity: selected ? _normalLabelFadeInValue() : _normalLabelFadeOutValue(),
                    child: styledLabel,
                  ),
                ),
                SizedBox(height: lerpedPadding),
              ],
            ),
          ),
        );
        break;
      case NavigationRailLabelType.all:
        content = Container(
          constraints: BoxConstraints(
            minWidth: width,
            minHeight: width,
          ),
          padding: const EdgeInsets.symmetric(horizontal: _horizontalDestinationPadding),
          child: Column(
            children: <Widget>[
              const SizedBox(height: _verticalDestinationPaddingWithLabel),
              themedIcon,
              styledLabel,
              const SizedBox(height: _verticalDestinationPaddingWithLabel),
            ],
          ),
        );
        break;
    }

    final ColorScheme colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      selected: selected,
      child: Stack(
        children: <Widget>[
          Material(
            type: MaterialType.transparency,
            clipBehavior: Clip.none,
            child: InkResponse(
              onTap: onTap,
              onHover: (_) {},
              highlightShape: BoxShape.rectangle,
              borderRadius: BorderRadius.all(Radius.circular(width / 2.0)),
              containedInkWell: true,
              splashColor: colors.primary.withOpacity(0.12),
              hoverColor: colors.primary.withOpacity(0.04),
              child: content,
            ),
          ),
          Semantics(
            label: indexLabel,
          ),
        ]
      ),
    );
  }

  double _normalLabelFadeInValue() {
    if (destinationAnimation.value < 0.25) {
      return 0;
    } else if (destinationAnimation.value < 0.75) {
      return (destinationAnimation.value - 0.25) * 2;
    } else {
      return 1;
    }
  }

  double _normalLabelFadeOutValue() {
    if (destinationAnimation.value > 0.75) {
      return (destinationAnimation.value - 0.75) * 4.0;
    } else {
      return 0;
    }
  }
  
  double _extendedLabelFadeValue() {
    return extendedTransitionAnimation.value < 0.25 ? extendedTransitionAnimation.value * 4.0 : 1.0;
  }

}

/// Defines the behavior of the labels of a [NavigationRail].
///
/// See also:
///
///   * [NavigationRail]
enum NavigationRailLabelType {
  /// Only the icons of a navigation rail item are shown.
  none,

  /// Only the selected navigation rail item will show its label.
  ///
  /// The label will animate in and out as new items are selected.
  selected,

  /// All navigation rail items will show their label.
  all,
}

/// Defines the alignment for the group of [NavigationRailDestination]s within
/// a [NavigationRail].
///
/// Navigation rail destinations can be aligned as a group to the [top],
/// [bottom], or [center] of a layout.
enum NavigationRailGroupAlignment {
  /// Place the [NavigationRailDestination]s at the top of the rail.
  top,

  /// Place the [NavigationRailDestination]s in the center of the rail.
  center,

  /// Place the [NavigationRailDestination]s at the bottom of the rail.
  bottom,
}

/// A description for an interactive button within a [NavigationRail].
///
/// See also:
///
///  * [NavigationRail]
class NavigationRailDestination {
  /// Creates an destination that is used with [NavigationRail.destinations].
  ///
  /// [icon] should not be null and [label] should not be null when this
  /// destination is used in the [NavigationRail].
  const NavigationRailDestination({
    @required this.icon,
    Widget activeIcon,
    this.label,
  }) : activeIcon = activeIcon ?? icon,
       assert(icon != null);
  /// The icon of the destination.
  ///
  /// Typically the icon is an [Icon] or an [ImageIcon] widget. If another type
  /// of widget is provided then it should configure itself to match the current
  /// [IconTheme] size and color.
  ///
  /// If [activeIcon] is provided, this will only be displayed when the
  /// destination is not selected.
  ///
  /// To make the [NavigationRail] more accessible, consider choosing an
  /// icon with a stroked and filled version, such as [Icons.cloud] and
  /// [Icons.cloud_queue]. [icon] should be set to the stroked version and
  /// [activeIcon] to the filled version.
  final Widget icon;

  /// An alternative icon displayed when this destination is selected.
  ///
  /// If this icon is not provided, the [NavigationRail] will display [icon] in
  /// either state.
  ///
  /// See also:
  ///
  ///  * [NavigationRailDestination.icon], for a description of how to pair
  ///    icons.
  final Widget activeIcon;

  /// The label for the destination.
  ///
  /// The label should be provided when used with the [NavigationRail]. When
  /// the labelType is [NavigationRailLabelType.none] and the rail is not
  /// extended, then it can be null, but should be used for semantics.
  final Widget label;
}

class _ExtendedNavigationRailAnimation extends InheritedWidget {
  const _ExtendedNavigationRailAnimation({
    Key key,
    @required this.animation,
    @required Widget child,
  }) : assert(child != null),
        super(key: key, child: child);

  final Animation<double> animation;

  static _ExtendedNavigationRailAnimation of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ExtendedNavigationRailAnimation>();
  }

  @override
  bool updateShouldNotify(_ExtendedNavigationRailAnimation old) => animation != old.animation;
}

const double _railWidth = 72.0;
const double _extendedRailWidth = 256.0;
const double _horizontalDestinationPadding = 8.0;
const double _verticalDestinationPaddingNoLabel = 24.0;
const double _verticalDestinationPaddingWithLabel = 16.0;
const Widget _verticalSpacer = SizedBox(height: 8.0);