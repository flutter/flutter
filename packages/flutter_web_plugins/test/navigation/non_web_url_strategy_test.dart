// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('!chrome')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'common.dart';

void main() {
  group('Non-web UrlStrategy', () {
    late TestPlatformLocation location;

    setUp(() {
      location = TestPlatformLocation();
    });

    test('Can create and set a $HashUrlStrategy', () {
      expect(() {
        final strategy = HashUrlStrategy(location);
        setUrlStrategy(strategy);
      }, returnsNormally);
    });

    test('Can create and set a $PathUrlStrategy', () {
      expect(() {
        final strategy = PathUrlStrategy(location);
        setUrlStrategy(strategy);
      }, returnsNormally);
    });

    test('Can usePathUrlStrategy', () {
      expect(() {
        usePathUrlStrategy();
      }, returnsNormally);
    });
  });
}
