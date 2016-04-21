// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test/test.dart';

import '../lib/main.dart' as material_gallery;

const List<String> demoCategories = const <String>['Demos', 'Components', 'Style'];
const List<String> demoNames = const <String>[
  'Weather',
  'Fitness',
  'Fancy lines',
  'Flexible space toolbar',
  'Floating action button',
  'Buttons',
  'Cards',
  'Chips',
  'Date picker',
  'Data tables',
  'Dialog',
  'Drop-down button',
  'Expand/collapse list control',
  'Grid',
  'Icons',
  'Leave-behind list items',
  'List',
  'Menus',
  'Modal bottom sheet',
  'Over-scroll',
  'Page selector',
  'Persistent bottom sheet',
  'Progress indicators',
  'Scrollable tabs',
  'Selection controls',
  'Sliders',
  'Snackbar',
  'Tabs',
  'Text fields',
  'Time picker',
  'Tooltips',
  'Colors',
  'Typography'
];

Finder byTooltip(WidgetTester tester, String message) {
  return find.byElement((Element element) {
    Widget widget = element.widget;
    if (widget is Tooltip)
      return widget.message == message;
    return false;
  });
}

Finder findNavigationMenuButton(WidgetTester tester) => byTooltip(tester, 'Open navigation menu');

Finder findBackButton(WidgetTester tester) => byTooltip(tester, 'Back');

// Start a gallery demo and then go back. This function assumes that the
// we're starting on home route and that the submenu that contains the demo
// called 'name' is already open.
void smokeDemo(WidgetTester tester, String menuItemText) {
  // Ensure that we're (likely to be) on the home page
  final Finder navigationMenuButton = findNavigationMenuButton(tester);
  expect(tester, hasWidget(navigationMenuButton));

  tester.tap(find.text(menuItemText));
  tester.pump(); // Launch the demo.
  tester.pump(const Duration(seconds: 1)); // Wait until the demo has opened.

  // Go back
  Finder backButton = findBackButton(tester);
  expect(tester, hasWidget(backButton));
  tester.tap(backButton);
  tester.pump(); // Start the navigator pop "back" operation.
  tester.pump(const Duration(seconds: 1)); // Wait until it has finished.
}

void main() {
  test('Material Gallery app smoke test', () {
    testWidgets((WidgetTester tester) {
      material_gallery.main(); // builds the app and schedules a frame but doesn't trigger one
      tester.pump(); // see https://github.com/flutter/flutter/issues/1865
      tester.pump(); // triggers a frame

      // Expand the demo category submenus.
      for(String category in demoCategories.reversed) {
        tester.tap(find.text(category));
        tester.pump();
        tester.pump(const Duration(seconds: 1)); // Wait until the menu has expanded.
      }

      final List<double> scrollDeltas = new List<double>();
      double previousY = tester.getTopRight(find.text(demoCategories[0])).y;
      for(String name in demoNames) {
        final double y = tester.getTopRight(find.text(name)).y;
        scrollDeltas.add(previousY - y);
        previousY = y;
      }

      // Launch each demo and then scroll that item out of the way.
      for(int i = 0; i < demoNames.length; i++) {
        final String name = demoNames[i];
        print("$name");
        smokeDemo(tester, name);
        tester.scroll(find.text(name), new Offset(0.0, scrollDeltas[i]));
        tester.pump();
      }

      Finder navigationMenuButton = findNavigationMenuButton(tester);
      expect(tester, hasWidget(navigationMenuButton));
      tester.tap(navigationMenuButton);
      tester.pump(); // Start opening drawer.
      tester.pump(const Duration(seconds: 1)); // Wait until it's really opened.

      // switch theme
      tester.tap(find.text('Dark'));
      tester.pump();
      tester.pump(const Duration(seconds: 1)); // Wait until it's changed.

      // switch theme
      tester.tap(find.text('Light'));
      tester.pump();
      tester.pump(const Duration(seconds: 1)); // Wait until it's changed.
    });
  });
}
