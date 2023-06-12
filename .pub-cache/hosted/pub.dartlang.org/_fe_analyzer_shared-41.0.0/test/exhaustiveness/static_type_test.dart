// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/exhaustiveness/static_type.dart';
import 'package:test/test.dart';

void main() {
  group('isSubtypeOf()', () {
    var a = StaticType('A');
    var b = StaticType('B', inherits: [a]);
    var b2 = StaticType('B2', inherits: [a]);
    var c = StaticType('C', inherits: [b]);
    var d = StaticType('D', inherits: [c]);

    test('subtype includes self', () {
      expect(a.isSubtypeOf(a), isTrue);
      expect(b.isSubtypeOf(b), isTrue);
      expect(c.isSubtypeOf(c), isTrue);
      expect(d.isSubtypeOf(d), isTrue);
    });

    test('immediate', () {
      expect(a.isSubtypeOf(b), isFalse);
      expect(b.isSubtypeOf(a), isTrue);

      expect(b.isSubtypeOf(c), isFalse);
      expect(c.isSubtypeOf(b), isTrue);

      expect(c.isSubtypeOf(d), isFalse);
      expect(d.isSubtypeOf(c), isTrue);
    });

    test('transitive', () {
      expect(a.isSubtypeOf(c), isFalse);
      expect(c.isSubtypeOf(a), isTrue);

      expect(b.isSubtypeOf(d), isFalse);
      expect(d.isSubtypeOf(b), isTrue);

      expect(a.isSubtypeOf(d), isFalse);
      expect(d.isSubtypeOf(a), isTrue);
    });

    test('unrelated', () {
      expect(b.isSubtypeOf(b2), isFalse);
      expect(b2.isSubtypeOf(b), isFalse);

      expect(c.isSubtypeOf(b2), isFalse);
      expect(b2.isSubtypeOf(c), isFalse);

      expect(d.isSubtypeOf(b2), isFalse);
      expect(b2.isSubtypeOf(d), isFalse);
    });

    test('multiple supertypes', () {
      //      I1   I2   I3
      //        \ /  \ /
      //        I12  I23
      //           \/
      //          I123
      var i1 = StaticType('I1');
      var i2 = StaticType('I2');
      var i3 = StaticType('I3');
      var i12 = StaticType('I12', inherits: [i1, i2]);
      var i23 = StaticType('I12', inherits: [i2, i3]);
      var i123 = StaticType('I12', inherits: [i12, i23]);

      expect(i1.isSubtypeOf(i2), isFalse);
      expect(i2.isSubtypeOf(i1), isFalse);
      expect(i2.isSubtypeOf(i3), isFalse);
      expect(i3.isSubtypeOf(i2), isFalse);
      expect(i1.isSubtypeOf(i3), isFalse);
      expect(i3.isSubtypeOf(i1), isFalse);

      expect(i1.isSubtypeOf(i12), isFalse);
      expect(i12.isSubtypeOf(i1), isTrue);
      expect(i2.isSubtypeOf(i12), isFalse);
      expect(i12.isSubtypeOf(i2), isTrue);
      expect(i3.isSubtypeOf(i12), isFalse);
      expect(i12.isSubtypeOf(i3), isFalse);

      expect(i1.isSubtypeOf(i23), isFalse);
      expect(i23.isSubtypeOf(i1), isFalse);
      expect(i2.isSubtypeOf(i23), isFalse);
      expect(i23.isSubtypeOf(i2), isTrue);
      expect(i3.isSubtypeOf(i23), isFalse);
      expect(i23.isSubtypeOf(i3), isTrue);

      expect(i1.isSubtypeOf(i123), isFalse);
      expect(i123.isSubtypeOf(i1), isTrue);
      expect(i2.isSubtypeOf(i123), isFalse);
      expect(i123.isSubtypeOf(i2), isTrue);
      expect(i3.isSubtypeOf(i123), isFalse);
      expect(i123.isSubtypeOf(i3), isTrue);
      expect(i12.isSubtypeOf(i123), isFalse);
      expect(i123.isSubtypeOf(i12), isTrue);
      expect(i23.isSubtypeOf(i123), isFalse);
      expect(i123.isSubtypeOf(i23), isTrue);
    });

    test('nullable', () {
      var a = StaticType('A');
      var b = StaticType('B', inherits: [a]);

      expect(StaticType.nullType.isSubtypeOf(a), isFalse);
      expect(StaticType.nullType.isSubtypeOf(b), isFalse);
      expect(StaticType.nullType.isSubtypeOf(a.nullable), isTrue);
      expect(StaticType.nullType.isSubtypeOf(b.nullable), isTrue);

      expect(a.isSubtypeOf(StaticType.nullType), isFalse);
      expect(b.isSubtypeOf(StaticType.nullType), isFalse);
      expect(a.nullable.isSubtypeOf(StaticType.nullType), isFalse);
      expect(b.nullable.isSubtypeOf(StaticType.nullType), isFalse);

      expect(a.isSubtypeOf(a.nullable), isTrue);
      expect(a.nullable.isSubtypeOf(a), isFalse);
      expect(a.nullable.isSubtypeOf(a.nullable), isTrue);

      expect(a.isSubtypeOf(b.nullable), isFalse);
      expect(a.nullable.isSubtypeOf(b), isFalse);
      expect(a.nullable.isSubtypeOf(b.nullable), isFalse);

      expect(b.isSubtypeOf(a.nullable), isTrue);
      expect(b.nullable.isSubtypeOf(a), isFalse);
      expect(b.nullable.isSubtypeOf(a.nullable), isTrue);
    });
  });

  test('fields', () {
    var a = StaticType('A');
    var b = StaticType('B');
    var c = StaticType('C', fields: {'x': a, 'y': b});
    var d = StaticType('D', fields: {'w': a});
    var e = StaticType('E', inherits: [c, d], fields: {'z': b});

    expect(a.fields, isEmpty);
    expect(b.fields, isEmpty);

    expect(c.fields, hasLength(2));
    expect(c.fields['x'], a);
    expect(c.fields['y'], b);

    // Fields are inherited.
    expect(e.fields, hasLength(4));
    expect(e.fields['x'], a);
    expect(e.fields['y'], b);
    expect(e.fields['w'], a);
    expect(e.fields['z'], b);

    // Overridden field types win.
    var f = StaticType('F', fields: {'x': a});
    var g = StaticType('G', inherits: [f], fields: {'x': b});
    expect(g.fields, hasLength(1));
    expect(g.fields['x'], b);
  });

  test('subtypes', () {
    var a = StaticType('A', isSealed: true);
    var b = StaticType('B', inherits: [a]);
    var c = StaticType('C', inherits: [a]);
    var d = StaticType('D', inherits: [c]);

    // Gets subtypes for sealed type.
    var aSubtypes = a.subtypes.toList();
    expect(aSubtypes, unorderedEquals([b, c]));

    // And unsealed.
    var cSubtypes = c.subtypes.toList();
    expect(cSubtypes, unorderedEquals([d]));
  });
}
