// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dev_tools/roll_dev.dart';
import 'package:test_api/test_api.dart';

void main() {
  group('parseFullTag', () {
    test('returns match on valid version input', () {
      final List<String> validTags = <String>[
        '1.2.3-dev.1.2-3-gabc123',
        'v1.2.3',
      ];
      for (final String validTag in validTags) {
        final Match match = parseFullTag(validTag);
        expect(match, isNotNull);
      }
    });
    test('returns null on invalid version input', () {
      final List<String> validTags = <String>[
        '1.2.3-1.2-3-gabc123',
        'v1.2.3',
        '1.2.3',
      ];
      for (final String validTag in validTags) {
        final Match match = parseFullTag(validTag);
        expect(match, null);
      }
    });
  });
}
