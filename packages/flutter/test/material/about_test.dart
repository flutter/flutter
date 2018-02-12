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
      new MaterialApp(
        title: 'Pirate app',
        home: new Scaffold(
          appBar: new AppBar(
            title: const Text('Home'),
          ),
          drawer: new Drawer(
            child: new ListView(
              children: const <Widget>[
                const AboutListTile(
                  applicationVersion: '0.1.2',
                  applicationIcon: const FlutterLogo(),
                  applicationLegalese: 'I am the very model of a modern major general.',
                  aboutBoxChildren: const <Widget>[
                    const Text('About box'),
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
      return new Stream<LicenseEntry>.fromIterable(<LicenseEntry>[
        const LicenseEntryWithLineBreaks(const <String>[ 'Pirate package '], 'Pirate license')
      ]);
    });

    await tester.tap(find.text('VIEW LICENSES'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('Pirate license'), findsOneWidget);
  });

  testWidgets('About box logic defaults to executable name for app name', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        title: 'flutter_tester',
        home: const Material(child: const AboutListTile()),
      ),
    );
    expect(find.text('About flutter_tester'), findsOneWidget);
  });

  testWidgets('AboutListTile control test', (WidgetTester tester) async {
    LicenseRegistry.addLicense(() {
      return new Stream<LicenseEntry>.fromIterable(<LicenseEntry>[
        const LicenseEntryWithLineBreaks(const <String>['AAA'], 'BBB')
      ]);
    });

    LicenseRegistry.addLicense(() {
      return new Stream<LicenseEntry>.fromIterable(<LicenseEntry>[
        const LicenseEntryWithLineBreaks(const <String>['Another package'], 'Another license')
      ]);
    });

    await tester.pumpWidget(
      new MaterialApp(
        home: const Center(
          child: const LicensePage(),
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
