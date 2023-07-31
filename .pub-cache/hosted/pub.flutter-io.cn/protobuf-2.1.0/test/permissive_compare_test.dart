// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:protobuf/src/protobuf/permissive_compare.dart';
import 'package:test/test.dart';

void main() {
  void symmetric(String a, String b, bool expected) {
    expect(permissiveCompare(a, b), expected);
    expect(permissiveCompare(b, a), expected);
  }

  List<String> variationsFromSeed(String seed) {
    final result = [
      seed,
      seed.toUpperCase(),
      '-$seed',
      '-${seed.toUpperCase()}',
      '_$seed',
      '_${seed.toUpperCase()}',
      '$seed-',
      '${seed}_',
    ];
    if (2 <= seed.length) {
      result.add('${seed.substring(0, 1)}_${seed.substring(1)}');
      result.add('${seed.substring(0, 1)}-${seed.substring(1)}');
      result.add('${seed.substring(0, 1).toUpperCase()}${seed.substring(1)}');
      result.add('${seed.substring(0, 1)}${seed.substring(1).toUpperCase()}');
    }
    return result;
  }

  test('permissive compare', () {
    final seeds = ['', 'a', 'b', 'aa', 'ab', 'bb', 'aaaa'];
    for (final a in seeds) {
      for (final aVariant in variationsFromSeed(a)) {
        for (final b in seeds) {
          for (final bVariant in variationsFromSeed(b)) {
            symmetric(aVariant, bVariant, a == b);
          }
        }
      }
    }
  });
}
