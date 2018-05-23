// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  int materialBuilderCalled;
  int cupertinoBuilderCalled;

  final WidgetBuilder materialBuilder = (_) {
    materialBuilderCalled++;
    return new Container();
  };

  final WidgetBuilder cupertinoBuilder = (_) {
    cupertinoBuilderCalled++;
    return new Container();
  };

  setUp(() {
    materialBuilderCalled = 0;
    cupertinoBuilderCalled = 0;
  });

  testWidgets('calls the right builder', (WidgetTester tester) async {
    await tester.pumpWidget(
      new PlatformBuilder(
        materialWidgetBuilder: materialBuilder,
        cupertinoWidgetBuilder: cupertinoBuilder,
      ),
    );

    expect(materialBuilderCalled, 1);

    await tester.pumpWidget(
      new Theme(
        data: new ThemeData(
          platform: TargetPlatform.iOS,
        ),
        child: new PlatformBuilder(
          materialWidgetBuilder: materialBuilder,
          cupertinoWidgetBuilder: cupertinoBuilder,
        ),
      )
    );

    expect(materialBuilderCalled, 1);
    expect(cupertinoBuilderCalled, 1);
  });

  testWidgets('do not adapt when themeAdaptiveType is used without Theme', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Theme(
        data: new ThemeData(
          platform: TargetPlatform.iOS,
        ),
        child: new PlatformBuilder(
          materialWidgetBuilder: materialBuilder,
          cupertinoWidgetBuilder: cupertinoBuilder,
          themeAdaptiveType: A,
        ),
      )
    );

    expect(materialBuilderCalled, 1);
  });

  testWidgets('do not adapt when AdaptiveWidgetThemeData.none is inherited', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Theme(
        data: new ThemeData(
          adaptiveWidgetTheme: AdaptiveWidgetThemeData.none,
          platform: TargetPlatform.iOS,
        ),
        child: new PlatformBuilder(
          materialWidgetBuilder: materialBuilder,
          cupertinoWidgetBuilder: cupertinoBuilder,
          themeAdaptiveType: A,
        ),
      )
    );

    expect(materialBuilderCalled, 1);
  });

  testWidgets('adapt for supported Material widgets when AdaptiveWidgetThemeData.bundled', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Theme(
        data: new ThemeData(
          adaptiveWidgetTheme: AdaptiveWidgetThemeData.bundled,
          platform: TargetPlatform.iOS,
        ),
        child: new PlatformBuilder(
          materialWidgetBuilder: materialBuilder,
          cupertinoWidgetBuilder: cupertinoBuilder,
          // Switch is a supported widget type.
          themeAdaptiveType: Switch,
        ),
      )
    );

    expect(cupertinoBuilderCalled, 1);

    await tester.pumpWidget(
      new Theme(
        data: new ThemeData(
          adaptiveWidgetTheme: AdaptiveWidgetThemeData.bundled,
          platform: TargetPlatform.iOS,
        ),
        child: new PlatformBuilder(
          materialWidgetBuilder: materialBuilder,
          cupertinoWidgetBuilder: cupertinoBuilder,
          // A is a random unsupported type.
          themeAdaptiveType: A,
        ),
      )
    );

    expect(materialBuilderCalled, 1);
    expect(cupertinoBuilderCalled, 1);
  });

  testWidgets('adapt for anything when AdaptiveWidgetThemeData.all', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Theme(
        data: new ThemeData(
          adaptiveWidgetTheme: AdaptiveWidgetThemeData.all,
          platform: TargetPlatform.iOS,
        ),
        child: new PlatformBuilder(
          materialWidgetBuilder: materialBuilder,
          cupertinoWidgetBuilder: cupertinoBuilder,
          themeAdaptiveType: A,
        ),
      )
    );

    expect(cupertinoBuilderCalled, 1);

    await tester.pumpWidget(
      new Theme(
        data: new ThemeData(
          adaptiveWidgetTheme: AdaptiveWidgetThemeData.all,
          platform: TargetPlatform.iOS,
        ),
        child: new PlatformBuilder(
          materialWidgetBuilder: materialBuilder,
          cupertinoWidgetBuilder: cupertinoBuilder,
          themeAdaptiveType: B,
        ),
      )
    );

    expect(cupertinoBuilderCalled, 2);
  });

  testWidgets('themeAdaptiveType can override Theme', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Theme(
        data: new ThemeData(
          adaptiveWidgetTheme: AdaptiveWidgetThemeData.none,
          platform: TargetPlatform.iOS,
        ),
        child: new PlatformBuilder(
          materialWidgetBuilder: materialBuilder,
          cupertinoWidgetBuilder: cupertinoBuilder,
          // No themeAdaptiveType specified which means always adapt.
        ),
      )
    );

    expect(cupertinoBuilderCalled, 1);
  });

  testWidgets('Theme subtree can individually override', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Theme(
        data: new ThemeData(
          adaptiveWidgetTheme: const AdaptiveWidgetThemeData(const <Type, bool> {
            A: true,
            B: true,
          }),
          platform: TargetPlatform.iOS,
        ),
        child: Column(
          children: <Widget>[
            new PlatformBuilder(
              materialWidgetBuilder: materialBuilder,
              cupertinoWidgetBuilder: cupertinoBuilder,
              themeAdaptiveType: A,
            ),
            new PlatformBuilder(
              materialWidgetBuilder: materialBuilder,
              cupertinoWidgetBuilder: cupertinoBuilder,
              themeAdaptiveType: B,
            ),
            new Builder(
              builder: (BuildContext context) {
                return new Theme(
                  data: Theme.of(context).copyWith(
                    adaptiveWidgetTheme: Theme.of(context).adaptiveWidgetTheme.merge(
                      const AdaptiveWidgetThemeData(const <Type, bool> {
                        B: false,
                      }),
                    ),
                  ),
                  child: Column(
                    children: <Widget>[
                      new PlatformBuilder(
                        materialWidgetBuilder: materialBuilder,
                        cupertinoWidgetBuilder: cupertinoBuilder,
                        themeAdaptiveType: A,
                      ),
                      new PlatformBuilder(
                        materialWidgetBuilder: materialBuilder,
                        cupertinoWidgetBuilder: cupertinoBuilder,
                        themeAdaptiveType: B,
                      ),
                    ],
                  ),
                );
              }
            )
          ],
        ),
      )
    );

    expect(materialBuilderCalled, 1);
    expect(cupertinoBuilderCalled, 3);
  });
}

class A {}
class B {}