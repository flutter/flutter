// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'constants.dart';
import 'theme.dart';

/// The collapsing effect while the space bar collapses from its full size.
enum CollapseMode {
  /// The background widget will scroll in a parallax fashion.
  parallax,

  /// The background widget pin in place until it reaches the min extent.
  pin,

  /// The background widget will act as normal with no collapsing effect.
  none,
}

/// The stretching effect while the space bar stretches beyond its full size.
enum StretchMode {
  /// The background widget will expand to fill the extra space.
  zoomBackground,

  /// The background will blur using a [ImageFilter.blur] effect.
  blurBackground,

  /// The title will fade away as the user over-scrolls.
  fadeTitle,
}

/// The part of a material design [AppBar] that expands, collapses, and
/// stretches.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=mSc7qFzxHDw}
///
/// Most commonly used in the [SliverAppBar.flexibleSpace] field, a flexible
/// space bar expands and contracts as the app scrolls so that the [AppBar]
/// reaches from the top of the app to the top of the scrolling contents of the
/// app. When using [SliverAppBar.flexibleSpace], the [SliverAppBar.expandedHeight]
/// must be large enough to accommodate the [SliverAppBar.flexibleSpace] widget.
///
/// Furthermore is included functionality for stretch behavior. When
/// [SliverAppBar.stretch] is true, and your [ScrollPhysics] allow for
/// overscroll, this space will stretch with the overscroll.
///
/// The widget that sizes the [AppBar] must wrap it in the widget returned by
/// [FlexibleSpaceBar.createSettings], to convey sizing information down to the
/// [FlexibleSpaceBar].
///
/// {@tool dartpad --template=freeform}
/// This sample application demonstrates the different features of the
/// [FlexibleSpaceBar] when used in a [SliverAppBar]. This app bar is configured
/// to stretch into the overscroll space, and uses the
/// [FlexibleSpaceBar.stretchModes] to apply `fadeTitle`, `blurBackground` and
/// `zoomBackground`. The app bar also makes use of [CollapseMode.parallax] by
/// default.
///
/// ```dart imports
/// import 'package:flutter/material.dart';
/// ```
/// ```dart
/// void main() => runApp(MaterialApp(home: MyApp()));
///
/// class MyApp extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       body: CustomScrollView(
///         physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
///         slivers: <Widget>[
///           SliverAppBar(
///             stretch: true,
///             onStretchTrigger: () {
///               // Function callback for stretch
///               return Future.value();
///             },
///             expandedHeight: 300.0,
///             flexibleSpace: FlexibleSpaceBar(
///               stretchModes: <StretchMode>[
///                 StretchMode.zoomBackground,
///                 StretchMode.blurBackground,
///                 StretchMode.fadeTitle,
///               ],
///               centerTitle: true,
///               title: const Text('Flight Report'),
///               background: Stack(
///                 fit: StackFit.expand,
///                 children: [
///                   Image.network(
///                     'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl-2.jpg',
///                     fit: BoxFit.cover,
///                   ),
///                   const DecoratedBox(
///                     decoration: BoxDecoration(
///                       gradient: LinearGradient(
///                         begin: Alignment(0.0, 0.5),
///                         end: Alignment(0.0, 0.0),
///                         colors: <Color>[
///                           Color(0x60000000),
///                           Color(0x00000000),
///                         ],
///                       ),
///                     ),
///                   ),
///                 ],
///               ),
///             ),
///           ),
///           SliverList(
///             delegate: SliverChildListDelegate([
///               ListTile(
///                 leading: Icon(Icons.wb_sunny),
///                 title: Text('Sunday'),
///                 subtitle: Text('sunny, h: 80, l: 65'),
///               ),
///               ListTile(
///                 leading: Icon(Icons.wb_sunny),
///                 title: Text('Monday'),
///                 subtitle: Text('sunny, h: 80, l: 65'),
///               ),
///               // ListTiles++
///             ]),
///           ),
///         ],
///       ),
///     );
///   }
/// }
///
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [SliverAppBar], which implements the expanding and contracting.
///  * [AppBar], which is used by [SliverAppBar].
///  * <https://material.io/design/components/app-bars-top.html#behavior>
class FlexibleSpaceBar extends StatefulWidget {
  /// Creates a flexible space bar.
  ///
  /// Most commonly used in the [AppBar.flexibleSpace] field.
  const FlexibleSpaceBar({
    Key? key,
    this.title,
    this.background,
    this.centerTitle,
    this.titlePadding,
    this.collapseMode = CollapseMode.parallax,
    this.stretchModes = const <StretchMode>[StretchMode.zoomBackground],
  }) : assert(collapseMode != null),
       super(key: key);

  /// The primary contents of the flexible space bar when expanded.
  ///
  /// Typically a [Text] widget.
  final Widget? title;

  /// Shown behind the [title] when expanded.
  ///
  /// Typically an [Image] widget with [Image.fit] set to [BoxFit.cover].
  final Widget? background;

  /// Whether the title should be centered.
  ///
  /// By default this property is true if the current target platform
  /// is [TargetPlatform.iOS] or [TargetPlatform.macOS], false otherwise.
  final bool? centerTitle;

  /// Collapse effect while scrolling.
  ///
  /// Defaults to [CollapseMode.parallax].
  final CollapseMode collapseMode;

  /// Stretch effect while over-scrolling.
  ///
  /// Defaults to include [StretchMode.zoomBackground].
  final List<StretchMode> stretchModes;

  /// Defines how far the [title] is inset from either the widget's
  /// bottom-left or its center.
  ///
  /// Typically this property is used to adjust how far the title is
  /// is inset from the bottom-left and it is specified along with
  /// [centerTitle] false.
  ///
  /// By default the value of this property is
  /// `EdgeInsetsDirectional.only(start: 72, bottom: 16)` if the title is
  /// not centered, `EdgeInsetsDirectional.only(start: 0, bottom: 16)` otherwise.
  final EdgeInsetsGeometry? titlePadding;

  /// Wraps a widget that contains an [AppBar] to convey sizing information down
  /// to the [FlexibleSpaceBar].
  ///
  /// Used by [Scaffold] and [SliverAppBar].
  ///
  /// `toolbarOpacity` affects how transparent the text within the toolbar
  /// appears. `minExtent` sets the minimum height of the resulting
  /// [FlexibleSpaceBar] when fully collapsed. `maxExtent` sets the maximum
  /// height of the resulting [FlexibleSpaceBar] when fully expanded.
  /// `currentExtent` sets the scale of the [FlexibleSpaceBar.background] and
  /// [FlexibleSpaceBar.title] widgets of [FlexibleSpaceBar] upon
  /// initialization.
  ///
  /// See also:
  ///
  ///  * [FlexibleSpaceBarSettings] which creates a settings object that can be
  ///    used to specify these settings to a [FlexibleSpaceBar].
  static Widget createSettings({
    double? toolbarOpacity,
    double? minExtent,
    double? maxExtent,
    required double currentExtent,
    required Widget child,
  }) {
    assert(currentExtent != null);
    return FlexibleSpaceBarSettings(
      toolbarOpacity: toolbarOpacity ?? 1.0,
      minExtent: minExtent ?? currentExtent,
      maxExtent: maxExtent ?? currentExtent,
      currentExtent: currentExtent,
      child: child,
    );
  }

  @override
  _FlexibleSpaceBarState createState() => _FlexibleSpaceBarState();
}

class _FlexibleSpaceBarState extends State<FlexibleSpaceBar> {
  bool _getEffectiveCenterTitle(ThemeData theme) {
    if (widget.centerTitle != null)
      return widget.centerTitle!;
    assert(theme.platform != null);
    switch (theme.platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return false;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
    }
  }

  Alignment _getTitleAlignment(bool effectiveCenterTitle) {
    if (effectiveCenterTitle)
      return Alignment.bottomCenter;
    final TextDirection textDirection = Directionality.of(context);
    assert(textDirection != null);
    switch (textDirection) {
      case TextDirection.rtl:
        return Alignment.bottomRight;
      case TextDirection.ltr:
        return Alignment.bottomLeft;
    }
  }

  double _getCollapsePadding(double t, FlexibleSpaceBarSettings settings) {
    switch (widget.collapseMode) {
      case CollapseMode.pin:
        return -(settings.maxExtent - settings.currentExtent);
      case CollapseMode.none:
        return 0.0;
      case CollapseMode.parallax:
        final double deltaExtent = settings.maxExtent - settings.minExtent;
        return -Tween<double>(begin: 0.0, end: deltaExtent / 4.0).transform(t);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final FlexibleSpaceBarSettings settings = context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>()!;
        assert(
          settings != null,
          'A FlexibleSpaceBar must be wrapped in the widget returned by FlexibleSpaceBar.createSettings().',
        );

        final List<Widget> children = <Widget>[];

        final double deltaExtent = settings.maxExtent - settings.minExtent;

        // 0.0 -> Expanded
        // 1.0 -> Collapsed to toolbar
        final double t = (1.0 - (settings.currentExtent - settings.minExtent) / deltaExtent).clamp(0.0, 1.0);

        // background
        if (widget.background != null) {
          final double fadeStart = math.max(0.0, 1.0 - kToolbarHeight / deltaExtent);
          const double fadeEnd = 1.0;
          assert(fadeStart <= fadeEnd);
          final double opacity = 1.0 - Interval(fadeStart, fadeEnd).transform(t);
          double height = settings.maxExtent;

          // StretchMode.zoomBackground
          if (widget.stretchModes.contains(StretchMode.zoomBackground) &&
            constraints.maxHeight > height) {
            height = constraints.maxHeight;
          }
          children.add(Positioned(
            top: _getCollapsePadding(t, settings),
            left: 0.0,
            right: 0.0,
            height: height,
            child: Opacity(
              // IOS is relying on this semantics node to correctly traverse
              // through the app bar when it is collapsed.
              alwaysIncludeSemantics: true,
              opacity: opacity,
              child: widget.background,
            ),
          ));

          // StretchMode.blurBackground
          if (widget.stretchModes.contains(StretchMode.blurBackground) &&
            constraints.maxHeight > settings.maxExtent) {
            final double blurAmount = (constraints.maxHeight - settings.maxExtent) / 10;
            children.add(Positioned.fill(
              child: BackdropFilter(
                child: Container(
                  color: Colors.transparent,
                ),
                filter: ui.ImageFilter.blur(
                  sigmaX: blurAmount,
                  sigmaY: blurAmount,
                )
              )
            ));
          }
        }

        // title
        if (widget.title != null) {
          final ThemeData theme = Theme.of(context);

          Widget? title;
          switch (theme.platform) {
            case TargetPlatform.iOS:
            case TargetPlatform.macOS:
              title = widget.title;
              break;
            case TargetPlatform.android:
            case TargetPlatform.fuchsia:
            case TargetPlatform.linux:
            case TargetPlatform.windows:
              title = Semantics(
                namesRoute: true,
                child: widget.title,
              );
              break;
          }

          // StretchMode.fadeTitle
          if (widget.stretchModes.contains(StretchMode.fadeTitle) &&
            constraints.maxHeight > settings.maxExtent) {
            final double stretchOpacity = 1 -
              (((constraints.maxHeight - settings.maxExtent) / 100).clamp(0.0, 1.0));
            title = Opacity(
              opacity: stretchOpacity,
              child: title,
            );
          }

          final double opacity = settings.toolbarOpacity;
          if (opacity > 0.0) {
            TextStyle titleStyle = theme.primaryTextTheme.headline6!;
            titleStyle = titleStyle.copyWith(
              color: titleStyle.color!.withOpacity(opacity)
            );
            final bool effectiveCenterTitle = _getEffectiveCenterTitle(theme);
            final EdgeInsetsGeometry padding = widget.titlePadding ??
              EdgeInsetsDirectional.only(
                start: effectiveCenterTitle ? 0.0 : 72.0,
                bottom: 16.0,
              );
            final double scaleValue = Tween<double>(begin: 1.5, end: 1.0).transform(t);
            final Matrix4 scaleTransform = Matrix4.identity()
              ..scale(scaleValue, scaleValue, 1.0);
            final Alignment titleAlignment = _getTitleAlignment(effectiveCenterTitle);
            children.add(Container(
              padding: padding,
              child: Transform(
                alignment: titleAlignment,
                transform: scaleTransform,
                child: Align(
                  alignment: titleAlignment,
                  child: DefaultTextStyle(
                    style: titleStyle,
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints constraints) {
                        return Container(
                          width: constraints.maxWidth / scaleValue,
                          alignment: titleAlignment,
                          child: title,
                        );
                      }
                    ),
                  ),
                ),
              ),
            ));
          }
        }

        return ClipRect(child: Stack(children: children));
      }
    );
  }
}

/// Provides sizing and opacity information to a [FlexibleSpaceBar].
///
/// See also:
///
///  * [FlexibleSpaceBar] which creates a flexible space bar.
class FlexibleSpaceBarSettings extends InheritedWidget {
  /// Creates a Flexible Space Bar Settings widget.
  ///
  /// Used by [Scaffold] and [SliverAppBar]. [child] must have a
  /// [FlexibleSpaceBar] widget in its tree for the settings to take affect.
  ///
  /// The required [toolbarOpacity], [minExtent], [maxExtent], [currentExtent],
  /// and [child] parameters must not be null.
  const FlexibleSpaceBarSettings({
    Key? key,
    required this.toolbarOpacity,
    required this.minExtent,
    required this.maxExtent,
    required this.currentExtent,
    required Widget child,
  }) : assert(toolbarOpacity != null),
       assert(minExtent != null && minExtent >= 0),
       assert(maxExtent != null && maxExtent >= 0),
       assert(currentExtent != null && currentExtent >= 0),
       assert(toolbarOpacity >= 0.0),
       assert(minExtent <= maxExtent),
       assert(minExtent <= currentExtent),
       assert(currentExtent <= maxExtent),
       super(key: key, child: child);

  /// Affects how transparent the text within the toolbar appears.
  final double toolbarOpacity;

  /// Minimum height of the resulting [FlexibleSpaceBar] when fully collapsed.
  final double minExtent;

  /// Maximum height of the resulting [FlexibleSpaceBar] when fully expanded.
  final double maxExtent;

  /// If the [FlexibleSpaceBar.title] or the [FlexibleSpaceBar.background] is
  /// not null, then this value is used to calculate the relative scale of
  /// these elements upon initialization.
  final double currentExtent;

  @override
  bool updateShouldNotify(FlexibleSpaceBarSettings oldWidget) {
    return toolbarOpacity != oldWidget.toolbarOpacity
        || minExtent != oldWidget.minExtent
        || maxExtent != oldWidget.maxExtent
        || currentExtent != oldWidget.currentExtent;
  }
}
