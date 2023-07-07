// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('browser') // Uses package:js

import 'package:google_identity_services_web/loader.dart';
import 'package:google_identity_services_web/src/js_interop/dom.dart' as dom;
import 'package:google_identity_services_web/src/js_loader.dart';

import 'package:js/js_util.dart' as js_util;

import 'package:test/test.dart';

// NOTE: This file needs to be separated from the others because Content
// Security Policies can never be *relaxed* once set.
//
// In order to not introduce a dependency in the order of the tests, we split
// them in different files, depending on the strictness of their CSP:
//
// * js_loader_test.dart : default TT configuration (not enforced)
// * js_loader_tt_custom_test.dart : TT are customized, but allowed
// * js_loader_tt_forbidden_test.dart: TT are completely disallowed

void main() {
  group('loadWebSdk (no TrustedTypes)', () {
    final dom.DomHtmlElement target = dom.document.createElement('div');

    test('Injects script into desired target', () async {
      loadWebSdk(target: target);

      // Target now should have a child that is a script element
      final Object children = js_util.getProperty<Object>(target, 'children');
      final Object injected = js_util.callMethod<Object>(
        children,
        'item',
        <Object>[0],
      );
      expect(injected, isA<dom.DomHtmlScriptElement>());

      final dom.DomHtmlScriptElement script =
          injected as dom.DomHtmlScriptElement;
      expect(js_util.getProperty<bool>(script, 'defer'), isTrue);
      expect(js_util.getProperty<bool>(script, 'async'), isTrue);
      expect(
        js_util.getProperty<String>(script, 'src'),
        'https://accounts.google.com/gsi/client',
      );
    });

    test('Completes when the script loads', () async {
      final Future<void> loadFuture = loadWebSdk(target: target);

      Future<void>.delayed(const Duration(milliseconds: 100), () {
        // Simulate the library calling `window.onGoogleLibraryLoad`.
        js_util.callMethod<void>(
          js_util.globalThis,
          'onGoogleLibraryLoad',
          <Object>[],
        );
      });

      await expectLater(loadFuture, completes);
    });
  });
}
