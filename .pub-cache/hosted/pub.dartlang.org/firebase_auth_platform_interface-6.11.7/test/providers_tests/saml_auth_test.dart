// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';

void main() {
  late TestSAMLAuthProvider samlAuthProvider;
  const String kMockProviderId = 'saml';
  setUpAll(() {
    samlAuthProvider = TestSAMLAuthProvider(kMockProviderId);
  });

  group('$SAMLAuthProvider', () {
    group('Constructor', () {
      test('returns an instance of [SAMLAuthProvider] ', () {
        expect(samlAuthProvider, isA<SAMLAuthProvider>());
        expect(samlAuthProvider, isA<AuthProvider>());
        expect(samlAuthProvider.providerId, equals(kMockProviderId));
      });
    });
  });
}

class TestSAMLAuthProvider extends SAMLAuthProvider {
  TestSAMLAuthProvider(String providerId) : super(providerId);
}
