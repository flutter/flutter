// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('browser') // Uses package:js

import 'package:google_identity_services_web/loader.dart';
import 'package:google_identity_services_web/src/js_interop/dom.dart' as dom;

import 'package:test/test.dart';

import 'tools.dart';

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
  group('loadWebSdk (TrustedTypes configured)', () {
    final dom.DomHtmlElement target = dom.document.createElement('div');
    injectMetaTag(<String, String>{
      'http-equiv': 'Content-Security-Policy',
      'content': "trusted-types my-custom-policy-name 'allow-duplicates';",
    });

    test('Wrong policy name: Fail with TrustedTypesException', () {
      expect(() {
        loadWebSdk(target: target);
      }, throwsA(isA<TrustedTypesException>()));
    });

    test('Correct policy name: Completes', () {
      final Future<void> done = loadWebSdk(
        target: target,
        trustedTypePolicyName: 'my-custom-policy-name',
      );

      expect(done, isA<Future<void>>());
    });
  });
}
