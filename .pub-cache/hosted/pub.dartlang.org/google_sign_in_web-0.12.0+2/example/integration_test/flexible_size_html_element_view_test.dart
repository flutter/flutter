// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_web/src/flexible_size_html_element_view.dart';
import 'package:integration_test/integration_test.dart';

import 'src/dom.dart';

/// Used to keep track of the number of HtmlElementView factories the test has registered.
int widgetFactoryNumber = 0;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('FlexHtmlElementView', () {
    tearDown(() {
      widgetFactoryNumber++;
    });

    testWidgets('empty case, calls onPlatformViewCreated',
        (WidgetTester tester) async {
      final Completer<int> viewCreatedCompleter = Completer<int>();

      await pumpResizableWidget(tester, onPlatformViewCreated: (int id) {
        viewCreatedCompleter.complete(id);
      });
      await tester.pumpAndSettle();

      await expectLater(viewCreatedCompleter.future, completes);
    });

    testWidgets('empty case, renders with initial size',
        (WidgetTester tester) async {
      const Size initialSize = Size(160, 100);

      final Element element = await pumpResizableWidget(
        tester,
        initialSize: initialSize,
      );
      await tester.pumpAndSettle();

      // Expect that the element matches the initialSize.
      expect(element.size!.width, initialSize.width);
      expect(element.size!.height, initialSize.height);
    });

    testWidgets('initialSize null, adopts size of injected element',
        (WidgetTester tester) async {
      const Size childSize = Size(300, 40);

      final DomHtmlElement resizable = document.createElement('div');
      resize(resizable, childSize);

      final Element element = await pumpResizableWidget(
        tester,
        onPlatformViewCreated: injectElement(resizable),
      );
      await tester.pumpAndSettle();

      // Expect that the element matches the initialSize.
      expect(element.size!.width, childSize.width);
      expect(element.size!.height, childSize.height);
    });

    testWidgets('with initialSize, adopts size of injected element',
        (WidgetTester tester) async {
      const Size initialSize = Size(160, 100);
      const Size newSize = Size(300, 40);

      final DomHtmlElement resizable = document.createElement('div');
      resize(resizable, newSize);

      final Element element = await pumpResizableWidget(
        tester,
        initialSize: initialSize,
        onPlatformViewCreated: injectElement(resizable),
      );
      await tester.pumpAndSettle();

      // Expect that the element matches the initialSize.
      expect(element.size!.width, newSize.width);
      expect(element.size!.height, newSize.height);
    });

    testWidgets('with injected element that resizes, follows resizes',
        (WidgetTester tester) async {
      const Size initialSize = Size(160, 100);
      final Size expandedSize = initialSize * 2;
      final Size contractedSize = initialSize / 2;

      final DomHtmlElement resizable = document.createElement('div')
        ..setAttribute(
            'style', 'width: 100%; height: 100%; background: #fabada;');

      final Element element = await pumpResizableWidget(
        tester,
        initialSize: initialSize,
        onPlatformViewCreated: injectElement(resizable),
      );
      await tester.pumpAndSettle();

      // Expect that the element matches the initialSize, because the
      // resizable is defined as width:100%, height:100%.
      expect(element.size!.width, initialSize.width);
      expect(element.size!.height, initialSize.height);

      // Expands
      resize(resizable, expandedSize);

      await tester.pumpAndSettle();

      expect(element.size!.width, expandedSize.width);
      expect(element.size!.height, expandedSize.height);

      // Contracts
      resize(resizable, contractedSize);

      await tester.pumpAndSettle();

      expect(element.size!.width, contractedSize.width);
      expect(element.size!.height, contractedSize.height);
    });
  });
}

/// Injects a ResizableFromJs widget into the `tester`.
Future<Element> pumpResizableWidget(
  WidgetTester tester, {
  void Function(int)? onPlatformViewCreated,
  Size? initialSize,
}) async {
  await tester.pumpWidget(ResizableFromJs(
    instanceId: widgetFactoryNumber,
    onPlatformViewCreated: onPlatformViewCreated,
    initialSize: initialSize,
  ));
  // Needed for JS to have time to kick-off.
  await tester.pump();

  // Return the element we just pumped
  final Iterable<Element> elements =
      find.byKey(Key('resizable_from_js_$widgetFactoryNumber')).evaluate();
  expect(elements, hasLength(1));
  return elements.first;
}

class ResizableFromJs extends StatelessWidget {
  ResizableFromJs({
    required this.instanceId,
    this.onPlatformViewCreated,
    this.initialSize,
    super.key,
  }) {
    // ignore: avoid_dynamic_calls, undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      'resizable_from_js_$instanceId',
      (int viewId) {
        final DomHtmlElement element = document.createElement('div');
        element.setAttribute('style',
            'width: 100%; height: 100%; overflow: hidden; background: red;');
        element.id = 'test_element_$viewId';
        return element;
      },
    );
  }

  final int instanceId;
  final void Function(int)? onPlatformViewCreated;
  final Size? initialSize;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: FlexHtmlElementView(
            viewType: 'resizable_from_js_$instanceId',
            key: Key('resizable_from_js_$instanceId'),
            onPlatformViewCreated: onPlatformViewCreated,
            initialSize: initialSize ?? const Size(640, 480),
          ),
        ),
      ),
    );
  }
}

/// Resizes `resizable` to `size`.
void resize(DomHtmlElement resizable, Size size) {
  resizable.setAttribute('style',
      'width: ${size.width}px; height: ${size.height}px; background: #fabada');
}

/// Returns a function that can be used to inject `element` in `onPlatformViewCreated` callbacks.
void Function(int) injectElement(DomHtmlElement element) {
  return (int viewId) {
    final DomHtmlElement root =
        document.querySelector('#test_element_$viewId')!;
    root.appendChild(element);
  };
}
