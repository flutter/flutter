
// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const List<String> kOptions = <String>[
    'aardvark',
    'baboon',
    'chameleon',
    'dingo',
    'elephant',
    'flamingo',
    'goose',
    'hippopotamus',
    'iguana',
    'jaguar',
    'koala',
    'lemur',
    'mouse',
    'northern white rhinocerous',
  ];

  testWidgets('builds builders', (WidgetTester tester) async {
    final GlobalKey fieldKey = GlobalKey();
    final GlobalKey resultsKey = GlobalKey();
    final AutocompleteController<String> autocompleteController =
        AutocompleteController<String>(
          options: kOptions,
        );

    await tester.pumpWidget(
      MaterialApp(
        home: AutocompleteCore<String>(
          autocompleteController: autocompleteController,
          buildField: (BuildContext context, TextEditingController textEditingController) {
            return Container(key: fieldKey);
          },
          buildResults: (BuildContext context, List<String> results, OnSelectedAutocomplete<String> onSelected) {
            return Container(key: resultsKey);
          },
        ),
      ),
    );

    expect(find.byKey(fieldKey), findsOneWidget);
    expect(find.byKey(resultsKey), findsOneWidget);
  });

  group('AutocompleteController', () {
    group('dispose', () {
      testWidgets('disposes the TextEditingController when not passed in', (WidgetTester tester) async {
        final AutocompleteController<String> autocompleteController =
            AutocompleteController<String>(
              options: kOptions,
            );
        expect(autocompleteController.textEditingController, isNotNull);

        autocompleteController.dispose();
        expect(() {
          autocompleteController.textEditingController.addListener(() {});
        }, throwsFlutterError);
      });

      testWidgets("doesn't dispose the TextEditingController when passed in", (WidgetTester tester) async {
        final TextEditingController textEditingController = TextEditingController();
        final AutocompleteController<String> autocompleteController =
            AutocompleteController<String>(
              options: kOptions,
              textEditingController: textEditingController,
            );
        expect(autocompleteController.textEditingController, isNotNull);

        autocompleteController.dispose();
        expect(() {
          autocompleteController.textEditingController.addListener(() {});
        }, isNot(throwsException));
        // No error thrown
      });
    });
  });
}
