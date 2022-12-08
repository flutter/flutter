// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'banner_theme.dart';
import 'divider.dart';
import 'material.dart';
import 'scaffold.dart';
import 'theme.dart';

// Examples can assume:
// late BuildContext context;

const Duration _materialBannerTransitionDuration = Duration(milliseconds: 250);
const Curve _materialBannerHeightCurve = Curves.fastOutSlowIn;

/// Specify how a [MaterialBanner] was closed.
///
/// The [ScaffoldMessengerState.showMaterialBanner] function returns a
/// [ScaffoldFeatureController]. The value of the controller's closed property
/// is a Future that resolves to a MaterialBannerClosedReason. Applications that need
/// to know how a [MaterialBanner] was closed can use this value.
///
/// Example:
///
/// ```dart
/// ScaffoldMessenger.of(context).showMaterialBanner(
///   const MaterialBanner(
///     content: Text('Message...'),
///     actions: <Widget>[
///       // ...
///     ],
///   )
/// ).closed.then((MaterialBannerClosedReason reason) {
///    // ...
/// });
/// ```
enum MaterialBannerClosedReason {
  /// The material banner was closed through a [SemanticsAction.dismiss].
  dismiss,

  /// The material banner was closed by a user's swipe.
  swipe,

  /// The material banner was closed by the [ScaffoldFeatureController] close callback
  /// or by calling [ScaffoldMessengerState.hideCurrentMaterialBanner] directly.
  hide,

  /// The material banner was closed by a call to [ScaffoldMessengerState.removeCurrentMaterialBanner].
  remove,
}

/// A Material Design banner.
///
/// A banner displays an important, succinct message, and provides actions for
/// users to address (or dismiss the banner). A user action is required for it
/// to be dismissed.
///
/// Banners should be displayed at the top of the screen, below a top app bar.
/// They are persistent and non-modal, allowing the user to either ignore them or
/// interact with them at any time.
///
/// {@tool dartpad}
/// Banners placed directly into the widget tree are static.
///
/// ** See code in examples/api/lib/material/banner/material_banner.0.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// MaterialBanner's can also be presented through a [ScaffoldMessenger].
/// Here is an example where ScaffoldMessengerState.showMaterialBanner() is used to show the MaterialBanner.
///
/// ** See code in examples/api/lib/material/banner/material_banner.1.dart **
/// {@end-tool}
///
/// The [actions] will be placed beside the [content] if there is only one.
/// Otherwise, the [actions] will be placed below the [content]. Use
/// [forceActionsBelow] to override this behavior.
///
/// If the [actions] placed below the [content], they will be laid out in a row.
/// If there isn't sufficient room to display everything, they are laid out
/// in a column instead.
///
/// The [actions] and [content] must be provided. An optional leading widget
/// (typically an [Image]) can also be provided. The [contentTextStyle] and
/// [backgroundColor] can be provided to customize the banner.
///
/// This widget is unrelated to the widgets library [Banner] widget.
class MaterialBanner extends StatefulWidget {
  /// Creates a [MaterialBanner].
  ///
  /// The [actions], [content], and [forceActionsBelow] must be non-null.
  /// The [actions].length must be greater than 0. The [elevation] must be null or
  /// non-negative.
  const MaterialBanner({
    super.key,
    required this.content,
    this.contentTextStyle,
    required this.actions,
    this.elevation,
    this.leading,
    this.backgroundColor,
    this.surfaceTintColor,
    this.shadowColor,
    this.dividerColor,
    this.padding,
    this.leadingPadding,
    this.forceActionsBelow = false,
    this.overflowAlignment = OverflowBarAlignment.end,
    this.animation,
    this.onVisible,
  }) : assert(elevation == null || elevation >= 0.0),
       assert(content != null),
       assert(actions != null),
       assert(forceActionsBelow != null);

  /// The content of the [MaterialBanner].
  ///
  /// Typically a [Text] widget.
  final Widget content;

  /// Style for the text in the [content] of the [MaterialBanner].
  ///
  /// If `null`, [MaterialBannerThemeData.contentTextStyle] is used. If that is
  /// also `null`, [TextTheme.bodyMedium] of [ThemeData.textTheme] is used.
  final TextStyle? contentTextStyle;

  /// The set of actions that are displayed at the bottom or trailing side of
  /// the [MaterialBanner].
  ///
  /// Typically this is a list of [TextButton] widgets.
  final List<Widget> actions;

  /// The z-coordinate at which to place the material banner.
  ///
  /// This controls the size of the shadow below the material banner.
  ///
  /// Defines the banner's [Material.elevation].
  ///
  /// If this property is null, then [MaterialBannerThemeData.elevation] of
  /// [ThemeData.bannerTheme] is used, if that is also null, the default value is 0.
  /// If the elevation is 0, the [Scaffold]'s body will be pushed down by the
  /// MaterialBanner when used with [ScaffoldMessenger].
  final double? elevation;

  /// The (optional) leading widget of the [MaterialBanner].
  ///
  /// Typically an [Icon] widget.
  final Widget? leading;

  /// The color of the surface of this [MaterialBanner].
  ///
  /// If `null`, [MaterialBannerThemeData.backgroundColor] is used. If that is
  /// also `null`, [ColorScheme.surface] of [ThemeData.colorScheme] is used.
  final Color? backgroundColor;

  /// The color used as an overlay on [backgroundColor] to indicate elevation.
  ///
  /// If null, [MaterialBannerThemeData.surfaceTintColor] is used. If that
  /// is also null, the default value is [ColorScheme.surfaceTint].
  ///
  /// See [Material.surfaceTintColor] for more details on how this
  /// overlay is applied.
  final Color? surfaceTintColor;

  /// The color of the shadow below the [MaterialBanner].
  ///
  /// If this property is null, then [MaterialBannerThemeData.shadowColor] of
  /// [ThemeData.bannerTheme] is used. If that is also null, the default value
  /// is null.
  final Color? shadowColor;

  /// The color of the divider.
  ///
  /// If this property is null, then [MaterialBannerThemeData.dividerColor] of
  /// [ThemeData.bannerTheme] is used. If that is also null, the default value
  /// is [ColorScheme.surfaceVariant].
  final Color? dividerColor;

  /// The amount of space by which to inset the [content].
  ///
  /// If the [actions] are below the [content], this defaults to
  /// `EdgeInsetsDirectional.only(start: 16.0, top: 24.0, end: 16.0, bottom: 4.0)`.
  ///
  /// If the [actions] are trailing the [content], this defaults to
  /// `EdgeInsetsDirectional.only(start: 16.0, top: 2.0)`.
  final EdgeInsetsGeometry? padding;

  /// The amount of space by which to inset the [leading] widget.
  ///
  /// This defaults to `EdgeInsetsDirectional.only(end: 16.0)`.
  final EdgeInsetsGeometry? leadingPadding;

  /// An override to force the [actions] to be below the [content] regardless of
  /// how many there are.
  ///
  /// If this is true, the [actions] will be placed below the [content]. If
  /// this is false, the [actions] will be placed on the trailing side of the
  /// [content] if [actions]'s length is 1 and below the [content] if greater
  /// than 1.
  ///
  /// Defaults to false.
  final bool forceActionsBelow;

  /// The horizontal alignment of the [actions] when the [actions] laid out in a column.
  ///
  /// Defaults to [OverflowBarAlignment.end].
  final OverflowBarAlignment overflowAlignment;

  /// The animation driving the entrance and exit of the material banner when presented by the [ScaffoldMessenger].
  final Animation<double>? animation;

  /// Called the first time that the material banner is visible within a [Scaffold] when presented by the [ScaffoldMessenger].
  final VoidCallback? onVisible;

  // API for ScaffoldMessengerState.showMaterialBanner():

  /// Creates an animation controller useful for driving a [MaterialBanner]'s entrance and exit animation.
  static AnimationController createAnimationController({ required TickerProvider vsync }) {
    return AnimationController(
      duration: _materialBannerTransitionDuration,
      debugLabel: 'MaterialBanner',
      vsync: vsync,
    );
  }

  /// Creates a copy of this material banner but with the animation replaced with the given animation.
  ///
  /// If the original material banner lacks a key, the newly created material banner will
  /// use the given fallback key.
  MaterialBanner withAnimation(Animation<double> newAnimation, { Key? fallbackKey }) {
    return MaterialBanner(
      key: key ?? fallbackKey,
      content: content,
      contentTextStyle: contentTextStyle,
      actions: actions,
      elevation: elevation,
      leading: leading,
      backgroundColor: backgroundColor,
      padding: padding,
      leadingPadding: leadingPadding,
      forceActionsBelow: forceActionsBelow,
      overflowAlignment: overflowAlignment,
      animation: newAnimation,
      onVisible: onVisible,
    );
  }

  @override
  State<MaterialBanner> createState() => _MaterialBannerState();
}

class _MaterialBannerState extends State<MaterialBanner> {
  bool _wasVisible = false;

  @override
  void initState() {
    super.initState();
    widget.animation?.addStatusListener(_onAnimationStatusChanged);
  }

  @override
  void didUpdateWidget(MaterialBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animation != oldWidget.animation) {
      oldWidget.animation?.removeStatusListener(_onAnimationStatusChanged);
      widget.animation?.addStatusListener(_onAnimationStatusChanged);
    }
  }

  @override
  void dispose() {
    widget.animation?.removeStatusListener(_onAnimationStatusChanged);
    super.dispose();
  }

  void _onAnimationStatusChanged(AnimationStatus animationStatus) {
    switch (animationStatus) {
      case AnimationStatus.dismissed:
      case AnimationStatus.forward:
      case AnimationStatus.reverse:
        break;
      case AnimationStatus.completed:
        if (widget.onVisible != null && !_wasVisible) {
          widget.onVisible!();
        }
        _wasVisible = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final MediaQueryData mediaQueryData = MediaQuery.of(context);

    assert(widget.actions.isNotEmpty);

    final ThemeData theme = Theme.of(context);
    final MaterialBannerThemeData bannerTheme = MaterialBannerTheme.of(context);
    final MaterialBannerThemeData defaults = theme.useMaterial3 ? _BannerDefaultsM3(context) : _BannerDefaultsM2(context);

    final bool isSingleRow = widget.actions.length == 1 && !widget.forceActionsBelow;
    final EdgeInsetsGeometry padding = widget.padding ?? bannerTheme.padding ?? (isSingleRow
        ? const EdgeInsetsDirectional.only(start: 16.0, top: 2.0)
        : const EdgeInsetsDirectional.only(start: 16.0, top: 24.0, end: 16.0, bottom: 4.0));
    final EdgeInsetsGeometry leadingPadding = widget.leadingPadding
        ?? bannerTheme.leadingPadding
        ?? const EdgeInsetsDirectional.only(end: 16.0);

    final Widget buttonBar = Container(
      alignment: AlignmentDirectional.centerEnd,
      constraints: const BoxConstraints(minHeight: 52.0),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: OverflowBar(
        overflowAlignment: widget.overflowAlignment,
        spacing: 8,
        children: widget.actions,
      ),
    );

    final double elevation = widget.elevation ?? bannerTheme.elevation ?? 0.0;
    final Color backgroundColor = widget.backgroundColor
        ?? bannerTheme.backgroundColor
        ?? defaults.backgroundColor!;
    final Color? surfaceTintColor = widget.surfaceTintColor
        ?? bannerTheme.surfaceTintColor
        ?? defaults.surfaceTintColor;
    final Color? shadowColor = widget.shadowColor
        ?? bannerTheme.shadowColor;
    final Color? dividerColor = widget.dividerColor
        ?? bannerTheme.dividerColor
        ?? defaults.dividerColor;
    final TextStyle? textStyle = widget.contentTextStyle
        ?? bannerTheme.contentTextStyle
        ?? defaults.contentTextStyle;

    Widget materialBanner = Container(
      margin: EdgeInsets.only(bottom: elevation > 0 ? 10.0 : 0.0),
      child: Material(
        elevation: elevation,
        color: backgroundColor,
        surfaceTintColor: surfaceTintColor,
        shadowColor: shadowColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: padding,
              child: Row(
                children: <Widget>[
                  if (widget.leading != null)
                    Padding(
                      padding: leadingPadding,
                      child: widget.leading,
                    ),
                  Expanded(
                    child: DefaultTextStyle(
                      style: textStyle!,
                      child: widget.content,
                    ),
                  ),
                  if (isSingleRow)
                    buttonBar,
                ],
              ),
            ),
            if (!isSingleRow)
              buttonBar,
            if (elevation == 0)
              Divider(height: 0, color: dividerColor),
          ],
        ),
      ),
    );

    // This provides a static banner for backwards compatibility.
    if (widget.animation == null) {
      return materialBanner;
    }

    materialBanner = SafeArea(
      child: materialBanner,
    );

    final CurvedAnimation heightAnimation = CurvedAnimation(parent: widget.animation!, curve: _materialBannerHeightCurve);
    final Animation<Offset> slideOutAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: widget.animation!,
      curve: const Threshold(0.0),
    ));

    materialBanner = Semantics(
      container: true,
      liveRegion: true,
      onDismiss: () {
        ScaffoldMessenger.of(context).removeCurrentMaterialBanner(reason: MaterialBannerClosedReason.dismiss);
      },
      child: mediaQueryData.accessibleNavigation
          ? materialBanner
          : SlideTransition(
        position: slideOutAnimation,
        child: materialBanner,
      ),
    );

    final Widget materialBannerTransition;
    if (mediaQueryData.accessibleNavigation) {
      materialBannerTransition = materialBanner;
    } else {
      materialBannerTransition = AnimatedBuilder(
        animation: heightAnimation,
        builder: (BuildContext context, Widget? child) {
          return Align(
            alignment: AlignmentDirectional.bottomStart,
            heightFactor: heightAnimation.value,
            child: child,
          );
        },
        child: materialBanner,
      );
    }

    return Hero(
      tag: '<MaterialBanner Hero tag - ${widget.content}>',
      child: ClipRect(child: materialBannerTransition),
    );
  }
}

class _BannerDefaultsM2 extends MaterialBannerThemeData {
  _BannerDefaultsM2(this.context)
    : _theme = Theme.of(context),
      super(elevation: 0.0);

  final BuildContext context;
  final ThemeData _theme;

  @override
  Color? get backgroundColor => _theme.colorScheme.surface;

  @override
  TextStyle? get contentTextStyle => _theme.textTheme.bodyMedium;
}

// BEGIN GENERATED TOKEN PROPERTIES - Banner

// Do not edit by hand. The code between the "BEGIN GENERATED" and
// "END GENERATED" comments are generated from data in the Material
// Design token database by the script:
//   dev/tools/gen_defaults/bin/gen_defaults.dart.

// Token database version: v0_143

class _BannerDefaultsM3 extends MaterialBannerThemeData {
  const _BannerDefaultsM3(this.context)
    : super(elevation: 1.0);

  final BuildContext context;

  @override
  Color? get backgroundColor => Theme.of(context).colorScheme.surface;

  @override
  Color? get surfaceTintColor => Theme.of(context).colorScheme.surfaceTint;

  @override
  Color? get dividerColor => Theme.of(context).colorScheme.outlineVariant;

  @override
  TextStyle? get contentTextStyle => Theme.of(context).textTheme.bodyMedium;
}

// END GENERATED TOKEN PROPERTIES - Banner
