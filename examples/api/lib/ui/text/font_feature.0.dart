// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// Flutter code sample for [FontFeature].

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  static PageRoute<T> _pageRouteBuilder<T>(
    RouteSettings settings,
    WidgetBuilder builder,
  ) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) => builder(context),
      transitionsBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) => child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      color: const Color(0xFFFFFFFF),
      home: ExampleWidget(),
      pageRouteBuilder: _pageRouteBuilder,
    );
  }
}

const TextStyle titleStyle = TextStyle(
  fontSize: 18,
  fontFeatures: <FontFeature>[FontFeature.enable('smcp')],
  color: Color(0xFF0000FF),
);

class ExampleWidget extends StatelessWidget {
  const ExampleWidget({super.key});

  Widget buildDivider() {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Container(
        color: const Color(0xFF000000),
        height: 4,
        width: double.infinity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The Cardo, Milonga and Raleway Dots fonts can be downloaded from Google
    // Fonts (https://www.google.com/fonts).
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: <Widget>[
            const Spacer(flex: 5),
            Text('regular numbers have their place:', style: titleStyle),
            const Text(
              'The 1972 cup final was a 1-1 draw.',
              style: TextStyle(fontFamily: 'Cardo', fontSize: 24),
            ),
            const Spacer(),
            Text(
              'but old-style figures blend well with lower case:',
              style: titleStyle,
            ),
            const Text(
              'The 1972 cup final was a 1-1 draw.',
              style: TextStyle(
                fontFamily: 'Cardo',
                fontSize: 24,
                fontFeatures: <FontFeature>[FontFeature.oldstyleFigures()],
              ),
            ),
            const Spacer(),
            buildDivider(),
            const Spacer(),
            Text(
              'fractions look better with a custom ligature:',
              style: titleStyle,
            ),
            const Text(
              'Add 1/2 tsp of flour and stir.',
              style: TextStyle(
                fontFamily: 'Milonga',
                fontSize: 24,
                fontFeatures: <FontFeature>[FontFeature.alternativeFractions()],
              ),
            ),
            const Spacer(),
            buildDivider(),
            const Spacer(),
            Text('multiple stylistic sets in one font:', style: titleStyle),
            const Text(
              'Raleway Dots',
              style: TextStyle(fontFamily: 'Raleway Dots', fontSize: 48),
            ),
            Text(
              'Raleway Dots',
              style: TextStyle(
                fontFeatures: <FontFeature>[FontFeature.stylisticSet(1)],
                fontFamily: 'Raleway Dots',
                fontSize: 48,
              ),
            ),
            const Spacer(flex: 5),
          ],
        ),
      ),
    );
  }
}
