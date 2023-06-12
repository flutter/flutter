// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/exhaustiveness/space.dart';
import 'package:_fe_analyzer_shared/src/exhaustiveness/static_type.dart';
import 'package:test/test.dart';

import 'utils.dart';

/// Test `subtract()` on combinations of types.
void main() {
  // Note: In the class diagrams, "(_)" means "sealed". A bare name is unsealed.
  group('sealed family', () {
    //     (A)
    //     / \
    //   (B) (C)
    //   / \   \
    //  D   E   F
    var a = StaticType('A', isSealed: true);
    var b = StaticType('B', isSealed: true, inherits: [a]);
    var c = StaticType('C', isSealed: true, inherits: [a]);
    var d = StaticType('D', inherits: [b]);
    var e = StaticType('E', inherits: [b]);
    var f = StaticType('F', inherits: [c]);

    var checkExhaustive = _makeTestFunction([a, b, c, d, e, f]);
    checkExhaustive([a], 'ABCDEF');
    checkExhaustive([b], 'BDE');
    checkExhaustive([c], 'CF');
    checkExhaustive([d], 'D');
    checkExhaustive([f], 'CF');

    checkExhaustive([a, b], 'ABCDEF');
    checkExhaustive([a, c], 'ABCDEF');
    checkExhaustive([a, d], 'ABCDEF');
    checkExhaustive([a, f], 'ABCDEF');

    checkExhaustive([b, c], 'ABCDEF');
    checkExhaustive([b, d], 'BDE');
    checkExhaustive([b, f], 'ABCDEF');

    checkExhaustive([c, d], 'CDF');
    checkExhaustive([c, e], 'CEF');
    checkExhaustive([c, f], 'CF');

    checkExhaustive([d, e], 'BDE'); // Covers B because both cases covered.
    checkExhaustive([d, f], 'CDF');
    checkExhaustive([e, f], 'CEF');

    checkExhaustive([d, e, f], 'ABCDEF'); // All cases covered.
  });

  group('sealed with many subtypes', () {
    //     (A)
    //    //|\\
    //   / /|\ \
    //  B C D E F
    var a = StaticType('A', isSealed: true);
    var b = StaticType('B', inherits: [a]);
    var c = StaticType('C', inherits: [a]);
    var d = StaticType('D', inherits: [a]);
    var e = StaticType('E', inherits: [a]);
    var f = StaticType('F', inherits: [a]);

    var checkExhaustive = _makeTestFunction([a, b, c, d, e, f]);
    checkExhaustive([a], 'ABCDEF');
    checkExhaustive([b], 'B');
    checkExhaustive([c, e], 'CE');
    checkExhaustive([b, d, f], 'BDF');
    checkExhaustive([b, c, e, f], 'BCEF');
    checkExhaustive([b, c, d, e, f], 'ABCDEF'); // Covers A.
  });

  group('sealed with multiple paths', () {
    //     (A)
    //     / \
    //   (B)  C
    //   / \ /
    //  D   E
    var a = StaticType('A', isSealed: true);
    var b = StaticType('B', isSealed: true, inherits: [a]);
    var c = StaticType('C', inherits: [a]);
    var d = StaticType('D', inherits: [b]);
    var e = StaticType('E', inherits: [b, c]);

    var checkExhaustive = _makeTestFunction([a, b, c, d, e]);
    checkExhaustive([a], 'ABCDE');
    checkExhaustive([b], 'BDE');
    checkExhaustive([c], 'CE');
    checkExhaustive([d], 'D');
    checkExhaustive([e], 'E');

    checkExhaustive([b, c], 'ABCDE');
    checkExhaustive([b, d], 'BDE');
    checkExhaustive([b, e], 'BDE');
    checkExhaustive([c, d], 'CDE');
    checkExhaustive([d, e], 'BDE');
  });

  group('sealed with unsealed supertype', () {
    //    A
    //    |
    //   (B)
    //   / \
    //  C   D
    var a = StaticType('A');
    var b = StaticType('B', isSealed: true, inherits: [a]);
    var c = StaticType('C', inherits: [b]);
    var d = StaticType('D', inherits: [b]);

    var checkExhaustive = _makeTestFunction([a, b, c, d]);
    checkExhaustive([a], 'ABCD');
    checkExhaustive([b], 'BCD');
    checkExhaustive([c], 'C');
    checkExhaustive([d], 'D');
    checkExhaustive([c, d], 'BCD');
  });

  group('sealed with single subclass', () {
    // (A)
    //  |
    // (B)
    //  |
    //  C
    var a = StaticType('A', isSealed: true);
    var b = StaticType('B', isSealed: true, inherits: [a]);
    var c = StaticType('C', inherits: [b]);

    var checkExhaustive = _makeTestFunction([a, b, c]);
    checkExhaustive([a], 'ABC');
    checkExhaustive([b], 'ABC'); // Every A must be a B, so A is covered.
    checkExhaustive([c], 'ABC'); // Every C must be a B, which must be an A.
    checkExhaustive([a, b], 'ABC');
    checkExhaustive([a, c], 'ABC');
    checkExhaustive([b, c], 'ABC');
    checkExhaustive([a, b, c], 'ABC');
  });

  group('unsealed', () {
    //      A
    //     / \
    //    B   C
    //   / \ / \
    //  D   E   F
    var a = StaticType('A');
    var b = StaticType('B', inherits: [a]);
    var c = StaticType('C', inherits: [a]);
    var d = StaticType('D', inherits: [b]);
    var e = StaticType('E', inherits: [b, c]);
    var f = StaticType('F', inherits: [c]);

    var checkExhaustive = _makeTestFunction([a, b, c, d, e, f]);
    checkExhaustive([a], 'ABCDEF');
    checkExhaustive([b], 'BDE');
    checkExhaustive([d], 'D');
    checkExhaustive([a, b], 'ABCDEF'); // Same as A.
    checkExhaustive([a, d], 'ABCDEF'); // Same as A.
    checkExhaustive([d, e], 'DE'); // Doesn't cover B because unsealed.
    checkExhaustive([d, f], 'DF');
    checkExhaustive([e, f], 'EF'); // Doesn't cover C because unsealed.
    checkExhaustive([b, f], 'BDEF');
    checkExhaustive([c, d], 'CDEF');
    checkExhaustive([d, e, f], 'DEF');
  });
}

/// Returns a function that takes a list of `types` and a string containing a
/// list of type letters that map to the types in [allTypes].
///
/// The function checks that the list of types exhaustively covers every type
/// whose name appears in the string. So:
///
///     checkExhaustive([d, e], 'bde');
///
/// Means that the union of D|E should be exhaustive over B, D, and E and not
/// exhaustive over the other types in [allTypes].
Function(List<StaticType>, String) _makeTestFunction(
    List<StaticType> allTypes) {
  assert(allTypes.length <= 6, 'Only supports up to six types.');
  var letters = 'ABCDEF';

  return (types, covered) {
    var spaces = types.map((type) => Space(type)).toList();

    for (var i = 0; i < allTypes.length; i++) {
      var value = Space(allTypes[i]);
      if (covered.contains(letters[i])) {
        expectExhaustive(value, spaces);
      } else {
        expectNotExhaustive(value, spaces);
      }
    }
  };
}
