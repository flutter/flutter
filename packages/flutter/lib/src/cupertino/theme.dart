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

class CupertinoTheme extends InheritedModel<_ThemeDataProperties> {
  const CupertinoTheme({
    Key key,
    @required this.data,
    @required Widget child,
  }) : assert(child != null),
       assert(data != null),
       super(key: key, child: child);

  final CupertinoThemeData data;

  @override
  bool updateShouldNotify(CupertinoTheme old) => data != old.data;

  @override
  bool updateShouldNotifyDependent(CupertinoTheme oldWidget, Set<_ThemeDataProperties> dependencies) {
    return (data.barBackgroundColor != oldWidget.data.barBackgroundColor && dependencies.contains(_ThemeDataProperties.barBackgroundColor))
      || (data.brightness != oldWidget.data.brightness && dependencies.contains(_ThemeDataProperties.brightness))
      || (data.primaryColor != oldWidget.data.primaryColor && dependencies.contains(_ThemeDataProperties.primaryColor))
      || (data.primaryContrastingColor != oldWidget.data.primaryContrastingColor && dependencies.contains(_ThemeDataProperties.primaryContrastingColor))
      || (data.scaffoldBackgroundColor != oldWidget.data.scaffoldBackgroundColor && dependencies.contains(_ThemeDataProperties.scaffoldBackgroundColor))
      || (data.tableBackgroundColor != oldWidget.data.tableBackgroundColor && dependencies.contains(_ThemeDataProperties.tableBackgroundColor))
      || (data.textTheme != oldWidget.data.textTheme && dependencies.contains(_ThemeDataProperties.textTheme));
  }

  static CupertinoThemeData of(BuildContext context) => _CupertinoThemeInheritedData(context);
}

enum _ThemeDataProperties {
  barBackgroundColor,
  brightness,
  primaryColor,
  primaryContrastingColor,
  scaffoldBackgroundColor,
  tableBackgroundColor,
  textTheme,
}

class _CupertinoThemeInheritedData extends CupertinoThemeData {
  const _CupertinoThemeInheritedData(this.context);

  final BuildContext context;

  @override
  Color get barBackgroundColor => getData(_ThemeDataProperties.barBackgroundColor).barBackgroundColor;

  @override
  Brightness get brightness => getData(_ThemeDataProperties.brightness).brightness;

  @override
  Color get primaryColor => getData(_ThemeDataProperties.primaryColor).primaryColor;

  @override
  Color get primaryContrastingColor => getData(_ThemeDataProperties.primaryContrastingColor).primaryContrastingColor;

  @override
  Color get scaffoldBackgroundColor => getData(_ThemeDataProperties.scaffoldBackgroundColor).scaffoldBackgroundColor;

  @override
  Color get tableBackgroundColor => getData(_ThemeDataProperties.tableBackgroundColor).tableBackgroundColor;

  @override
  CupertinoTextTheme get textTheme => getData(_ThemeDataProperties.textTheme).textTheme;

  CupertinoThemeData getData(_ThemeDataProperties property) {
    return InheritedModel.inheritFrom<CupertinoTheme>(context, aspect: property)?.data
        ?? const CupertinoThemeData();
  }

  @override
  CupertinoThemeData copyWith({
    Brightness brightness,
    Color primaryColor,
    Color primaryContrastingColor,
    CupertinoTextTheme textTheme,
    Color barBackgroundColor,
    Color scaffoldBackgroundColor,
    Color tableBackgroundColor,
  }) {
    // When you copyWith, you effectively are depending on everything.
    return InheritedModel.inheritFrom<CupertinoTheme>(context)?.data?.copyWith(
      brightness: brightness,
      primaryColor: primaryColor,
      primaryContrastingColor: primaryContrastingColor,
      textTheme: textTheme,
      barBackgroundColor: barBackgroundColor,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      tableBackgroundColor: tableBackgroundColor,
    );
  }
}

@immutable
class CupertinoThemeData extends Diagnosticable {
  const CupertinoThemeData({
    Brightness brightness,
    Color primaryColor,
    Color primaryContrastingColor,
    CupertinoTextTheme textTheme,
    Color barBackgroundColor,
    Color scaffoldBackgroundColor,
    Color tableBackgroundColor,
  }) : this.raw(
        brightness,
        primaryColor,
        primaryContrastingColor,
        textTheme,
        barBackgroundColor,
        scaffoldBackgroundColor,
        tableBackgroundColor,
      );

  @protected
  const CupertinoThemeData.raw(
    this._brightness,
    this._primaryColor,
    this._primaryContrastingColor,
    this._textTheme,
    this._barBackgroundColor,
    this._scaffoldBackgroundColor,
    this._tableBackgroundColor,
  );

  bool get _isLight => brightness == Brightness.light;

  final Brightness _brightness;
  Brightness get brightness => _brightness ?? Brightness.light;

  final Color _primaryColor;
  Color get primaryColor {
    return _primaryColor ??
        (_isLight ? CupertinoColors.activeBlue : CupertinoColors.activeOrange);
  }

  final Color _primaryContrastingColor;
  Color get primaryContrastingColor {
    return _primaryContrastingColor ??
        (_isLight ? CupertinoColors.white : CupertinoColors.black);
  }

  final CupertinoTextTheme _textTheme;
  CupertinoTextTheme get textTheme {
    return _textTheme ?? CupertinoTextTheme(
      isLight: _isLight,
      primaryColor: primaryColor,
    );
  }

  final Color _barBackgroundColor;
  Color get barBackgroundColor {
    return _barBackgroundColor ??
        (_isLight ? _kDefaultBarLightBackgroundColor : _kDefaultBarDarkBackgroundColor);
  }

  final Color _scaffoldBackgroundColor;
  Color get scaffoldBackgroundColor {
    return _scaffoldBackgroundColor ??
        (_isLight ? CupertinoColors.white : CupertinoColors.black);
  }

  final Color _tableBackgroundColor;
  Color get tableBackgroundColor {
    return _tableBackgroundColor ??
        (_isLight ? CupertinoColors.extraLightBackgroundGray : CupertinoColors.darkBackgroundGray);
  }

  CupertinoThemeData raw() {
    return _RawCupertinoThemeData(
      _brightness,
      _primaryColor,
      _primaryContrastingColor,
      _textTheme,
      _barBackgroundColor,
      _scaffoldBackgroundColor,
      _tableBackgroundColor,
    );
  }

  CupertinoThemeData copyWith({
    Brightness brightness,
    Color primaryColor,
    Color primaryContrastingColor,
    CupertinoTextTheme textTheme,
    Color barBackgroundColor,
    Color scaffoldBackgroundColor,
    Color tableBackgroundColor,
  }) {
    return CupertinoThemeData(
      brightness: brightness ?? _brightness,
      primaryColor: primaryColor ?? _primaryColor,
      primaryContrastingColor: primaryContrastingColor ?? _primaryContrastingColor,
      textTheme: textTheme ?? _textTheme,
      barBackgroundColor: barBackgroundColor ?? _barBackgroundColor,
      scaffoldBackgroundColor: scaffoldBackgroundColor ?? _scaffoldBackgroundColor,
      tableBackgroundColor: tableBackgroundColor ?? _tableBackgroundColor,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    const CupertinoThemeData defaultData = CupertinoThemeData();
    properties.add(EnumProperty<Brightness>('brightness', brightness, defaultValue: defaultData.brightness));
    properties.add(DiagnosticsProperty<Color>('primaryColor', primaryColor, defaultValue: defaultData.primaryColor));
    properties.add(DiagnosticsProperty<Color>('primaryContrastingColor', primaryContrastingColor, defaultValue: defaultData.primaryContrastingColor));
    properties.add(DiagnosticsProperty<CupertinoTextTheme>('textTheme', textTheme, defaultValue: defaultData.textTheme));
    properties.add(DiagnosticsProperty<Color>('barBackgroundColor', barBackgroundColor, defaultValue: defaultData.barBackgroundColor));
    properties.add(DiagnosticsProperty<Color>('scaffoldBackgroundColor', scaffoldBackgroundColor, defaultValue: defaultData.scaffoldBackgroundColor));
    properties.add(DiagnosticsProperty<Color>('tableBackgroundColor', tableBackgroundColor, defaultValue: defaultData.tableBackgroundColor));
  }
}

@immutable
class _RawCupertinoThemeData extends CupertinoThemeData {
  const _RawCupertinoThemeData(
    this.brightness,
    this.primaryColor,
    this.primaryContrastingColor,
    this.textTheme,
    this.barBackgroundColor,
    this.scaffoldBackgroundColor,
    this.tableBackgroundColor,
  ) : super.raw(
        brightness,
        primaryColor,
        primaryContrastingColor,
        textTheme,
        barBackgroundColor,
        scaffoldBackgroundColor,
        tableBackgroundColor,
      );

  @override final Brightness brightness;
  @override final Color primaryColor;
  @override final Color primaryContrastingColor;
  @override final CupertinoTextTheme textTheme;
  @override final Color barBackgroundColor;
  @override final Color scaffoldBackgroundColor;
  @override final Color tableBackgroundColor;
}
