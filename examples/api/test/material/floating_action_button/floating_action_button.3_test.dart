// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/floating_action_button/floating_action_button.3.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FloatingActionButton variants', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.MyApp(),
    );

    final ThemeData theme = ThemeData(colorSchemeSeed: const Color(0xff6750a4), useMaterial3: true);

    expect(find.byType(FloatingActionButton), findsNWidgets(4));
    expect(find.byIcon(Icons.add), findsNWidgets(4));

    final Finder smallFabElevatedButton = find.byType(ElevatedButton).at(0);
    final RenderBox smallFabRenderBox = tester.renderObject(smallFabElevatedButton);
    expect(smallFabRenderBox.size, const Size(48.0, 48.0));
    Material material = tester.widget(
      find.descendant(
        of: find.byType(ElevatedButton).at(0),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, theme.colorScheme.primaryContainer);
    expect(material.shape, RoundedRectangleBorder(borderRadius:  BorderRadius.circular(12.0)));

    final Finder regularFABElevatedButton = find.byType(ElevatedButton).at(1);
    final RenderBox regularFABRenderBox = tester.renderObject(regularFABElevatedButton);
    expect(regularFABRenderBox.size, const Size(56.0, 56.0));
    material = tester.widget(
      find.descendant(
        of: find.byType(ElevatedButton).at(1),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, theme.colorScheme.primaryContainer);
    expect(material.shape, RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)));

    final Finder largeFABElevatedButton = find.byType(ElevatedButton).at(2);
    final RenderBox largeFABRenderBox = tester.renderObject(largeFABElevatedButton);
    expect(largeFABRenderBox.size, const Size(96.0, 96.0));
    material = tester.widget(
      find.descendant(
        of: find.byType(ElevatedButton).at(2),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, theme.colorScheme.primaryContainer);
    expect(material.shape, RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.0)));

    final Finder extendedFABElevatedButton = find.byType(ElevatedButton).at(3);
    final RenderBox extendedFABRenderBox = tester.renderObject(extendedFABElevatedButton);
    expect(extendedFABRenderBox.size, const Size(111.0, 56.0));
    material = tester.widget(
      find.descendant(
        of: find.byType(ElevatedButton).at(3),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, theme.colorScheme.primaryContainer);
    expect(material.shape, RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)));
  });
}
