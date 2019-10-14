// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('debugCheckHasMaterial control test', (WidgetTester tester) async {
    await tester.pumpWidget(const ListTile());
    final dynamic exception = tester.takeException();
    expect(exception, isFlutterError);
    final FlutterError error = exception;
    expect(error.toStringDeep(),
        'FlutterError\n'
            '   No Material widget found.\n'
            '   ListTile widgets require a Material widget ancestor.\n'
            '   In material design, most widgets are conceptually "printed" on a\n'
            '   sheet of material. In Flutter\'s material library, that material\n'
            '   is represented by the Material widget. It is the Material widget\n'
            '   that renders ink splashes, for instance. Because of this, many\n'
            '   material library widgets require that there be a Material widget\n'
            '   in the tree above them.\n'
            '   To introduce a Material widget, you can either directly include\n'
            '   one, or use a widget that contains Material itself, such as a\n'
            '   Card, Dialog, Drawer, or Scaffold.\n'
            '   The specific widget that could not find a Material ancestor was:\n'
            '     ListTile\n'
            '   The ancestors of this widget were:\n'
            '     [root]\n'
    );
  });

  testWidgets('debugCheckHasMaterialLocalizations control test', (
      WidgetTester tester) async {
    await tester.pumpWidget(const BackButton());
    final dynamic exception = tester.takeException();
    expect(exception, isFlutterError);
    final FlutterError error = exception;
    expect(error.toStringDeep(),
        'FlutterError\n'
            '   No MaterialLocalizations found.\n'
            '   BackButton widgets require MaterialLocalizations to be provided\n'
            '   by a Localizations widget ancestor.\n'
            '   Localizations are used to generate many different messages,\n'
            '   labels,and abbreviations which are used by the material library.\n'
            '   To introduce a MaterialLocalizations, either use a  MaterialApp\n'
            '   at the root of your application to include them automatically, or\n'
            '   add a Localization widget with a MaterialLocalizations delegate.\n'
            '   The specific widget that could not find a MaterialLocalizations\n'
            '   ancestor was:\n'
            '     BackButton\n'
            '   The ancestors of this widget were:\n'
            '     [root]\n'
    );
  });

  testWidgets(
      'debugCheckHasScaffold control test', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (BuildContext context) {
              showBottomSheet<void>(context: context,
                  builder: (BuildContext context) => Container());
              return Container();
            }
        )
    ));
    final dynamic exception = tester.takeException();
    expect(exception, isFlutterError);
    final FlutterError error = exception;
    expect(error.toStringDeep(), startsWith(
        'FlutterError\n'
            '   No Scaffold widget found.\n'
            '   Builder widgets require a Scaffold widget ancestor.\n'
            '   The specific widget that could not find a Scaffold ancestor was:\n'
            '     Builder\n'
    ));
    expect(error.toStringDeep(), endsWith(
        '   Typically, the Scaffold widget is introduced by the MaterialApp\n'
            '   or WidgetsApp widget at the top of your application widget tree.\n'
    ));
  });
}
