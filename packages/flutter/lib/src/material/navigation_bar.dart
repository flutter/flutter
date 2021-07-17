import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'color_scheme.dart';
import 'ink_well.dart';
import 'material.dart';
import 'material_localizations.dart';
import 'theme.dart';

/// Material 3 Navigation Bar component.
///
/// This widget holds a collection destinations (usually
/// [NavigationBarDestination]s).
///
/// Usage:
/// ```dart
/// Scaffold(
///   bottomNavigationBar: NavigationBar(
///     onTap: (i) => setState(() => _currentPageIndex = i),
///     selectedIndex: _currentPageIndex,
///     destinations: [
///       NavigationBarDestination(
///         icon: Icon(Icons.explore),
///         label: 'Explore',
///       ),
///       NavigationBarDestination(
///         icon: Icon(Icons.commute),
///         label: 'Commute',
///       ),
///       NavigationBarDestination(
///         icon: Icon(Icons.bookmark),
///         unselectedIcon: Icons.bookmark_border,
///         label: 'Saved',
///       ),
///     ],
///   ),
/// ),
/// ```
class NavigationBar extends StatelessWidget {
  /// Creates a Material 3 Navigation Bar component.
  const NavigationBar({
    Key? key,
    this.animationDuration = const Duration(milliseconds: 500),
    this.selectedIndex = 0,
    required this.destinations,
    this.onTap,
    this.elevation = 8,
    this.backgroundColor,
    this.height,
    this.labelBehavior = NavigationBarDestinationLabelBehavior.alwaysShow,
  }) : super(key: key);

  /// Determines how long the animation is for each destination as it goes from
  /// unselected to selected.
  final Duration animationDuration;

  /// Determines which destination from [destinations] is currently selected.
  ///
  /// When this is updated, the destination (from [destinations]) at
  /// [selectedIndex] goes from unselected to selected. It will animate its
  /// [NavigationBarDestinationInfo.selectedAnimation] from 0.0 to 1.0.
  final int selectedIndex;

  /// The list of destinations (usually [NavigationBarDestination]s) in this
  /// [NavigationBar].
  ///
  /// When [selectedIndex] is updated, the destination from this list at
  /// [selectedIndex] will animate from 0 (unselected) to 1.0 (selected). When
  /// the animation is increasing or completed, the destination is considered
  /// selected, when the animation is decreasing or dismissed, the destination
  /// is considered unselected.
  ///
  /// Any widget in this list will have access to a
  /// [NavigationBarDestinationInfo] inherited widget.
  final List<Widget> destinations;

  /// Called when one of the [destinations] is tapped.
  ///
  /// This callback usually updates the int passed to [selectedIndex].
  final ValueChanged<int>? onTap;

  /// The z-coordinate of this [NavigationBar].
  final double elevation;

  /// The color of the [NavigationBar] itself.
  ///
  /// If null, defaults to [ColorScheme.surface].
  final Color? backgroundColor;

  /// The height of the [NavigationBar]'s Material, from the bottom of the
  /// screen to the top border of the widget, not including safe area padding
  /// for things like system navigation.
  ///
  /// Defaults to 74 when labels are used (when [labelBehavior] is
  /// [NavigationBarDestinationLabelBehavior.alwaysShow] or
  /// [NavigationBarDestinationLabelBehavior.onlyShowSelected]). Defaults to 56
  /// when no labels are used (when [labelBehavior] is
  /// [NavigationBarDestinationLabelBehavior.alwaysHide]).
  final double? height;

  /// Determines the behavior for how the labels will layout.
  ///
  /// Can be used to show all labels (the default), show only the selected
  /// label, or hide all labels.
  final NavigationBarDestinationLabelBehavior labelBehavior;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final double effectiveHeight =
      labelBehavior == NavigationBarDestinationLabelBehavior.alwaysHide ? 56 : 74;
    return Material(
      elevation: elevation,
      color: backgroundColor ?? ElevationOverlay.colorWithOverlay(colorScheme.surface, colorScheme.onSurface, 3.0),
      child: NavigationBarBottomPadding(
        child: SizedBox(
          height: effectiveHeight,
          child: Row(
            children: <Widget>[
              for (int i = 0; i < destinations.length; i++)
                Expanded(
                  child: SelectableAnimatedBuilder(
                    duration: animationDuration,
                    isSelected: i == selectedIndex,
                    builder: (BuildContext context, Animation<double> animation) {
                      return NavigationBarDestinationInfo(
                        destinationNumber: i,
                        totalNumberOfDestinations: destinations.length,
                        selectedAnimation: animation,
                        labelBehavior: labelBehavior,
                        onTap: onTap != null ? () => onTap!(i) : () {},
                        child: destinations[i],
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Options for how the labels should layout and when they should appear in the
/// navigation bar destinations.
enum NavigationBarDestinationLabelBehavior {
  /// Always shows all of the labels under each navigation bar destination,
  /// selected and unselected.
  alwaysShow,

  /// Never shows any of the labels under the navigation bar destinations,
  /// regardless of selected vs unselected.
  alwaysHide,

  /// Only shows the labels of the selected navigation bar destination.
  ///
  /// When an destination is unselected, the label will be faded out, and the
  /// icon will be centered.
  ///
  /// When an destination is selected, the label will fade in and the label and
  /// icon will slide up so that they are both centered.
  onlyShowSelected,
}

/// Destination Widget for displaying Icons + labels in the Material 3
/// Navigation Bars through [NavigationBar.destinations].
///
/// The destination this widget creates will look something like this:
/// =======
/// |
/// |  ☆  <-- [icon] (or [unselectedIcon])
/// | text <-- [label]
/// |
/// =======
///
/// See also:
///  * [NavigationBarDestinationBuilder] - Use this class when you need more
///    custom destinations than [NavigationBarDestination] provides, for
///    example, if you have animated icons.
class NavigationBarDestination extends StatelessWidget {
  /// Creates a navigation bar destination with an icon and a label, to be used
  /// in the [NavigationBar.destinations].
  const NavigationBarDestination({
    Key? key,
    required this.icon,
    this.unselectedIcon,
    required this.label,
  }) : super(key: key);

  /// The [Widget] (usually an [Icon]) that displays when this
  /// [NavigationBarDestination] is selected.
  final Widget icon;

  /// The optional [Widget] (usually an [Icon]) that displays when this
  /// [NavigationBarDestination] is unselected.
  ///
  /// If [unselectedIcon] is non-null, the destination will fade from
  /// [unselectedIcon] to [icon] when this destination goes from unselected to
  /// selected.
  final Widget? unselectedIcon;

  /// The text label that appears below the icon of this
  /// [NavigationBarDestination].
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Animation<double> animation =
        NavigationBarDestinationInfo.of(context).selectedAnimation;

    return NavigationBarDestinationBuilder(
      label: label,
      buildIcon: (BuildContext context) {
        final Widget selectedIconWidget = IconTheme.merge(
          child: icon,
          data: IconThemeData(
            size: 24,
            color: colorScheme.onSurface,
          ),
        );
        final Widget unselectedIconWidget = IconTheme.merge(
          child: unselectedIcon ?? icon,
          data: IconThemeData(
            size: 24,
            color: colorScheme.onSurface,
          ),
        );

        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            NavigationBarIndicator(animation: animation),
            StatusTransitionWidgetBuilder(
              animation: animation,
              builder: (BuildContext context, Widget? child) {
                return animation.isForwardOrCompleted
                    ? selectedIconWidget
                    : unselectedIconWidget;
              },
            ),
          ],
        );
      },
      buildLabel: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: ClampTextScaleFactor(
            // Don't scale labels of destinations, instead, tooltip text will
            // upscale.
            upperLimit: 1,
            child: Text(
              label,
              style: theme.textTheme.overline?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Widget that handles the semantics and layout of a navigation bar
/// destination.
///
/// Prefer [NavigationBarDestination] over this widget, as it is a simpler
/// (although less customizable) way to get navigation bar destinations.
///
/// The icon and label of this destination are built with [buildIcon] and
/// [buildLabel]. They should build the unselected and selected icon and label
/// according to [NavigationBarDestinationInfo.selectedAnimation], where 0 is
/// unselected and 1 is selected.
///
/// See [NavigationBarDestination] for an example usage.
class NavigationBarDestinationBuilder extends StatelessWidget {
  /// Builds a destination (icon + label) to use in a Material 3 [NavigationBar].
  const NavigationBarDestinationBuilder({
    Key? key,
    required this.buildIcon,
    required this.buildLabel,
    required this.label,
  }) : super(key: key);

  /// Builds the icon for an destination in a [NavigationBar].
  ///
  /// To animate between unselected and selected, build the icon based on
  /// [NavigationBarDestinationInfo.selectedAnimation]. When the animation is 0,
  /// the destination is unselected, when the animation is 1, the destination is
  /// selected.
  ///
  /// The destination is considered selected as soon as the animation is
  /// increasing or completed, and it is considered unselected as soon as the
  /// animation is decreasing or dismissed.
  final Widget Function(BuildContext) buildIcon;

  /// Builds the label for an destination in a [NavigationBar].
  ///
  /// To animate between unselected and selected, build the icon based on
  /// [NavigationBarDestinationInfo.selectedAnimation].  When the animation is
  /// 0, the destination is unselected, when the animation is 1, the destination
  /// is selected.
  ///
  /// The destination is considered selected as soon as the animation is
  /// increasing or completed, and it is considered unselected as soon as the
  /// animation is decreasing or dismissed.
  final Widget Function(BuildContext) buildLabel;

  /// The text value of what is in the label widget, this is required for
  /// semantics so that screen readers and tooltips can read the proper label.
  final String label;

  @override
  Widget build(BuildContext context) {
    final NavigationBarDestinationInfo info = NavigationBarDestinationInfo.of(context);
    return NavigationBarDestinationSemantics(
      child: NavigationBarDestinationTooltip(
        message: label,
        child: InkWell(
          onTap: info.onTap,
          child: Row(
            children: <Widget>[
              Expanded(
                child: NavigationBarDestinationLayout(
                  icon: buildIcon(context),
                  label: buildLabel(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget that handles the layout of the icon + label in a navigation bar
/// destination, based on [NavigationBarDestinationInfo.labelBehavior] and
/// [NavigationBarDestinationInfo.selectedAnimation].
///
/// Depending on the [NavigationBarDestinationInfo.labelBehavior], the labels
/// will shift and fade accordingly.
class NavigationBarDestinationLayout extends StatelessWidget {
  /// Builds a widget to layout an icon + label for a destination in a Material
  /// 3 [NavigationBar].
  const NavigationBarDestinationLayout({
    Key? key,
    required this.icon,
    required this.label,
  }) : super(key: key);

  /// The icon widget that sits on top of the label.
  ///
  /// See [NavigationBarDestination.icon].
  final Widget icon;

  /// The label widget that sits below the icon.
  ///
  /// This widget will sometimes be faded out, depending on
  /// [NavigationBarDestinationInfo.selectedAnimation].
  ///
  /// See [NavigationBarDestination.label].
  final Widget label;

  static final Key _iconKey = UniqueKey();
  static final Key _labelKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return DestinationLayoutAnimationBuilder(
      builder: (BuildContext context, Animation<double> animation) {
        return CustomMultiChildLayout(
          delegate: _NavigationBarDestinationLayoutDelegate(
            animation: animation,
          ),
          children: <Widget>[
            LayoutId(
              id: _NavigationBarDestinationLayoutDelegate.iconId,
              child: RepaintBoundary(
                key: _iconKey,
                child: icon,
              ),
            ),
            LayoutId(
              id: _NavigationBarDestinationLayoutDelegate.labelId,
              child: FadeTransition(
                alwaysIncludeSemantics: true,
                opacity: animation,
                child: RepaintBoundary(
                  key: _labelKey,
                  child: label,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Determines the appropriate [Curve] and [Animation] to use for laying out the
/// [NavigationBarDestination], based on
/// [NavigationBarDestinationInfo.labelBehavior].
///
/// The animation controlling the position and fade of the labels differs
/// from the selection animation, depending on the
/// [NavigationBarDestinationLabelBehavior]. This widget determines what
/// animation should be used for the position and fade of the labels.
class DestinationLayoutAnimationBuilder extends StatelessWidget {
  /// Builds a child with the appropriate animation [Curve] based on the
  /// [NavigationBarDestinationInfo.labelBehavior].
  const DestinationLayoutAnimationBuilder({Key? key, required this.builder})
      : super(key: key);

  /// Builds the child of this widget.
  ///
  /// The [Animation] will be the appropriate [Animation] to use for the layout
  /// and fade of the [NavigationBarDestination], either a curve, always
  /// showing (1), or always hiding (0).
  final Widget Function(BuildContext, Animation<double>) builder;

  @override
  Widget build(BuildContext context) {
    final NavigationBarDestinationInfo info = NavigationBarDestinationInfo.of(context);
    switch (info.labelBehavior) {
      case NavigationBarDestinationLabelBehavior.alwaysShow:
        return builder(context, kAlwaysCompleteAnimation);
      case NavigationBarDestinationLabelBehavior.alwaysHide:
        return builder(context, kAlwaysDismissedAnimation);
      case NavigationBarDestinationLabelBehavior.onlyShowSelected:
        return _CurvedAnimationBuilder(
          animation: info.selectedAnimation,
          curve: Curves.easeInOutCubicEmphasized,
          reverseCurve: Curves.easeInOutCubicEmphasized.flipped,
          builder: (BuildContext context, Animation<double> curvedAnimation) {
            return builder(context, curvedAnimation);
          },
        );
    }
  }
}

/// Semantics widget for a navigation bar destination.
///
/// Requires a [NavigationBarDestinationInfo] parent (normally provided by the
/// [NavigationBar] by default).
///
/// Provides localized semantic labels to the destination, for example, it will
/// read "Home, Tab 1 of 3".
///
/// Used by [NavigationBarDestinationBuilder].
class NavigationBarDestinationSemantics extends StatelessWidget {
  /// Adds the the appropriate semantics for navigation bar destinations to the
  /// [child].
  const NavigationBarDestinationSemantics({
    Key? key,
    required this.child,
  }) : super(key: key);

  /// The widget that should receive the destination semantics.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final NavigationBarDestinationInfo destinationInfo = NavigationBarDestinationInfo.of(context);
    // The AnimationStatusBuilder will make sure that the semantics update to
    // "selected" when the animation status changes.
    return StatusTransitionWidgetBuilder(
      animation: destinationInfo.selectedAnimation,
      builder: (BuildContext context, Widget? child) {
        return Semantics(
          selected: destinationInfo.selectedAnimation.isForwardOrCompleted,
          container: true,
          child: child,
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          child,
          Semantics(
            label: localizations.tabLabel(
              tabIndex: destinationInfo.destinationNumber + 1,
              tabCount: destinationInfo.totalNumberOfDestinations,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tooltip widget for use in a [NavigationBar].
///
/// It appears just above the navigation bar when one of the destinations is
/// long pressed.
class NavigationBarDestinationTooltip extends StatelessWidget {
  /// Adds a tooltip to the [child] widget.
  const NavigationBarDestinationTooltip({
    Key? key,
    required this.message,
    required this.child,
  }) : super(key: key);

  /// The text that is rendered in the tooltip when it appears.
  final String message;

  /// The widget that, when pressed, will show a tooltip.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      verticalOffset: 42,
      excludeFromSemantics: true,
      preferBelow: false,
      child: child,
    );
  }
}

/// Indicator from the Material 3 Navigation Bar component.
///
/// When [animation] is 0, the indicator is not present. As [animation] grows
/// from 0 to 1, the indicator scales in on the x axis.
///
/// Useful in a [Stack] widget behind the icons in the Material 3 Navigation Bar
/// to illuminate the selected destination.
class NavigationBarIndicator extends StatelessWidget {
  /// Builds an indicator, usually used in a stack behind the icon of a
  /// navigation bar destination.
  const NavigationBarIndicator({
    Key? key,
    required this.animation,
    this.color,
  }) : super(key: key);

  /// Determines the scale of the indicator.
  ///
  /// When [animation] is 0, the indicator is not present. The indicator scales
  /// in as [animation] grows from 0 to 1.
  final Animation<double> animation;

  /// The fill color of this indicator.
  ///
  /// If null, defaults to [ColorScheme.secondary].
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        // The scale should be 0 when the animation is unselected, as soon as
        // the animation starts, the scale jumps to 40%, and then animates to
        // 100% along a curve.
        final double scale = animation.isDismissed
            ? 0.0
            : Tween<double>(
                begin: .4,
                end: 1.0,
              ).transform(
                CurveTween(
                  curve: Curves.easeInOutCubicEmphasized,
                ).transform(animation.value),
              );

        return Transform(
          alignment: Alignment.center,
          // Scale in the X direction only.
          transform: Matrix4.diagonal3Values(
            scale,
            1.0,
            1.0,
          ),
          child: child,
        );
      },
      // Fade should be a 100ms animation whenever the parent animation changes
      // direction.
      child: StatusTransitionWidgetBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          return SelectableAnimatedBuilder(
            isSelected: animation.isForwardOrCompleted,
            duration: const Duration(milliseconds: 100),
            alwaysDoFullAnimation: true,
            builder: (BuildContext context, Animation<double> fadeAnimation) {
              return FadeTransition(
                opacity: fadeAnimation,
                child: Container(
                  width: 64,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: color ?? colorScheme.secondary.withOpacity(.24),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Inherited widget for passing data from the [NavigationBar] to the
/// [NavigationBar.destinations] children widgets.
///
/// Useful for building navigation bar destinations using:
/// `NavigationBarDestinationInfo.of(context)`.
class NavigationBarDestinationInfo extends InheritedWidget {
  /// Adds the information needed to build a navigation bar destination to the
  /// [child] and descendants.
  const NavigationBarDestinationInfo({
    Key? key,
    required this.destinationNumber,
    required this.totalNumberOfDestinations,
    required this.selectedAnimation,
    required this.labelBehavior,
    required this.onTap,
    required Widget child,
  }) : super(key: key, child: child);

  /// Which destination number is this in the navigation bar.
  ///
  /// For example:
  /// ```dart
  /// NavigationBar(
  ///   destinations: [
  ///     NavigationBarDestination(), // This is destination number 0.
  ///     NavigationBarDestination(), // This is destination number 1.
  ///     NavigationBarDestination(), // This is destination number 2.
  ///   ]
  /// )
  /// ```
  ///
  /// This is required for semantics, so that each destination can have a label
  /// "Tab 1 of 3", for example.
  final int destinationNumber;

  /// How many total destinations are are in this navigation bar.
  ///
  /// This is required for semantics, so that each destination can have a label
  /// "Tab 1 of 4", for example.
  final int totalNumberOfDestinations;

  /// Indicates whether or not this destination is selected, from 0 (unselected)
  /// to 1 (selected).
  final Animation<double> selectedAnimation;

  /// Determines the behavior for how the labels will layout.
  ///
  /// Can be used to show all labels (the default), show only the selected
  /// label, or hide all labels.
  final NavigationBarDestinationLabelBehavior labelBehavior;

  /// The callback that should be called when this destination is tapped.
  ///
  /// This is computed by calling [NavigationBar.onTap] with [destinationNumber]
  /// passed in.
  final VoidCallback onTap;

  /// Returns a non null [NavigationBarDestinationInfo].
  ///
  /// This will return an error if called with no [NavigationBarDestinationInfo]
  /// ancestor.
  ///
  /// Used by widgets that are implementing a navigation bar destination info to
  /// get information like the selected animation and destination number.
  static NavigationBarDestinationInfo of(BuildContext context) {
    final NavigationBarDestinationInfo? result = context
        .dependOnInheritedWidgetOfExactType<NavigationBarDestinationInfo>();
    assert(
      result != null,
      'Navigation bar destinations need a NavigationBarDestinationInfo parent, '
      'usually provided by NavigationBar.',
    );
    return result!;
  }

  @override
  bool updateShouldNotify(NavigationBarDestinationInfo oldWidget) =>
      destinationNumber != oldWidget.destinationNumber ||
      totalNumberOfDestinations != oldWidget.totalNumberOfDestinations ||
      selectedAnimation != oldWidget.selectedAnimation ||
      labelBehavior != oldWidget.labelBehavior ||
      onTap != oldWidget.onTap;
}

/// Widget that provides enough padding below a navigation bar to account for
/// the safe areas on the bottom of devices.
///
/// This ensures that the navigation bar extends to the bottom of the screen.
class NavigationBarBottomPadding extends StatelessWidget {
  /// Adds padding below [child] if used on a device with a safe area on the
  /// bottom of the screen.
  const NavigationBarBottomPadding({
    Key? key,
    required this.child,
  }) : super(key: key);

  /// The child widget that should extend to the bottom of the screen.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double additionalBottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: additionalBottomPadding),
      child: MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        child: child,
      ),
    );
  }
}

/// Custom layout delegate for shifting navigation bar destinations.
///
/// This will lay out the icon + label according to the [animation].
///
/// When the [animation] is 0, the icon will be centered, and the label will be
/// positioned directly below it.
///
/// When the [animation] is 1, the label will still be positioned directly below
/// the icon, but the icon + label combination will be centered.
///
/// Used in a [CustomMultiChildLayout] widget in the
/// [NavigationBarDestinationBuilder].
class _NavigationBarDestinationLayoutDelegate extends MultiChildLayoutDelegate {
  _NavigationBarDestinationLayoutDelegate({required this.animation})
      : super(relayout: animation);

  /// The selection animation that indicates whether or not this destination is
  /// selected.
  ///
  /// See [NavigationBarDestinationInfo.selectedAnimation].
  final Animation<double> animation;

  /// ID for the icon widget child.
  ///
  /// This is used by the [LayoutId] when this delegate is used in a
  /// [CustomMultiChildLayout].
  ///
  /// See [NavigationBarDestinationBuilder].
  static const int iconId = 1;

  /// ID for the label widget child.
  ///
  /// This is used by the [LayoutId] when this delegate is used in a
  /// [CustomMultiChildLayout].
  ///
  /// See [NavigationBarDestinationBuilder].
  static const int labelId = 2;

  @override
  void performLayout(Size size) {
    double halfWidth(Size size) => size.width / 2;
    double halfHeight(Size size) => size.height / 2;

    final Size iconSize = layoutChild(iconId, BoxConstraints.loose(size));
    final Size labelSize = layoutChild(labelId, BoxConstraints.loose(size));

    final double yPositionOffset = Tween<double>(
      // When unselected, the icon is centered vertically.
      begin: halfHeight(iconSize),
      // When selected, the icon and label are centered vertically.
      end: halfHeight(iconSize) + halfHeight(labelSize),
    ).transform(animation.value);
    final double iconYPosition = halfHeight(size) - yPositionOffset;

    // Position the icon.
    positionChild(
      iconId,
      Offset(
        // Center the icon horizontally.
        halfWidth(size) - halfWidth(iconSize),
        iconYPosition,
      ),
    );

    // Position the label.
    positionChild(
      labelId,
      Offset(
        // Center the label horizontally.
        halfWidth(size) - halfWidth(labelSize),
        // Label always appears directly below the icon.
        iconYPosition + iconSize.height,
      ),
    );
  }

  @override
  bool shouldRelayout(_NavigationBarDestinationLayoutDelegate oldDelegate) {
    return oldDelegate.animation != animation;
  }
}


/// Utility Widgets

/// Clamps [MediaQuery.textScaleFactor] so that if it is greater than
/// [upperLimit] or less than [lowerLimit], [upperLimit] or [lowerLimit] will be
/// used instead for the [child] widget.
///
/// Example:
/// ```
/// _ClampTextScaleFactor(
///   upperLimit: 2.0,
///   child: Text('Foo'), // If textScaleFactor is 3.0, this will only scale 2x.
/// )
/// ```
class ClampTextScaleFactor extends StatelessWidget {
  /// Clamps the text scale factor of descendants by modifying the [MediaQuery]
  /// surrounding [child].
  const ClampTextScaleFactor({
    Key? key,
    this.lowerLimit = 0,
    this.upperLimit = double.infinity,
    required this.child,
  }) : super(key: key);

  /// The minimum amount that the text scale factor should be for the [child]
  /// widget.
  ///
  /// If this is `.5`, the textScaleFactor for child widgets will never be
  /// smaller than `.5`.
  final double lowerLimit;

  /// The maximum amount that the text scale factor should be for the [child]
  /// widget.
  ///
  /// If this is `1.5`, the textScaleFactor for child widgets will never be
  /// greater than `1.5`.
  final double upperLimit;

  /// The [Widget] that should have its (and its descendants) text scale factor
  /// clamped.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    return MediaQuery(
      data: mediaQuery.copyWith(
        textScaleFactor: mediaQuery.textScaleFactor.clamp(
          lowerLimit,
          upperLimit,
        ),
      ),
      child: child,
    );
  }
}

/// Widget that listens to an animation, and rebuilds when the animation changes
/// [AnimationStatus].
///
/// This can be more efficient than just using an [AnimatedBuilder] when you
/// only need to rebuild when the [Animation.status] changes, since
/// [AnimatedBuilder] rebuilds every time the animation ticks.
class StatusTransitionWidgetBuilder extends StatusTransitionWidget {
  /// Creates a widget that rebuilds when the given animation changes status.
  const StatusTransitionWidgetBuilder({
    Key? key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(animation: animation, key: key);

  /// Called every time the [animation] changes [AnimationStatus].
  final TransitionBuilder builder;

  /// The child widget to pass to the [builder].
  ///
  /// If a [builder] callback's return value contains a subtree that does not
  /// depend on the animation, it's more efficient to build that subtree once
  /// instead of rebuilding it on every animation status change.
  ///
  /// Using this pre-built child is entirely optional, but can improve
  /// performance in some cases and is therefore a good practice.
  ///
  /// See: [AnimatedBuilder.child]
  final Widget? child;

  @override
  Widget build(BuildContext context) => builder(context, child);
}

/// Builder widget for widgets that need to be animated from 0 (unselected) to
/// 1.0 (selected).
///
/// This widget creates and manages an [AnimationController] that it passes down
/// to the child through the [builder] function.
///
/// When [isSelected] is `true`, the animation controller will animate from
/// 0 to 1 (for [duration] time).
///
/// When [isSelected] is `false`, the animation controller will animate from
/// 1 to 0 (for [duration] time).
///
/// If [isSelected] is updated while the widget is animating, the animation will
/// be reversed until it is either 0 or 1 again. If [alwaysDoFullAnimation] is
/// true, the animation will reset to 0 or 1 before beginning the animation, so
/// that the full animation is done.
///
/// Usage:
/// ```dart
/// SelectableAnimatedBuilder(
///   isSelected: _isDrawerOpen,
///   builder: (context, animation) {
///     return AnimatedIcon(
///       icon: AnimatedIcons.menu_arrow,
///       progress: animation,
///       semanticLabel: 'Show menu',
///     );
///   }
/// )
/// ```
class SelectableAnimatedBuilder extends StatefulWidget {
  /// Builds and maintains an [AnimationController] that will animate from 0 to
  /// 1 and back depending on when [isSelected] is true.
  const SelectableAnimatedBuilder({
    Key? key,
    required this.isSelected,
    this.duration = const Duration(milliseconds: 200),
    this.alwaysDoFullAnimation = false,
    required this.builder,
  }) : super(key: key);

  /// When true, the widget will animate an animation controller from 0 to 1.
  ///
  /// The animation controller is passed to the child widget through [builder].
  final bool isSelected;

  /// How long the animation controller should animate for when [isSelected] is
  /// updated.
  ///
  /// If the animation is currently running and [isSelected] is updated, only
  /// the [duration] left to finish the animation will be run.
  final Duration duration;

  /// If true, the animation will always go all the way from 0 to 1 when
  /// [isSelected] is true, and from 1 to 0 when [isSelected] is false, even
  /// when the status changes mid animation.
  ///
  /// If this is false and the status changes mid animation, the animation will
  /// reverse direction from it's current point.
  ///
  /// Defaults to false.
  final bool alwaysDoFullAnimation;

  /// Builds the child widget based on the current animation status.
  ///
  /// When [isSelected] is updated to true, this builder will be called and the
  /// animation will animate up to 1. When [isSelected] is updated to
  /// `false`, this will be called and the animation will animate down to 0.
  final Widget Function(BuildContext, Animation<double>) builder;

  @override
  SelectableAnimatedBuilderState createState() =>
      SelectableAnimatedBuilderState();
}

/// State that manages the [AnimationController] that is passed to
/// [SelectableAnimatedBuilder.builder].
class SelectableAnimatedBuilderState extends State<SelectableAnimatedBuilder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _controller.duration = widget.duration;
    _controller.value = widget.isSelected ? 1.0 : 0.0;
  }

  @override
  void didUpdateWidget(SelectableAnimatedBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.isSelected != widget.isSelected) {
      widget.isSelected
          ? _controller.forward(from: widget.alwaysDoFullAnimation ? 0 : null)
          : _controller.reverse(from: widget.alwaysDoFullAnimation ? 1 : null);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      _controller,
    );
  }
}

/// Watches [animation] and calls [builder] with the appropriate [Curve]
/// depending on the direction of the [animation] status.
///
/// If [animation.status] is forward or complete, [curve] is used. If
/// [animation.status] is reverse or dismissed, [reverseCurve] is used.
///
/// If the [animation] changes direction while it is already running, the curve
/// used will not change, this will keep the animations smooth until it
/// completes.
///
/// This is similar to [CurvedAnimation] except the animation status listeners
/// are removed when this widget is disposed.
class _CurvedAnimationBuilder extends StatefulWidget {
  const _CurvedAnimationBuilder({
    Key? key,
    required this.animation,
    required this.curve,
    required this.reverseCurve,
    required this.builder,
  }) : super(key: key);

  final Animation<double> animation;
  final Curve curve;
  final Curve reverseCurve;
  final Widget Function(BuildContext, Animation<double>) builder;

  @override
  _CurvedAnimationBuilderState createState() => _CurvedAnimationBuilderState();
}

class _CurvedAnimationBuilderState extends State<_CurvedAnimationBuilder> {
  late AnimationStatus _animationDirection;
  AnimationStatus? _preservedDirection;

  @override
  void initState() {
    super.initState();
    _animationDirection = widget.animation.status;
    _updateStatus(widget.animation.status);
    widget.animation.addStatusListener(_updateStatus);
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_updateStatus);
    super.dispose();
  }

  // Keeps track of the current animation status, as well as the "preserved
  // direction" when the animation changes direction mid animation.
  //
  // The preserved direction is reset when the animation finishes in either
  // direction.
  void _updateStatus(AnimationStatus status) {
    if (_animationDirection != status) {
      setState(() {
        _animationDirection = status;
      });
    }

    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      setState(() {
        _preservedDirection = null;
      });
    }

    if (_preservedDirection == null &&
        (status == AnimationStatus.forward ||
            status == AnimationStatus.reverse)) {
      setState(() {
        _preservedDirection = status;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool shouldUseForwardCurve =
        (_preservedDirection ?? _animationDirection) != AnimationStatus.reverse;

    final Animation<double> curvedAnimation = CurveTween(
      curve: shouldUseForwardCurve ? widget.curve : widget.reverseCurve,
    ).animate(widget.animation);

    return widget.builder(context, curvedAnimation);
  }
}

/// Convenience static extensions on Animation.
extension _AnimationUtils on Animation<double> {
  /// Returns `true` if this animation is ticking forward, or has completed,
  /// based on [status].
  bool get isForwardOrCompleted =>
      status == AnimationStatus.forward || status == AnimationStatus.completed;
}
