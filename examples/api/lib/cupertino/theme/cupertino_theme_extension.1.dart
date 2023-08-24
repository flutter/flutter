// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Flutter code sample for [CupertinoThemeExtension].

@immutable
class MyColors extends CupertinoThemeExtension<MyColors> {
  const MyColors({
    required this.brandColor,
    required this.danger,
  });

  final Color? brandColor;
  final Color? danger;

  @override
  MyColors copyWith({Color? brandColor, Color? danger}) {
    return MyColors(
      brandColor: brandColor ?? this.brandColor,
      danger: danger ?? this.danger,
    );
  }

  @override
  CupertinoThemeExtension<MyColors> resolveFrom(BuildContext context) {
    return MyColors(
      brandColor: CupertinoDynamicColor.maybeResolve(brandColor, context),
      danger: CupertinoDynamicColor.maybeResolve(danger, context),
    );
  }

  // Optional
  @override
  String toString() => 'MyColors(brandColor: $brandColor, danger: $danger)';
}

void main() {
  // Slow down time to see lerping.
  timeDilation = 5.0;
  runApp(const CupertinoThemeExtensionExampleApp());
}

class CupertinoThemeExtensionExampleApp extends StatefulWidget {
  const CupertinoThemeExtensionExampleApp({super.key});

  @override
  State<CupertinoThemeExtensionExampleApp> createState() => _CupertinoThemeExtensionExampleAppState();
}

class _CupertinoThemeExtensionExampleAppState extends State<CupertinoThemeExtensionExampleApp> {
  bool isLightTheme = true;

  void toggleTheme() {
    setState(() => isLightTheme = !isLightTheme);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      theme: CupertinoThemeData(
        brightness: isLightTheme ? Brightness.light : Brightness.dark,
        extensions: const <CupertinoThemeExtension<dynamic>>[
          MyColors(
            brandColor: CupertinoDynamicColor.withBrightness(
              color: Color(0xFF1E88E5),
              darkColor: Color(0xFF90CAF9),
            ),
            danger: CupertinoDynamicColor.withBrightness(
              color: Color(0xFFE53935),
              darkColor: Color(0xFFEF9A9A),
            ),
          ),
        ],
      ),
      home: Home(
        isLightTheme: isLightTheme,
        toggleTheme: toggleTheme,
      ),
    );
  }
}

class Home extends StatelessWidget {
  const Home({
    super.key,
    required this.isLightTheme,
    required this.toggleTheme,
  });

  final bool isLightTheme;
  final void Function() toggleTheme;

  @override
  Widget build(BuildContext context) {
    final MyColors myColors = CupertinoTheme.of(context).extension<MyColors>()!;
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('CupertinoThemeExtension Sample'),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AnimatedContainer(width: 100, height: 100, color: myColors.brandColor, duration: kThemeChangeDuration),
            const SizedBox(width: 10),
            AnimatedContainer(width: 100, height: 100, color: myColors.danger, duration: kThemeChangeDuration),
            const SizedBox(width: 50),
            CupertinoButton.filled(
              onPressed: toggleTheme,
              child: Icon(isLightTheme ? CupertinoIcons.moon_zzz_fill : CupertinoIcons.sun_max_fill),
            ),
          ],
        ),
      ),
    );
  }
}
