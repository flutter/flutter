// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'text_theme.dart';

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

  static CupertinoThemeData of(BuildContext context) {
    final _InheritedCupertinoTheme inheritedTheme = context.inheritFromWidgetOfExactType(_InheritedCupertinoTheme);
    return inheritedTheme.data;
  }
}

class _InheritedCupertinoTheme extends InheritedWidget {
  const _InheritedCupertinoTheme({
    Key key,
    @required this.data,
    @required Widget child
  }) : assert(data != null),
       super(key: key, child: child);

  final CupertinoThemeData data;

  @override
  bool updateShouldNotify(_InheritedCupertinoTheme old) => data != old.data;
}

class CupertinoThemeData extends Diagnosticable {
  factory CupertinoThemeData({
    Brightness brightness,
    Color primaryColor,
    CupertinoTextTheme textTheme,
    Color barBackgroundColor,
    Color barBorderColor,
    Color scaffoldBackgroundColor,
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
  }

  Brightness brightness;
  Color primaryColor;
  CupertinoTextTheme textTheme;
  Color barBackgroundColor;
  Color barBorderColor;
  Color scaffoldBackgroundColor;
}