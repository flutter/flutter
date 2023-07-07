// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('browser')
import 'package:firebase_core_web/firebase_core_web.dart';
import 'package:flutter_test/flutter_test.dart';

import 'tools.dart';

// NOTE: This file needs to be separated from the others because Content
// Security Policies can never be *relaxed* once set.

void main() {
  group('injectScript (TrustedTypes configured)', () {
    injectMetaTag(<String, String>{
      'http-equiv': 'Content-Security-Policy',
      'content': "trusted-types flutterfire-firebase_core 'allow-duplicates';",
    });

    test('Should inject Firebase Core script properly', () {
      final coreWeb = FirebaseCoreWeb();
      final version = coreWeb.firebaseSDKVersion;
      final Future<void> done = coreWeb.injectSrcScript(
        'https://www.gstatic.com/firebasejs/$version/firebase-app.js',
        'firebase_core',
      );

      expect(done, isA<Future<void>>());
    });
  });
}
