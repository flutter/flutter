// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_print

import 'dart:html' as html;

// Imports the Flutter Driver API.
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:pointer_interceptor_example/main.dart' as app;

final Finder nonClickableButtonFinder =
    find.byKey(const Key('transparent-button'));
final Finder clickableWrappedButtonFinder =
    find.byKey(const Key('wrapped-transparent-button'));
final Finder clickableButtonFinder = find.byKey(const Key('clickable-button'));
final Finder backgroundFinder =
    find.byKey(const ValueKey<String>('background-widget'));

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Without semantics', () {
    testWidgets(
        'on wrapped elements, the browser does not hit the background-html-view',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      final html.Element element =
          _getHtmlElementAtCenter(clickableButtonFinder, tester);

      expect(element.id, isNot('background-html-view'));
    }, semanticsEnabled: false);

    testWidgets(
        'on wrapped elements with intercepting set to false, the browser hits the background-html-view',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      final html.Element element =
          _getHtmlElementAtCenter(clickableWrappedButtonFinder, tester);

      expect(element.id, 'background-html-view');
    }, semanticsEnabled: false);

    testWidgets(
        'on unwrapped elements, the browser hits the background-html-view',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      final html.Element element =
          _getHtmlElementAtCenter(nonClickableButtonFinder, tester);

      expect(element.id, 'background-html-view');
    }, semanticsEnabled: false);

    testWidgets('on background directly', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      final html.Element element =
          _getHtmlElementAt(tester.getTopLeft(backgroundFinder));

      expect(element.id, 'background-html-view');
    }, semanticsEnabled: false);
  });

  group('With semantics', () {
    testWidgets('finds semantics of wrapped widgets',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      if (!_newSemanticsAvailable()) {
        print('Skipping test: Needs flutter > 2.10');
        return;
      }

      final html.Element element =
          _getHtmlElementAtCenter(clickableButtonFinder, tester);

      expect(element.tagName.toLowerCase(), 'flt-semantics');
      expect(element.getAttribute('aria-label'), 'Works As Expected');
    });

    testWidgets(
        'finds semantics of wrapped widgets with intercepting set to false',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      if (!_newSemanticsAvailable()) {
        print('Skipping test: Needs flutter > 2.10');
        return;
      }

      final html.Element element =
          _getHtmlElementAtCenter(clickableWrappedButtonFinder, tester);

      expect(element.tagName.toLowerCase(), 'flt-semantics');
      expect(element.getAttribute('aria-label'),
          'Never calls onPressed transparent');
    });

    testWidgets('finds semantics of unwrapped elements',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      if (!_newSemanticsAvailable()) {
        print('Skipping test: Needs flutter > 2.10');
        return;
      }

      final html.Element element =
          _getHtmlElementAtCenter(nonClickableButtonFinder, tester);

      expect(element.tagName.toLowerCase(), 'flt-semantics');
      expect(element.getAttribute('aria-label'), 'Never calls onPressed');
    });

    // Notice that, when hit-testing the background platform view, instead of
    // finding a semantics node, the platform view itself is found. This is
    // because the platform view does not add interactive semantics nodes into
    // the framework's semantics tree. Instead, its semantics is determined by
    // the HTML content of the platform view itself. Flutter's semantics tree
    // simply allows the hit test to land on the platform view by making itself
    // hit test transparent.
    testWidgets('on background directly', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      final html.Element element =
          _getHtmlElementAt(tester.getTopLeft(backgroundFinder));

      expect(element.id, 'background-html-view');
    });
  });
}

// Calls [_getHtmlElementAt] passing it the center of the widget identified by
// the `finder`.
html.Element _getHtmlElementAtCenter(Finder finder, WidgetTester tester) {
  final Offset point = tester.getCenter(finder);
  return _getHtmlElementAt(point);
}

// Locates the DOM element at the given `point` using `elementFromPoint`.
//
// `elementFromPoint` is an approximate proxy for a hit test, although it's
// sensitive to the presence of shadow roots and browser quirks (not all
// browsers agree on what it should return in all situations). Since this test
// runs only in Chromium, it relies on Chromium's behavior.
html.Element _getHtmlElementAt(Offset point) {
  // Probe at the shadow so the browser reports semantics nodes in addition to
  // platform view elements. If probed from `html.document` the browser hides
  // the contents of <flt-glass-name> as an implementation detail.
  final html.ShadowRoot glassPaneShadow =
      html.document.querySelector('flt-glass-pane')!.shadowRoot!;
  return glassPaneShadow.elementFromPoint(point.dx.toInt(), point.dy.toInt())!;
}

// TODO(dit): Remove this after flutter master (2.13) lands into stable.
// This detects that we can do new semantics assertions by looking at the 'id'
// attribute on flt-semantics elements (it is now set in 2.13 and up).
bool _newSemanticsAvailable() {
  final html.ShadowRoot glassPaneShadow =
      html.document.querySelector('flt-glass-pane')!.shadowRoot!;
  final List<html.Element> elements =
      glassPaneShadow.querySelectorAll('flt-semantics[id]');
  return elements.isNotEmpty;
}
