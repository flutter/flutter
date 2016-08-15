// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LinkTextSpan extends TextSpan {
  LinkTextSpan({ TextStyle style, String url, String text }) : super(
    style: style,
    text: text ?? url,
    recognizer: new TapGestureRecognizer()..onTap = () {
      UrlLauncher.launch(url);
    }
  );
}

class GalleryDrawerHeader extends StatefulWidget {
  const GalleryDrawerHeader({ Key key, this.light }) : super(key: key);

  final bool light;

  @override
  _GalleryDrawerHeaderState createState() => new _GalleryDrawerHeaderState();
}

class _GalleryDrawerHeaderState extends State<GalleryDrawerHeader> {
  bool _logoHasName = true;
  bool _logoHorizontal = true;
  Map<int, Color> _swatch = Colors.blue;

  @override
  Widget build(BuildContext context) {
    final double systemTopPadding = MediaQuery.of(context).padding.top;

    return new DrawerHeader(
      decoration: new FlutterLogoDecoration(
        margin: new EdgeInsets.fromLTRB(12.0, 12.0 + systemTopPadding, 12.0, 12.0),
        style: _logoHasName ? _logoHorizontal ? FlutterLogoStyle.horizontal
                                              : FlutterLogoStyle.stacked
                                              : FlutterLogoStyle.markOnly,
        swatch: _swatch,
        textColor: config.light ? const Color(0xFF616161) : const Color(0xFF9E9E9E),
      ),
      duration: const Duration(milliseconds: 750),
      child: new GestureDetector(
        onLongPress: () {
          setState(() {
            _logoHorizontal = !_logoHorizontal;
            if (!_logoHasName)
              _logoHasName = true;
          });
        },
        onTap: () {
          setState(() {
            _logoHasName = !_logoHasName;
          });
        },
        onDoubleTap: () {
          setState(() {
            final List<Map<int, Color>> options = <Map<int, Color>>[];
            if (_swatch != Colors.blue)
              options.addAll(<Map<int, Color>>[Colors.blue, Colors.blue, Colors.blue, Colors.blue, Colors.blue, Colors.blue, Colors.blue]);
            if (_swatch != Colors.amber)
              options.addAll(<Map<int, Color>>[Colors.amber, Colors.amber, Colors.amber]);
            if (_swatch != Colors.red)
              options.addAll(<Map<int, Color>>[Colors.red, Colors.red, Colors.red]);
            if (_swatch != Colors.indigo)
              options.addAll(<Map<int, Color>>[Colors.indigo, Colors.indigo, Colors.indigo]);
            if (_swatch != Colors.pink)
              options.addAll(<Map<int, Color>>[Colors.pink]);
            if (_swatch != Colors.purple)
              options.addAll(<Map<int, Color>>[Colors.purple]);
            if (_swatch != Colors.cyan)
              options.addAll(<Map<int, Color>>[Colors.cyan]);
            _swatch = options[new math.Random().nextInt(options.length)];
          });
        }
      )
    );
  }
}

class GalleryDrawer extends StatelessWidget {
  GalleryDrawer({
    Key key,
    this.useLightTheme,
    this.onThemeChanged,
    this.timeDilation,
    this.onTimeDilationChanged,
    this.showPerformanceOverlay,
    this.onShowPerformanceOverlayChanged
  }) : super(key: key) {
    assert(onThemeChanged != null);
    assert(onTimeDilationChanged != null);
  }

  final bool useLightTheme;
  final ValueChanged<bool> onThemeChanged;

  final double timeDilation;
  final ValueChanged<double> onTimeDilationChanged;

  final bool showPerformanceOverlay;
  final ValueChanged<bool> onShowPerformanceOverlayChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final TextStyle aboutTextStyle = themeData.textTheme.body2;
    final TextStyle aboutLinkStyle = themeData.textTheme.body2.copyWith(color: themeData.accentColor);

    return new Drawer(
      child: new Block(
        children: <Widget>[
          new GalleryDrawerHeader(light: useLightTheme),
          new DrawerItem(
            icon: new Icon(Icons.brightness_5),
            onPressed: () { onThemeChanged(true); },
            selected: useLightTheme,
            child: new Row(
              children: <Widget>[
                new Flexible(child: new Text('Light')),
                new Radio<bool>(
                  value: true,
                  groupValue: useLightTheme,
                  onChanged: onThemeChanged
                )
              ]
            )
          ),
          new DrawerItem(
            icon: new Icon(Icons.brightness_7),
            onPressed: () { onThemeChanged(false); },
            selected: useLightTheme,
            child: new Row(
              children: <Widget>[
                new Flexible(child: new Text('Dark')),
                new Radio<bool>(
                  value: false,
                  groupValue: useLightTheme,
                  onChanged: onThemeChanged
                )
              ]
            )
          ),
          new Divider(),
          new DrawerItem(
            icon: new Icon(Icons.hourglass_empty),
            selected: timeDilation != 1.0,
            onPressed: () { onTimeDilationChanged(timeDilation != 1.0 ? 1.0 : 20.0); },
            child: new Row(
              children: <Widget>[
                new Flexible(child: new Text('Animate Slowly')),
                new Checkbox(
                  value: timeDilation != 1.0,
                  onChanged: (bool value) { onTimeDilationChanged(value ? 20.0 : 1.0); }
                )
              ]
            )
          ),
          new DrawerItem(
            icon: new Icon(Icons.assessment),
            onPressed: () { onShowPerformanceOverlayChanged(!showPerformanceOverlay); },
            selected: showPerformanceOverlay,
            child: new Row(
              children: <Widget>[
                new Flexible(child: new Text('Performance Overlay')),
                new Checkbox(
                  value: showPerformanceOverlay,
                  onChanged: (bool value) { onShowPerformanceOverlayChanged(!showPerformanceOverlay); }
                )
              ]
            )
          ),
          new AboutDrawerItem(
            icon: new FlutterLogo(),
            applicationVersion: '2016 Q3 Preview',
            applicationIcon: new FlutterLogo(),
            applicationLegalese: '© 2016 The Chromium Authors',
            aboutBoxChildren: <Widget>[
              new Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: new RichText(
                  text: new TextSpan(
                    children: <TextSpan>[
                      new TextSpan(
                        style: aboutTextStyle,
                        text: "Flutter is an early-stage, open-source project to help "
                        "developers build high-performance, high-fidelity, mobile "
                        "apps for iOS and Android from a single codebase. This "
                        "gallery is a preview of Flutter's many widgets, behaviors, "
                        "animations, layouts, and more. Learn more about Flutter at "
                      ),
                      new LinkTextSpan(
                        style: aboutLinkStyle,
                        url: 'https://flutter.io'
                      ),
                      new TextSpan(
                        style: aboutTextStyle,
                        text: ".\n\nTo see the source code for this app, please visit the "
                      ),
                      new LinkTextSpan(
                        style: aboutLinkStyle,
                        url: 'https://goo.gl/iv1p4G',
                        text: 'flutter github repo'
                      ),
                      new TextSpan(
                        style: aboutTextStyle,
                        text: "."
                      )
                    ]
                  )
                )
              )
            ]
          )
        ]
      )
    );
  }
}
