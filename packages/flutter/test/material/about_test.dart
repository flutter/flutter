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
              children: <Widget>[
                new AboutListTile(
                  applicationVersion: '0.1.2',
                  applicationIcon: const FlutterLogo(),
                  applicationLegalese: 'I am the very model of a modern major general.',
                  aboutBoxChildren: <Widget>[
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
        new LicenseEntryWithLineBreaks(<String>[ 'Pirate package '], 'Pirate license')
      ]);
    });

    await tester.tap(find.text('VIEW LICENSES'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('Pirate license'), findsOneWidget);
  });

  testWidgets('About box logic defaults to executable name for app name', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Material(child: new AboutListTile()),
    );
    expect(find.text('About flutter_tester'), findsOneWidget);
  });

  testWidgets('AboutListTile control test', (WidgetTester tester) async {
    final List<String> log = <String>[];

    Future<Null> licenseFuture;
    LicenseRegistry.addLicense(() {
      log.add('license1');
      licenseFuture = tester.pumpWidget(new Container());
      return new Stream<LicenseEntry>.fromIterable(<LicenseEntry>[]);
    });

    LicenseRegistry.addLicense(() {
      log.add('license2');
      return new Stream<LicenseEntry>.fromIterable(<LicenseEntry>[
        new LicenseEntryWithLineBreaks(<String>[ 'Another package '], 'Another license')
      ]);
    });

    await tester.pumpWidget(const Center(
      child: const LicensePage()
    ));

    expect(licenseFuture, isNotNull);
    await licenseFuture;

    // We should not hit an exception here.
    await tester.idle();

    expect(log, equals(<String>['license1', 'license2']));
  });
}
