// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;

import 'package:ui/src/engine.dart';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';

import '../../matchers.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('PlatformViewManager', () {
    final String viewType = 'forTest';
    final int viewId = 6;

    late PlatformViewManager contentManager;

    setUp(() {
      contentManager = PlatformViewManager();
    });

    group('knowsViewType', () {
      test('recognizes viewTypes after registering them', () async {
        expect(contentManager.knowsViewType(viewType), isFalse);

        contentManager.registerFactory(viewType, (int id) => html.DivElement());

        expect(contentManager.knowsViewType(viewType), isTrue);
      });
    });

    group('knowsViewId', () {
      test('recognizes viewIds after *rendering* them', () async {
        expect(contentManager.knowsViewId(viewId), isFalse);

        contentManager.registerFactory(viewType, (int id) => html.DivElement());

        expect(contentManager.knowsViewId(viewId), isFalse);

        contentManager.renderContent(viewType, viewId, null);

        expect(contentManager.knowsViewId(viewId), isTrue);
      });

      test('forgets viewIds after clearing them', () {
        contentManager.registerFactory(viewType, (int id) => html.DivElement());
        contentManager.renderContent(viewType, viewId, null);

        expect(contentManager.knowsViewId(viewId), isTrue);

        contentManager.clearPlatformView(viewId);

        expect(contentManager.knowsViewId(viewId), isFalse);
      });
    });

    group('registerFactory', () {
      test('does NOT re-register factories', () async {
        contentManager.registerFactory(
            viewType, (int id) => html.DivElement()..id = 'pass');
        // this should be rejected
        contentManager.registerFactory(
            viewType, (int id) => html.SpanElement()..id = 'fail');

        final html.Element contents =
            contentManager.renderContent(viewType, viewId, null);

        expect(contents.querySelector('#pass'), isNotNull);
        expect(contents.querySelector('#fail'), isNull,
            reason: 'Factories cannot be overridden once registered');
      });
    });

    group('renderContent', () {
      final String unregisteredViewType = 'unregisteredForTest';
      final String anotherViewType = 'anotherViewType';

      setUp(() {
        contentManager.registerFactory(viewType, (int id) {
          return html.DivElement()..setAttribute('data-viewId', '$id');
        });

        contentManager.registerFactory(anotherViewType, (int id) {
          return html.DivElement()
            ..setAttribute('data-viewId', '$id')
            ..style.height = 'auto'
            ..style.width = '55%';
        });
      });

      test('refuse to render views for unregistered factories', () async {
        try {
          contentManager.renderContent(unregisteredViewType, viewId, null);
          fail('renderContent should have thrown an Assertion error!');
        } catch (e) {
          expect(e, isAssertionError);
          expect((e as AssertionError).message, contains(unregisteredViewType));
        }
      });

      test('rendered markup contains required attributes', () async {
        final html.Element content =
            contentManager.renderContent(viewType, viewId, null);
        expect(content.getAttribute('slot'), contains('$viewId'));

        final html.Element userContent = content.querySelector('div')!;
        expect(userContent.style.height, '100%');
        expect(userContent.style.width, '100%');
      });

      test('slot property has the same value as createPlatformViewSlot', () async {
        final html.Element content =
            contentManager.renderContent(viewType, viewId, null);
        final html.Element slot = createPlatformViewSlot(viewId);
        final html.Element innerSlot = slot.querySelector('slot')!;

        expect(content.getAttribute('slot'), innerSlot.getAttribute('name'),
            reason:
                'The slot attribute of the rendered content must match the name attribute of the SLOT of a given viewId');
      });

      test('do not modify style.height / style.width if passed by the user (anotherViewType)',
          () async {
        final html.Element content =
            contentManager.renderContent(anotherViewType, viewId, null);
        final html.Element userContent = content.querySelector('div')!;
        expect(userContent.style.height, 'auto');
        expect(userContent.style.width, '55%');
      });

      test('returns cached instances of already-rendered content', () async {
        final html.Element firstRender =
            contentManager.renderContent(viewType, viewId, null);
        final html.Element anotherRender =
            contentManager.renderContent(viewType, viewId, null);

        expect(firstRender, same(anotherRender));
      });
    });
  });
}
