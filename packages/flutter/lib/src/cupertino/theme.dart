// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'text_theme.dart';

export 'package:flutter/services.dart' show Brightness;

// Values derived from https://developer.apple.com/design/resources/.
const Color _kDefaultBarLightBackgroundColor = Color(0xCCF8F8F8);

// Values derived from https://developer.apple.com/design/resources/.
const Color _kDefaultBarDarkBackgroundColor = Color(0xB7212121);

// Values derived from https://developer.apple.com/design/resources/.
const Color _kDefaultBarBorderColor = Color(0x4C000000);

class CupertinoTheme extends StatelessWidget {
  const CupertinoTheme({
    Key key,
    @required this.data,
    @required this.child,
  }) : assert(child != null),
       assert(data != null),
       super(key: key);

  final CupertinoThemeData data;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _InheritedCupertinoTheme(
      data: data,
      child: child,
    );
  }

  static CupertinoThemeData of(BuildContext context) => _CupertinoThemeInheritedData(context);
}

class _InheritedCupertinoTheme extends InheritedModel<_ThemeDataProperties> {
  const _InheritedCupertinoTheme({
    Key key,
    @required this.data,
    @required Widget child
  }) : assert(data != null),
       super(key: key, child: child);

  final CupertinoThemeData data;

  @override
  bool updateShouldNotify(_InheritedCupertinoTheme old) => data != old.data;

  @override
  bool updateShouldNotifyDependent(_InheritedCupertinoTheme oldWidget, Set<_ThemeDataProperties> dependencies) {
    return (data.barBackgroundColor != oldWidget.data.barBackgroundColor && dependencies.contains(_ThemeDataProperties.barBackgroundColor))
        || (data.barBorderColor != oldWidget.data.barBorderColor && dependencies.contains(_ThemeDataProperties.barBorderColor))
        || (data.brightness != oldWidget.data.brightness && dependencies.contains(_ThemeDataProperties.brightness))
        || (data.primaryColor != oldWidget.data.primaryColor && dependencies.contains(_ThemeDataProperties.primaryColor))
        || (data.scaffoldBackgroundColor != oldWidget.data.scaffoldBackgroundColor && dependencies.contains(_ThemeDataProperties.scaffoldBackgroundColor))
        || (data.tableBackgroundColor != oldWidget.data.tableBackgroundColor && dependencies.contains(_ThemeDataProperties.tableBackgroundColor))
        || (data.textTheme != oldWidget.data.textTheme && dependencies.contains(_ThemeDataProperties.textTheme));
  }
}

enum _ThemeDataProperties {
  barBackgroundColor,
  barBorderColor,
  brightness,
  primaryColor,
  scaffoldBackgroundColor,
  tableBackgroundColor,
  textTheme,
}

class _CupertinoThemeInheritedData implements CupertinoThemeData {
  _CupertinoThemeInheritedData(this.context);

  BuildContext context;

  @override
  Color get barBackgroundColor => getData(_ThemeDataProperties.barBackgroundColor).barBackgroundColor;

  @override
  Color get barBorderColor => getData(_ThemeDataProperties.barBorderColor).barBorderColor;

  @override
  Brightness get brightness => getData(_ThemeDataProperties.brightness).brightness;

  @override
  Color get primaryColor => getData(_ThemeDataProperties.primaryColor).primaryColor;

  @override
  Color get scaffoldBackgroundColor => getData(_ThemeDataProperties.scaffoldBackgroundColor).scaffoldBackgroundColor;

  @override
  Color get tableBackgroundColor => getData(_ThemeDataProperties.tableBackgroundColor).tableBackgroundColor;

  @override
  CupertinoTextTheme get textTheme => getData(_ThemeDataProperties.textTheme).textTheme;

  CupertinoThemeData getData(_ThemeDataProperties property) {
    return InheritedModel.inheritFrom<_InheritedCupertinoTheme>(context, aspect: property).data;
  }
}

class CupertinoThemeData {
  factory CupertinoThemeData({
    Brightness brightness,
    Color primaryColor,
    CupertinoTextTheme textTheme,
    Color barBackgroundColor,
    Color barBorderColor,
    Color scaffoldBackgroundColor,
    Color tableBackgroundColor,
  }) {
    brightness ??= Brightness.light;
    final bool isLight = brightness == Brightness.light;
    primaryColor ??= isLight ? CupertinoColors.activeBlue : CupertinoColors.activeOrange;
    textTheme ??= CupertinoTextTheme(
      isDark: !isLight,
      primaryColor: primaryColor,
    );
    barBackgroundColor ??= isLight ? _kDefaultBarLightBackgroundColor : _kDefaultBarDarkBackgroundColor;
    barBorderColor ??= _kDefaultBarBorderColor;
    scaffoldBackgroundColor ??= isLight ? CupertinoColors.white : CupertinoColors.black;
    tableBackgroundColor ??= isLight ? CupertinoColors.extraLightBackgroundGray : CupertinoColors.darkBackgroundGray;
    return CupertinoThemeData._(
      brightness,
      primaryColor,
      textTheme,
      barBackgroundColor,
      barBorderColor,
      scaffoldBackgroundColor,
      tableBackgroundColor,
    );
  }

  const CupertinoThemeData._(
    this.brightness,
    this.primaryColor,
    this.textTheme,
    this.barBackgroundColor,
    this.barBorderColor,
    this.scaffoldBackgroundColor,
    this.tableBackgroundColor,
  );

  final Brightness brightness;
  final Color primaryColor;
  final CupertinoTextTheme textTheme;
  final Color barBackgroundColor;
  final Color barBorderColor;
  final Color scaffoldBackgroundColor;
  final Color tableBackgroundColor;
}
