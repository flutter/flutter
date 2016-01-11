// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart';

import 'icon_theme.dart';
import 'icon_theme_data.dart';
import 'ink_well.dart';
import 'material.dart';
import 'tabs.dart';
import 'theme.dart';

// TODO(eseidel): This needs to change based on device size?
// http://www.google.com/design/spec/layout/metrics-keylines.html#metrics-keylines-keylines-spacing
const double _kSize = 56.0;
const double _kSizeMini = 40.0;
const Duration _kShowDuration = const Duration(milliseconds: 200);

// TODO(hansmuller) use ItemBuilder<T> when TabBarSelection<T> exists
typedef Widget PerTabChildBuilder<T>(BuildContext context, int index);

class FloatingActionButton extends StatefulComponent {
  const FloatingActionButton({
    Key key,
    this.child,
    this.backgroundColor,
    this.elevation: 6,
    this.highlightElevation: 12,
    this.onPressed,
    this.mini: false,
    this.perTabChildBuilder,
    this.tabBarSelection // TODO: remove once this is fixed https://github.com/flutter/flutter/issues/835
  }) : super(key: key);

  final Widget child;
  final Color backgroundColor;
  final VoidCallback onPressed;
  final int elevation;
  final int highlightElevation;
  final bool mini;
  final PerTabChildBuilder perTabChildBuilder;
  final TabBarSelection tabBarSelection;

  _FloatingActionButtonState createState() => new _FloatingActionButtonState();
}

class _FloatingActionButtonState extends State<FloatingActionButton> {
  Performance _showPerformance;

  void initState() {
    super.initState();
    if (config.tabBarSelection != null)
      config.tabBarSelection.performance.addListener(_handleTabProgressChange);
  }

  void dispose() {
    if (config.tabBarSelection != null)
      config.tabBarSelection.performance.removeListener(_handleTabProgressChange);
    super.dispose();
  }

  void didUpdateConfig(FloatingActionButton oldConfig) {
    super.didUpdateConfig(oldConfig);
    if (config.tabBarSelection?.performance != oldConfig.tabBarSelection?.performance) {
      // TBD: remove the old listener if any, add the new one if any
    }
  }

  void _handleTabProgressChange() {
    if (config.tabBarSelection.indexIsChanging) {
      setState(() {
        if (config.tabBarSelection.performance.status == PerformanceStatus.completed) {
          _showPerformance = new Performance(duration: _kShowDuration)
          ..addListener(() { setState(() {}); })
          ..forward().then((_) {
            _showPerformance = null;
          });
        }
      });
    }
  }

  bool _highlight = false;

  void _handleHighlightChanged(bool value) {
    setState(() {
      _highlight = value;
    });
  }

  Widget build(BuildContext context) {
    Widget child = config.child;
    if (config.perTabChildBuilder != null) {
      int index = config.tabBarSelection.indexIsChanging ? config.tabBarSelection.previousIndex : config.tabBarSelection.index;
      child = config.perTabChildBuilder(context, index);
    }

    if (child == null)
      return new Container();

    IconThemeColor iconThemeColor = IconThemeColor.white;
    Color materialColor = config.backgroundColor;
    if (materialColor == null) {
      ThemeData themeData = Theme.of(context);
      materialColor = themeData.accentColor;
      iconThemeColor = themeData.accentColorBrightness == ThemeBrightness.dark ? IconThemeColor.white : IconThemeColor.black;
    }

    final double outerRadius = config.mini ? _kSizeMini : _kSize;
    double innerRadius = outerRadius;
    if (child != null) {
      if (config.tabBarSelection != null && config.tabBarSelection.indexIsChanging)
        innerRadius = new AnimatedValue<double>(outerRadius, end: 0.0, curve: Curves.ease)
          .lerp(config.tabBarSelection.performance.progress);
      else if (_showPerformance != null)
        innerRadius = new AnimatedValue<double>(0.0, end: outerRadius, curve: Curves.ease)
          .lerp(_showPerformance.progress);
    }

    return new SizedBox(
      width: outerRadius,
      height: outerRadius,
      child: new Center(
        child: new Material(
          color: materialColor,
          type: MaterialType.circle,
          elevation: _highlight ? config.highlightElevation : config.elevation,
          child: new SizedBox(
            width: innerRadius,
            height: innerRadius,
            child: new InkWell(
              onTap: config.onPressed,
              onHighlightChanged: _handleHighlightChanged,
              child: new IconTheme(
                data: new IconThemeData(color: iconThemeColor),
                child: child
              )
            )
          )
        )
      )
    );
  }
}
