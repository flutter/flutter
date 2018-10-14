// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AboutListTile control test', (WidgetTester tester) async {
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
                  applicationIcon: FlutterLogo(),
                  applicationLegalese: 'I am the very model of a modern major general.',
                  aboutBoxChildren: <Widget>[
                    Text('About box'),
                  ]
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('About Pirate app'), findsNothing);
    expect(find.text('0.1.2'), findsNothing);
    expect(find.text('About box'), findsNothing);

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('About Pirate app'), findsOneWidget);
    expect(find.text('0.1.2'), findsNothing);
    expect(find.text('About box'), findsNothing);

    await tester.tap(find.text('About Pirate app'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('About Pirate app'), findsOneWidget);
    expect(find.text('0.1.2'), findsOneWidget);
    expect(find.text('About box'), findsOneWidget);

    LicenseRegistry.addLicense(() {
      return Stream<LicenseEntry>.fromIterable(<LicenseEntry>[
        const LicenseEntryWithLineBreaks(<String>[ 'Pirate package '], 'Pirate license')
      ]);
    });

    await tester.tap(find.text('VIEW LICENSES'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('Pirate license'), findsOneWidget);
  });

  testWidgets('About box logic defaults to executable name for app name', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        title: 'flutter_tester',
        home: Material(child: AboutListTile()),
      ),
    );
    expect(find.text('About flutter_tester'), findsOneWidget);
  });

  testWidgets('AboutListTile control test', (WidgetTester tester) async {
    LicenseRegistry.addLicense(() {
      return Stream<LicenseEntry>.fromIterable(<LicenseEntry>[
        const LicenseEntryWithLineBreaks(<String>['AAA'], 'BBB')
      ]);
    });

    LicenseRegistry.addLicense(() {
      return Stream<LicenseEntry>.fromIterable(<LicenseEntry>[
        const LicenseEntryWithLineBreaks(<String>['Another package'], 'Another license')
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
  });
}
