// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/widgets.dart';

import 'color_scheme.dart';
import 'ink_well.dart';
import 'material.dart';
import 'material_localizations.dart';
import 'navigation_bar.dart';
import 'navigation_rail_theme.dart';
import 'theme.dart';

/// A material widget that is meant to be displayed at the left or right of an
/// app to navigate between a small number of views, typically between three and
/// five.
///
/// The navigation rail is meant for layouts with wide viewports, such as a
/// desktop web or tablet landscape layout. For smaller layouts, like mobile
/// portrait, a [BottomNavigationBar] should be used instead.
///
/// A navigation rail is usually used as the first or last element of a [Row]
/// which defines the app's [Scaffold] body.
///
/// The appearance of all of the [NavigationRail]s within an app can be
/// specified with [NavigationRailTheme]. The default values for null theme
/// properties are based on the [Theme]'s [ThemeData.textTheme],
/// [ThemeData.iconTheme], and [ThemeData.colorScheme].
///
/// Adaptive layouts can build different instances of the [Scaffold] in order to
/// have a navigation rail for more horizontal layouts and a bottom navigation
/// bar for more vertical layouts. See
/// [the adaptive_scaffold.dart sample](https://github.com/flutter/samples/blob/master/experimental/web_dashboard/lib/src/widgets/third_party/adaptive_scaffold.dart)
/// for an example.
///
/// {@tool dartpad}
/// This example shows a [NavigationRail] used within a Scaffold with 3
/// [NavigationRailDestination]s. The main content is separated by a divider
/// (although elevation on the navigation rail can be used instead). The
/// `_selectedIndex` is updated by the `onDestinationSelected` callback.
///
/// ** See code in examples/api/lib/material/navigation_rail/navigation_rail.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [Scaffold], which can display the navigation rail within a [Row] of the
///    [Scaffold.body] slot.
///  * [NavigationRailDestination], which is used as a model to create tappable
///    destinations in the navigation rail.
///  * [BottomNavigationBar], which is a similar navigation widget that's laid
///     out horizontally.
///  * https://material.io/components/navigation-rail/
class NavigationRail extends StatefulWidget {
  /// Creates a material design navigation rail.
  ///
  /// The value of [destinations] must be a list of one or more
  /// [NavigationRailDestination] values.
  ///
  /// If [elevation] is specified, it must be non-negative.
  ///
  /// If [minWidth] is specified, it must be non-negative, and if
  /// [minExtendedWidth] is specified, it must be non-negative and greater than
  /// [minWidth].
  ///
  /// The argument [extended] must not be null. [extended] can only be set to
  /// true when the [labelType] is null or [NavigationRailLabelType.none].
  ///
  /// If [backgroundColor], [elevation], [groupAlignment], [labelType],
  /// [unselectedLabelTextStyle], [selectedLabelTextStyle],
  /// [unselectedIconTheme], or [selectedIconTheme] are null, then their
  /// [NavigationRailThemeData] values will be used. If the corresponding
  /// [NavigationRailThemeData] property is null, then the navigation rail
  /// defaults are used. See the individual properties for more information.
  ///
  /// Typically used within a [Row] that defines the [Scaffold.body] property.
  const NavigationRail({
    Key? key,
    this.backgroundColor,
    this.extended = false,
    this.leading,
    this.trailing,
    required this.destinations,
    required this.selectedIndex,
    this.onDestinationSelected,
    this.elevation,
    this.groupAlignment,
    this.labelType,
    this.unselectedLabelTextStyle,
    this.selectedLabelTextStyle,
    this.unselectedIconTheme,
    this.selectedIconTheme,
    this.minWidth,
    this.minExtendedWidth,
    this.useIndicator,
    this.indicatorColor,
  }) :  assert(destinations != null && destinations.length >= 2),
        assert(selectedIndex != null),
        assert(0 <= selectedIndex && selectedIndex < destinations.length),
        assert(elevation == null || elevation > 0),
        assert(minWidth == null || minWidth > 0),
        assert(minExtendedWidth == null || minExtendedWidth > 0),
        assert((minWidth == null || minExtendedWidth == null) || minExtendedWidth >= minWidth),
        assert(extended != null),
        assert(!extended || (labelType == null || labelType == NavigationRailLabelType.none)),
        super(key: key);

  /// Sets the color of the Container that holds all of the [NavigationRail]'s
  /// contents.
  ///
  /// The default value is [NavigationRailThemeData.backgroundColor]. If
  /// [NavigationRailThemeData.backgroundColor] is null, then the default value
  /// is based on [ColorScheme.surface] of [ThemeData.colorScheme].
  final Color? backgroundColor;

  /// Indicates that the [NavigationRail] should be in the extended state.
  ///
  /// The extended state has a wider rail container, and the labels are
  /// positioned next to the icons. [minExtendedWidth] can be used to set the
  /// minimum width of the rail when it is in this state.
  ///
  /// The rail will implicitly animate between the extended and normal state.
  ///
  /// If the rail is going to be in the extended state, then the [labelType]
  /// must be set to [NavigationRailLabelType.none].
  ///
  /// The default value is false.
  final bool extended;

  /// The leading widget in the rail that is placed above the destinations.
  ///
  /// It is placed at the top of the rail, above the [destinations]. Its
  /// location is not affected by [groupAlignment].
  ///
  /// This is commonly a [FloatingActionButton], but may also be a non-button,
  /// such as a logo.
  ///
  /// The default value is null.
  final Widget? leading;

  /// The trailing widget in the rail that is placed below the destinations.
  ///
  /// The trailing widget is placed below the last [NavigationRailDestination].
  /// It's location is affected by [groupAlignment].
  ///
  /// This is commonly a list of additional options or destinations that is
  /// usually only rendered when [extended] is true.
  ///
  /// The default value is null.
  final Widget? trailing;

  /// Defines the appearance of the button items that are arrayed within the
  /// navigation rail.
  ///
  /// The value must be a list of two or more [NavigationRailDestination]
  /// values.
  final List<NavigationRailDestination> destinations;

  /// The index into [destinations] for the current selected
  /// [NavigationRailDestination].
  final int selectedIndex;

  /// Called when one of the [destinations] is selected.
  ///
  /// The stateful widget that creates the navigation rail needs to keep
  /// track of the index of the selected [NavigationRailDestination] and call
  /// `setState` to rebuild the navigation rail with the new [selectedIndex].
  final ValueChanged<int>? onDestinationSelected;

  /// The rail's elevation or z-coordinate.
  ///
  /// If [Directionality] is [intl.TextDirection.LTR], the inner side is the
  /// right side, and if [Directionality] is [intl.TextDirection.RTL], it is
  /// the left side.
  ///
  /// The default value is 0.
  final double? elevation;

  /// The vertical alignment for the group of [destinations] within the rail.
  ///
  /// The [NavigationRailDestination]s are grouped together with the [trailing]
  /// widget, between the [leading] widget and the bottom of the rail.
  ///
  /// The value must be between -1.0 and 1.0.
  ///
  /// If [groupAlignment] is -1.0, then the items are aligned to the top. If
  /// [groupAlignment] is 0.0, then the items are aligned to the center. If
  /// [groupAlignment] is 1.0, then the items are aligned to the bottom.
  ///
  /// The default is -1.0.
  ///
  /// See also:
  ///   * [Alignment.y]
  ///
  final double? groupAlignment;

  /// Defines the layout and behavior of the labels for the default, unextended
  /// [NavigationRail].
  ///
  /// When a navigation rail is [extended], the labels are always shown.
  ///
  /// The default value is [NavigationRailThemeData.labelType]. If
  /// [NavigationRailThemeData.labelType] is null, then the default value is
  /// [NavigationRailLabelType.none].
  ///
  /// See also:
  ///
  ///   * [NavigationRailLabelType] for information on the meaning of different
  ///   types.
  final NavigationRailLabelType? labelType;

  /// The [TextStyle] of a destination's label when it is unselected.
  ///
  /// When one of the [destinations] is selected the [selectedLabelTextStyle]
  /// will be used instead.
  ///
  /// The default value is based on the [Theme]'s [TextTheme.bodyText1]. The
  /// default color is based on the [Theme]'s [ColorScheme.onSurface].
  ///
  /// Properties from this text style, or
  /// [NavigationRailThemeData.unselectedLabelTextStyle] if this is null, are
  /// merged into the defaults.
  final TextStyle? unselectedLabelTextStyle;

  /// The [TextStyle] of a destination's label when it is selected.
  ///
  /// When a [NavigationRailDestination] is not selected,
  /// [unselectedLabelTextStyle] will be used.
  ///
  /// The default value is based on the [TextTheme.bodyText1] of
  /// [ThemeData.textTheme]. The default color is based on the [Theme]'s
  /// [ColorScheme.primary].
  ///
  /// Properties from this text style,
  /// or [NavigationRailThemeData.selectedLabelTextStyle] if this is null, are
  /// merged into the defaults.
  final TextStyle? selectedLabelTextStyle;

  /// The visual properties of the icon in the unselected destination.
  ///
  /// If this field is not provided, or provided with any null properties, then
  /// a copy of the [IconThemeData.fallback] with a custom [NavigationRail]
  /// specific color will be used.
  ///
  /// The default value is the [Theme]'s [ThemeData.iconTheme] with a color
  /// of the [Theme]'s [ColorScheme.onSurface] with an opacity of 0.64.
  /// Properties from this icon theme, or
  /// [NavigationRailThemeData.unselectedIconTheme] if this is null, are
  /// merged into the defaults.
  final IconThemeData? unselectedIconTheme;

  /// The visual properties of the icon in the selected destination.
  ///
  /// When a [NavigationRailDestination] is not selected,
  /// [unselectedIconTheme] will be used.
  ///
  /// The default value is the [Theme]'s [ThemeData.iconTheme] with a color
  /// of the [Theme]'s [ColorScheme.primary]. Properties from this icon theme,
  /// or [NavigationRailThemeData.selectedIconTheme] if this is null, are
  /// merged into the defaults.
  final IconThemeData? selectedIconTheme;

  /// The smallest possible width for the rail regardless of the destination's
  /// icon or label size.
  ///
  /// The default is 72.
  ///
  /// This value also defines the min width and min height of the destinations.
  ///
  /// To make a compact rail, set this to 56 and use
  /// [NavigationRailLabelType.none].
  final double? minWidth;

  /// The final width when the animation is complete for setting [extended] to
  /// true.
  ///
  /// This is only used when [extended] is set to true.
  ///
  /// The default value is 256.
  final double? minExtendedWidth;

  /// If `true`, adds a rounded [NavigationIndicator] behind the selected
  /// destination's icon.
  ///
  /// The indicator's shape will be circular if [labelType] is
  /// [NavigationRailLabelType.none], or a [StadiumBorder] if [labelType] is
  /// [NavigationRailLabelType.all] or [NavigationRailLabelType.selected].
  ///
  /// If `null`, defaults to [NavigationRailThemeData.useIndicator]. If that is
  /// `null`, defaults to [ThemeData.useMaterial3].
  final bool? useIndicator;

  /// Overrides the default value of [NavigationRail]'s selection indicator color,
  /// when [useIndicator] is true.
  final Color? indicatorColor;

  /// Returns the animation that controls the [NavigationRail.extended] state.
  ///
  /// This can be used to synchronize animations in the [leading] or [trailing]
  /// widget, such as an animated menu or a [FloatingActionButton] animation.
  ///
  /// {@tool dartpad}
  /// This example shows how to use this animation to create a [FloatingActionButton]
  /// that animates itself between the normal and extended states of the
  /// [NavigationRail].
  ///
  /// An instance of `MyNavigationRailFab` is created for [NavigationRail.leading].
  /// Pressing the FAB button toggles the "extended" state of the [NavigationRail].
  ///
  /// ** See code in examples/api/lib/material/navigation_rail/navigation_rail.extended_animation.0.dart **
  /// {@end-tool}
  static Animation<double> extendedAnimation(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ExtendedNavigationRailAnimation>()!.animation;
  }

  @override
  State<NavigationRail> createState() => _NavigationRailState();
}

class _NavigationRailState extends State<NavigationRail> with TickerProviderStateMixin {
  late List<AnimationController> _destinationControllers;
  late List<Animation<double>> _destinationAnimations;
  late AnimationController _extendedController;
  late Animation<double> _extendedAnimation;

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

    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _destinationControllers[oldWidget.selectedIndex].reverse();
      _destinationControllers[widget.selectedIndex].forward();
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final NavigationRailThemeData navigationRailTheme = NavigationRailTheme.of(context);
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);

    final Color backgroundColor = widget.backgroundColor ?? navigationRailTheme.backgroundColor ?? theme.colorScheme.surface;
    final double elevation = widget.elevation ?? navigationRailTheme.elevation ?? 0;
    final double minWidth = widget.minWidth ?? _minRailWidth;
    final double minExtendedWidth = widget.minExtendedWidth ?? _minExtendedRailWidth;
    final Color baseSelectedColor = theme.colorScheme.primary;
    final Color baseUnselectedColor = theme.colorScheme.onSurface.withOpacity(0.64);
    final IconThemeData? defaultUnselectedIconTheme = widget.unselectedIconTheme ?? navigationRailTheme.unselectedIconTheme;
    final IconThemeData unselectedIconTheme = IconThemeData(
      size: defaultUnselectedIconTheme?.size ?? 24.0,
      color: defaultUnselectedIconTheme?.color ?? theme.colorScheme.onSurface,
      opacity: defaultUnselectedIconTheme?.opacity ?? 0.64,
    );
    final IconThemeData? defaultSelectedIconTheme = widget.selectedIconTheme ?? navigationRailTheme.selectedIconTheme;
    final IconThemeData selectedIconTheme = IconThemeData(
      size: defaultSelectedIconTheme?.size ?? 24.0,
      color: defaultSelectedIconTheme?.color ?? theme.colorScheme.primary,
      opacity: defaultSelectedIconTheme?.opacity ?? 1.0,
    );
    final TextStyle unselectedLabelTextStyle = theme.textTheme.bodyText1!.copyWith(color: baseUnselectedColor).merge(widget.unselectedLabelTextStyle ?? navigationRailTheme.unselectedLabelTextStyle);
    final TextStyle selectedLabelTextStyle = theme.textTheme.bodyText1!.copyWith(color: baseSelectedColor).merge(widget.selectedLabelTextStyle ?? navigationRailTheme.selectedLabelTextStyle);
    final double groupAlignment = widget.groupAlignment ?? navigationRailTheme.groupAlignment ?? -1.0;
    final NavigationRailLabelType labelType = widget.labelType ?? navigationRailTheme.labelType ?? NavigationRailLabelType.none;

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
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: lerpDouble(minWidth, minExtendedWidth, _extendedAnimation.value)!,
                    ),
                    child: widget.leading,
                  ),
                  _verticalSpacer,
                ],
              Expanded(
                child: Align(
                  alignment: Alignment(0, groupAlignment),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      for (int i = 0; i < widget.destinations.length; i += 1)
                        _RailDestination(
                          minWidth: minWidth,
                          minExtendedWidth: minExtendedWidth,
                          extendedTransitionAnimation: _extendedAnimation,
                          selected: widget.selectedIndex == i,
                          icon: widget.selectedIndex == i ? widget.destinations[i].selectedIcon : widget.destinations[i].icon,
                          label: widget.destinations[i].label,
                          destinationAnimation: _destinationAnimations[i],
                          labelType: labelType,
                          iconTheme: widget.selectedIndex == i ? selectedIconTheme : unselectedIconTheme,
                          labelTextStyle: widget.selectedIndex == i ? selectedLabelTextStyle : unselectedLabelTextStyle,
                          padding: widget.destinations[i].padding,
                          useIndicator: widget.useIndicator ?? navigationRailTheme.useIndicator ?? theme.useMaterial3,
                          indicatorColor: widget.indicatorColor ?? navigationRailTheme.indicatorColor,
                          onTap: () {
                            if (widget.onDestinationSelected != null)
                              widget.onDestinationSelected!(i);
                          },
                          indexLabel: localizations.tabLabel(
                            tabIndex: i + 1,
                            tabCount: widget.destinations.length,
                          ),
                        ),
                      if (widget.trailing != null)
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: lerpDouble(minWidth, minExtendedWidth, _extendedAnimation.value)!,
                          ),
                          child: widget.trailing,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _disposeControllers() {
    for (final AnimationController controller in _destinationControllers) {
      controller.dispose();
    }
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
    _destinationControllers[widget.selectedIndex].value = 1.0;
    _extendedController = AnimationController(
      duration: kThemeAnimationDuration,
      vsync: this,
      value: widget.extended ? 1.0 : 0.0,
    );
    _extendedAnimation = CurvedAnimation(
      parent: _extendedController,
      curve: Curves.easeInOut,
    );
    _extendedController.addListener(() {
      _rebuild();
    });
  }

  void _resetState() {
    _disposeControllers();
    _initControllers();
  }

  void _rebuild() {
    setState(() {
      // Rebuilding when any of the controllers tick, i.e. when the items are
      // animating.
    });
  }
}

class _RailDestination extends StatelessWidget {
  _RailDestination({
    required this.minWidth,
    required this.minExtendedWidth,
    required this.icon,
    required this.label,
    required this.destinationAnimation,
    required this.extendedTransitionAnimation,
    required this.labelType,
    required this.selected,
    required this.iconTheme,
    required this.labelTextStyle,
    required this.onTap,
    required this.indexLabel,
    this.padding,
    required this.useIndicator,
    this.indicatorColor,
  }) : assert(minWidth != null),
       assert(minExtendedWidth != null),
       assert(icon != null),
       assert(label != null),
       assert(destinationAnimation != null),
       assert(extendedTransitionAnimation != null),
       assert(labelType != null),
       assert(selected != null),
       assert(iconTheme != null),
       assert(labelTextStyle != null),
       assert(onTap != null),
       assert(indexLabel != null),
       _positionAnimation = CurvedAnimation(
          parent: ReverseAnimation(destinationAnimation),
          curve: Curves.easeInOut,
          reverseCurve: Curves.easeInOut.flipped,
       );

  final double minWidth;
  final double minExtendedWidth;
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
  final EdgeInsetsGeometry? padding;
  final bool useIndicator;
  final Color? indicatorColor;

  final Animation<double> _positionAnimation;

  @override
  Widget build(BuildContext context) {
    assert(
      useIndicator || indicatorColor == null,
      '[NavigationRail.indicatorColor] does not have an effect when [NavigationRail.useIndicator] is false',
    );

    final Widget themedIcon = IconTheme(
      data: iconTheme,
      child: icon,
    );
    final Widget styledLabel = DefaultTextStyle(
      style: labelTextStyle,
      child: label,
    );

    final Widget content;

    switch (labelType) {
      case NavigationRailLabelType.none:
        final Widget iconPart = SizedBox(
          width: minWidth,
          height: minWidth,
          child: _AddIndicator(
            addIndicator: useIndicator,
            indicatorColor: indicatorColor,
            isCircular: true,
            indicatorAnimation: destinationAnimation,
            child: themedIcon,
          ),
        );
        if (extendedTransitionAnimation.value == 0) {
          content = Padding(
            padding: padding ?? EdgeInsets.zero,
            child: Stack(
              children: <Widget>[
                iconPart,
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
              ],
            ),
          );
        } else {
          final Animation<double> labelFadeAnimation = extendedTransitionAnimation.drive(CurveTween(curve: const Interval(0.0, 0.25)));
          content = Padding(
            padding: padding ?? EdgeInsets.zero,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: lerpDouble(minWidth, minExtendedWidth, extendedTransitionAnimation.value)!,
              ),
              child: ClipRect(
                child: Row(
                  children: <Widget>[
                    iconPart,
                    Align(
                      heightFactor: 1.0,
                      widthFactor: extendedTransitionAnimation.value,
                      alignment: AlignmentDirectional.centerStart,
                      child: FadeTransition(
                        alwaysIncludeSemantics: true,
                        opacity: labelFadeAnimation,
                        child: styledLabel,
                      ),
                    ),
                    SizedBox(width: _horizontalDestinationPadding * extendedTransitionAnimation.value),
                  ],
                ),
              ),
            ),
          );
        }
        break;
      case NavigationRailLabelType.selected:
        final double appearingAnimationValue = 1 - _positionAnimation.value;
        final double verticalPadding = lerpDouble(_verticalDestinationPaddingNoLabel, _verticalDestinationPaddingWithLabel, appearingAnimationValue)!;
        final Interval interval = selected ? const Interval(0.25, 0.75) : const Interval(0.75, 1.0);
        final Animation<double> labelFadeAnimation = destinationAnimation.drive(CurveTween(curve: interval));

        content = Container(
          constraints: BoxConstraints(
            minWidth: minWidth,
            minHeight: minWidth,
          ),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: _horizontalDestinationPadding),
          child: ClipRect(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: verticalPadding),
                _AddIndicator(
                  addIndicator: useIndicator,
                  indicatorColor: indicatorColor,
                  isCircular: false,
                  indicatorAnimation: destinationAnimation,
                  child: themedIcon,
                ),
                Align(
                  alignment: Alignment.topCenter,
                  heightFactor: appearingAnimationValue,
                  widthFactor: 1.0,
                  child: FadeTransition(
                    alwaysIncludeSemantics: true,
                    opacity: labelFadeAnimation,
                    child: styledLabel,
                  ),
                ),
                SizedBox(height: verticalPadding),
              ],
            ),
          ),
        );
        break;
      case NavigationRailLabelType.all:
        content = Container(
          constraints: BoxConstraints(
            minWidth: minWidth,
            minHeight: minWidth,
          ),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: _horizontalDestinationPadding),
          child: Column(
            children: <Widget>[
              const SizedBox(height: _verticalDestinationPaddingWithLabel),
              _AddIndicator(
                addIndicator: useIndicator,
                indicatorColor: indicatorColor,
                isCircular: false,
                indicatorAnimation: destinationAnimation,
                child: themedIcon,
              ),
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
            child: InkResponse(
              onTap: onTap,
              onHover: (_) {},
              highlightShape: BoxShape.rectangle,
              borderRadius: BorderRadius.all(Radius.circular(minWidth / 2.0)),
              containedInkWell: true,
              splashColor: colors.primary.withOpacity(0.12),
              hoverColor: colors.primary.withOpacity(0.04),
              child: content,
            ),
          ),
          Semantics(
            label: indexLabel,
          ),
        ],
      ),
    );
  }
}

/// When [addIndicator] is `true`, puts [child] center aligned in a [Stack] with
/// a [NavigationIndicator] behind it, otherwise returns [child].
///
/// When [isCircular] is true, the indicator will be a circle, otherwise the
/// indicator will be a stadium shape.
class _AddIndicator extends StatelessWidget {
  const _AddIndicator({
    Key? key,
    required this.addIndicator,
    required this.isCircular,
    required this.indicatorColor,
    required this.indicatorAnimation,
    required this.child,
  }) : super(key: key);

  final bool addIndicator;
  final bool isCircular;
  final Color? indicatorColor;
  final Animation<double> indicatorAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!addIndicator) {
      return child;
    }
    late final Widget indicator;
    if (isCircular) {
      const double circularIndicatorDiameter = 56;
      indicator = NavigationIndicator(
        animation: indicatorAnimation,
        height: circularIndicatorDiameter,
        width: circularIndicatorDiameter,
        borderRadius: BorderRadius.circular(circularIndicatorDiameter / 2),
        color: indicatorColor,
      );
    } else {
      indicator = NavigationIndicator(
        animation: indicatorAnimation,
        width: 56,
        borderRadius: BorderRadius.circular(16),
        color: indicatorColor,
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        indicator,
        child,
      ],
    );
  }
}


/// Defines the behavior of the labels of a [NavigationRail].
///
/// See also:
///
///   * [NavigationRail]
enum NavigationRailLabelType {
  /// Only the [NavigationRailDestination]s are shown.
  none,

  /// Only the selected [NavigationRailDestination] will show its label.
  ///
  /// The label will animate in and out as new [NavigationRailDestination]s are
  /// selected.
  selected,

  /// All [NavigationRailDestination]s will show their label.
  all,
}

/// Defines a [NavigationRail] button that represents one "destination" view.
///
/// See also:
///
///  * [NavigationRail]
class NavigationRailDestination {
  /// Creates a destination that is used with [NavigationRail.destinations].
  ///
  /// [icon] and [label] must be non-null. When the [NavigationRail.labelType]
  /// is [NavigationRailLabelType.none], the label is still used for semantics,
  /// and may still be used if [NavigationRail.extended] is true.
  const NavigationRailDestination({
    required this.icon,
    Widget? selectedIcon,
    required this.label,
    this.padding,
  }) : selectedIcon = selectedIcon ?? icon,
       assert(icon != null),
       assert(label != null);

  /// The icon of the destination.
  ///
  /// Typically the icon is an [Icon] or an [ImageIcon] widget. If another type
  /// of widget is provided then it should configure itself to match the current
  /// [IconTheme] size and color.
  ///
  /// If [selectedIcon] is provided, this will only be displayed when the
  /// destination is not selected.
  ///
  /// To make the [NavigationRail] more accessible, consider choosing an
  /// icon with a stroked and filled version, such as [Icons.cloud] and
  /// [Icons.cloud_queue]. The [icon] should be set to the stroked version and
  /// [selectedIcon] to the filled version.
  final Widget icon;

  /// An alternative icon displayed when this destination is selected.
  ///
  /// If this icon is not provided, the [NavigationRail] will display [icon] in
  /// either state. The size, color, and opacity of the
  /// [NavigationRail.selectedIconTheme] will still apply.
  ///
  /// See also:
  ///
  ///  * [NavigationRailDestination.icon], for a description of how to pair
  ///    icons.
  final Widget selectedIcon;

  /// The label for the destination.
  ///
  /// The label must be provided when used with the [NavigationRail]. When the
  /// [NavigationRail.labelType] is [NavigationRailLabelType.none], the label is
  /// still used for semantics, and may still be used if
  /// [NavigationRail.extended] is true.
  final Widget label;

  /// The amount of space to inset the destination item.
  final EdgeInsetsGeometry? padding;
}

class _ExtendedNavigationRailAnimation extends InheritedWidget {
  const _ExtendedNavigationRailAnimation({
    Key? key,
    required this.animation,
    required Widget child,
  }) : assert(child != null),
       super(key: key, child: child);

  final Animation<double> animation;

  @override
  bool updateShouldNotify(_ExtendedNavigationRailAnimation old) => animation != old.animation;
}

const double _minRailWidth = 72.0;
const double _minExtendedRailWidth = 256.0;
const double _horizontalDestinationPadding = 8.0;
const double _verticalDestinationPaddingNoLabel = 24.0;
const double _verticalDestinationPaddingWithLabel = 16.0;
const Widget _verticalSpacer = SizedBox(height: 8.0);
