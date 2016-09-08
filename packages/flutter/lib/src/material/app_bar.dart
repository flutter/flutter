// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:sky_services/flutter/platform/system_chrome.mojom.dart' as mojom;

import 'constants.dart';
import 'icon_theme.dart';
import 'icon_theme_data.dart';
import 'material.dart';
import 'tabs.dart';
import 'theme.dart';
import 'typography.dart';

const Object _kDefaultHeroTag = const Object();
const Object _kUnspecifiedArgument = const Object();

/// A widget that can appear at the bottom of an [AppBar]. The [Scaffold] uses
/// the bottom widget's [bottomHeight] to handle layout for
/// [AppBarBehavior.scroll] and [AppBarBehavior.under].
abstract class AppBarBottomWidget extends Widget {
  /// Defines the height of the app bar's optional bottom widget.
  double get bottomHeight;
}

// TODO(eseidel) Toolbar needs to change size based on orientation:
// http://www.google.com/design/spec/layout/structure.html#structure-app-bar
// Mobile Landscape: 48dp
// Mobile Portrait: 56dp
// Tablet/Desktop: 64dp

class _AppBarExpandedHeight extends InheritedWidget {
  _AppBarExpandedHeight({
    this.expandedHeight,
    Widget child
  }) : super(child: child) {
    assert(expandedHeight != null);
  }

  final double expandedHeight;

  @override
  bool updateShouldNotify(_AppBarExpandedHeight oldWidget) {
    return expandedHeight != oldWidget.expandedHeight;
  }
}

/// A material design app bar.
///
/// An app bar consists of a toolbar and potentially other widgets, such as a
/// [TabBar] and a [FlexibleSpaceBar]. App bars typically expose one or more
/// common actions with [IconButtons]s which are optionally followed by a
/// [PopupMenuButton] for less common operations.
///
/// App bars are most commonly used in the [Scaffold.appBar] property, which
/// places the app bar at the top of the app.
///
/// The AppBar displays the toolbar widgets, [leading], [title], and
/// [actions], above the [bottom] (if any). If a [flexibleSpace] widget is
/// specified then it is stacked behind the toolbar and the bottom widget.
///
/// The [Scaffold] typically creates the app bar with an initial height equal to
/// [expandedHeight]. If the [Scaffold.appBarBehavior] is set then the
/// AppBar's [collapsedHeight] and [bottomHeight] define how small the app bar
/// will become when the application is scrolled.
///
/// See also:
///
///  * [Scaffold]
///  * [TabBar]
///  * [IconButton]
///  * [PopupMenuButton]
///  * [FlexibleSpaceBar]
///  * <https://www.google.com/design/spec/layout/structure.html#structure-toolbars>
class AppBar extends StatelessWidget {
  /// Creates a material design app bar.
  ///
  /// Typically used in the [Scaffold.appBar] property.
  AppBar({
    Key key,
    this.leading,
    this.title,
    this.actions,
    this.flexibleSpace,
    this.bottom,
    this.elevation: 4,
    this.backgroundColor,
    this.brightness,
    this.iconTheme,
    this.textTheme,
    this.padding: EdgeInsets.zero,
    this.centerTitle,
    this.heroTag: _kDefaultHeroTag,
    double expandedHeight,
    double collapsedHeight
  }) : _expandedHeight = expandedHeight,
       _collapsedHeight = collapsedHeight,
       super(key: key);

  /// A widget to display before the [title].
  ///
  /// If this field is null and this app bar is used in a [Scaffold], the
  /// [Scaffold] will fill this field with an appropriate widget. For example,
  /// if the [Scaffold] also has a [Drawer], the [Scaffold] will fill this
  /// widget with an [IconButton] that opens the drawer. If there's no [Drawer]
  /// and the parent [Navigator] can go back, the [Scaffold] will fill this
  /// field with an [IconButton] that calls [Navigator.pop].
  final Widget leading;

  /// The primary widget displayed in the appbar.
  ///
  /// Typically a [Text] widget containing a description of the current contents
  /// of the app.
  final Widget title;

  /// Widgets to display after the title widget.
  ///
  /// Typically these widgets are [IconButton]s representing common operations.
  /// For less common operations, consider using a [PopupMenuButton] as the
  /// last action.
  final List<Widget> actions;

  /// This widget is stacked behind the toolbar and the tabbar and it is not
  /// inset by the specified [padding]. It's height will be the same as the
  /// the app bar's overall height.
  ///
  /// Typically a [FlexibleSpaceBar]. See [FlexibleSpaceBar] for details.
  final Widget flexibleSpace;

  /// This widget appears across the bottom of the appbar.
  ///
  /// Typically a [TabBar].
  final AppBarBottomWidget bottom;

  /// The z-coordinate at which to place this app bar.
  ///
  /// The following elevations have defined shadows: 1, 2, 3, 4, 6, 8, 9, 12, 16, 24
  final int elevation;

  /// The color to use for the app bar's material. Typically this should be set
  /// along with [brightness], [iconTheme], [textTheme].
  ///
  /// Defaults to [ThemeData.primaryColor].
  final Color backgroundColor;

  /// The brightness of the app bar's material. Typically this is set along
  /// with [backgroundColor], [iconTheme], [textTheme].
  ///
  /// Defaults to [ThemeData.primaryColorBrightness].
  final Brightness brightness;

  /// The color, opacity, and size to use for app bar icons. Typically this
  /// is set along with [backgroundColor], [brightness], [textTheme].
  ///
  /// Defaults to [ThemeData.primaryIconTheme].
  final IconThemeData iconTheme;

  /// The typographic styles to use for text in the app bar. Typically this is
  /// set along with [brightness] [backgroundColor], [iconTheme].
  ///
  /// Defaults to [ThemeData.primaryTextTheme].
  final TextTheme textTheme;

  /// The amount of space by which to inset the contents of the app bar.
  /// The [Scaffold] increases [padding.top] by the height of the system
  /// status bar so that the toolbar appears below the status bar.
  final EdgeInsets padding;

  /// Whether the title should be centered.
  ///
  /// Defaults to being adapted to the current [TargetPlatform].
  final bool centerTitle;

  /// The tag to apply to the app bar's [Hero] widget.
  ///
  /// Defaults to a tag that matches other app bars.
  final Object heroTag;

  final double _expandedHeight;
  final double _collapsedHeight;

  static double getExpandedHeightFor(BuildContext context) {
    _AppBarExpandedHeight marker = context.inheritFromWidgetOfExactType(_AppBarExpandedHeight);
    return marker?.expandedHeight ?? 0.0;
  }

  /// Creates a copy of this app bar but with the given fields replaced with the new values.
  AppBar copyWith({
    Key key,
    Widget leading,
    Widget title,
    List<Widget> actions,
    Widget flexibleSpace,
    AppBarBottomWidget bottom,
    int elevation,
    Color backgroundColor,
    Brightness brightness,
    TextTheme textTheme,
    EdgeInsets padding,
    Object heroTag: _kUnspecifiedArgument,
    double expandedHeight,
    double collapsedHeight
  }) {
    return new AppBar(
      key: key ?? this.key,
      leading: leading ?? this.leading,
      title: title ?? this.title,
      actions: actions ?? this.actions,
      flexibleSpace: flexibleSpace ?? this.flexibleSpace,
      bottom: bottom ?? this.bottom,
      elevation: elevation ?? this.elevation,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      brightness: brightness ?? this.brightness,
      iconTheme: iconTheme ?? this.iconTheme,
      textTheme: textTheme ?? this.textTheme,
      padding: padding ?? this.padding,
      heroTag: heroTag != _kUnspecifiedArgument ? heroTag : this.heroTag,
      expandedHeight: expandedHeight ?? this._expandedHeight,
      collapsedHeight: collapsedHeight ?? this._collapsedHeight
    );
  }

  double get _toolBarHeight => kToolBarHeight;

  /// The height of the bottom widget. The [Scaffold] uses this value to control
  /// the size of the app bar when its appBarBehavior is [AppBarBehavior.scroll]
  /// or [AppBarBehavior.under].
  double get bottomHeight => bottom?.bottomHeight ?? 0.0;

  /// By default, the total height of the toolbar and the bottom widget (if any).
  /// The [Scaffold] gives its app bar this height initially. If a
  /// [flexibleSpace] widget is specified this height should be big
  /// enough to accommodate whatever that widget contains.
  double get expandedHeight => _expandedHeight ?? (_toolBarHeight + bottomHeight);

  /// By default, the height of the toolbar and the bottom widget (if any).
  /// If the height of the app bar is constrained to be less than this value
  /// then the toolbar and bottom widget are scrolled upwards, out of view.
  double get collapsedHeight => _collapsedHeight ?? (_toolBarHeight + bottomHeight);

  // Defines the opacity of the toolbar's text and icons.
  double _toolBarOpacity(double appBarHeight, double statusBarHeight) {
    return ((appBarHeight - bottomHeight - statusBarHeight) / _toolBarHeight).clamp(0.0, 1.0);
  }

  double _bottomOpacity(double appBarHeight, double statusBarHeight) {
    return ((appBarHeight - statusBarHeight) / bottomHeight).clamp(0.0, 1.0);
  }

  bool _getEffectiveCenterTitle(ThemeData themeData) {
    if (centerTitle != null)
      return centerTitle;
    assert(themeData.platform != null);
    switch (themeData.platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return false;
      case TargetPlatform.iOS:
        return true;
    }
    return null;
  }

  Widget _buildForSize(BuildContext context, BoxConstraints constraints) {
    assert(constraints.maxHeight < double.INFINITY);
    final Size size = constraints.biggest;
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final ThemeData themeData = Theme.of(context);

    IconThemeData appBarIconTheme = iconTheme ?? themeData.primaryIconTheme;
    TextStyle centerStyle = textTheme?.title ?? themeData.primaryTextTheme.title;
    TextStyle sideStyle = textTheme?.body1 ?? themeData.primaryTextTheme.body1;

    final bool effectiveCenterTitle = _getEffectiveCenterTitle(themeData);

    Brightness brightness = this.brightness ?? themeData.primaryColorBrightness;
    SystemChrome.setSystemUIOverlayStyle(brightness == Brightness.dark
      ? mojom.SystemUiOverlayStyle.light
      : mojom.SystemUiOverlayStyle.dark);

    final double toolBarOpacity = _toolBarOpacity(size.height, statusBarHeight);
    if (toolBarOpacity != 1.0) {
      final double opacity = const Interval(0.25, 1.0, curve: Curves.fastOutSlowIn).transform(toolBarOpacity);
      if (centerStyle?.color != null)
        centerStyle = centerStyle.copyWith(color: centerStyle.color.withOpacity(opacity));
      if (sideStyle?.color != null)
        sideStyle = sideStyle.copyWith(color: sideStyle.color.withOpacity(opacity));
      appBarIconTheme = appBarIconTheme.copyWith(
        opacity: opacity * (appBarIconTheme.opacity ?? 1.0)
      );
    }

    Widget centerWidget;
    if (title != null) {
      centerWidget = new DefaultTextStyle(
        style: centerStyle,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        child: title
      );
    }

    final List<Widget> toolBarRow = <Widget>[];
    if (leading != null) {
      toolBarRow.add(new Padding(
        padding: new EdgeInsets.only(right: 16.0),
        child: leading
      ));
    }
    toolBarRow.add(new Flexible(
      child: new Align(
        // TODO(abarth): In RTL this should be aligned to the right.
        alignment: FractionalOffset.centerLeft,
        child: new Padding(
          padding: new EdgeInsets.only(left: 8.0),
          child: effectiveCenterTitle ? null : centerWidget
        )
      )
    ));
    if (actions != null)
      toolBarRow.addAll(actions);

    Widget toolBar = new Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: new Row(children: toolBarRow)
    );

    if (effectiveCenterTitle && centerWidget != null) {
      toolBar = new Stack(
        children: <Widget>[
          // TODO(abarth): If there isn't enough room, we should move the title
          // off center rather than overlap the actions.
          new Center(child: centerWidget),
          toolBar
        ]
      );
    }

    Widget appBar = new SizedBox(
      height: kToolBarHeight,
      child: new IconTheme.merge(
        context: context,
        data: appBarIconTheme,
        child: new DefaultTextStyle(
          style: sideStyle,
          child: toolBar
        )
      )
    );

    final double bottomOpacity = _bottomOpacity(size.height, statusBarHeight);
    if (bottom != null) {
      appBar = new Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          appBar,
          bottomOpacity == 1.0 ? bottom : new Opacity(
            child: bottom,
            opacity: const Interval(0.25, 1.0, curve: Curves.fastOutSlowIn).transform(bottomOpacity)
          )
        ]
      );
    }

    // The padding applies to the toolbar and tabbar, not the flexible space.
    // The incoming padding parameter's top value typically equals the height
    // of the status bar - so that the toolbar appears below the status bar.
    appBar = new Padding(
      padding: padding,
      child: appBar
    );

    // If the appBar's height shrinks below collapsedHeight, it will be clipped and bottom
    // justified. This is so that the toolbar and the tabbar appear to move upwards as
    // the appBar's height is reduced below collapsedHeight.
    final double paddedCollapsedHeight = collapsedHeight + padding.top + padding.bottom;
    if (size.height < paddedCollapsedHeight) {
      appBar = new ClipRect(
        child: new OverflowBox(
          alignment: FractionalOffset.bottomLeft,
          minHeight: paddedCollapsedHeight,
          maxHeight: paddedCollapsedHeight,
          child: appBar
        )
      );
    } else if (flexibleSpace != null) {
      appBar = new Positioned(top: 0.0, left: 0.0, right: 0.0, child: appBar);
    }

    if (flexibleSpace != null) {
      appBar = new Stack(
        children: <Widget>[
          flexibleSpace,
          appBar
        ]
      );
    }

    Widget child = new _AppBarExpandedHeight(
      expandedHeight: expandedHeight,
      child: new Material(
        color: backgroundColor ?? themeData.primaryColor,
        elevation: elevation,
        child: new Align(
          alignment: FractionalOffset.topCenter,
          child: appBar
        )
      )
    );

    if (heroTag != null) {
      return new Hero(
        tag: heroTag,
        child: child
      );
    }

    return child;
  }

  @override
  Widget build(BuildContext context) => new LayoutBuilder(builder: _buildForSize);
}
