
// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('builds builders', (WidgetTester tester) async {
    final GlobalKey fieldKey = GlobalKey();
    final GlobalKey resultsKey = GlobalKey();
    final AutocompleteController<String> autocompleteController =
        AutocompleteController<String>();

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

  // TODO(justinmc): More tests.
}
