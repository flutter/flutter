// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    LicenseRegistry.reset();
  });

  testWidgets('AboutListTile control test', (WidgetTester tester) async {
    const FlutterLogo logo = FlutterLogo();

    await tester.pumpWidget(
      MaterialApp(
        title: 'Pirate app',
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Home'),
          ),
          drawer: Drawer(
            child: ListView(
              children: const <Widget>[
                AboutListTile(
                  applicationVersion: '0.1.2',
                  applicationIcon: logo,
                  applicationLegalese: 'I am the very model of a modern major general.',
                  aboutBoxChildren: <Widget>[
                    Text('About box'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('About Pirate app'), findsNothing);
    expect(find.text('0.1.2'), findsNothing);
    expect(find.byWidget(logo), findsNothing);
    expect(
      find.text('I am the very model of a modern major general.'),
      findsNothing,
    );
    expect(find.text('About box'), findsNothing);

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('About Pirate app'), findsOneWidget);
    expect(find.text('0.1.2'), findsNothing);
    expect(find.byWidget(logo), findsNothing);
    expect(
      find.text('I am the very model of a modern major general.'),
      findsNothing,
    );
    expect(find.text('About box'), findsNothing);

    await tester.tap(find.text('About Pirate app'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('About Pirate app'), findsOneWidget);
    expect(find.text('0.1.2'), findsOneWidget);
    expect(find.byWidget(logo), findsOneWidget);
    expect(
      find.text('I am the very model of a modern major general.'),
      findsOneWidget,
    );
    expect(find.text('About box'), findsOneWidget);

    LicenseRegistry.addLicense(() {
      return Stream<LicenseEntry>.fromIterable(<LicenseEntry>[
        const LicenseEntryWithLineBreaks(<String>['Pirate package '], 'Pirate license'),
      ]);
    });

    await tester.tap(find.text('VIEW LICENSES'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('Pirate app'), findsOneWidget);
    expect(find.text('0.1.2'), findsOneWidget);
    expect(find.byWidget(logo), findsOneWidget);
    expect(
      find.text('I am the very model of a modern major general.'),
      findsOneWidget,
    );
    expect(find.text('Pirate license'), findsOneWidget);
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/54385

  testWidgets('About box logic defaults to executable name for app name', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        title: 'flutter_tester',
        home: Material(child: AboutListTile()),
      ),
    );
    expect(find.text('About flutter_tester'), findsOneWidget);
  });

  testWidgets('LicensePage control test', (WidgetTester tester) async {
    LicenseRegistry.addLicense(() {
      return Stream<LicenseEntry>.fromIterable(<LicenseEntry>[
        const LicenseEntryWithLineBreaks(<String>['AAA'], 'BBB'),
      ]);
    });

    LicenseRegistry.addLicense(() {
      return Stream<LicenseEntry>.fromIterable(<LicenseEntry>[
        const LicenseEntryWithLineBreaks(
          <String>['Another package'],
          'Another license',
        ),
      ]);
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: LicensePage(),
        ),
      ),
    );

    expect(find.text('AAA'), findsNothing);
    expect(find.text('BBB'), findsNothing);
    expect(find.text('Another package'), findsNothing);
    expect(find.text('Another license'), findsNothing);

    await tester.pumpAndSettle();

    expect(find.text('AAA'), findsOneWidget);
    expect(find.text('BBB'), findsOneWidget);
    expect(find.text('Another package'), findsOneWidget);
    expect(find.text('Another license'), findsOneWidget);
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/54385

  testWidgets('LicensePage control test with all properties', (WidgetTester tester) async {
    const FlutterLogo logo = FlutterLogo();

    LicenseRegistry.addLicense(() {
      return Stream<LicenseEntry>.fromIterable(<LicenseEntry>[
        const LicenseEntryWithLineBreaks(<String>['AAA'], 'BBB'),
      ]);
    });

    LicenseRegistry.addLicense(() {
      return Stream<LicenseEntry>.fromIterable(<LicenseEntry>[
        const LicenseEntryWithLineBreaks(
          <String>['Another package'],
          'Another license',
        ),
      ]);
    });

    await tester.pumpWidget(
      const MaterialApp(
        title: 'Pirate app',
        home: Center(
          child: LicensePage(
            applicationName: 'LicensePage test app',
            applicationVersion: '0.1.2',
            applicationIcon: logo,
            applicationLegalese: 'I am the very model of a modern major general.',
          ),
        ),
      ),
    );

    expect(find.text('Pirate app'), findsNothing);
    expect(find.text('LicensePage test app'), findsOneWidget);
    expect(find.text('0.1.2'), findsOneWidget);
    expect(find.byWidget(logo), findsOneWidget);
    expect(
      find.text('I am the very model of a modern major general.'),
      findsOneWidget,
    );
    expect(find.text('AAA'), findsNothing);
    expect(find.text('BBB'), findsNothing);
    expect(find.text('Another package'), findsNothing);
    expect(find.text('Another license'), findsNothing);

    await tester.pumpAndSettle();

    expect(find.text('Pirate app'), findsNothing);
    expect(find.text('LicensePage test app'), findsOneWidget);
    expect(find.text('0.1.2'), findsOneWidget);
    expect(find.byWidget(logo), findsOneWidget);
    expect(
      find.text('I am the very model of a modern major general.'),
      findsOneWidget,
    );
    expect(find.text('AAA'), findsOneWidget);
    expect(find.text('BBB'), findsOneWidget);
    expect(find.text('Another package'), findsOneWidget);
    expect(find.text('Another license'), findsOneWidget);
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/54385

  testWidgets('LicensePage respects the notch', (WidgetTester tester) async {
    const double safeareaPadding = 27.0;

    LicenseRegistry.addLicense(() {
      return Stream<LicenseEntry>.fromIterable(<LicenseEntry>[
        const LicenseEntryWithLineBreaks(<String>['ABC'], 'DEF'),
      ]);
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            padding: EdgeInsets.all(safeareaPadding),
          ),
          child: LicensePage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.text('DEF')), const Offset(8.0 + safeareaPadding, 287.0));
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/54385

  testWidgets('LicensePage returns early if unmounted', (WidgetTester tester) async {
    final Completer<LicenseEntry> licenseCompleter = Completer<LicenseEntry>();
    LicenseRegistry.addLicense(() {
      return Stream<LicenseEntry>.fromFuture(licenseCompleter.future);
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: LicensePage(),
      ),
    );
    await tester.pump();

    await tester.pumpWidget(
      const MaterialApp(
        home: Placeholder(),
      ),
    );

    await tester.pumpAndSettle();
    final FakeLicenseEntry licenseEntry = FakeLicenseEntry();
    licenseCompleter.complete(licenseEntry);
    expect(licenseEntry.paragraphsCalled, false);
  });

  testWidgets('LicensePage returns late if unmounted', (WidgetTester tester) async {
    final Completer<LicenseEntry> licenseCompleter = Completer<LicenseEntry>();
    LicenseRegistry.addLicense(() {
      return Stream<LicenseEntry>.fromFuture(licenseCompleter.future);
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: LicensePage(),
      ),
    );
    await tester.pump();
    final FakeLicenseEntry licenseEntry = FakeLicenseEntry();
    licenseCompleter.complete(licenseEntry);

    await tester.pumpWidget(
      const MaterialApp(
        home: Placeholder(),
      ),
    );

    await tester.pumpAndSettle();
    expect(licenseEntry.paragraphsCalled, true);
  });

  testWidgets('LicensePage logic defaults to executable name for app name', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        title: 'flutter_tester',
        home: Material(child: LicensePage()),
      ),
    );
    expect(find.text('flutter_tester'), findsOneWidget);
  });

  testWidgets('AboutListTile dense property is applied', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Material(child: Center(child: AboutListTile())),
    ));
    Rect tileRect = tester.getRect(find.byType(AboutListTile));
    expect(tileRect.height, 56.0);

    await tester.pumpWidget(const MaterialApp(
      home: Material(child: Center(child: AboutListTile(dense: false))),
    ));
    tileRect = tester.getRect(find.byType(AboutListTile));
    expect(tileRect.height, 56.0);

    await tester.pumpWidget(const MaterialApp(
      home: Material(child: Center(child: AboutListTile(dense: true))),
    ));
    tileRect = tester.getRect(find.byType(AboutListTile));
    expect(tileRect.height, 48.0);
  });

  testWidgets('showLicensePage uses nested navigator by default', (WidgetTester tester) async {
    final LicensePageObserver rootObserver = LicensePageObserver();
    final LicensePageObserver nestedObserver = LicensePageObserver();

    await tester.pumpWidget(MaterialApp(
      navigatorObservers: <NavigatorObserver>[rootObserver],
      initialRoute: '/',
      onGenerateRoute: (_) {
        return PageRouteBuilder<dynamic>(
          pageBuilder: (_, __, ___) => Navigator(
            observers: <NavigatorObserver>[nestedObserver],
            onGenerateRoute: (RouteSettings settings) {
              return PageRouteBuilder<dynamic>(
                pageBuilder: (BuildContext context, _, __) {
                  return RaisedButton(
                    onPressed: () {
                      showLicensePage(
                        context: context,
                        applicationName: 'A',
                      );
                    },
                    child: const Text('Show License Page'),
                  );
                },
              );
            },
          ),
        );
      },
    ));

    // Open the dialog.
    await tester.tap(find.byType(RaisedButton));

    expect(rootObserver.licensePageCount, 0);
    expect(nestedObserver.licensePageCount, 1);
  });

  testWidgets('showLicensePage uses root navigator if useRootNavigator is true', (WidgetTester tester) async {
    final LicensePageObserver rootObserver = LicensePageObserver();
    final LicensePageObserver nestedObserver = LicensePageObserver();

    await tester.pumpWidget(MaterialApp(
      navigatorObservers: <NavigatorObserver>[rootObserver],
      initialRoute: '/',
      onGenerateRoute: (_) {
        return PageRouteBuilder<dynamic>(
          pageBuilder: (_, __, ___) => Navigator(
            observers: <NavigatorObserver>[nestedObserver],
            onGenerateRoute: (RouteSettings settings) {
              return PageRouteBuilder<dynamic>(
                pageBuilder: (BuildContext context, _, __) {
                  return RaisedButton(
                    onPressed: () {
                      showLicensePage(
                        context: context,
                        useRootNavigator: true,
                        applicationName: 'A',
                      );
                    },
                    child: const Text('Show License Page'),
                  );
                },
              );
            },
          ),
        );
      },
    ));

    // Open the dialog.
    await tester.tap(find.byType(RaisedButton));

    expect(rootObserver.licensePageCount, 1);
    expect(nestedObserver.licensePageCount, 0);
  });

  testWidgets('showAboutDialog uses root navigator by default', (WidgetTester tester) async {
    final AboutDialogObserver rootObserver = AboutDialogObserver();
    final AboutDialogObserver nestedObserver = AboutDialogObserver();

    await tester.pumpWidget(MaterialApp(
      navigatorObservers: <NavigatorObserver>[rootObserver],
      home: Navigator(
        observers: <NavigatorObserver>[nestedObserver],
        onGenerateRoute: (RouteSettings settings) {
          return MaterialPageRoute<dynamic>(
            builder: (BuildContext context) {
              return RaisedButton(
                onPressed: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'A',
                  );
                },
                child: const Text('Show About Dialog'),
              );
            },
          );
        },
      ),
    ));

    // Open the dialog.
    await tester.tap(find.byType(RaisedButton));

    expect(rootObserver.dialogCount, 1);
    expect(nestedObserver.dialogCount, 0);
  });

  testWidgets('showAboutDialog uses nested navigator if useRootNavigator is false', (WidgetTester tester) async {
    final AboutDialogObserver rootObserver = AboutDialogObserver();
    final AboutDialogObserver nestedObserver = AboutDialogObserver();

    await tester.pumpWidget(MaterialApp(
      navigatorObservers: <NavigatorObserver>[rootObserver],
      home: Navigator(
        observers: <NavigatorObserver>[nestedObserver],
        onGenerateRoute: (RouteSettings settings) {
          return MaterialPageRoute<dynamic>(
            builder: (BuildContext context) {
              return RaisedButton(
                onPressed: () {
                  showAboutDialog(
                    context: context,
                    useRootNavigator: false,
                    applicationName: 'A',
                  );
                },
                child: const Text('Show About Dialog'),
              );
            },
          );
        },
      ),
    ));

    // Open the dialog.
    await tester.tap(find.byType(RaisedButton));

    expect(rootObserver.dialogCount, 0);
    expect(nestedObserver.dialogCount, 1);
  });

  testWidgets("AboutListTile's child should not be offset when the icon is not specified.", (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AboutListTile(
            child: Text('About'),
          ),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byType(AboutListTile),
        matching: find.byType(Icon),
      ),
      findsNothing,
    );
  });

  testWidgets("AboutDialog's contents are scrollable", (WidgetTester tester) async {
    final Key contentKey = UniqueKey();
    await tester.pumpWidget(MaterialApp(
      home: Navigator(
        onGenerateRoute: (RouteSettings settings) {
          return MaterialPageRoute<dynamic>(
            builder: (BuildContext context) {
              return RaisedButton(
                onPressed: () {
                  showAboutDialog(
                    context: context,
                    useRootNavigator: false,
                    applicationName: 'A',
                    children: <Widget>[
                      Container(
                        key: contentKey,
                        color: Colors.orange,
                        height: 500,
                      ),
                    ],
                  );
                },
                child: const Text('Show About Dialog'),
              );
            },
          );
        },
      ),
    ));

    await tester.tap(find.text('Show About Dialog'));
    await tester.pumpAndSettle();

    // Try dragging by the [AboutDialog]'s title.
    RenderBox box = tester.renderObject(find.text('A'));
    Offset originalOffset = box.localToGlobal(Offset.zero);
    await tester.drag(find.byKey(contentKey), const Offset(0.0, -20.0));

    expect(box.localToGlobal(Offset.zero), equals(originalOffset.translate(0.0, -20.0)));

    // Try dragging by the additional children in contents.
    box = tester.renderObject(find.byKey(contentKey));
    originalOffset = box.localToGlobal(Offset.zero);
    await tester.drag(find.byKey(contentKey), const Offset(0.0, -20.0));

    expect(box.localToGlobal(Offset.zero), equals(originalOffset.translate(0.0, -20.0)));
  });
}

class FakeLicenseEntry extends LicenseEntry {
  FakeLicenseEntry();

  bool get paragraphsCalled => _paragraphsCalled;
  bool _paragraphsCalled = false;

  @override
  Iterable<String> packages = <String>[];

  @override
  Iterable<LicenseParagraph> get paragraphs {
    _paragraphsCalled = true;
    return <LicenseParagraph>[];
  }
}

class LicensePageObserver extends NavigatorObserver {
  int licensePageCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic> previousRoute) {
    if (route is MaterialPageRoute<dynamic>) {
      licensePageCount++;
    }
    super.didPush(route, previousRoute);
  }
}

class AboutDialogObserver extends NavigatorObserver {
  int dialogCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic> previousRoute) {
    if (route.toString().contains('_DialogRoute')) {
      dialogCount++;
    }
    super.didPush(route, previousRoute);
  }
}
