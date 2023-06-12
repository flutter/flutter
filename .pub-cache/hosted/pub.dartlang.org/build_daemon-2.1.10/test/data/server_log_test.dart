// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'package:build_daemon/data/server_log.dart';

void main() {
  group('Levels', () {
    test('are comparable', () {
      for (var matcher in [lessThan, lessThanOrEqualTo]) {
        expect(Level.FINEST, matcher(Level.FINER));
        expect(Level.FINER, matcher(Level.FINE));
        expect(Level.FINE, matcher(Level.CONFIG));
        expect(Level.CONFIG, matcher(Level.INFO));
        expect(Level.INFO, matcher(Level.WARNING));
        expect(Level.WARNING, matcher(Level.SEVERE));
        expect(Level.SEVERE, matcher(Level.SHOUT));
      }

      for (var matcher in [greaterThan, greaterThanOrEqualTo]) {
        expect(Level.SHOUT, matcher(Level.SEVERE));
        expect(Level.SEVERE, matcher(Level.WARNING));
        expect(Level.WARNING, matcher(Level.INFO));
        expect(Level.INFO, matcher(Level.CONFIG));
        expect(Level.CONFIG, matcher(Level.FINE));
        expect(Level.FINE, matcher(Level.FINER));
        expect(Level.FINER, matcher(Level.FINEST));
      }

      for (var level in Level.values) {
        expect(level, lessThanOrEqualTo(level));
        expect(level, greaterThanOrEqualTo(level));
      }
    });
  });
}
