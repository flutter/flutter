// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show defaultTargetPlatform, required;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

import 'theme.dart';

class LinkTextSpan extends TextSpan {

  // Beware!
  //
  // This class is only safe because the TapGestureRecognizer is not
  // given a deadline and therefore never allocates any resources.
  //
  // In any other situation -- setting a deadline, using any of the less trivial
  // recognizers, etc -- you would have to manage the gesture recognizer's
  // lifetime and call dispose() when the TextSpan was no longer being rendered.
  //
  // Since TextSpan itself is @immutable, this means that you would have to
  // manage the recognizer from outside the TextSpan, e.g. in the State of a
  // stateful widget that then hands the recognizer to the TextSpan.

  LinkTextSpan({ TextStyle style, String url, String text }) : super(
    style: style,
    text: text ?? url,
    recognizer: new TapGestureRecognizer()..onTap = () {
      launch(url);
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
  MaterialColor _logoColor = Colors.blue;

  @override
  Widget build(BuildContext context) {
    final double systemTopPadding = MediaQuery.of(context).padding.top;

    return new Semantics(
      label: 'Flutter',
      child: new DrawerHeader(
        decoration: new FlutterLogoDecoration(
          margin: new EdgeInsets.fromLTRB(12.0, 12.0 + systemTopPadding, 12.0, 12.0),
          style: _logoHasName ? _logoHorizontal ? FlutterLogoStyle.horizontal
                                                : FlutterLogoStyle.stacked
                                                : FlutterLogoStyle.markOnly,
          lightColor: _logoColor.shade400,
          darkColor: _logoColor.shade900,
          textColor: widget.light ? const Color(0xFF616161) : const Color(0xFF9E9E9E),
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
              final List<MaterialColor> options = <MaterialColor>[];
              if (_logoColor != Colors.blue)
                options.addAll(<MaterialColor>[Colors.blue, Colors.blue, Colors.blue, Colors.blue, Colors.blue, Colors.blue, Colors.blue]);
              if (_logoColor != Colors.amber)
                options.addAll(<MaterialColor>[Colors.amber, Colors.amber, Colors.amber]);
              if (_logoColor != Colors.red)
                options.addAll(<MaterialColor>[Colors.red, Colors.red, Colors.red]);
              if (_logoColor != Colors.indigo)
                options.addAll(<MaterialColor>[Colors.indigo, Colors.indigo, Colors.indigo]);
              if (_logoColor != Colors.pink)
                options.addAll(<MaterialColor>[Colors.pink]);
              if (_logoColor != Colors.purple)
                options.addAll(<MaterialColor>[Colors.purple]);
              if (_logoColor != Colors.cyan)
                options.addAll(<MaterialColor>[Colors.cyan]);
              _logoColor = options[new math.Random().nextInt(options.length)];
            });
          }
        ),
      ),
    );
  }
}

class GalleryDrawer extends StatelessWidget {
  const GalleryDrawer({
    Key key,
    this.galleryTheme,
    @required this.onThemeChanged,
    this.timeDilation,
    @required this.onTimeDilationChanged,
    this.textScaleFactor,
    this.onTextScaleFactorChanged,
    this.showPerformanceOverlay,
    this.onShowPerformanceOverlayChanged,
    this.checkerboardRasterCacheImages,
    this.onCheckerboardRasterCacheImagesChanged,
    this.checkerboardOffscreenLayers,
    this.onCheckerboardOffscreenLayersChanged,
    this.onPlatformChanged,
    this.overrideDirection: TextDirection.ltr,
    this.onOverrideDirectionChanged,
    this.onSendFeedback,
  }) : assert(onThemeChanged != null),
       assert(onTimeDilationChanged != null),
       super(key: key);

  final GalleryTheme galleryTheme;
  final ValueChanged<GalleryTheme> onThemeChanged;

  final double timeDilation;
  final ValueChanged<double> onTimeDilationChanged;

  final double textScaleFactor;
  final ValueChanged<double> onTextScaleFactorChanged;

  final bool showPerformanceOverlay;
  final ValueChanged<bool> onShowPerformanceOverlayChanged;

  final bool checkerboardRasterCacheImages;
  final ValueChanged<bool> onCheckerboardRasterCacheImagesChanged;

  final bool checkerboardOffscreenLayers;
  final ValueChanged<bool> onCheckerboardOffscreenLayersChanged;

  final ValueChanged<TargetPlatform> onPlatformChanged;

  final TextDirection overrideDirection;
  final ValueChanged<TextDirection> onOverrideDirectionChanged;

  final VoidCallback onSendFeedback;

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final TextStyle aboutTextStyle = themeData.textTheme.body2;
    final TextStyle linkStyle = themeData.textTheme.body2.copyWith(color: themeData.accentColor);

    final List<Widget> themeItems = kAllGalleryThemes.map<Widget>((GalleryTheme theme) {
      return new RadioListTile<GalleryTheme>(
        title: new Text(theme.name),
        secondary: new Icon(theme.icon),
        value: theme,
        groupValue: galleryTheme,
        onChanged: onThemeChanged,
        selected: galleryTheme == theme,
      );
    }).toList();

    final Widget mountainViewItem = new RadioListTile<TargetPlatform>(
      // on iOS, we don't want to show an Android phone icon
      secondary: new Icon(defaultTargetPlatform == TargetPlatform.iOS ? Icons.star : Icons.phone_android),
      title: new Text(defaultTargetPlatform == TargetPlatform.iOS ? 'Mountain View' : 'Android'),
      value: TargetPlatform.android,
      groupValue: Theme.of(context).platform,
      onChanged: onPlatformChanged,
      selected: Theme.of(context).platform == TargetPlatform.android,
    );

    final Widget cupertinoItem = new RadioListTile<TargetPlatform>(
      // on iOS, we don't want to show the iPhone icon
      secondary: new Icon(defaultTargetPlatform == TargetPlatform.iOS ? Icons.star_border : Icons.phone_iphone),
      title: new Text(defaultTargetPlatform == TargetPlatform.iOS ? 'Cupertino' : 'iOS'),
      value: TargetPlatform.iOS,
      groupValue: Theme.of(context).platform,
      onChanged: onPlatformChanged,
      selected: Theme.of(context).platform == TargetPlatform.iOS,
    );

    final List<Widget> textSizeItems = <Widget>[];
    final Map<double, String> textSizes = <double, String>{
      null: 'System Default',
      0.8: 'Small',
      1.0: 'Normal',
      1.3: 'Large',
      2.0: 'Huge',
    };
    for (double size in textSizes.keys) {
      textSizeItems.add(new RadioListTile<double>(
        secondary: const Icon(Icons.text_fields),
        title: new Text(textSizes[size]),
        value: size,
        groupValue: textScaleFactor,
        onChanged: onTextScaleFactorChanged,
        selected: textScaleFactor == size,
      ));
    }

    final Widget animateSlowlyItem = new CheckboxListTile(
      title: const Text('Animate Slowly'),
      value: timeDilation != 1.0,
      onChanged: (bool value) {
        onTimeDilationChanged(value ? 20.0 : 1.0);
      },
      secondary: const Icon(Icons.hourglass_empty),
      selected: timeDilation != 1.0,
    );

    final Widget overrideDirectionItem = new CheckboxListTile(
      title: const Text('Force RTL'),
      value: overrideDirection == TextDirection.rtl,
      onChanged: (bool value) {
        onOverrideDirectionChanged(value ? TextDirection.rtl : TextDirection.ltr);
      },
      secondary: const Icon(Icons.format_textdirection_r_to_l),
      selected: overrideDirection == TextDirection.rtl,
    );

    final Widget sendFeedbackItem = new ListTile(
      leading: const Icon(Icons.report),
      title: const Text('Send feedback'),
      onTap: onSendFeedback ?? () {
        launch('https://github.com/flutter/flutter/issues/new');
      },
    );

    final Widget aboutItem = new AboutListTile(
      icon: const FlutterLogo(),
      applicationVersion: 'April 2017 Preview',
      applicationIcon: const FlutterLogo(),
      applicationLegalese: '© 2017 The Chromium Authors',
      aboutBoxChildren: <Widget>[
        new Padding(
          padding: const EdgeInsets.only(top: 24.0),
          child: new RichText(
            text: new TextSpan(
              children: <TextSpan>[
                new TextSpan(
                  style: aboutTextStyle,
                  text: 'Flutter is an early-stage, open-source project to help developers'
                        'build high-performance, high-fidelity, mobile apps for '
                        '${defaultTargetPlatform == TargetPlatform.iOS ? 'multiple platforms' : 'iOS and Android'} '
                        'from a single codebase. This gallery is a preview of '
                        "Flutter's many widgets, behaviors, animations, layouts, "
                        'and more. Learn more about Flutter at '
                ),
                new LinkTextSpan(
                  style: linkStyle,
                  url: 'https://flutter.io'
                ),
                new TextSpan(
                  style: aboutTextStyle,
                  text: '.\n\nTo see the source code for this app, please visit the '
                ),
                new LinkTextSpan(
                  style: linkStyle,
                  url: 'https://goo.gl/iv1p4G',
                  text: 'flutter github repo'
                ),
                new TextSpan(
                  style: aboutTextStyle,
                  text: '.'
                )
              ]
            )
          )
        )
      ]
    );

    final List<Widget> allDrawerItems = <Widget>[
      new GalleryDrawerHeader(
        light: galleryTheme.theme.brightness == Brightness.light,
      ),
    ]
    ..addAll(themeItems)
    ..addAll(<Widget>[
      const Divider(),
      mountainViewItem,
      cupertinoItem,
      const Divider(),
    ])
    ..addAll(textSizeItems)
    ..addAll(<Widget>[
      overrideDirectionItem,
      const Divider(),
      animateSlowlyItem,
      const Divider(),
    ]);

    bool addedOptionalItem = false;
    if (onCheckerboardOffscreenLayersChanged != null) {
      allDrawerItems.add(new CheckboxListTile(
        title: const Text('Checkerboard Offscreen Layers'),
        value: checkerboardOffscreenLayers,
        onChanged: onCheckerboardOffscreenLayersChanged,
        secondary: const Icon(Icons.assessment),
        selected: checkerboardOffscreenLayers,
      ));
      addedOptionalItem = true;
    }

    if (onCheckerboardRasterCacheImagesChanged != null) {
      allDrawerItems.add(new CheckboxListTile(
        title: const Text('Checkerboard Raster Cache Images'),
        value: checkerboardRasterCacheImages,
        onChanged: onCheckerboardRasterCacheImagesChanged,
        secondary: const Icon(Icons.assessment),
        selected: checkerboardRasterCacheImages,
      ));
      addedOptionalItem = true;
    }

    if (onShowPerformanceOverlayChanged != null) {
      allDrawerItems.add(new CheckboxListTile(
        title: const Text('Performance Overlay'),
        value: showPerformanceOverlay,
        onChanged: onShowPerformanceOverlayChanged,
        secondary: const Icon(Icons.assessment),
        selected: showPerformanceOverlay,
      ));
      addedOptionalItem = true;
    }

    if (addedOptionalItem)
      allDrawerItems.add(const Divider());

    allDrawerItems.addAll(<Widget>[
      sendFeedbackItem,
      aboutItem,
    ]);

    return new Drawer(child: new ListView(primary: false, children: allDrawerItems));
  }
}
