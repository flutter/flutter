// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'bottom_navigation_bar.dart';
/// @docImport 'floating_action_button.dart';
library;

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'color_scheme.dart';
import 'colors.dart';
import 'icon_button.dart';
import 'icons.dart';
import 'material.dart';
import 'material_localizations.dart';
import 'scaffold.dart';
import 'snack_bar_theme.dart';
import 'text_button.dart';
import 'text_button_theme.dart';
import 'theme.dart';

// Examples can assume:
// late BuildContext context;

const double _singleLineVerticalPadding = 14.0;
const Duration _snackBarTransitionDuration = Duration(milliseconds: 250);
const Duration _snackBarDisplayDuration = Duration(milliseconds: 4000);
const Curve _snackBarHeightCurve = Curves.fastOutSlowIn;
const Curve _snackBarM3HeightCurve = Curves.easeInOutQuart;

const Curve _snackBarFadeInCurve = Interval(0.4, 1.0);
const Curve _snackBarM3FadeInCurve = Interval(0.4, 0.6, curve: Curves.easeInCirc);
const Curve _snackBarFadeOutCurve = Interval(0.72, 1.0, curve: Curves.fastOutSlowIn);

/// Specify how a [SnackBar] was closed.
///
/// The [ScaffoldMessengerState.showSnackBar] function returns a
/// [ScaffoldFeatureController]. The value of the controller's closed property
/// is a Future that resolves to a SnackBarClosedReason. Applications that need
/// to know how a snackbar was closed can use this value.
///
/// Example:
///
/// ```dart
/// ScaffoldMessenger.of(context).showSnackBar(
///   const SnackBar(
///     content: Text('He likes me. I think he likes me.'),
///   )
/// ).closed.then((SnackBarClosedReason reason) {
///    // ...
/// });
/// ```
enum SnackBarClosedReason {
  /// The snack bar was closed after the user tapped a [SnackBarAction].
  action,

  /// The snack bar was closed through a [SemanticsAction.dismiss].
  dismiss,

  /// The snack bar was closed by a user's swipe.
  swipe,

  /// The snack bar was closed by the [ScaffoldFeatureController] close callback
  /// or by calling [ScaffoldMessengerState.hideCurrentSnackBar] directly.
  hide,

  /// The snack bar was closed by an call to [ScaffoldMessengerState.removeCurrentSnackBar].
  remove,

  /// The snack bar was closed because its timer expired.
  timeout,
}

/// A button for a [SnackBar], known as an "action".
///
/// Snack bar actions are always enabled. Instead of disabling a snack bar
/// action, avoid including it in the snack bar in the first place.
///
/// Snack bar actions can only be pressed once. Subsequent presses are ignored.
///
/// See also:
///
///  * [SnackBar]
///  * <https://material.io/design/components/snackbars.html>
class SnackBarAction extends StatefulWidget {
  /// Creates an action for a [SnackBar].
  const SnackBarAction({
    super.key,
    this.textColor,
    this.disabledTextColor,
    this.backgroundColor,
    this.disabledBackgroundColor,
    required this.label,
    required this.onPressed,
  }) : assert(
         backgroundColor is! WidgetStateColor || disabledBackgroundColor == null,
         'disabledBackgroundColor must not be provided when background color is '
         'a WidgetStateColor',
       );

  /// The button label color. If not provided, defaults to
  /// [SnackBarThemeData.actionTextColor].
  ///
  /// If [textColor] is a [WidgetStateColor], then the text color will be
  /// resolved against the set of [WidgetState]s that the action text
  /// is in, thus allowing for different colors for states such as pressed,
  /// hovered and others.
  final Color? textColor;

  /// The button background fill color. If not provided, defaults to
  /// [SnackBarThemeData.actionBackgroundColor].
  ///
  /// If [backgroundColor] is a [WidgetStateColor], then the text color will
  /// be resolved against the set of [WidgetState]s that the action text is
  /// in, thus allowing for different colors for the states.
  final Color? backgroundColor;

  /// The button disabled label color. This color is shown after the
  /// [SnackBarAction] is dismissed.
  final Color? disabledTextColor;

  /// The button disabled background color. This color is shown after the
  /// [SnackBarAction] is dismissed.
  ///
  /// If not provided, defaults to [SnackBarThemeData.disabledActionBackgroundColor].
  final Color? disabledBackgroundColor;

  /// The button label.
  final String label;

  /// The callback to be called when the button is pressed.
  ///
  /// This callback will be called at most once each time this action is
  /// displayed in a [SnackBar].
  final VoidCallback onPressed;

  @override
  State<SnackBarAction> createState() => _SnackBarActionState();
}

class _SnackBarActionState extends State<SnackBarAction> {
  bool _haveTriggeredAction = false;

  void _handlePressed() {
    if (_haveTriggeredAction) {
      return;
    }
    setState(() {
      _haveTriggeredAction = true;
    });
    widget.onPressed();
    ScaffoldMessenger.of(context).hideCurrentSnackBar(reason: SnackBarClosedReason.action);
  }

  @override
  Widget build(BuildContext context) {
    final SnackBarThemeData defaults = Theme.of(context).useMaterial3
        ? _SnackbarDefaultsM3(context)
        : _SnackbarDefaultsM2(context);
    final SnackBarThemeData snackBarTheme = SnackBarTheme.of(context);

    WidgetStateColor resolveForegroundColor() {
      if (widget.textColor != null) {
        if (widget.textColor is WidgetStateColor) {
          return widget.textColor! as WidgetStateColor;
        }
      } else if (snackBarTheme.actionTextColor != null) {
        if (snackBarTheme.actionTextColor is WidgetStateColor) {
          return snackBarTheme.actionTextColor! as WidgetStateColor;
        }
      } else if (defaults.actionTextColor != null) {
        if (defaults.actionTextColor is WidgetStateColor) {
          return defaults.actionTextColor! as WidgetStateColor;
        }
      }

      return WidgetStateColor.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return widget.disabledTextColor ??
              snackBarTheme.disabledActionTextColor ??
              defaults.disabledActionTextColor!;
        }
        return widget.textColor ?? snackBarTheme.actionTextColor ?? defaults.actionTextColor!;
      });
    }

    WidgetStateColor? resolveBackgroundColor() {
      if (widget.backgroundColor is WidgetStateColor) {
        return widget.backgroundColor! as WidgetStateColor;
      }
      if (snackBarTheme.actionBackgroundColor is WidgetStateColor) {
        return snackBarTheme.actionBackgroundColor! as WidgetStateColor;
      }
      return WidgetStateColor.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return widget.disabledBackgroundColor ??
              snackBarTheme.disabledActionBackgroundColor ??
              Colors.transparent;
        }
        return widget.backgroundColor ?? snackBarTheme.actionBackgroundColor ?? Colors.transparent;
      });
    }

    return TextButton(
      style: TextButton.styleFrom(overlayColor: resolveForegroundColor()).copyWith(
        foregroundColor: resolveForegroundColor(),
        backgroundColor: resolveBackgroundColor(),
      ),
      onPressed: _haveTriggeredAction ? null : _handlePressed,
      child: Text(widget.label),
    );
  }
}

/// A lightweight message with an optional action which briefly displays at the
/// bottom of the screen.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=zpO6n_oZWw0}
///
/// To display a snack bar, call `ScaffoldMessenger.of(context).showSnackBar()`,
/// passing an instance of [SnackBar] that describes the message.
///
/// To control how long the [SnackBar] remains visible, specify a [duration].
///
/// A SnackBar with an action will not time out when TalkBack or VoiceOver are
/// enabled. This is controlled by [AccessibilityFeatures.accessibleNavigation].
///
/// During page transitions, the [SnackBar] will smoothly animate to its
/// location on the other page. For example if the [SnackBar.behavior] is set to
/// [SnackBarBehavior.floating] and the next page has a floating action button,
/// while the current one does not, the [SnackBar] will smoothly animate above
/// the floating action button. It also works in the case of a back gesture
/// transition.
///
/// {@tool dartpad}
/// Here is an example of a [SnackBar] with an [action] button implemented using
/// [SnackBarAction].
///
/// ** See code in examples/api/lib/material/snack_bar/snack_bar.0.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// Here is an example of a customized [SnackBar]. It utilizes
/// [behavior], [shape], [padding], [width], and [duration] to customize the
/// location, appearance, and the duration for which the [SnackBar] is visible.
///
/// ** See code in examples/api/lib/material/snack_bar/snack_bar.1.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// This example demonstrates the various [SnackBar] widget components,
/// including an optional icon, in either floating or fixed format.
///
/// ** See code in examples/api/lib/material/snack_bar/snack_bar.2.dart **
/// {@end-tool}
///
/// See also:
///
///  * [ScaffoldMessenger.of], to obtain the current [ScaffoldMessengerState],
///    which manages the display and animation of snack bars.
///  * [ScaffoldMessengerState.showSnackBar], which displays a [SnackBar].
///  * [ScaffoldMessengerState.removeCurrentSnackBar], which abruptly hides the
///    currently displayed snack bar, if any, and allows the next to be displayed.
///  * [SnackBarAction], which is used to specify an [action] button to show
///    on the snack bar.
///  * [SnackBarThemeData], to configure the default property values for
///    [SnackBar] widgets.
///  * <https://material.io/design/components/snackbars.html>
class SnackBar extends StatefulWidget {
  /// Creates a snack bar.
  ///
  /// The [elevation] must be null or non-negative.
  const SnackBar({
    super.key,
    required this.content,
    this.backgroundColor,
    this.elevation,
    this.margin,
    this.padding,
    this.width,
    this.shape,
    this.hitTestBehavior,
    this.behavior,
    this.action,
    this.actionOverflowThreshold,
    this.showCloseIcon,
    this.closeIconColor,
    this.duration = _snackBarDisplayDuration,
    bool? persist,
    this.animation,
    this.onVisible,
    this.dismissDirection,
    this.clipBehavior = Clip.hardEdge,
  }) : assert(elevation == null || elevation >= 0.0),
       assert(width == null || margin == null, 'Width and margin can not be used together'),
       assert(
         actionOverflowThreshold == null ||
             (actionOverflowThreshold >= 0 && actionOverflowThreshold <= 1),
         'Action overflow threshold must be between 0 and 1 inclusive',
       ),
       persist = persist ?? action != null;

  /// The primary content of the snack bar.
  ///
  /// Typically a [Text] widget.
  final Widget content;

  /// The snack bar's background color.
  ///
  /// If not specified, the ambient [SnackBarThemeData.backgroundColor] is used.
  /// If that is not specified it will default to a
  /// dark variation of [ColorScheme.surface] for light themes, or
  /// [ColorScheme.onSurface] for dark themes.
  final Color? backgroundColor;

  /// The z-coordinate at which to place the snack bar. This controls the size
  /// of the shadow below the snack bar.
  ///
  /// Defines the card's [Material.elevation].
  ///
  /// If this property is null, then the ambient [SnackBarThemeData.elevation]
  /// is used, if that is also null, the default value is 6.0.
  final double? elevation;

  /// Empty space to surround the snack bar.
  ///
  /// This property is only used when [behavior] is [SnackBarBehavior.floating].
  /// It can not be used if [width] is specified.
  ///
  /// If this property is null, then the ambient [SnackBarThemeData.insetPadding]
  /// is used. If that is also null, then the default is
  /// `EdgeInsets.fromLTRB(15.0, 5.0, 15.0, 10.0)`.
  ///
  /// If this property is not null and [hitTestBehavior] is null, then [hitTestBehavior] default is [HitTestBehavior.deferToChild].
  final EdgeInsetsGeometry? margin;

  /// The amount of padding to apply to the snack bar's content and optional
  /// action.
  ///
  /// If this property is null, the default padding values are as follows:
  ///
  /// * [content]
  ///     * Top and bottom paddings are 14.
  ///     * Left padding is 24 if [behavior] is [SnackBarBehavior.fixed],
  ///       16 if [behavior] is [SnackBarBehavior.floating].
  ///     * Right padding is same as start padding if there is no [action],
  ///       otherwise 0.
  /// * [action]
  ///     * Top and bottom paddings are 14.
  ///     * Left and right paddings are half of [content]'s left padding.
  ///
  /// If this property is not null, the padding is as follows:
  ///
  /// * [content]
  ///     * Left, top and bottom paddings are assigned normally.
  ///     * Right padding is assigned normally if there is no [action],
  ///       otherwise 0.
  /// * [action]
  ///     * Left padding is replaced with half the right padding.
  ///     * Top and bottom paddings are assigned normally.
  ///     * Right padding is replaced with one and a half times the
  ///       right padding.
  final EdgeInsetsGeometry? padding;

  /// The width of the snack bar.
  ///
  /// If width is specified, the snack bar will be centered horizontally in the
  /// available space. This property is only used when [behavior] is
  /// [SnackBarBehavior.floating]. It can not be used if [margin] is specified.
  ///
  /// If this property is null, then the ambient [SnackBarThemeData.width]
  /// is used. If that is null, the snack bar will take up the full device
  /// width less the margin.
  final double? width;

  /// The shape of the snack bar's [Material].
  ///
  /// Defines the snack bar's [Material.shape].
  ///
  /// If this property is null, then the ambient [SnackBarThemeData.shape]
  /// is used. If that's null then the shape will
  /// depend on the [SnackBarBehavior]. For [SnackBarBehavior.fixed], no
  /// overriding shape is specified, so the [SnackBar] is rectangular. For
  /// [SnackBarBehavior.floating], it uses a [RoundedRectangleBorder] with a
  /// circular corner radius of 4.0.
  final ShapeBorder? shape;

  /// Defines how the snack bar area, including margin, will behave during hit testing.
  ///
  /// If this property is null, and [margin] is not null or the ambient
  /// [SnackBarThemeData.insetPadding] is not null, then
  /// [HitTestBehavior.deferToChild] is used by default.
  ///
  /// Please refer to [HitTestBehavior] for a detailed explanation of every behavior.
  final HitTestBehavior? hitTestBehavior;

  /// This defines the behavior and location of the snack bar.
  ///
  /// Defines where a [SnackBar] should appear within a [Scaffold] and how its
  /// location should be adjusted when the scaffold also includes a
  /// [FloatingActionButton] or a [BottomNavigationBar]
  ///
  /// If this property is null, then the ambient [SnackBarThemeData.behavior]
  /// is used. If that is null, then the default is [SnackBarBehavior.fixed].
  ///
  /// If this value is [SnackBarBehavior.floating], the length of the bar
  /// is defined by either [width] or [margin].
  final SnackBarBehavior? behavior;

  /// (optional) An action that the user can take based on the snack bar.
  ///
  /// For example, the snack bar might let the user undo the operation that
  /// prompted the snackbar. Snack bars can have at most one action.
  ///
  /// The action should not be "dismiss" or "cancel".
  final SnackBarAction? action;

  /// (optional) The percentage threshold for action widget's width before it overflows
  /// to a new line.
  ///
  /// Must be between 0 and 1.
  /// If the width of the [action] divided by the total snackbar width
  /// is greater than this percentage, the [action] will appear below the [content].
  ///
  /// At a value of 0, the action will always overflow to a new line.
  ///
  /// Defaults to 0.50.
  final double? actionOverflowThreshold;

  /// (optional) Whether to include a "close" icon widget.
  ///
  /// Tapping the icon will close the snack bar.
  final bool? showCloseIcon;

  /// An optional color for the close icon, if [showCloseIcon] is
  /// true.
  ///
  /// If this property is null, then the ambient [SnackBarThemeData.closeIconColor]
  /// is used. If that is null, then the default is inverse surface.
  ///
  /// If [closeIconColor] is a [WidgetStateColor], then the icon color will be
  /// resolved against the set of [WidgetState]s that the action text
  /// is in, thus allowing for different colors for states such as pressed,
  /// hovered and others.
  final Color? closeIconColor;

  /// The amount of time the snack bar should be displayed.
  ///
  /// Defaults to 4.0s.
  ///
  /// See also:
  ///
  ///  * [ScaffoldMessengerState.removeCurrentSnackBar], which abruptly hides the
  ///    currently displayed snack bar, if any, and allows the next to be
  ///    displayed.
  ///  * <https://material.io/design/components/snackbars.html>
  final Duration duration;

  /// Whether the snack bar will stay or auto-dismiss after timeout.
  ///
  /// If true, the snack bar remains visible even after the timeout, until the
  /// user taps the action button or the close icon.
  ///
  /// If false, the snack bar will be dismissed after the timeout.
  ///
  /// If not provided, but the snackbar action is not null, the snackbar will
  /// persist as well.
  final bool persist;

  /// The animation driving the entrance and exit of the snack bar.
  final Animation<double>? animation;

  /// Called the first time that the snackbar is visible within a [Scaffold].
  ///
  /// When multiple [Scaffold]s are registered to the same [ScaffoldMessengerState],
  /// [onVisible] is called once for each scaffold.
  ///
  /// See also:
  ///
  ///  * [ScaffoldMessenger], which manages [SnackBar]s for [Scaffold] descendants.
  final VoidCallback? onVisible;

  /// The direction in which the SnackBar can be dismissed.
  ///
  /// If this property is null, then the ambient [SnackBarThemeData.dismissDirection]
  /// is used. If that is null, then the default is [DismissDirection.down].
  final DismissDirection? dismissDirection;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.hardEdge].
  final Clip clipBehavior;

  // API for ScaffoldMessengerState.showSnackBar():

  /// Creates an animation controller useful for driving a snack bar's entrance and exit animation.
  static AnimationController createAnimationController({
    required TickerProvider vsync,
    Duration? duration,
    Duration? reverseDuration,
  }) {
    return AnimationController(
      duration: duration ?? _snackBarTransitionDuration,
      reverseDuration: reverseDuration,
      debugLabel: 'SnackBar',
      vsync: vsync,
    );
  }

  /// Creates a copy of this snack bar but with the animation replaced with the given animation.
  ///
  /// If the original snack bar lacks a key, the newly created snack bar will
  /// use the given fallback key.
  SnackBar withAnimation(Animation<double> newAnimation, {Key? fallbackKey}) {
    return SnackBar(
      key: key ?? fallbackKey,
      content: content,
      backgroundColor: backgroundColor,
      elevation: elevation,
      margin: margin,
      padding: padding,
      width: width,
      shape: shape,
      hitTestBehavior: hitTestBehavior,
      behavior: behavior,
      action: action,
      actionOverflowThreshold: actionOverflowThreshold,
      showCloseIcon: showCloseIcon,
      closeIconColor: closeIconColor,
      duration: duration,
      persist: persist,
      animation: newAnimation,
      onVisible: onVisible,
      dismissDirection: dismissDirection,
      clipBehavior: clipBehavior,
    );
  }

  @override
  State<SnackBar> createState() => _SnackBarState();
}

class _SnackBarState extends State<SnackBar> {
  bool _wasVisible = false;

  CurvedAnimation? _heightAnimation;
  CurvedAnimation? _fadeInAnimation;
  CurvedAnimation? _fadeInM3Animation;
  CurvedAnimation? _fadeOutAnimation;
  CurvedAnimation? _heightM3Animation;

  final Key _dismissibleKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    widget.animation!.addStatusListener(_onAnimationStatusChanged);
    _setAnimations();
  }

  @override
  void didUpdateWidget(SnackBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animation != oldWidget.animation) {
      oldWidget.animation!.removeStatusListener(_onAnimationStatusChanged);
      widget.animation!.addStatusListener(_onAnimationStatusChanged);
      _disposeAnimations();
      _setAnimations();
    }
  }

  void _setAnimations() {
    assert(widget.animation != null);
    _heightAnimation = CurvedAnimation(parent: widget.animation!, curve: _snackBarHeightCurve);
    _fadeInAnimation = CurvedAnimation(parent: widget.animation!, curve: _snackBarFadeInCurve);
    _fadeInM3Animation = CurvedAnimation(parent: widget.animation!, curve: _snackBarM3FadeInCurve);
    _fadeOutAnimation = CurvedAnimation(
      parent: widget.animation!,
      curve: _snackBarFadeOutCurve,
      reverseCurve: const Threshold(0.0),
    );
    // Material 3 Animation has a height animation on entry, but a direct fade out on exit.
    _heightM3Animation = CurvedAnimation(
      parent: widget.animation!,
      curve: _snackBarM3HeightCurve,
      reverseCurve: const Threshold(0.0),
    );
  }

  void _disposeAnimations() {
    _heightAnimation?.dispose();
    _fadeInAnimation?.dispose();
    _fadeInM3Animation?.dispose();
    _fadeOutAnimation?.dispose();
    _heightM3Animation?.dispose();
    _heightAnimation = null;
    _fadeInAnimation = null;
    _fadeInM3Animation = null;
    _fadeOutAnimation = null;
    _heightM3Animation = null;
  }

  @override
  void dispose() {
    widget.animation!.removeStatusListener(_onAnimationStatusChanged);
    _disposeAnimations();
    super.dispose();
  }

  void _onAnimationStatusChanged(AnimationStatus animationStatus) {
    if (animationStatus.isCompleted) {
      if (widget.onVisible != null && !_wasVisible) {
        widget.onVisible!();
      }
      _wasVisible = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final bool accessibleNavigation = MediaQuery.accessibleNavigationOf(context);
    assert(widget.animation != null);
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final SnackBarThemeData snackBarTheme = SnackBarTheme.of(context);
    final isThemeDark = theme.brightness == Brightness.dark;
    final Color buttonColor = isThemeDark ? colorScheme.primary : colorScheme.secondary;
    final SnackBarThemeData defaults = theme.useMaterial3
        ? _SnackbarDefaultsM3(context)
        : _SnackbarDefaultsM2(context);

    // SnackBar uses a theme that is the opposite brightness from
    // the surrounding theme.
    final Brightness brightness = isThemeDark ? Brightness.light : Brightness.dark;

    // Invert the theme values for Material 2. Material 3 values are tokenized to pre-inverted values.
    final ThemeData effectiveTheme = theme.useMaterial3
        ? theme
        : theme.copyWith(
            colorScheme: ColorScheme(
              primary: colorScheme.onPrimary,
              secondary: buttonColor,
              surface: colorScheme.onSurface,
              background: defaults.backgroundColor,
              error: colorScheme.onError,
              onPrimary: colorScheme.primary,
              onSecondary: colorScheme.secondary,
              onSurface: colorScheme.surface,
              onBackground: colorScheme.background,
              onError: colorScheme.error,
              brightness: brightness,
            ),
          );

    final TextStyle? contentTextStyle = snackBarTheme.contentTextStyle ?? defaults.contentTextStyle;
    final SnackBarBehavior snackBarBehavior =
        widget.behavior ?? snackBarTheme.behavior ?? defaults.behavior!;
    final double? width = widget.width ?? snackBarTheme.width;
    assert(() {
      // Whether the behavior is set through the constructor or the theme,
      // assert that other properties are configured properly.
      if (snackBarBehavior != SnackBarBehavior.floating) {
        String message(String parameter) {
          final prefix = '$parameter can only be used with floating behavior.';
          if (widget.behavior != null) {
            return '$prefix SnackBarBehavior.fixed was set in the SnackBar constructor.';
          } else if (snackBarTheme.behavior != null) {
            return '$prefix SnackBarBehavior.fixed was set by the inherited SnackBarThemeData.';
          } else {
            return '$prefix SnackBarBehavior.fixed was set by default.';
          }
        }

        assert(widget.margin == null, message('Margin'));
        assert(width == null, message('Width'));
      }
      return true;
    }());

    final bool showCloseIcon =
        widget.showCloseIcon ?? snackBarTheme.showCloseIcon ?? defaults.showCloseIcon!;

    final isFloatingSnackBar = snackBarBehavior == SnackBarBehavior.floating;
    final horizontalPadding = isFloatingSnackBar ? 16.0 : 24.0;

    final IconButton? iconButton = showCloseIcon
        ? IconButton(
            key: StandardComponentType.closeButton.key,
            icon: const Icon(Icons.close),
            iconSize: 24.0,
            // constraints: const BoxConstraints(),
            // padding: EdgeInsets.zero,
            color: widget.closeIconColor ?? snackBarTheme.closeIconColor ?? defaults.closeIconColor,
            onPressed: () => ScaffoldMessenger.of(
              context,
            ).hideCurrentSnackBar(reason: SnackBarClosedReason.dismiss),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          )
        : null;

    final EdgeInsets margin =
        widget.margin?.resolve(TextDirection.ltr) ??
        snackBarTheme.insetPadding ??
        defaults.insetPadding!;

    final double actionOverflowThreshold =
        widget.actionOverflowThreshold ??
        snackBarTheme.actionOverflowThreshold ??
        defaults.actionOverflowThreshold!;

    final Widget contentWidget = DefaultTextStyle(style: contentTextStyle!, child: widget.content);

    final Widget? actionWidget = widget.action != null
        ? TextButtonTheme(
            data: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: buttonColor,
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              ),
            ),
            child: widget.action!,
          )
        : null;

    Widget snackBar = _SnackBarLayoutWidget(
      textDirection: Directionality.of(context),
      actionOverflowThreshold: actionOverflowThreshold,
      padding: widget.padding,
      content: contentWidget,
      action: actionWidget,
      isFloating: isFloatingSnackBar,
      closeIcon: showCloseIcon ? iconButton : null,
    );

    if (!isFloatingSnackBar) {
      snackBar = SafeArea(top: false, child: snackBar);
    }

    final double elevation = widget.elevation ?? snackBarTheme.elevation ?? defaults.elevation!;
    final Color backgroundColor =
        widget.backgroundColor ?? snackBarTheme.backgroundColor ?? defaults.backgroundColor!;
    final ShapeBorder? shape =
        widget.shape ?? snackBarTheme.shape ?? (isFloatingSnackBar ? defaults.shape : null);
    final DismissDirection dismissDirection =
        widget.dismissDirection ?? snackBarTheme.dismissDirection ?? DismissDirection.down;

    snackBar = Material(
      shape: shape,
      elevation: elevation,
      color: backgroundColor,
      clipBehavior: widget.clipBehavior,
      child: Theme(
        data: effectiveTheme,
        child: accessibleNavigation || theme.useMaterial3
            ? snackBar
            : FadeTransition(opacity: _fadeOutAnimation!, child: snackBar),
      ),
    );

    if (isFloatingSnackBar) {
      // If width is provided, do not include horizontal margins.
      if (width != null) {
        snackBar = Padding(
          padding: EdgeInsets.only(top: margin.top, bottom: margin.bottom),
          child: SizedBox(width: width, child: snackBar),
        );
      } else {
        snackBar = Padding(padding: margin, child: snackBar);
      }
      snackBar = SafeArea(top: false, bottom: false, child: snackBar);
    }

    snackBar = Semantics(
      container: true,
      liveRegion: true,
      onDismiss: () {
        ScaffoldMessenger.of(context).removeCurrentSnackBar(reason: SnackBarClosedReason.dismiss);
      },
      child: Dismissible(
        key: _dismissibleKey,
        direction: dismissDirection,
        resizeDuration: null,
        behavior:
            widget.hitTestBehavior ??
            (widget.margin != null || snackBarTheme.insetPadding != null
                ? HitTestBehavior.deferToChild
                : HitTestBehavior.opaque),
        onDismissed: (DismissDirection direction) {
          ScaffoldMessenger.of(context).removeCurrentSnackBar(reason: SnackBarClosedReason.swipe);
        },
        child: snackBar,
      ),
    );

    final Widget snackBarTransition;
    if (accessibleNavigation) {
      snackBarTransition = snackBar;
    } else if (isFloatingSnackBar && !theme.useMaterial3) {
      snackBarTransition = FadeTransition(opacity: _fadeInAnimation!, child: snackBar);
      // Is Material 3 Floating Snack Bar.
    } else if (isFloatingSnackBar && theme.useMaterial3) {
      snackBarTransition = FadeTransition(
        opacity: _fadeInM3Animation!,
        child: ValueListenableBuilder<double>(
          valueListenable: _heightM3Animation!,
          builder: (BuildContext context, double value, Widget? child) {
            return Align(alignment: Alignment.bottomLeft, heightFactor: value, child: child);
          },
          child: snackBar,
        ),
      );
    } else {
      snackBarTransition = ValueListenableBuilder<double>(
        valueListenable: _heightAnimation!,
        builder: (BuildContext context, double value, Widget? child) {
          return Align(alignment: AlignmentDirectional.topStart, heightFactor: value, child: child);
        },
        child: snackBar,
      );
    }

    return Hero(
      tag: '<SnackBar Hero tag - ${widget.content}>',
      transitionOnUserGestures: true,
      child: ClipRect(clipBehavior: widget.clipBehavior, child: snackBarTransition),
    );
  }
}

enum _SnackBarSlot { content, action, closeIcon }

class _SnackBarLayoutWidget extends SlottedMultiChildRenderObjectWidget<_SnackBarSlot, RenderBox> {
  const _SnackBarLayoutWidget({
    required this.content,
    this.action,
    this.closeIcon,
    required this.actionOverflowThreshold,
    required this.textDirection,
    required this.padding,
    required this.isFloating,
  }) : assert(actionOverflowThreshold >= 0 && actionOverflowThreshold <= 1);

  final Widget content;
  final Widget? action;
  final Widget? closeIcon;
  final double actionOverflowThreshold;
  final TextDirection textDirection;
  final EdgeInsetsGeometry? padding;
  final bool isFloating;

  @override
  Widget? childForSlot(_SnackBarSlot slot) {
    switch (slot) {
      case _SnackBarSlot.content:
        return content;
      case _SnackBarSlot.action:
        return action;
      case _SnackBarSlot.closeIcon:
        return closeIcon;
    }
  }

  @override
  SlottedContainerRenderObjectMixin<_SnackBarSlot, RenderBox> createRenderObject(
    BuildContext context,
  ) {
    return _RenderSnackBarLayout(
      actionOverflowThreshold: actionOverflowThreshold,
      textDirection: textDirection,
      padding: padding,
      isFloating: isFloating,
    );
  }

  @override
  Iterable<_SnackBarSlot> get slots => _SnackBarSlot.values;

  @override
  void updateRenderObject(BuildContext context, _RenderSnackBarLayout renderObject) {
    renderObject
      ..actionOverflowThreshold = actionOverflowThreshold
      ..textDirection = textDirection
      ..padding = padding;
  }
}

class _RenderSnackBarLayout extends RenderBox
    with SlottedContainerRenderObjectMixin<_SnackBarSlot, RenderBox> {
  _RenderSnackBarLayout({
    required double actionOverflowThreshold,
    required TextDirection textDirection,
    required EdgeInsetsGeometry? padding,
    required bool isFloating,
  }) : assert(actionOverflowThreshold >= 0 && actionOverflowThreshold <= 1),
       _actionOverflowThreshold = actionOverflowThreshold,
       _textDirection = textDirection,
       _isFloating = isFloating,
       _padding = padding;

  EdgeInsetsGeometry? _padding;
  double _actionOverflowThreshold;
  TextDirection _textDirection;
  final bool _isFloating;

  double get actionOverflowThreshold => _actionOverflowThreshold;
  set actionOverflowThreshold(double value) {
    assert(value >= 0 && value <= 1);
    if (_actionOverflowThreshold == value) {
      return;
    }
    _actionOverflowThreshold = value;
    markNeedsLayout();
  }

  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
    markNeedsLayout();
  }

  EdgeInsetsGeometry? get padding => _padding;
  set padding(EdgeInsetsGeometry? value) {
    if (_padding == value) {
      return;
    }
    _padding = value;
    markNeedsLayout();
  }

  bool get isFloating => _isFloating;

  @override
  void performLayout() {
    final RenderBox? content = childForSlot(_SnackBarSlot.content);
    final RenderBox? action = childForSlot(_SnackBarSlot.action);
    final RenderBox? closeIcon = childForSlot(_SnackBarSlot.closeIcon);

    if (content == null) {
      size = constraints.smallest;
      return;
    }

    final hasAction = action != null;
    final hasCloseIcon = closeIcon != null;
    final bool hasButtons = hasAction || hasCloseIcon;
    final isLtr = textDirection == TextDirection.ltr;
    final horizontalPadding = isFloating ? 16.0 : 24.0;
    final double availableWidth = constraints.maxWidth;

    final EdgeInsets resolvedPadding =
        _padding?.resolve(textDirection) ??
        EdgeInsetsDirectional.only(
          top: _singleLineVerticalPadding,
          bottom: _singleLineVerticalPadding,
          start: horizontalPadding,
          end: hasButtons ? 0.0 : horizontalPadding,
        ).resolve(textDirection);

    final double verticalPadding = resolvedPadding.top + resolvedPadding.bottom;
    final double edgeWrapPadding = _padding != null
        ? (isLtr ? resolvedPadding.right : resolvedPadding.left)
        : 0.0;
    final double contentSpacePadding = isLtr ? resolvedPadding.left : resolvedPadding.right;

    // Dry Layout
    final double baseButtonMargin = _padding?.resolve(TextDirection.ltr).right ?? horizontalPadding;
    final double actionHorizontalMargin = hasAction ? baseButtonMargin / 2.0 : 0.0;
    final double iconHorizontalMargin = hasCloseIcon ? baseButtonMargin / 12.0 : 0.0;

    final Size dryCloseIconSize = hasCloseIcon
        ? closeIcon.getDryLayout(BoxConstraints(maxHeight: constraints.maxHeight))
        : Size.zero;
    final Size dryActionSize = hasAction
        ? action.getDryLayout(BoxConstraints(maxHeight: constraints.maxHeight))
        : Size.zero;

    final double actionFootprint = hasAction
        ? (dryActionSize.width + actionHorizontalMargin * 2)
        : 0.0;
    final double iconFootprint = hasCloseIcon
        ? (dryCloseIconSize.width + iconHorizontalMargin * 2)
        : 0.0;
    final double totalActionAreaWidth = actionFootprint + iconFootprint + edgeWrapPadding;

    // Overflow check
    var willOverflow = false;
    if (hasButtons && availableWidth > 0 && availableWidth < double.infinity) {
      final double buttonsWidth = dryActionSize.width + dryCloseIconSize.width;
      willOverflow = (buttonsWidth / availableWidth) > actionOverflowThreshold;
    }

    // Calculate content sizes
    double strictContentMaxWidth;
    if (availableWidth == double.infinity) {
      strictContentMaxWidth = double.infinity;
    } else if (hasButtons && !willOverflow) {
      strictContentMaxWidth = math.max(
        0.0,
        availableWidth - contentSpacePadding - totalActionAreaWidth,
      );
    } else {
      strictContentMaxWidth = math.max(0.0, availableWidth - contentSpacePadding - edgeWrapPadding);
    }

    final minContentWidth = strictContentMaxWidth == double.infinity ? 0.0 : strictContentMaxWidth;
    final Size contentSize = ChildLayoutHelper.layoutChild(
      content,
      constraints.copyWith(
        minWidth: minContentWidth,
        maxWidth: strictContentMaxWidth,
        minHeight: 0,
      ),
    );

    final Size closeIconSize = hasCloseIcon
        ? ChildLayoutHelper.layoutChild(closeIcon, BoxConstraints(maxHeight: constraints.maxHeight))
        : Size.zero;
    final Size actionSize = hasAction
        ? ChildLayoutHelper.layoutChild(action, BoxConstraints(maxHeight: constraints.maxHeight))
        : Size.zero;

    final double naturalHeight = contentSize.height + verticalPadding;
    final double maxButtonHeight = math.max(closeIconSize.height, actionSize.height);

    final double totalHeight = !hasButtons
        ? naturalHeight
        : (willOverflow
              ? contentSize.height + maxButtonHeight + resolvedPadding.bottom
              : math.max(naturalHeight, maxButtonHeight));

    size = constraints.constrain(Size(availableWidth, totalHeight));

    // Position the content.
    final double contentX = isLtr
        ? resolvedPadding.left
        : availableWidth - resolvedPadding.left - contentSize.width;
    final double contentY = (!hasButtons || !willOverflow)
        ? (totalHeight - contentSize.height) / 2
        : resolvedPadding.top;

    (content.parentData! as BoxParentData).offset = Offset(contentX, contentY);

    if (!hasButtons) {
      return;
    }

    // Position the buttons.
    final double actionRowTop = resolvedPadding.top + contentSize.height;
    double currentX = isLtr ? availableWidth - edgeWrapPadding : edgeWrapPadding;

    void positionButton(
      RenderBox child,
      Size childSize,
      double horizontalMargin,
      double yOffsetBase,
    ) {
      final double x = isLtr
          ? currentX - horizontalMargin - childSize.width
          : currentX + horizontalMargin;
      final double y = yOffsetBase + (maxButtonHeight - childSize.height) / 2;

      (child.parentData! as BoxParentData).offset = Offset(x, y);

      currentX = isLtr ? x - horizontalMargin : x + childSize.width + horizontalMargin;
    }

    final double buttonYBase = willOverflow ? actionRowTop : (totalHeight - maxButtonHeight) / 2;

    if (hasCloseIcon) {
      positionButton(closeIcon, closeIconSize, iconHorizontalMargin, buttonYBase);
    }
    if (hasAction) {
      positionButton(action, actionSize, actionHorizontalMargin, buttonYBase);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final _SnackBarSlot slot in _SnackBarSlot.values) {
      final RenderBox? child = childForSlot(slot);
      if (child != null) {
        final childParentData = child.parentData! as BoxParentData;
        context.paintChild(child, childParentData.offset + offset);
      }
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final RenderBox child in children) {
      final parentData = child.parentData! as BoxParentData;
      final bool isHit = result.addWithPaintOffset(
        offset: parentData.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          assert(transformed == position - parentData.offset);
          return child.hitTest(result, position: transformed);
        },
      );
      if (isHit) {
        return true;
      }
    }
    return false;
  }

  // Boilerplate for intrinsic dimensions. The actual values are not important
  @override
  double computeMinIntrinsicWidth(double height) => _computeIntrinsicWidth(height, true);
  @override
  double computeMaxIntrinsicWidth(double height) => _computeIntrinsicWidth(height, false);

  double _computeIntrinsicWidth(double height, bool isMin) {
    final double contentWidth = isMin
        ? (childForSlot(_SnackBarSlot.content)?.getMinIntrinsicWidth(height) ?? 0)
        : (childForSlot(_SnackBarSlot.content)?.getMaxIntrinsicWidth(height) ?? 0);
    final double actionWidth = isMin
        ? (childForSlot(_SnackBarSlot.action)?.getMinIntrinsicWidth(double.infinity) ?? 0)
        : (childForSlot(_SnackBarSlot.action)?.getMaxIntrinsicWidth(double.infinity) ?? 0);
    final double closeWidth = isMin
        ? (childForSlot(_SnackBarSlot.closeIcon)?.getMinIntrinsicWidth(double.infinity) ?? 0)
        : (childForSlot(_SnackBarSlot.closeIcon)?.getMaxIntrinsicWidth(double.infinity) ?? 0);
    return contentWidth + actionWidth + closeWidth;
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      computeDryLayout(BoxConstraints(maxWidth: width)).height;
  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeDryLayout(BoxConstraints(maxWidth: width)).height;
}

// Hand coded defaults based on Material Design 2.
class _SnackbarDefaultsM2 extends SnackBarThemeData {
  _SnackbarDefaultsM2(BuildContext context)
    : _theme = Theme.of(context),
      _colors = Theme.of(context).colorScheme,
      super(elevation: 6.0);

  late final ThemeData _theme;
  late final ColorScheme _colors;

  @override
  Color get backgroundColor => _theme.brightness == Brightness.light
      ? Color.alphaBlend(_colors.onSurface.withOpacity(0.80), _colors.surface)
      : _colors.onSurface;

  @override
  TextStyle? get contentTextStyle => ThemeData(
    useMaterial3: _theme.useMaterial3,
    brightness: _theme.brightness == Brightness.light ? Brightness.dark : Brightness.light,
  ).textTheme.titleMedium;

  @override
  SnackBarBehavior get behavior => SnackBarBehavior.fixed;

  @override
  Color get actionTextColor => _colors.secondary;

  @override
  Color get disabledActionTextColor =>
      _colors.onSurface.withOpacity(_theme.brightness == Brightness.light ? 0.38 : 0.3);

  @override
  ShapeBorder get shape =>
      const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4.0)));

  @override
  EdgeInsets get insetPadding => const EdgeInsets.fromLTRB(15.0, 5.0, 15.0, 10.0);

  @override
  bool get showCloseIcon => false;

  @override
  Color get closeIconColor => _colors.onSurface;

  @override
  double get actionOverflowThreshold => 0.50;
}

// BEGIN GENERATED TOKEN PROPERTIES - Snackbar

// Do not edit by hand. The code between the "BEGIN GENERATED" and
// "END GENERATED" comments are generated from data in the Material
// Design token database by the script:
//   dev/tools/gen_defaults/bin/gen_defaults.dart.

// dart format off
class _SnackbarDefaultsM3 extends SnackBarThemeData {
    _SnackbarDefaultsM3(this.context);

  final BuildContext context;
  late final ThemeData _theme = Theme.of(context);
  late final ColorScheme _colors = _theme.colorScheme;

  @override
  Color get backgroundColor => _colors.inverseSurface;

  @override
  Color get actionTextColor =>  WidgetStateColor.resolveWith((Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) {
      return _colors.inversePrimary;
    }
    if (states.contains(WidgetState.pressed)) {
      return _colors.inversePrimary;
    }
    if (states.contains(WidgetState.hovered)) {
      return _colors.inversePrimary;
    }
    if (states.contains(WidgetState.focused)) {
      return _colors.inversePrimary;
    }
    return _colors.inversePrimary;
  });

  @override
  Color get disabledActionTextColor =>
    _colors.inversePrimary;


  @override
  TextStyle get contentTextStyle =>
    Theme.of(context).textTheme.bodyMedium!.copyWith
      (color:  _colors.onInverseSurface,
    );

  @override
  double get elevation => 6.0;

  @override
  ShapeBorder get shape => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4.0)));

  @override
  SnackBarBehavior get behavior => SnackBarBehavior.fixed;

  @override
  EdgeInsets get insetPadding => const EdgeInsets.fromLTRB(15.0, 5.0, 15.0, 10.0);

  @override
  bool get showCloseIcon => false;

  @override
  Color? get closeIconColor => _colors.onInverseSurface;

  @override
  double get actionOverflowThreshold => 0.50;
}
// dart format on

// END GENERATED TOKEN PROPERTIES - Snackbar
