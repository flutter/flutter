// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/floating_action_button/floating_action_button.1.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FloatingActionButton variants', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.FloatingActionButtonExampleApp(),
    );

    final Finder fabButtonMaterial = find.descendant(
      of: find.byType(ElevatedButton),
      matching: find.byType(Material),
    );

    final ThemeData theme = ThemeData(useMaterial3: true);

    expect(find.byType(FloatingActionButton), findsNWidgets(4));
    expect(find.byIcon(Icons.add), findsNWidgets(4));

    final Finder smallFabMaterialButton = fabButtonMaterial.at(0);
    final RenderBox smallFabRenderBox = tester.renderObject(smallFabMaterialButton);
    expect(smallFabRenderBox.size, const Size(40.0, 40.0));
    expect(tester.widget<Material>(smallFabMaterialButton).color, theme.colorScheme.primaryContainer);
    expect(tester.widget<Material>(smallFabMaterialButton).shape, RoundedRectangleBorder(borderRadius:  BorderRadius.circular(12.0)));

    final Finder regularFABMaterialButton = fabButtonMaterial.at(1);
    final RenderBox regularFABRenderBox = tester.renderObject(regularFABMaterialButton);
    expect(regularFABRenderBox.size, const Size(56.0, 56.0));
    expect(tester.widget<Material>(regularFABMaterialButton).color, theme.colorScheme.primaryContainer);
    expect(tester.widget<Material>(regularFABMaterialButton).shape, RoundedRectangleBorder(borderRadius:  BorderRadius.circular(16.0)));

    final Finder largeFABMaterialButton = fabButtonMaterial.at(2);
    final RenderBox largeFABRenderBox = tester.renderObject(largeFABMaterialButton);
    expect(largeFABRenderBox.size, const Size(96.0, 96.0));
    expect(tester.widget<Material>(largeFABMaterialButton).color, theme.colorScheme.primaryContainer);
    expect(tester.widget<Material>(largeFABMaterialButton).shape, RoundedRectangleBorder(borderRadius:  BorderRadius.circular(28.0)));

    final Finder extendedFABMaterialButton = fabButtonMaterial.at(3);
    final RenderBox extendedFABRenderBox = tester.renderObject(extendedFABMaterialButton);
    expect(extendedFABRenderBox.size, within(distance: 0.01, from: const Size(110.3, 56.0)));
    expect(tester.widget<Material>(extendedFABMaterialButton).color, theme.colorScheme.primaryContainer);
    expect(tester.widget<Material>(extendedFABMaterialButton).shape, RoundedRectangleBorder(borderRadius:  BorderRadius.circular(16.0)));
  });
}
