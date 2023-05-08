// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])
library;

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

void main() {
  testWidgets('Navigation bar updates destinations when tapped', (WidgetTester tester) async {
    int mutatedIndex = -1;
    final Widget widget = _buildWidget(
      NavigationBar(
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.ac_unit),
            label: 'AC',
          ),
          NavigationDestination(
            icon: Icon(Icons.access_alarm),
            label: 'Alarm',
          ),
        ],
        onDestinationSelected: (int i) {
          mutatedIndex = i;
        },
      ),
    );

    await tester.pumpWidget(widget);

    expect(find.text('AC'), findsOneWidget);
    expect(find.text('Alarm'), findsOneWidget);

    await tester.tap(find.text('Alarm'));
    expect(mutatedIndex, 1);

    await tester.tap(find.text('AC'));
    expect(mutatedIndex, 0);
  });

  testWidgets('NavigationBar can update background color', (WidgetTester tester) async {
    const Color color = Colors.yellow;

    await tester.pumpWidget(
      _buildWidget(
        NavigationBar(
          backgroundColor: color,
          destinations: const <Widget>[
            NavigationDestination(
              icon: Icon(Icons.ac_unit),
              label: 'AC',
            ),
            NavigationDestination(
              icon: Icon(Icons.access_alarm),
              label: 'Alarm',
            ),
          ],
          onDestinationSelected: (int i) {},
        ),
      ),
    );

    expect(_getMaterial(tester).color, equals(color));
  });

  testWidgets('NavigationBar can update elevation', (WidgetTester tester) async {
    const double elevation = 42.0;

    await tester.pumpWidget(
      _buildWidget(
        NavigationBar(
          elevation: elevation,
          destinations: const <Widget>[
            NavigationDestination(
              icon: Icon(Icons.ac_unit),
              label: 'AC',
            ),
            NavigationDestination(
              icon: Icon(Icons.access_alarm),
              label: 'Alarm',
            ),
          ],
          onDestinationSelected: (int i) {},
        ),
      ),
    );

    expect(_getMaterial(tester).elevation, equals(elevation));
  });

  testWidgets('NavigationBar adds bottom padding to height', (WidgetTester tester) async {
    const double bottomPadding = 40.0;

    await tester.pumpWidget(
      _buildWidget(
        NavigationBar(
          destinations: const <Widget>[
            NavigationDestination(
              icon: Icon(Icons.ac_unit),
              label: 'AC',
            ),
            NavigationDestination(
              icon: Icon(Icons.access_alarm),
              label: 'Alarm',
            ),
          ],
          onDestinationSelected: (int i) {},
        ),
      ),
    );

    final double defaultSize = tester.getSize(find.byType(NavigationBar)).height;
    expect(defaultSize, 80);

    await tester.pumpWidget(
      _buildWidget(
        MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.only(bottom: bottomPadding)),
          child: NavigationBar(
            destinations: const <Widget>[
              NavigationDestination(
                icon: Icon(Icons.ac_unit),
                label: 'AC',
              ),
              NavigationDestination(
                icon: Icon(Icons.access_alarm),
                label: 'Alarm',
              ),
            ],
            onDestinationSelected: (int i) {},
          ),
        ),
      ),
    );

    final double expectedHeight = defaultSize + bottomPadding;
    expect(tester.getSize(find.byType(NavigationBar)).height, expectedHeight);
  });

  testWidgets('NavigationBar respects the notch/system navigation bar in landscape mode', (WidgetTester tester) async {
    const double safeAreaPadding = 40.0;
    Widget navigationBar() {
      return NavigationBar(
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.ac_unit),
            label: 'AC',
          ),
          NavigationDestination(
            key: Key('Center'),
            icon: Icon(Icons.center_focus_strong),
            label: 'Center',
          ),
          NavigationDestination(
            icon: Icon(Icons.access_alarm),
            label: 'Alarm',
          ),
        ],
        onDestinationSelected: (int i) {},
      );
    }

    await tester.pumpWidget(_buildWidget(navigationBar()));
    final double defaultWidth = tester.getSize(find.byType(NavigationBar)).width;
    final Finder defaultCenterItem = find.byKey(const Key('Center'));
    final Offset center = tester.getCenter(defaultCenterItem);
    expect(center.dx, defaultWidth / 2);

    await tester.pumpWidget(
      _buildWidget(
        MediaQuery(
          data: const MediaQueryData(
            padding: EdgeInsets.only(left: safeAreaPadding),
          ),
          child: navigationBar(),
        ),
      ),
    );

    // The position of center item of navigation bar should indicate whether
    // the safe area is sufficiently respected, when safe area is on the left side.
    // e.g. Android device with system navigation bar in landscape mode.
    final Finder leftPaddedCenterItem = find.byKey(const Key('Center'));
    final Offset leftPaddedCenter = tester.getCenter(leftPaddedCenterItem);
    expect(
      leftPaddedCenter.dx,
      closeTo((defaultWidth + safeAreaPadding) / 2.0, precisionErrorTolerance),
    );

    await tester.pumpWidget(
      _buildWidget(
        MediaQuery(
          data: const MediaQueryData(
              padding: EdgeInsets.only(right: safeAreaPadding)
          ),
          child: navigationBar(),
        ),
      ),
    );

    // The position of center item of navigation bar should indicate whether
    // the safe area is sufficiently respected, when safe area is on the right side.
    // e.g. Android device with system navigation bar in landscape mode.
    final Finder rightPaddedCenterItem = find.byKey(const Key('Center'));
    final Offset rightPaddedCenter = tester.getCenter(rightPaddedCenterItem);
    expect(
      rightPaddedCenter.dx,
      closeTo((defaultWidth - safeAreaPadding) / 2, precisionErrorTolerance),
    );

    await tester.pumpWidget(
      _buildWidget(
        MediaQuery(
          data: const MediaQueryData(
            padding: EdgeInsets.fromLTRB(
                safeAreaPadding,
                0,
                safeAreaPadding,
                safeAreaPadding
            ),
          ),
          child: navigationBar(),
        ),
      ),
    );

    // The position of center item of navigation bar should indicate whether
    // the safe area is sufficiently respected, when safe areas are on both sides.
    // e.g. iOS device with both sides of round corner.
    final Finder paddedCenterItem = find.byKey(const Key('Center'));
    final Offset paddedCenter = tester.getCenter(paddedCenterItem);
    expect(
      paddedCenter.dx,
      closeTo(defaultWidth / 2, precisionErrorTolerance),
    );
  });

  testWidgets('NavigationBar uses proper defaults when no parameters are given', (WidgetTester tester) async {
    // Pre-M3 settings that were hand coded.
    await tester.pumpWidget(
      _buildWidget(
        NavigationBar(
          destinations: const <Widget>[
            NavigationDestination(
              icon: Icon(Icons.ac_unit),
              label: 'AC',
            ),
            NavigationDestination(
              icon: Icon(Icons.access_alarm),
              label: 'Alarm',
            ),
          ],
          onDestinationSelected: (int i) {},
        ),
      ),
    );

    expect(_getMaterial(tester).color, const Color(0xffeaeaea));
    expect(_getMaterial(tester).surfaceTintColor, null);
    expect(_getMaterial(tester).elevation, 0);
    expect(tester.getSize(find.byType(NavigationBar)).height, 80);
    expect(_getIndicatorDecoration(tester)?.color, const Color(0x3d2196f3));
    expect(_getIndicatorDecoration(tester)?.shape, RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)));

    // M3 settings from the token database.
    await tester.pumpWidget(
      _buildWidget(
        Theme(
          data: ThemeData.light().copyWith(useMaterial3: true),
          child: NavigationBar(
            destinations: const <Widget>[
              NavigationDestination(
                icon: Icon(Icons.ac_unit),
                label: 'AC',
              ),
              NavigationDestination(
                icon: Icon(Icons.access_alarm),
                label: 'Alarm',
              ),
            ],
            onDestinationSelected: (int i) {},
          ),
        ),
      ),
    );

    expect(_getMaterial(tester).color, ThemeData().colorScheme.surface);
    expect(_getMaterial(tester).surfaceTintColor, ThemeData().colorScheme.surfaceTint);
    expect(_getMaterial(tester).elevation, 3);
    expect(tester.getSize(find.byType(NavigationBar)).height, 80);
    expect(_getIndicatorDecoration(tester)?.color, const Color(0xff2196f3));
    expect(_getIndicatorDecoration(tester)?.shape, const StadiumBorder());
  });

  testWidgets('NavigationBar shows tooltips with text scaling ', (WidgetTester tester) async {
    const String label = 'A';

    Widget buildApp({ required double textScaleFactor }) {
      return MediaQuery(
        data: MediaQueryData(textScaleFactor: textScaleFactor),
        child: Localizations(
          locale: const Locale('en', 'US'),
          delegates: const <LocalizationsDelegate<dynamic>>[
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Navigator(
              onGenerateRoute: (RouteSettings settings) {
                return MaterialPageRoute<void>(
                  builder: (BuildContext context) {
                    return Scaffold(
                      bottomNavigationBar: NavigationBar(
                        destinations: const <NavigationDestination>[
                          NavigationDestination(
                            label: label,
                            icon: Icon(Icons.ac_unit),
                            tooltip: label,
                          ),
                          NavigationDestination(
                            label: 'B',
                            icon: Icon(Icons.battery_alert),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildApp(textScaleFactor: 1.0));
    expect(find.text(label), findsOneWidget);
    await tester.longPress(find.text(label));
    expect(find.text(label), findsNWidgets(2));

    // The default size of a tooltip with the text A.
    const Size defaultTooltipSize = Size(14.0, 14.0);
    expect(tester.getSize(find.text(label).last), defaultTooltipSize);
    // The duration is needed to ensure the tooltip disappears.
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.pumpWidget(buildApp(textScaleFactor: 4.0));
    expect(find.text(label), findsOneWidget);
    await tester.longPress(find.text(label));
    expect(tester.getSize(find.text(label).last), Size(defaultTooltipSize.width * 4, defaultTooltipSize.height * 4));
  });

  testWidgets('Custom tooltips in NavigationBarDestination', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: NavigationBar(
            destinations: const <NavigationDestination>[
              NavigationDestination(
                label: 'A',
                tooltip: 'A tooltip',
                icon: Icon(Icons.ac_unit),
              ),
              NavigationDestination(
                label: 'B',
                icon: Icon(Icons.battery_alert),
              ),
              NavigationDestination(
                label: 'C',
                icon: Icon(Icons.cake),
                tooltip: '',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('A'), findsOneWidget);
    await tester.longPress(find.text('A'));
    expect(find.byTooltip('A tooltip'), findsOneWidget);

    expect(find.text('B'), findsOneWidget);
    await tester.longPress(find.text('B'));
    expect(find.byTooltip('B'), findsOneWidget);

    expect(find.text('C'), findsOneWidget);
    await tester.longPress(find.text('C'));
    expect(find.byTooltip('C'), findsNothing);
  });


  testWidgets('Navigation bar semantics', (WidgetTester tester) async {
    Widget widget({int selectedIndex = 0}) {
      return _buildWidget(
        NavigationBar(
          selectedIndex: selectedIndex,
          destinations: const <Widget>[
            NavigationDestination(
              icon: Icon(Icons.ac_unit),
              label: 'AC',
            ),
            NavigationDestination(
              icon: Icon(Icons.access_alarm),
              label: 'Alarm',
            ),
          ],
        ),
      );
    }

    await tester.pumpWidget(widget());

    expect(
      tester.getSemantics(find.text('AC')),
      matchesSemantics(
        label: 'AC\nTab 1 of 2',
        textDirection: TextDirection.ltr,
        isFocusable: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('Alarm')),
      matchesSemantics(
        label: 'Alarm\nTab 2 of 2',
        textDirection: TextDirection.ltr,
        isFocusable: true,
        hasTapAction: true,
      ),
    );

    await tester.pumpWidget(widget(selectedIndex: 1));

    expect(
      tester.getSemantics(find.text('AC')),
      matchesSemantics(
        label: 'AC\nTab 1 of 2',
        textDirection: TextDirection.ltr,
        isFocusable: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('Alarm')),
      matchesSemantics(
        label: 'Alarm\nTab 2 of 2',
        textDirection: TextDirection.ltr,
        isFocusable: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
  });

  testWidgets('Navigation bar semantics with some labels hidden', (WidgetTester tester) async {
    Widget widget({int selectedIndex = 0}) {
      return _buildWidget(
        NavigationBar(
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          selectedIndex: selectedIndex,
          destinations: const <Widget>[
            NavigationDestination(
              icon: Icon(Icons.ac_unit),
              label: 'AC',
            ),
            NavigationDestination(
              icon: Icon(Icons.access_alarm),
              label: 'Alarm',
            ),
          ],
        ),
      );
    }

    await tester.pumpWidget(widget());

    expect(
      tester.getSemantics(find.text('AC')),
      matchesSemantics(
        label: 'AC\nTab 1 of 2',
        textDirection: TextDirection.ltr,
        isFocusable: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('Alarm')),
      matchesSemantics(
        label: 'Alarm\nTab 2 of 2',
        textDirection: TextDirection.ltr,
        isFocusable: true,
        hasTapAction: true,
      ),
    );

    await tester.pumpWidget(widget(selectedIndex: 1));

    expect(
      tester.getSemantics(find.text('AC')),
      matchesSemantics(
        label: 'AC\nTab 1 of 2',
        textDirection: TextDirection.ltr,
        isFocusable: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('Alarm')),
      matchesSemantics(
        label: 'Alarm\nTab 2 of 2',
        textDirection: TextDirection.ltr,
        isFocusable: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
  });

  testWidgets('Navigation bar does not grow with text scale factor', (WidgetTester tester) async {
    const int animationMilliseconds = 800;

    Widget widget({double textScaleFactor = 1}) {
      return _buildWidget(
        MediaQuery(
          data: MediaQueryData(textScaleFactor: textScaleFactor),
          child: NavigationBar(
            animationDuration: const Duration(milliseconds: animationMilliseconds),
            destinations: const <NavigationDestination>[
              NavigationDestination(
                icon: Icon(Icons.ac_unit),
                label: 'AC',
              ),
              NavigationDestination(
                icon: Icon(Icons.access_alarm),
                label: 'Alarm',
              ),
            ],
          ),
        ),
      );
    }

    await tester.pumpWidget(widget());
    final double initialHeight = tester.getSize(find.byType(NavigationBar)).height;

    await tester.pumpWidget(widget(textScaleFactor: 2));
    final double newHeight = tester.getSize(find.byType(NavigationBar)).height;

    expect(newHeight, equals(initialHeight));
  });

  testWidgets('Navigation indicator renders ripple', (WidgetTester tester) async {
    // This is a regression test for https://github.com/flutter/flutter/issues/116751.
    int selectedIndex = 0;

    Widget buildWidget({ NavigationDestinationLabelBehavior? labelBehavior }) {
      return MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          bottomNavigationBar: Center(
            child: NavigationBar(
              selectedIndex: selectedIndex,
              labelBehavior: labelBehavior,
              destinations: const <Widget>[
                NavigationDestination(
                  icon: Icon(Icons.ac_unit),
                  label: 'AC',
                ),
                NavigationDestination(
                  icon: Icon(Icons.access_alarm),
                  label: 'Alarm',
                ),
              ],
              onDestinationSelected: (int i) { },
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildWidget());

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.moveTo(tester.getCenter(find.byIcon(Icons.access_alarm)));
    await tester.pumpAndSettle();

    final RenderObject inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) => object.runtimeType.toString() == '_RenderInkFeatures');
    Offset indicatorCenter = const Offset(600, 30);
    const Size includedIndicatorSize = Size(64, 32);
    const Size excludedIndicatorSize = Size(74, 40);

    // Test ripple when NavigationBar is using `NavigationDestinationLabelBehavior.alwaysShow` (default).
    expect(
      inkFeatures,
      paints
        ..clipPath(
          pathMatcher: isPathThat(
            includes: <Offset>[
              // Left center.
              Offset(indicatorCenter.dx - (includedIndicatorSize.width / 2), indicatorCenter.dy),
              // Top center.
              Offset(indicatorCenter.dx, indicatorCenter.dy - (includedIndicatorSize.height / 2)),
              // Right center.
              Offset(indicatorCenter.dx + (includedIndicatorSize.width / 2), indicatorCenter.dy),
              // Bottom center.
              Offset(indicatorCenter.dx, indicatorCenter.dy + (includedIndicatorSize.height / 2)),
            ],
            excludes: <Offset>[
              // Left center.
              Offset(indicatorCenter.dx - (excludedIndicatorSize.width / 2), indicatorCenter.dy),
              // Top center.
              Offset(indicatorCenter.dx, indicatorCenter.dy - (excludedIndicatorSize.height / 2)),
              // Right center.
              Offset(indicatorCenter.dx + (excludedIndicatorSize.width / 2), indicatorCenter.dy),
              // Bottom center.
              Offset(indicatorCenter.dx, indicatorCenter.dy + (excludedIndicatorSize.height / 2)),
            ],
          ),
        )
        ..circle(
          x: indicatorCenter.dx,
          y: indicatorCenter.dy,
          radius: 35.0,
          color: const Color(0x0a000000),
        )
    );

    // Test ripple when NavigationBar is using `NavigationDestinationLabelBehavior.alwaysHide`.
    await tester.pumpWidget(buildWidget(labelBehavior: NavigationDestinationLabelBehavior.alwaysHide));
    await gesture.moveTo(tester.getCenter(find.byIcon(Icons.access_alarm)));
    await tester.pumpAndSettle();

    indicatorCenter = const Offset(600, 40);

    expect(
      inkFeatures,
      paints
        ..clipPath(
          pathMatcher: isPathThat(
            includes: <Offset>[
              // Left center.
              Offset(indicatorCenter.dx - (includedIndicatorSize.width / 2), indicatorCenter.dy),
              // Top center.
              Offset(indicatorCenter.dx, indicatorCenter.dy - (includedIndicatorSize.height / 2)),
              // Right center.
              Offset(indicatorCenter.dx + (includedIndicatorSize.width / 2), indicatorCenter.dy),
              // Bottom center.
              Offset(indicatorCenter.dx, indicatorCenter.dy + (includedIndicatorSize.height / 2)),
            ],
            excludes: <Offset>[
              // Left center.
              Offset(indicatorCenter.dx - (excludedIndicatorSize.width / 2), indicatorCenter.dy),
              // Top center.
              Offset(indicatorCenter.dx, indicatorCenter.dy - (excludedIndicatorSize.height / 2)),
              // Right center.
              Offset(indicatorCenter.dx + (excludedIndicatorSize.width / 2), indicatorCenter.dy),
              // Bottom center.
              Offset(indicatorCenter.dx, indicatorCenter.dy + (excludedIndicatorSize.height / 2)),
            ],
          ),
        )
        ..circle(
          x: indicatorCenter.dx,
          y: indicatorCenter.dy,
          radius: 35.0,
          color: const Color(0x0a000000),
        )
    );

    // Test ripple when NavigationBar is using `NavigationDestinationLabelBehavior.onlyShowSelected`.
    await tester.pumpWidget(buildWidget(labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected));
    await gesture.moveTo(tester.getCenter(find.byIcon(Icons.access_alarm)));
    await tester.pumpAndSettle();

    expect(
      inkFeatures,
      paints
        ..clipPath(
          pathMatcher: isPathThat(
            includes: <Offset>[
              // Left center.
              Offset(indicatorCenter.dx - (includedIndicatorSize.width / 2), indicatorCenter.dy),
              // Top center.
              Offset(indicatorCenter.dx, indicatorCenter.dy - (includedIndicatorSize.height / 2)),
              // Right center.
              Offset(indicatorCenter.dx + (includedIndicatorSize.width / 2), indicatorCenter.dy),
              // Bottom center.
              Offset(indicatorCenter.dx, indicatorCenter.dy + (includedIndicatorSize.height / 2)),
            ],
            excludes: <Offset>[
              // Left center.
              Offset(indicatorCenter.dx - (excludedIndicatorSize.width / 2), indicatorCenter.dy),
              // Top center.
              Offset(indicatorCenter.dx, indicatorCenter.dy - (excludedIndicatorSize.height / 2)),
              // Right center.
              Offset(indicatorCenter.dx + (excludedIndicatorSize.width / 2), indicatorCenter.dy),
              // Bottom center.
              Offset(indicatorCenter.dx, indicatorCenter.dy + (excludedIndicatorSize.height / 2)),
            ],
          ),
        )
        ..circle(
          x: indicatorCenter.dx,
          y: indicatorCenter.dy,
          radius: 35.0,
          color: const Color(0x0a000000),
        )
    );

    // Make sure ripple is shifted when selectedIndex changes.
    selectedIndex = 1;
    await tester.pumpWidget(buildWidget(labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected));
    await tester.pumpAndSettle();
    indicatorCenter = const Offset(600, 30);

    expect(
      inkFeatures,
      paints
        ..clipPath(
          pathMatcher: isPathThat(
            includes: <Offset>[
              // Left center.
              Offset(indicatorCenter.dx - (includedIndicatorSize.width / 2), indicatorCenter.dy),
              // Top center.
              Offset(indicatorCenter.dx, indicatorCenter.dy - (includedIndicatorSize.height / 2)),
              // Right center.
              Offset(indicatorCenter.dx + (includedIndicatorSize.width / 2), indicatorCenter.dy),
              // Bottom center.
              Offset(indicatorCenter.dx, indicatorCenter.dy + (includedIndicatorSize.height / 2)),
            ],
            excludes: <Offset>[
              // Left center.
              Offset(indicatorCenter.dx - (excludedIndicatorSize.width / 2), indicatorCenter.dy),
              // Top center.
              Offset(indicatorCenter.dx, indicatorCenter.dy - (excludedIndicatorSize.height / 2)),
              // Right center.
              Offset(indicatorCenter.dx + (excludedIndicatorSize.width / 2), indicatorCenter.dy),
              // Bottom center.
              Offset(indicatorCenter.dx, indicatorCenter.dy + (excludedIndicatorSize.height / 2)),
            ],
          ),
        )
        ..circle(
          x: indicatorCenter.dx,
          y: indicatorCenter.dy,
          radius: 35.0,
          color: const Color(0x0a000000),
        )
    );
  });

  testWidgets('Navigation indicator ripple golden test', (WidgetTester tester) async {
    // This is a regression test for https://github.com/flutter/flutter/issues/117420.

    Widget buildWidget({ NavigationDestinationLabelBehavior? labelBehavior }) {
      return MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          bottomNavigationBar: Center(
            child: NavigationBar(
              labelBehavior: labelBehavior,
              destinations: const <Widget>[
                NavigationDestination(
                  icon: SizedBox(),
                  label: 'AC',
                ),
                NavigationDestination(
                  icon: SizedBox(),
                  label: 'Alarm',
                ),
              ],
              onDestinationSelected: (int i) { },
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildWidget());

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.moveTo(tester.getCenter(find.byType(NavigationDestination).last));
    await tester.pumpAndSettle();

    // Test ripple when NavigationBar is using `NavigationDestinationLabelBehavior.alwaysShow` (default).
    await expectLater(find.byType(NavigationBar), matchesGoldenFile('indicator_alwaysShow_m3.png'));

    // Test ripple when NavigationBar is using `NavigationDestinationLabelBehavior.alwaysHide`.
    await tester.pumpWidget(buildWidget(labelBehavior: NavigationDestinationLabelBehavior.alwaysHide));
    await gesture.moveTo(tester.getCenter(find.byType(NavigationDestination).last));
    await tester.pumpAndSettle();

    await expectLater(find.byType(NavigationBar), matchesGoldenFile('indicator_alwaysHide_m3.png'));

    // Test ripple when NavigationBar is using `NavigationDestinationLabelBehavior.onlyShowSelected`.
    await tester.pumpWidget(buildWidget(labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected));
    await gesture.moveTo(tester.getCenter(find.byType(NavigationDestination).first));
    await tester.pumpAndSettle();

    await expectLater(find.byType(NavigationBar), matchesGoldenFile('indicator_onlyShowSelected_selected_m3.png'));

    await gesture.moveTo(tester.getCenter(find.byType(NavigationDestination).last));
    await tester.pumpAndSettle();

    await expectLater(find.byType(NavigationBar), matchesGoldenFile('indicator_onlyShowSelected_unselected_m3.png'));
  });

  testWidgets('Navigation indicator scale transform', (WidgetTester tester) async {
    int selectedIndex = 0;

    Widget buildNavigationBar() {
      return MaterialApp(
        theme: ThemeData.light(),
        home: Scaffold(
          bottomNavigationBar: Center(
            child: NavigationBar(
              selectedIndex: selectedIndex,
              destinations: const <Widget>[
                NavigationDestination(
                  icon: Icon(Icons.ac_unit),
                  label: 'AC',
                ),
                NavigationDestination(
                  icon: Icon(Icons.access_alarm),
                  label: 'Alarm',
                ),
              ],
              onDestinationSelected: (int i) { },
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildNavigationBar());
    await tester.pumpAndSettle();
    final Finder transformFinder = find.descendant(
      of: find.byType(NavigationIndicator),
      matching: find.byType(Transform),
    ).last;
    Matrix4 transform = tester.widget<Transform>(transformFinder).transform;
    expect(transform.getColumn(0)[0], 0.0);

    selectedIndex = 1;
    await tester.pumpWidget(buildNavigationBar());
    await tester.pump(const Duration(milliseconds: 100));
    transform = tester.widget<Transform>(transformFinder).transform;
    expect(transform.getColumn(0)[0], closeTo(0.7805849514007568, precisionErrorTolerance));

    await tester.pump(const Duration(milliseconds: 100));
    transform = tester.widget<Transform>(transformFinder).transform;
    expect(transform.getColumn(0)[0], closeTo(0.9473570239543915, precisionErrorTolerance));

    await tester.pumpAndSettle();
    transform = tester.widget<Transform>(transformFinder).transform;
    expect(transform.getColumn(0)[0], 1.0);
  });

  testWidgets('Navigation destination updates indicator color and shape', (WidgetTester tester) async {
    final ThemeData theme = ThemeData(useMaterial3: true);
    const Color color = Color(0xff0000ff);
    const ShapeBorder shape = RoundedRectangleBorder();

    Widget buildNavigationBar({Color? indicatorColor, ShapeBorder? indicatorShape}) {
      return MaterialApp(
        theme: theme,
        home: Scaffold(
          bottomNavigationBar: NavigationBar(
            indicatorColor: indicatorColor,
            indicatorShape: indicatorShape,
            destinations: const <Widget>[
              NavigationDestination(
                icon: Icon(Icons.ac_unit),
                label: 'AC',
              ),
              NavigationDestination(
                icon: Icon(Icons.access_alarm),
                label: 'Alarm',
              ),
            ],
            onDestinationSelected: (int i) { },
          ),
        ),
      );
    }

    await tester.pumpWidget(buildNavigationBar());

    // Test default indicator color and shape.
    expect(_getIndicatorDecoration(tester)?.color, theme.colorScheme.secondaryContainer);
    expect(_getIndicatorDecoration(tester)?.shape, const StadiumBorder());

    await tester.pumpWidget(buildNavigationBar(indicatorColor: color, indicatorShape: shape));

    // Test custom indicator color and shape.
    expect(_getIndicatorDecoration(tester)?.color, color);
    expect(_getIndicatorDecoration(tester)?.shape, shape);
  });

  group('Material 2', () {
    // Tests that are only relevant for Material 2. Once ThemeData.useMaterial3
    // is turned on by default, these tests can be removed.

    testWidgets('Navigation destination updates indicator color and shape', (WidgetTester tester) async {
      final ThemeData theme = ThemeData(useMaterial3: false);
      const Color color = Color(0xff0000ff);
      const ShapeBorder shape = RoundedRectangleBorder();

      Widget buildNavigationBar({Color? indicatorColor, ShapeBorder? indicatorShape}) {
        return MaterialApp(
          theme: theme,
          home: Scaffold(
            bottomNavigationBar: NavigationBar(
              indicatorColor: indicatorColor,
              indicatorShape: indicatorShape,
              destinations: const <Widget>[
                NavigationDestination(
                  icon: Icon(Icons.ac_unit),
                  label: 'AC',
                ),
                NavigationDestination(
                  icon: Icon(Icons.access_alarm),
                  label: 'Alarm',
                ),
              ],
              onDestinationSelected: (int i) { },
            ),
          ),
        );
      }

      await tester.pumpWidget(buildNavigationBar());

      // Test default indicator color and shape.
      expect(_getIndicatorDecoration(tester)?.color, theme.colorScheme.secondary.withOpacity(0.24));
      expect(
        _getIndicatorDecoration(tester)?.shape,
        const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      );

      await tester.pumpWidget(buildNavigationBar(indicatorColor: color, indicatorShape: shape));

      // Test custom indicator color and shape.
      expect(_getIndicatorDecoration(tester)?.color, color);
      expect(_getIndicatorDecoration(tester)?.shape, shape);
    });

    testWidgets('Navigation indicator renders ripple', (WidgetTester tester) async {
      // This is a regression test for https://github.com/flutter/flutter/issues/116751.
      int selectedIndex = 0;

      Widget buildWidget({ NavigationDestinationLabelBehavior? labelBehavior }) {
        return MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: Scaffold(
            bottomNavigationBar: Center(
              child: NavigationBar(
              selectedIndex: selectedIndex,
              labelBehavior: labelBehavior,
              destinations: const <Widget>[
                NavigationDestination(
                  icon: Icon(Icons.ac_unit),
                  label: 'AC',
                ),
                NavigationDestination(
                  icon: Icon(Icons.access_alarm),
                  label: 'Alarm',
                ),
              ],
              onDestinationSelected: (int i) { },
            ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildWidget());

      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer();
      await gesture.moveTo(tester.getCenter(find.byIcon(Icons.access_alarm)));
      await tester.pumpAndSettle();

      final RenderObject inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) => object.runtimeType.toString() == '_RenderInkFeatures');
      Offset indicatorCenter = const Offset(600, 33);
      const Size includedIndicatorSize = Size(64, 32);
      const Size excludedIndicatorSize = Size(74, 40);

      // Test ripple when NavigationBar is using `NavigationDestinationLabelBehavior.alwaysShow` (default).
      expect(
        inkFeatures,
        paints
          ..clipPath(
            pathMatcher: isPathThat(
              includes: <Offset>[
                // Left center.
                Offset(indicatorCenter.dx - (includedIndicatorSize.width / 2), indicatorCenter.dy),
                // Top center.
                Offset(indicatorCenter.dx, indicatorCenter.dy - (includedIndicatorSize.height / 2)),
                // Right center.
                Offset(indicatorCenter.dx + (includedIndicatorSize.width / 2), indicatorCenter.dy),
                // Bottom center.
                Offset(indicatorCenter.dx, indicatorCenter.dy + (includedIndicatorSize.height / 2)),
              ],
              excludes: <Offset>[
                // Left center.
                Offset(indicatorCenter.dx - (excludedIndicatorSize.width / 2), indicatorCenter.dy),
                // Top center.
                Offset(indicatorCenter.dx, indicatorCenter.dy - (excludedIndicatorSize.height / 2)),
                // Right center.
                Offset(indicatorCenter.dx + (excludedIndicatorSize.width / 2), indicatorCenter.dy),
                // Bottom center.
                Offset(indicatorCenter.dx, indicatorCenter.dy + (excludedIndicatorSize.height / 2)),
              ],
            ),
          )
          ..circle(
            x: indicatorCenter.dx,
            y: indicatorCenter.dy,
            radius: 35.0,
            color: const Color(0x0a000000),
          )
      );

      // Test ripple when NavigationBar is using `NavigationDestinationLabelBehavior.alwaysHide`.
      await tester.pumpWidget(buildWidget(labelBehavior: NavigationDestinationLabelBehavior.alwaysHide));
      await gesture.moveTo(tester.getCenter(find.byIcon(Icons.access_alarm)));
      await tester.pumpAndSettle();

      indicatorCenter = const Offset(600, 40);

      expect(
        inkFeatures,
        paints
          ..clipPath(
            pathMatcher: isPathThat(
              includes: <Offset>[
                // Left center.
                Offset(indicatorCenter.dx - (includedIndicatorSize.width / 2), indicatorCenter.dy),
                // Top center.
                Offset(indicatorCenter.dx, indicatorCenter.dy - (includedIndicatorSize.height / 2)),
                // Right center.
                Offset(indicatorCenter.dx + (includedIndicatorSize.width / 2), indicatorCenter.dy),
                // Bottom center.
                Offset(indicatorCenter.dx, indicatorCenter.dy + (includedIndicatorSize.height / 2)),
              ],
              excludes: <Offset>[
                // Left center.
                Offset(indicatorCenter.dx - (excludedIndicatorSize.width / 2), indicatorCenter.dy),
                // Top center.
                Offset(indicatorCenter.dx, indicatorCenter.dy - (excludedIndicatorSize.height / 2)),
                // Right center.
                Offset(indicatorCenter.dx + (excludedIndicatorSize.width / 2), indicatorCenter.dy),
                // Bottom center.
                Offset(indicatorCenter.dx, indicatorCenter.dy + (excludedIndicatorSize.height / 2)),
              ],
            ),
          )
          ..circle(
            x: indicatorCenter.dx,
            y: indicatorCenter.dy,
            radius: 35.0,
            color: const Color(0x0a000000),
          )
      );

      // Test ripple when NavigationBar is using `NavigationDestinationLabelBehavior.onlyShowSelected`.
      await tester.pumpWidget(buildWidget(labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected));
      await gesture.moveTo(tester.getCenter(find.byIcon(Icons.access_alarm)));
      await tester.pumpAndSettle();

      expect(
        inkFeatures,
        paints
          ..clipPath(
            pathMatcher: isPathThat(
              includes: <Offset>[
                // Left center.
                Offset(indicatorCenter.dx - (includedIndicatorSize.width / 2), indicatorCenter.dy),
                // Top center.
                Offset(indicatorCenter.dx, indicatorCenter.dy - (includedIndicatorSize.height / 2)),
                // Right center.
                Offset(indicatorCenter.dx + (includedIndicatorSize.width / 2), indicatorCenter.dy),
                // Bottom center.
                Offset(indicatorCenter.dx, indicatorCenter.dy + (includedIndicatorSize.height / 2)),
              ],
              excludes: <Offset>[
                // Left center.
                Offset(indicatorCenter.dx - (excludedIndicatorSize.width / 2), indicatorCenter.dy),
                // Top center.
                Offset(indicatorCenter.dx, indicatorCenter.dy - (excludedIndicatorSize.height / 2)),
                // Right center.
                Offset(indicatorCenter.dx + (excludedIndicatorSize.width / 2), indicatorCenter.dy),
                // Bottom center.
                Offset(indicatorCenter.dx, indicatorCenter.dy + (excludedIndicatorSize.height / 2)),
              ],
            ),
          )
          ..circle(
            x: indicatorCenter.dx,
            y: indicatorCenter.dy,
            radius: 35.0,
            color: const Color(0x0a000000),
          )
      );

      // Make sure ripple is shifted when selectedIndex changes.
      selectedIndex = 1;
      await tester.pumpWidget(buildWidget(labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected));
      await tester.pumpAndSettle();
      indicatorCenter = const Offset(600, 33);

      expect(
        inkFeatures,
        paints
          ..clipPath(
            pathMatcher: isPathThat(
              includes: <Offset>[
                // Left center.
                Offset(indicatorCenter.dx - (includedIndicatorSize.width / 2), indicatorCenter.dy),
                // Top center.
                Offset(indicatorCenter.dx, indicatorCenter.dy - (includedIndicatorSize.height / 2)),
                // Right center.
                Offset(indicatorCenter.dx + (includedIndicatorSize.width / 2), indicatorCenter.dy),
                // Bottom center.
                Offset(indicatorCenter.dx, indicatorCenter.dy + (includedIndicatorSize.height / 2)),
              ],
              excludes: <Offset>[
                // Left center.
                Offset(indicatorCenter.dx - (excludedIndicatorSize.width / 2), indicatorCenter.dy),
                // Top center.
                Offset(indicatorCenter.dx, indicatorCenter.dy - (excludedIndicatorSize.height / 2)),
                // Right center.
                Offset(indicatorCenter.dx + (excludedIndicatorSize.width / 2), indicatorCenter.dy),
                // Bottom center.
                Offset(indicatorCenter.dx, indicatorCenter.dy + (excludedIndicatorSize.height / 2)),
              ],
            ),
          )
          ..circle(
            x: indicatorCenter.dx,
            y: indicatorCenter.dy,
            radius: 35.0,
            color: const Color(0x0a000000),
          )
      );
    });

    testWidgets('Navigation indicator ripple golden test', (WidgetTester tester) async {
      // This is a regression test for https://github.com/flutter/flutter/issues/117420.

      Widget buildWidget({ NavigationDestinationLabelBehavior? labelBehavior }) {
        return MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: Scaffold(
            bottomNavigationBar: Center(
              child: NavigationBar(
                labelBehavior: labelBehavior,
                destinations: const <Widget>[
                  NavigationDestination(
                    icon: SizedBox(),
                    label: 'AC',
                  ),
                  NavigationDestination(
                    icon: SizedBox(),
                    label: 'Alarm',
                  ),
                ],
                onDestinationSelected: (int i) { },
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildWidget());

      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer();
      await gesture.moveTo(tester.getCenter(find.byType(NavigationDestination).last));
      await tester.pumpAndSettle();

      // Test ripple when NavigationBar is using `NavigationDestinationLabelBehavior.alwaysShow` (default).
      await expectLater(find.byType(NavigationBar), matchesGoldenFile('indicator_alwaysShow_m2.png'));

      // Test ripple when NavigationBar is using `NavigationDestinationLabelBehavior.alwaysHide`.
      await tester.pumpWidget(buildWidget(labelBehavior: NavigationDestinationLabelBehavior.alwaysHide));
      await gesture.moveTo(tester.getCenter(find.byType(NavigationDestination).last));
      await tester.pumpAndSettle();

      await expectLater(find.byType(NavigationBar), matchesGoldenFile('indicator_alwaysHide_m2.png'));

      // Test ripple when NavigationBar is using `NavigationDestinationLabelBehavior.onlyShowSelected`.
      await tester.pumpWidget(buildWidget(labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected));
      await gesture.moveTo(tester.getCenter(find.byType(NavigationDestination).first));
      await tester.pumpAndSettle();

      await expectLater(find.byType(NavigationBar), matchesGoldenFile('indicator_onlyShowSelected_selected_m2.png'));

      await gesture.moveTo(tester.getCenter(find.byType(NavigationDestination).last));
      await tester.pumpAndSettle();

      await expectLater(find.byType(NavigationBar), matchesGoldenFile('indicator_onlyShowSelected_unselected_m2.png'));
    });

    testWidgets('Destination icon does not rebuild when tapped', (WidgetTester tester) async {
      // This is a regression test for https://github.com/flutter/flutter/issues/122811.

      Widget buildNavigationBar() {
        return MaterialApp(
          home: Scaffold(
            bottomNavigationBar: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                int selectedIndex = 0;
                return NavigationBar(
                  selectedIndex: selectedIndex,
                  destinations: const <Widget>[
                    NavigationDestination(
                      icon: IconWithRandomColor(icon: Icons.ac_unit),
                      label: 'AC',
                    ),
                    NavigationDestination(
                      icon: IconWithRandomColor(icon: Icons.access_alarm),
                      label: 'Alarm',
                    ),
                  ],
                  onDestinationSelected: (int i) {
                    setState(() {
                      selectedIndex = i;
                    });
                  },
                );
              }
            ),
          ),
        );
      }

      await tester.pumpWidget(buildNavigationBar());
      Icon icon = tester.widget<Icon>(find.byType(Icon).last);
      final Color initialColor = icon.color!;

      // Trigger a rebuild.
      await tester.tap(find.text('Alarm'));
      await tester.pumpAndSettle();

      // Icon color should be the same as before the rebuild.
      icon = tester.widget<Icon>(find.byType(Icon).last);
      expect(icon.color, initialColor);
    });
  });
}

Widget _buildWidget(Widget child) {
  return MaterialApp(
    theme: ThemeData.light(),
    home: Scaffold(
      bottomNavigationBar: Center(
        child: child,
      ),
    ),
  );
}

Material _getMaterial(WidgetTester tester) {
  return tester.firstWidget<Material>(
    find.descendant(of: find.byType(NavigationBar), matching: find.byType(Material)),
  );
}

ShapeDecoration? _getIndicatorDecoration(WidgetTester tester) {
  return tester.firstWidget<Container>(
    find.descendant(
      of: find.byType(FadeTransition),
      matching: find.byType(Container),
    ),
  ).decoration as ShapeDecoration?;
}

class IconWithRandomColor extends StatelessWidget {
  const IconWithRandomColor({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final Color randomColor = Color((Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
    return Icon(icon, color: randomColor);
  }
}
