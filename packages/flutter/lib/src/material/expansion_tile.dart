// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'circle_avatar.dart';
/// @docImport 'text_theme.dart';
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'color_scheme.dart';
import 'colors.dart';
import 'expansion_tile_theme.dart';
import 'icons.dart';
import 'list_tile.dart';
import 'list_tile_theme.dart';
import 'material.dart';
import 'material_localizations.dart';
import 'theme.dart';
import 'theme_data.dart';

const Duration _kExpand = Duration(milliseconds: 200);

/// Enables control over a single [ExpansionTile]'s expanded/collapsed state.
///
/// It can be useful to expand or collapse an [ExpansionTile]
/// programmatically, for example to reconfigure an existing expansion
/// tile based on a system event. To do so, create an [ExpansionTile]
/// with an [ExpansionTileController] that's owned by a stateful widget
/// or look up the tile's automatically created [ExpansionTileController]
/// with [ExpansibleController.of].
///
/// {@tool dartpad}
/// Typical usage of the [ExpansibleController.of] function is to call it from within the
/// `build` method of a descendant of an [ExpansionTile].
///
/// When the [ExpansionTile] is actually created in the same `build`
/// function as the callback that refers to the controller, then the
/// `context` argument to the `build` function can't be used to find
/// the [ExpansionTileController] (since it's "above" the widget
/// being returned in the widget tree). In cases like that you can
/// add a [Builder] widget, which provides a new scope with a
/// [BuildContext] that is "under" the [ExpansionTile]:
///
/// ** See code in examples/api/lib/material/expansion_tile/expansion_tile.1.dart **
/// {@end-tool}
///
/// A more efficient solution is to split your build function into
/// several widgets. This introduces a new context from which you
/// can obtain the [ExpansionTileController]. With this approach you
/// would have an outer widget that creates the [ExpansionTile]
/// populated by instances of your new inner widgets, and then in
/// these inner widgets you would use `ExpansionTileController.of`.
///
/// The  [ExpansibleController.expand] and [ExpansibleController.collapse]
/// methods cause the [ExpansionTile] to rebuild, so they may not be called from
/// a build method.
///
/// Remember to dispose of the [ExpansionTileController] when it is no longer
/// needed. This will ensure we discard any resources used by the object.
@Deprecated(
  'Use ExpansibleController instead. '
  'This feature was deprecated after v3.31.0-0.1.pre.',
)
typedef ExpansionTileController = ExpansibleController;

/// A single-line [ListTile] with an expansion arrow icon that expands or collapses
/// the tile to reveal or hide the [children].
///
/// This widget is typically used with [ListView] to create an "expand /
/// collapse" list entry. When used with scrolling widgets like [ListView], a
/// unique [PageStorageKey] must be specified as the [key], to enable the
/// [ExpansionTile] to save and restore its expanded state when it is scrolled
/// in and out of view.
///
/// This class overrides the [ListTileThemeData.iconColor] and [ListTileThemeData.textColor]
/// theme properties for its [ListTile]. These colors animate between values when
/// the tile is expanded and collapsed: between [iconColor], [collapsedIconColor] and
/// between [textColor] and [collapsedTextColor].
///
/// The expansion arrow icon is shown on the right by default in left-to-right languages
/// (i.e. the trailing edge). This can be changed using [controlAffinity]. This maps
/// to the [leading] and [trailing] properties of [ExpansionTile].
///
/// {@tool dartpad}
/// This example demonstrates how the [ExpansionTile] icon's location and appearance
/// can be customized.
///
/// ** See code in examples/api/lib/material/expansion_tile/expansion_tile.0.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// This example demonstrates how an [ExpansibleController] can be used to
/// programmatically expand or collapse an [ExpansionTile].
///
/// ** See code in examples/api/lib/material/expansion_tile/expansion_tile.1.dart **
/// {@end-tool}
///
/// ## Accessibility
///
/// The accessibility behavior of [ExpansionTile] is platform adaptive, based on
/// the device's actual platform rather than the theme's platform setting. This
/// ensures that assistive technologies like VoiceOver on iOS and macOS receive
/// the correct platform-specific semantics hints, even when the app's theme is
/// configured to mimic a different platform's appearance.
///
/// See also:
///
///  * [ListTile], useful for creating expansion tile [children] when the
///    expansion tile represents a sublist.
///  * The "Expand and collapse" section of
///    <https://material.io/components/lists#types>
class ExpansionTile extends StatefulWidget {
  /// Creates a single-line [ListTile] with an expansion arrow icon that expands or collapses
  /// the tile to reveal or hide the [children]. The [initiallyExpanded] property must
  /// be non-null.
  const ExpansionTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.onExpansionChanged,
    this.children = const <Widget>[],
    this.trailing,
    this.showTrailingIcon = true,
    this.initiallyExpanded = false,
    this.maintainState = false,
    this.tilePadding,
    this.expandedCrossAxisAlignment,
    this.expandedAlignment,
    this.childrenPadding,
    this.backgroundColor,
    this.collapsedBackgroundColor,
    this.textColor,
    this.collapsedTextColor,
    this.iconColor,
    this.collapsedIconColor,
    this.shape,
    this.collapsedShape,
    this.clipBehavior,
    this.controlAffinity,
    this.controller,
    this.dense,
    this.splashColor,
    this.visualDensity,
    this.minTileHeight,
    this.enableFeedback = true,
    this.enabled = true,
    this.expansionAnimationStyle,
    this.internalAddSemanticForOnTap = false,
  }) : assert(
         expandedCrossAxisAlignment != CrossAxisAlignment.baseline,
         'CrossAxisAlignment.baseline is not supported since the expanded children '
         'are aligned in a column, not a row. Try to use another constant.',
       );

  /// A widget to display before the title.
  ///
  /// Typically a [CircleAvatar] widget.
  ///
  /// Depending on the value of [controlAffinity], the [leading] widget
  /// may replace the rotating expansion arrow icon.
  final Widget? leading;

  /// The primary content of the list item.
  ///
  /// Typically a [Text] widget.
  final Widget title;

  /// Additional content displayed below the title.
  ///
  /// Typically a [Text] widget.
  final Widget? subtitle;

  /// Called when the tile expands or collapses.
  ///
  /// When the tile starts expanding, this function is called with the value
  /// true. When the tile starts collapsing, this function is called with
  /// the value false.
  ///
  /// Instead of providing this property, consider adding this callback as a
  /// listener to a provided [controller].
  final ValueChanged<bool>? onExpansionChanged;

  /// The widgets that are displayed when the tile expands.
  ///
  /// Typically [ListTile] widgets.
  final List<Widget> children;

  /// The color to display behind the sublist when expanded.
  ///
  /// If this property is null then [ExpansionTileThemeData.backgroundColor] is used. If that
  /// is also null then Colors.transparent is used.
  ///
  /// See also:
  ///
  /// * [ExpansionTileTheme.of], which returns the nearest [ExpansionTileTheme]'s
  ///   [ExpansionTileThemeData].
  final Color? backgroundColor;

  /// When not null, defines the background color of tile when the sublist is collapsed.
  ///
  /// If this property is null then [ExpansionTileThemeData.collapsedBackgroundColor] is used.
  /// If that is also null then Colors.transparent is used.
  ///
  /// See also:
  ///
  /// * [ExpansionTileTheme.of], which returns the nearest [ExpansionTileTheme]'s
  ///   [ExpansionTileThemeData].
  final Color? collapsedBackgroundColor;

  /// A widget to display after the title.
  ///
  /// Depending on the value of [controlAffinity], the [trailing] widget
  /// may replace the rotating expansion arrow icon.
  final Widget? trailing;

  /// Specifies if the [ExpansionTile] should build a default trailing icon if [trailing] is null.
  final bool showTrailingIcon;

  /// Specifies if the list tile is initially expanded (true) or collapsed (false).
  ///
  /// Alternatively, a provided [controller] can be used to initially expand the
  /// tile if [ExpansibleController.expand] is called before this widget is built.
  ///
  /// Defaults to false.
  final bool initiallyExpanded;

  /// Specifies whether the state of the children is maintained when the tile expands and collapses.
  ///
  /// When true, the children are kept in the tree while the tile is collapsed.
  /// When false (default), the children are removed from the tree when the tile is
  /// collapsed and recreated upon expansion.
  final bool maintainState;

  /// Specifies padding for the [ListTile].
  ///
  /// Analogous to [ListTile.contentPadding], this property defines the insets for
  /// the [leading], [title], [subtitle] and [trailing] widgets. It does not inset
  /// the expanded [children] widgets.
  ///
  /// If this property is null then [ExpansionTileThemeData.tilePadding] is used. If that
  /// is also null then the tile's padding is `EdgeInsets.symmetric(horizontal: 16.0)`.
  ///
  /// See also:
  ///
  /// * [ExpansionTileTheme.of], which returns the nearest [ExpansionTileTheme]'s
  ///   [ExpansionTileThemeData].
  final EdgeInsetsGeometry? tilePadding;

  /// Specifies the alignment of [children], which are arranged in a column when
  /// the tile is expanded.
  ///
  /// The internals of the expanded tile make use of a [Column] widget for
  /// [children], and [Align] widget to align the column. The [expandedAlignment]
  /// parameter is passed directly into the [Align].
  ///
  /// Modifying this property controls the alignment of the column within the
  /// expanded tile, not the alignment of [children] widgets within the column.
  /// To align each child within [children], see [expandedCrossAxisAlignment].
  ///
  /// The width of the column is the width of the widest child widget in [children].
  ///
  /// If this property is null then [ExpansionTileThemeData.expandedAlignment]is used. If that
  /// is also null then the value of [expandedAlignment] is [Alignment.center].
  ///
  /// See also:
  ///
  /// * [ExpansionTileTheme.of], which returns the nearest [ExpansionTileTheme]'s
  ///   [ExpansionTileThemeData].
  final Alignment? expandedAlignment;

  /// Specifies the alignment of each child within [children] when the tile is expanded.
  ///
  /// The internals of the expanded tile make use of a [Column] widget for
  /// [children], and the `crossAxisAlignment` parameter is passed directly into
  /// the [Column].
  ///
  /// Modifying this property controls the cross axis alignment of each child
  /// within its [Column]. The width of the [Column] that houses [children] will
  /// be the same as the widest child widget in [children]. The width of the
  /// [Column] might not be equal to the width of the expanded tile.
  ///
  /// To align the [Column] along the expanded tile, use the [expandedAlignment]
  /// property instead.
  ///
  /// When the value is null, the value of [expandedCrossAxisAlignment] is
  /// [CrossAxisAlignment.center].
  final CrossAxisAlignment? expandedCrossAxisAlignment;

  /// Specifies padding for [children].
  ///
  /// If this property is null then [ExpansionTileThemeData.childrenPadding] is used. If that
  /// is also null then the value of [childrenPadding] is [EdgeInsets.zero].
  ///
  /// See also:
  ///
  /// * [ExpansionTileTheme.of], which returns the nearest [ExpansionTileTheme]'s
  ///   [ExpansionTileThemeData].
  final EdgeInsetsGeometry? childrenPadding;

  /// The icon color of tile's expansion arrow icon when the sublist is expanded.
  ///
  /// Used to override to the [ListTileThemeData.iconColor].
  ///
  /// If this property is null then [ExpansionTileThemeData.iconColor] is used. If that
  /// is also null then the value of [ColorScheme.primary] is used.
  ///
  /// See also:
  ///
  /// * [ExpansionTileTheme.of], which returns the nearest [ExpansionTileTheme]'s
  ///   [ExpansionTileThemeData].
  final Color? iconColor;

  /// The icon color of tile's expansion arrow icon when the sublist is collapsed.
  ///
  /// Used to override to the [ListTileThemeData.iconColor].
  ///
  /// If this property is null then [ExpansionTileThemeData.collapsedIconColor] is used. If that
  /// is also null and [ThemeData.useMaterial3] is true, [ColorScheme.onSurface] is used. Otherwise,
  /// defaults to [ThemeData.unselectedWidgetColor] color.
  ///
  /// See also:
  ///
  /// * [ExpansionTileTheme.of], which returns the nearest [ExpansionTileTheme]'s
  ///   [ExpansionTileThemeData].
  final Color? collapsedIconColor;

  /// The color of the tile's titles when the sublist is expanded.
  ///
  /// Used to override to the [ListTileThemeData.textColor].
  ///
  /// If this property is null then [ExpansionTileThemeData.textColor] is used. If that
  /// is also null then and [ThemeData.useMaterial3] is true, color of the [TextTheme.bodyLarge]
  /// will be used for the [title] and [subtitle]. Otherwise, defaults to [ColorScheme.primary] color.
  ///
  /// See also:
  ///
  /// * [ExpansionTileTheme.of], which returns the nearest [ExpansionTileTheme]'s
  ///   [ExpansionTileThemeData].
  final Color? textColor;

  /// The color of the tile's titles when the sublist is collapsed.
  ///
  /// Used to override to the [ListTileThemeData.textColor].
  ///
  /// If this property is null then [ExpansionTileThemeData.collapsedTextColor] is used.
  /// If that is also null and [ThemeData.useMaterial3] is true, color of the
  /// [TextTheme.bodyLarge] will be used for the [title] and [subtitle]. Otherwise,
  /// defaults to color of the [TextTheme.titleMedium].
  ///
  /// See also:
  ///
  /// * [ExpansionTileTheme.of], which returns the nearest [ExpansionTileTheme]'s
  ///   [ExpansionTileThemeData].
  final Color? collapsedTextColor;

  /// The tile's border shape when the sublist is expanded.
  ///
  /// If this property is null, the [ExpansionTileThemeData.shape] is used. If that
  /// is also null, a [Border] with vertical sides default to [ThemeData.dividerColor] is used
  ///
  /// See also:
  ///
  /// * [ExpansionTileTheme.of], which returns the nearest [ExpansionTileTheme]'s
  ///   [ExpansionTileThemeData].
  final ShapeBorder? shape;

  /// The tile's border shape when the sublist is collapsed.
  ///
  /// If this property is null, the [ExpansionTileThemeData.collapsedShape] is used. If that
  /// is also null, a [Border] with vertical sides default to Color [Colors.transparent] is used
  ///
  /// See also:
  ///
  /// * [ExpansionTileTheme.of], which returns the nearest [ExpansionTileTheme]'s
  ///   [ExpansionTileThemeData].
  final ShapeBorder? collapsedShape;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// If this is not null and a custom collapsed or expanded shape is provided,
  /// the value of [clipBehavior] will be used to clip the expansion tile.
  ///
  /// If this property is null, the [ExpansionTileThemeData.clipBehavior] is used. If that
  /// is also null, defaults to [Clip.antiAlias].
  ///
  /// See also:
  ///
  /// * [ExpansionTileTheme.of], which returns the nearest [ExpansionTileTheme]'s
  ///   [ExpansionTileThemeData].
  final Clip? clipBehavior;

  /// Typically used to force the expansion arrow icon to the tile's leading or trailing edge.
  ///
  /// By default, the value of [controlAffinity] is [ListTileControlAffinity.platform],
  /// which means that the expansion arrow icon will appear on the tile's trailing edge.
  final ListTileControlAffinity? controlAffinity;

  /// If provided, the controller can be used to expand and collapse tiles.
  ///
  /// In cases where control over the tile's state is needed from a callback
  /// triggered by a widget within the tile, [ExpansibleController.of] may be
  /// more convenient than supplying a controller.
  final ExpansibleController? controller;

  /// {@macro flutter.material.ListTile.dense}
  final bool? dense;

  /// The splash color of the ink response when the tile is tapped.
  ///
  /// This color is passed directly to the underlying [ListTile]'s
  /// `splashColor` property, which controls the ink ripple (splash)
  /// animation when the tile is tapped. Internally, [ListTile] uses
  /// an [InkWell] (which handles the actual splash effect), and so the
  /// provided color will apply to that ripple.
  ///
  /// If null, the splash color will default to the current theme’s
  /// `ThemeData.splashColor`.
  ///
  /// See also:
  ///
  /// * [ListTile.splashColor], which sets the ink splash for the tile.
  /// * [InkWell.splashColor], which determines the color of the ripple
  ///   effect in Material widgets.
  /// * [ThemeData.splashColor], which provides a fallback color.
  final Color? splashColor;

  /// Defines how compact the expansion tile's layout will be.
  ///
  /// {@macro flutter.material.themedata.visualDensity}
  final VisualDensity? visualDensity;

  /// {@macro flutter.material.ListTile.minTileHeight}
  final double? minTileHeight;

  /// {@macro flutter.material.ListTile.enableFeedback}
  final bool? enableFeedback;

  /// Whether this expansion tile is interactive.
  ///
  /// If false, the internal [ListTile] will be disabled, changing its
  /// appearance according to the theme and disabling user interaction.
  ///
  /// Even if disabled, the expansion can still be toggled programmatically
  /// through an [ExpansionTileController].
  final bool enabled;

  /// Used to override the expansion animation curve and duration.
  ///
  /// If [AnimationStyle.duration] is provided, it will be used to override
  /// the expansion animation duration. If it is null, then [AnimationStyle.duration]
  /// from the [ExpansionTileThemeData.expansionAnimationStyle] will be used.
  /// Otherwise, defaults to 200ms.
  ///
  /// If [AnimationStyle.curve] is provided, it will be used to override
  /// the expansion animation curve. If it is null, then [AnimationStyle.curve]
  /// from the [ExpansionTileThemeData.expansionAnimationStyle] will be used.
  /// Otherwise, defaults to [Curves.easeIn].
  ///
  /// If [AnimationStyle.reverseCurve] is provided, it will be used to override
  /// the collapse animation curve. If it is null, then [AnimationStyle.reverseCurve]
  /// from the [ExpansionTileThemeData.expansionAnimationStyle] will be used.
  /// Otherwise, the same curve will be used as for expansion.
  ///
  /// To disable the theme animation, use [AnimationStyle.noAnimation].
  ///
  /// {@tool dartpad}
  /// This sample showcases how to override the [ExpansionTile] expansion
  /// animation curve and duration using [AnimationStyle].
  ///
  /// ** See code in examples/api/lib/material/expansion_tile/expansion_tile.2.dart **
  /// {@end-tool}
  final AnimationStyle? expansionAnimationStyle;

  /// Whether to add button:true to the semantics if onTap is provided.
  /// This is a temporary flag to help changing the behavior of ListTile onTap semantics.
  ///
  // TODO(hangyujin): Remove this flag after fixing related g3 tests and flipping
  // the default value to true.
  final bool internalAddSemanticForOnTap;

  @override
  State<ExpansionTile> createState() => _ExpansionTileState();
}

class _ExpansionTileState extends State<ExpansionTile> {
  static final Animatable<double> _easeInTween = CurveTween(curve: Curves.easeIn);
  static final Animatable<double> _easeOutTween = CurveTween(curve: Curves.easeOut);
  static final Animatable<double> _halfTween = Tween<double>(begin: 0.0, end: 0.5);

  final ShapeBorderTween _borderTween = ShapeBorderTween();
  final ColorTween _headerColorTween = ColorTween();
  final ColorTween _iconColorTween = ColorTween();
  final ColorTween _backgroundColorTween = ColorTween();

  late Animation<double> _iconTurns;
  late Animation<ShapeBorder?> _border;
  late Animation<Color?> _headerColor;
  late Animation<Color?> _iconColor;
  late Animation<Color?> _backgroundColor;

  late ExpansionTileThemeData _expansionTileTheme;
  late ExpansibleController _tileController;
  Timer? _timer;
  late Curve _curve;
  late Curve? _reverseCurve;
  late Duration _duration;

  @override
  void initState() {
    super.initState();
    _curve = Curves.easeIn;
    _duration = _kExpand;
    _tileController = widget.controller ?? ExpansibleController();
    if (widget.initiallyExpanded) {
      _tileController.expand();
    }
    _tileController.addListener(_onExpansionChanged);
  }

  @override
  void dispose() {
    _tileController.removeListener(_onExpansionChanged);
    if (widget.controller == null) {
      _tileController.dispose();
    }
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  void _onExpansionChanged() {
    final TextDirection textDirection = WidgetsLocalizations.of(context).textDirection;
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final String stateHint = _tileController.isExpanded
        ? localizations.collapsedHint
        : localizations.expandedHint;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // TODO(tahatesser): This is a workaround for VoiceOver interrupting
      // semantic announcements on iOS. https://github.com/flutter/flutter/issues/122101.
      _timer?.cancel();
      _timer = Timer(const Duration(seconds: 1), () {
        SemanticsService.sendAnnouncement(View.of(context), stateHint, textDirection);
        _timer?.cancel();
        _timer = null;
      });
    } else {
      SemanticsService.sendAnnouncement(View.of(context), stateHint, textDirection);
    }
    widget.onExpansionChanged?.call(_tileController.isExpanded);
  }

  // Platform or null affinity defaults to trailing.
  ListTileControlAffinity _effectiveAffinity() {
    final ListTileThemeData listTileTheme = ListTileTheme.of(context);
    final ListTileControlAffinity affinity =
        widget.controlAffinity ?? listTileTheme.controlAffinity ?? ListTileControlAffinity.trailing;
    switch (affinity) {
      case ListTileControlAffinity.leading:
        return ListTileControlAffinity.leading;
      case ListTileControlAffinity.trailing:
      case ListTileControlAffinity.platform:
        return ListTileControlAffinity.trailing;
    }
  }

  Widget? _buildIcon(BuildContext context, Animation<double> animation) {
    _iconTurns = animation.drive(_halfTween.chain(_easeInTween));
    return RotationTransition(turns: _iconTurns, child: const Icon(Icons.expand_more));
  }

  Widget? _buildLeadingIcon(BuildContext context, Animation<double> animation) {
    if (_effectiveAffinity() != ListTileControlAffinity.leading) {
      return null;
    }
    return _buildIcon(context, animation);
  }

  Widget? _buildTrailingIcon(BuildContext context, Animation<double> animation) {
    if (_effectiveAffinity() != ListTileControlAffinity.trailing) {
      return null;
    }
    return _buildIcon(context, animation);
  }

  Widget _buildHeader(BuildContext context, Animation<double> animation) {
    _iconColor = animation.drive(_iconColorTween.chain(_easeInTween));
    _headerColor = animation.drive(_headerColorTween.chain(_easeInTween));
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final String onTapHint = _tileController.isExpanded
        ? localizations.expansionTileExpandedTapHint
        : localizations.expansionTileCollapsedTapHint;
    final String semanticsHint = switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS =>
        _tileController.isExpanded
            ? '${localizations.collapsedHint}\n ${localizations.expansionTileExpandedHint}'
            : '${localizations.expandedHint}\n ${localizations.expansionTileCollapsedHint}',
      _ => _tileController.isExpanded ? localizations.collapsedHint : localizations.expandedHint,
    };

    return Semantics(
      hint: semanticsHint,
      onTapHint: onTapHint,
      child: ListTileTheme.merge(
        iconColor: _iconColor.value ?? _expansionTileTheme.iconColor,
        textColor: _headerColor.value,
        child: ListTile(
          enabled: widget.enabled,
          onTap: _tileController.isExpanded ? _tileController.collapse : _tileController.expand,
          dense: widget.dense,
          splashColor: widget.splashColor,
          visualDensity: widget.visualDensity,
          enableFeedback: widget.enableFeedback,
          contentPadding: widget.tilePadding ?? _expansionTileTheme.tilePadding,
          leading: widget.leading ?? _buildLeadingIcon(context, animation),
          title: widget.title,
          subtitle: widget.subtitle,
          trailing: widget.showTrailingIcon
              ? widget.trailing ?? _buildTrailingIcon(context, animation)
              : null,
          minTileHeight: widget.minTileHeight,
          internalAddSemanticForOnTap: widget.internalAddSemanticForOnTap,
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, Animation<double> animation) {
    return Align(
      alignment:
          widget.expandedAlignment ?? _expansionTileTheme.expandedAlignment ?? Alignment.center,
      child: Padding(
        padding: widget.childrenPadding ?? _expansionTileTheme.childrenPadding ?? EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: widget.expandedCrossAxisAlignment ?? CrossAxisAlignment.center,
          children: widget.children,
        ),
      ),
    );
  }

  Widget _buildExpansible(
    BuildContext context,
    Widget header,
    Widget body,
    Animation<double> animation,
  ) {
    _backgroundColor = animation.drive(_backgroundColorTween.chain(_easeOutTween));
    _border = animation.drive(_borderTween.chain(_easeOutTween));
    final Color backgroundColor =
        _backgroundColor.value ?? _expansionTileTheme.backgroundColor ?? Colors.transparent;
    final ShapeBorder expansionTileBorder =
        _border.value ??
        const Border(
          top: BorderSide(color: Colors.transparent),
          bottom: BorderSide(color: Colors.transparent),
        );
    final Clip clipBehavior =
        widget.clipBehavior ?? _expansionTileTheme.clipBehavior ?? Clip.antiAlias;

    final Decoration decoration = ShapeDecoration(
      color: backgroundColor,
      shape: expansionTileBorder,
    );

    final Widget tile = Padding(
      padding: decoration.padding,
      child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[header, body]),
    );

    final bool isShapeProvided =
        widget.shape != null ||
        _expansionTileTheme.shape != null ||
        widget.collapsedShape != null ||
        _expansionTileTheme.collapsedShape != null;

    if (isShapeProvided) {
      return Material(
        clipBehavior: clipBehavior,
        color: backgroundColor,
        shape: expansionTileBorder,
        child: tile,
      );
    }

    return DecoratedBox(decoration: decoration, child: tile);
  }

  @override
  void didUpdateWidget(covariant ExpansionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ThemeData theme = Theme.of(context);
    _expansionTileTheme = ExpansionTileTheme.of(context);
    final ExpansionTileThemeData defaults = theme.useMaterial3
        ? _ExpansionTileDefaultsM3(context)
        : _ExpansionTileDefaultsM2(context);
    if (widget.collapsedShape != oldWidget.collapsedShape || widget.shape != oldWidget.shape) {
      _updateShapeBorder(theme);
    }
    if (widget.collapsedTextColor != oldWidget.collapsedTextColor ||
        widget.textColor != oldWidget.textColor) {
      _updateHeaderColor(defaults);
    }
    if (widget.collapsedIconColor != oldWidget.collapsedIconColor ||
        widget.iconColor != oldWidget.iconColor) {
      _updateIconColor(defaults);
    }
    if (widget.backgroundColor != oldWidget.backgroundColor ||
        widget.collapsedBackgroundColor != oldWidget.collapsedBackgroundColor) {
      _updateBackgroundColor();
    }
    if (widget.expansionAnimationStyle != oldWidget.expansionAnimationStyle) {
      _updateAnimationDuration();
      _updateHeightFactorCurve();
    }
    if (widget.controller != oldWidget.controller) {
      _tileController.removeListener(_onExpansionChanged);
      if (oldWidget.controller == null) {
        _tileController.dispose();
      }

      _tileController = widget.controller ?? ExpansibleController();
      _tileController.addListener(_onExpansionChanged);
    }
  }

  @override
  void didChangeDependencies() {
    final ThemeData theme = Theme.of(context);
    _expansionTileTheme = ExpansionTileTheme.of(context);
    final ExpansionTileThemeData defaults = theme.useMaterial3
        ? _ExpansionTileDefaultsM3(context)
        : _ExpansionTileDefaultsM2(context);
    _updateAnimationDuration();
    _updateShapeBorder(theme);
    _updateHeaderColor(defaults);
    _updateIconColor(defaults);
    _updateBackgroundColor();
    _updateHeightFactorCurve();
    super.didChangeDependencies();
  }

  void _updateAnimationDuration() {
    _duration =
        widget.expansionAnimationStyle?.duration ??
        _expansionTileTheme.expansionAnimationStyle?.duration ??
        const Duration(milliseconds: 200);
  }

  void _updateShapeBorder(ThemeData theme) {
    _borderTween
      ..begin =
          widget.collapsedShape ??
          _expansionTileTheme.collapsedShape ??
          const Border(
            top: BorderSide(color: Colors.transparent),
            bottom: BorderSide(color: Colors.transparent),
          )
      ..end =
          widget.shape ??
          _expansionTileTheme.shape ??
          Border(
            top: BorderSide(color: theme.dividerColor),
            bottom: BorderSide(color: theme.dividerColor),
          );
  }

  void _updateHeaderColor(ExpansionTileThemeData defaults) {
    _headerColorTween
      ..begin =
          widget.collapsedTextColor ??
          _expansionTileTheme.collapsedTextColor ??
          defaults.collapsedTextColor
      ..end = widget.textColor ?? _expansionTileTheme.textColor ?? defaults.textColor;
  }

  void _updateIconColor(ExpansionTileThemeData defaults) {
    _iconColorTween
      ..begin =
          widget.collapsedIconColor ??
          _expansionTileTheme.collapsedIconColor ??
          defaults.collapsedIconColor
      ..end = widget.iconColor ?? _expansionTileTheme.iconColor ?? defaults.iconColor;
  }

  void _updateBackgroundColor() {
    _backgroundColorTween
      ..begin = widget.collapsedBackgroundColor ?? _expansionTileTheme.collapsedBackgroundColor
      ..end = widget.backgroundColor ?? _expansionTileTheme.backgroundColor;
  }

  void _updateHeightFactorCurve() {
    _curve =
        widget.expansionAnimationStyle?.curve ??
        _expansionTileTheme.expansionAnimationStyle?.curve ??
        Curves.easeIn;
    _reverseCurve =
        widget.expansionAnimationStyle?.reverseCurve ??
        _expansionTileTheme.expansionAnimationStyle?.reverseCurve;
  }

  @override
  Widget build(BuildContext context) {
    return Expansible(
      controller: _tileController,
      curve: _curve,
      duration: _duration,
      reverseCurve: _reverseCurve,
      maintainState: widget.maintainState,
      headerBuilder: _buildHeader,
      bodyBuilder: _buildBody,
      expansibleBuilder: _buildExpansible,
    );
  }
}

class _ExpansionTileDefaultsM2 extends ExpansionTileThemeData {
  _ExpansionTileDefaultsM2(this.context);

  final BuildContext context;
  late final ThemeData _theme = Theme.of(context);
  late final ColorScheme _colorScheme = _theme.colorScheme;

  @override
  Color? get textColor => _colorScheme.primary;

  @override
  Color? get iconColor => _colorScheme.primary;

  @override
  Color? get collapsedTextColor => _theme.textTheme.titleMedium!.color;

  @override
  Color? get collapsedIconColor => _theme.unselectedWidgetColor;
}

// BEGIN GENERATED TOKEN PROPERTIES - ExpansionTile

// Do not edit by hand. The code between the "BEGIN GENERATED" and
// "END GENERATED" comments are generated from data in the Material
// Design token database by the script:
//   dev/tools/gen_defaults/bin/gen_defaults.dart.

// dart format off
class _ExpansionTileDefaultsM3 extends ExpansionTileThemeData {
  _ExpansionTileDefaultsM3(this.context);

  final BuildContext context;
  late final ThemeData _theme = Theme.of(context);
  late final ColorScheme _colors = _theme.colorScheme;

  @override
  Color? get textColor => _colors.onSurface;

  @override
  Color? get iconColor => _colors.primary;

  @override
  Color? get collapsedTextColor => _colors.onSurface;

  @override
  Color? get collapsedIconColor => _colors.onSurfaceVariant;
}
// dart format on

// END GENERATED TOKEN PROPERTIES - ExpansionTile
