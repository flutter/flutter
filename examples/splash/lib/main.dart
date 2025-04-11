// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:splash/foo.dart';

ThemeData theme() => ThemeData(primaryColor: Colors.red);
ThemeData themeDark() => ThemeData(primaryColor: Colors.green);

CupertinoThemeData cupertinoTheme() =>
    CupertinoThemeData(primaryColor: Colors.red);
CupertinoThemeData cupertinoThemeDark() =>
    CupertinoThemeData(primaryColor: Colors.green);

PreviewThemeData themeData() => PreviewThemeData(
  materialLight: theme(), //ThemeData.light(),
  materialDark: themeDark(), //ThemeData.dark(),
  cupertinoLight:
      cupertinoTheme(), //CupertinoThemeData(brightness: Brightness.light),
  cupertinoDark:
      cupertinoThemeDark(), //CupertinoThemeData(brightness: Brightness.dark),
);

@Preview(theme: themeData, brightness: foo)
WidgetBuilder preview() => (BuildContext context) {
  final theme = Theme.of(context);
  return Column(
    children: [
      Text('Foo', style: TextStyle(color: theme.primaryColor)),
      CupertinoButton.filled(child: Text('Foo'), onPressed: () => null),
    ],
  );
};

void main() {
  runApp(
    const DecoratedBox(
      decoration: BoxDecoration(color: Colors.white),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          textDirection: TextDirection.ltr,
          children: <Widget>[
            FlutterLogo(size: 48),
            Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'This app is only meant to be run under the Flutter debugger',
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
