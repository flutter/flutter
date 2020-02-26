import 'dart:math' as math;
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
    this.destinations,
    this.currentIndex,
    this.onDestinationSelected,
    this.elevation,
    this.groupAlignment = NavigationRailGroupAlignment.top,
    this.labelType = NavigationRailLabelType.none,
    this.unselectedLabelTextStyle,
    this.selectedLabelTextStyle,
    this.unselectedIconTheme,
    this.selectedIconTheme,
    this.minWidth = _railWidth,
    this.extendedWidth = _extendedRailWidth,
  }) : assert(extendedWidth >= _railWidth);

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
  final double minWidth;

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

  // The following variables are used to measure and store the sizes of the
  // inner content of each destination so that the rail can adapt to various
  // icon sizes, font sizes, and textScaleFactors.
  bool _contentMeasured = false;
  List<GlobalKey> _offstageActiveIconKeys;
  List<GlobalKey> _offstageIconKeys;
  List<GlobalKey> _offstageSelectedLabelKeys;
  List<GlobalKey> _offstageLabelKeys;
  List<Size> _activeIconSizes = <Size>[];
  List<Size> _iconSizes = <Size>[];
  List<Size> _selectedLabelSizes = <Size>[];
  List<Size> _labelSizes = <Size>[];

  @override
  void initState() {
    super.initState();
    _initControllers();
    _initKeys();
    _measureContentsThenResize(false, context);
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

//  @override
//  void didChangeDependencies() {
//    _measureLabelsAndResize(true);
//  }

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

    _measureContentsThenResize(true, context);
  }

  @override
  Widget build(BuildContext context) {
    final NavigationRailThemeData navigationRailTheme = Theme.of(context).navigationRailTheme;
    final Widget leading = widget.leading;
    final Widget trailing = widget.trailing;

    final Color backgroundColor = widget.backgroundColor ?? navigationRailTheme.backgroundColor ?? Theme.of(context).colorScheme.surface;
    final double elevation = widget.elevation ?? navigationRailTheme.elevation ?? 0;
    final Color baseSelectedColor = Theme.of(context).colorScheme.primary;
    final Color baseColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.64);
    final IconThemeData unselectedIconTheme = const IconThemeData.fallback().copyWith(color: baseColor).merge(widget.unselectedIconTheme ?? navigationRailTheme.unselectedIconTheme);
    final IconThemeData selectedIconTheme = const IconThemeData.fallback().copyWith(color: baseSelectedColor).merge(widget.selectedIconTheme ?? navigationRailTheme.selectedIconTheme);
    final TextStyle unselectedLabelTextStyle = TextStyle(color: baseColor, fontSize: 14).merge(widget.unselectedLabelTextStyle ?? navigationRailTheme.unselectedLabelTextStyle);
    final TextStyle selectedLabelTextStyle = TextStyle(color: baseSelectedColor, fontSize: 14).merge(widget.selectedLabelTextStyle ?? navigationRailTheme.selectedLabelTextStyle);
    final NavigationRailGroupAlignment groupAlignment = widget.groupAlignment ?? navigationRailTheme.groupAlignment ?? NavigationRailGroupAlignment.top;
    final NavigationRailLabelType labelType = widget.labelType ?? navigationRailTheme.labelType ?? NavigationRailLabelType.none;
    final MainAxisAlignment destinationsAlignment = _resolveGroupAlignment(groupAlignment);
    final bool isNoLabelOrExtended = widget.labelType != NavigationRailLabelType.none || _extendedAnimation.value > 0;

    // The width of that content inside of the destination. This does not
    // the label for the extended rail.
    final double maxDestinationContentWidth = <double>[
      widget.minWidth - 2 * _horizontalDestinationPadding,
      ...<Size>[
        ..._activeIconSizes,
        ..._iconSizes,
        if (isNoLabelOrExtended) ..._selectedLabelSizes,
        if (isNoLabelOrExtended) ..._labelSizes,
      ].map((Size size) => size.width)].reduce(math.max);
    final double destinationWidth = maxDestinationContentWidth + 2 * _horizontalDestinationPadding;
    final double railWidth = destinationWidth + _extendedAnimation.value * (widget.extendedWidth - widget.minWidth) * destinationWidth / (widget.minWidth - 2 * _horizontalDestinationPadding);


    return _ExtendedNavigationRailAnimation(
      animation: _extendedAnimation,
      child: !_contentMeasured ?
          Stack(
            overflow: Overflow.visible,
            children: <Widget>[
              for (int i = 0; i < widget.destinations.length; i++)
                ...<Widget>[
                  Offstage(
                    child: KeyedSubtree(
                      key: _offstageActiveIconKeys[i],
                      child: IconTheme(
                        data: selectedIconTheme,
                        child: widget.destinations[i].activeIcon,
                      ),
                    ),
                  ),
                  Offstage(
                    child: KeyedSubtree(
                      key: _offstageIconKeys[i],
                      child: IconTheme(
                        data: unselectedIconTheme,
                        child: widget.destinations[i].icon,
                      ),
                    ),
                  ),
                  Offstage(
                    child: KeyedSubtree(
                      key: _offstageSelectedLabelKeys[i],
                      child: DefaultTextStyle(
                        style: selectedLabelTextStyle,
                        child: widget.destinations[i].label,
                      ),
                    ),
                  ),
                  Offstage(
                    child: KeyedSubtree(
                      key: _offstageLabelKeys[i],
                      child: DefaultTextStyle(
                        style: unselectedLabelTextStyle,
                        child: widget.destinations[i].label,
                      ),
                    ),
                  ),
                ],
          ],
        ) : Material(
        elevation: elevation,
        child: Container(
          width: railWidth,
          color: backgroundColor,
          child: Column(
            children: <Widget>[
              _verticalSpacer,
              if (leading != null)
                ...<Widget>[
                  if (_extendedAnimation.value > 0)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Padding(
                        padding: const EdgeInsets.only(left: _horizontalDestinationPadding),
                        child: leading,
                      ),
                    )
                  else
                    leading,
                  _verticalSpacer,
                ],
              Expanded(
                child: Column(
                  mainAxisAlignment: destinationsAlignment,
                  children: <Widget>[
                    for (int i = 0; i < widget.destinations.length; i++)
                      _RailDestinationBox(
                        width: destinationWidth,
                        extendedTransitionAnimation: _extendedAnimation,
                        selected: widget.currentIndex == i,
                        icon: widget.currentIndex == i ? widget.destinations[i].activeIcon : widget.destinations[i].icon,
                        label: widget.destinations[i].label,
                        destinationAnimation: _destinationAnimations[i],
                        labelType: labelType,
                        iconTheme: widget.currentIndex == i ? selectedIconTheme : unselectedIconTheme,
                        labelTextStyle: widget.currentIndex == i ? selectedLabelTextStyle : unselectedLabelTextStyle,
                        iconSize: widget.currentIndex == i ? _activeIconSizes[i] : _iconSizes[i],
                        labelSize: widget.currentIndex == i ? _selectedLabelSizes[i] : _labelSizes[i],
                        onTap: () {
                          widget.onDestinationSelected(i);
                        },
                      ),
                  ],
                ),
              ),
              // TODO: measure this and use the measurement for padding
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  void _measureContentsThenResize(bool shouldSetState, BuildContext context) {
    if ((widget.labelType ?? Theme.of(context).navigationRailTheme.labelType) != NavigationRailLabelType.none) {
      SchedulerBinding.instance.addPostFrameCallback(_resize);
      if (shouldSetState) {
        setState(() {
          _contentMeasured = false;
        });
      }
    }
  }

  void _resize(Duration duration) {
    if (_contentMeasured == false) {
      setState(() {
        _contentMeasured = true;
        _activeIconSizes = _toRenderBoxSizes(_offstageActiveIconKeys);
        _iconSizes = _toRenderBoxSizes(_offstageIconKeys);
        _selectedLabelSizes = _toRenderBoxSizes(_offstageSelectedLabelKeys);
        _labelSizes = _toRenderBoxSizes(_offstageLabelKeys);
      });
    }
  }

  void _initKeys() {
    _offstageActiveIconKeys = _keysFromDestinations();
    _offstageIconKeys = _keysFromDestinations();
    _offstageSelectedLabelKeys = _keysFromDestinations();
    _offstageLabelKeys = _keysFromDestinations();
  }

  List<Size> _toRenderBoxSizes(List<GlobalKey> keys) => keys.map(_toRenderBoxSize).toList();

  Size _toRenderBoxSize(GlobalKey key) => (key.currentContext.findRenderObject() as RenderBox).size;

  List<GlobalKey> _keysFromDestinations() => widget.destinations.map((NavigationRailDestination destination) => GlobalKey()).toList();

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
    @required this.icon,
    @required this.label,
    @required this.destinationAnimation,
    @required this.extendedTransitionAnimation,
    @required this.labelType,
    @required this.selected,
    @required this.iconTheme,
    @required this.labelTextStyle,
    @required this.iconSize,
    @required this.labelSize,
    @required this.onTap,
  }) : assert(width != null),
       assert(icon != null),
       assert(label != null),
       assert(destinationAnimation != null),
       assert(extendedTransitionAnimation != null),
       assert(labelType != null),
       assert(selected != null),
       assert(iconTheme != null),
       assert(labelTextStyle != null),
       assert(iconSize != null),
       assert(labelSize != null),
       assert(onTap != null),
       _positionAnimation = CurvedAnimation(
          parent: ReverseAnimation(destinationAnimation),
          curve: Curves.easeInOut,
          reverseCurve: Curves.easeInOut.flipped,
       );

  final double width;
  final Widget icon;
  final Widget label;
  final Animation<double> destinationAnimation;
  final NavigationRailLabelType labelType;
  final bool selected;
  final Animation<double> extendedTransitionAnimation;
  final IconThemeData iconTheme;
  final TextStyle labelTextStyle;
  final Size iconSize;
  final Size labelSize;
  final VoidCallback onTap;

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
    if (extendedTransitionAnimation.value > 0) {
      final double height = math.max(labelSize.height, _verticalDestinationPaddingNoLabel * 2 + iconSize.height);
      final TextDirection textDirection = Directionality.of(context);
      content = SizedBox(
        width: double.infinity,
        child: Stack(
          children: <Widget>[
            Positioned(
              child: SizedBox(
                width: width,
                height: height,
                child: themedIcon,
              ),
            ),
            Positioned.directional(
              textDirection: textDirection,
              start: width,
              height: height,
              child: Opacity(
                opacity: _extendedLabelFadeValue(),
                child: Container(
                  alignment: AlignmentDirectional.centerStart,
                  child: styledLabel,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      switch (labelType) {
        case NavigationRailLabelType.none:
          content = SizedBox(
            width: width,
            height: _verticalDestinationPaddingNoLabel * 2 + iconSize.height,
            child: themedIcon,
          );
          break;
        case NavigationRailLabelType.selected:
          final double appearingAnimationValue = 1 - _positionAnimation.value;
          final double lerpedPadding = lerpDouble(_verticalDestinationPaddingNoLabel, _verticalDestinationPaddingWithLabel, appearingAnimationValue);
          content = SizedBox(
            width: width,
            height: iconSize.height + appearingAnimationValue * labelSize.height + 2 * lerpedPadding,
            child: Stack(
              children: <Widget>[
                Positioned(
                  top: lerpedPadding,
                  left: (width - iconSize.width) / 2,
                  child: themedIcon,
                ),
                Positioned(
                  top: iconSize.height + lerpedPadding,
                  left: (width - labelSize.width) / 2,
                  child: Opacity(
                    alwaysIncludeSemantics: true,
                    opacity: selected ? _normalLabelFadeInValue() : _normalLabelFadeOutValue(),
                    child: styledLabel,
                  ),
                ),
              ],
            ),
          );
          break;
        case NavigationRailLabelType.all:
          content = SizedBox(
            width: width,
            height: _verticalDestinationPaddingWithLabel * 2 + labelSize.height + iconSize.height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                themedIcon,
                styledLabel,
              ],
            ),
          );
          break;
      }
    }

    final ColorScheme colors = Theme.of(context).colorScheme;
    return Semantics(
      explicitChildNodes: false,
      child: Material(
        type: MaterialType.transparency,
        clipBehavior: Clip.none,
        child: InkResponse(
          onTap: onTap,
          onHover: (_) {},
          highlightShape: BoxShape.rectangle,
          borderRadius: BorderRadius.all(Radius.circular(width / 2)),
          containedInkWell: true,
          splashColor: colors.primary.withOpacity(0.12),
          hoverColor: colors.primary.withOpacity(0.04),
          child: content,
        ),
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
      return (destinationAnimation.value - 0.75) * 4;
    } else {
      return 0;
    }
  }
  
  double _extendedLabelFadeValue() {
    return extendedTransitionAnimation.value < 0.25 ? extendedTransitionAnimation.value * 4 : 1;
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
  /// The label should be provided when used with the [NavigationRail], unless
  /// [NavigationRailLabelType.none] used and the rail will not be extended.
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

const double _railWidth = 72;
const double _extendedRailWidth = 256;
const double _horizontalDestinationPadding = 8;
const double _verticalDestinationPaddingNoLabel = 24;
const double _verticalDestinationPaddingWithLabel = 16;
const Widget _verticalSpacer = SizedBox(height: 8);