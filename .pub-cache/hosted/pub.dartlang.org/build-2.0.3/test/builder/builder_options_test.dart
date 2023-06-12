// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:test/test.dart';

void main() {
  group('BuilderOptions', () {
    test('overrides with non-empty options', () {
      var defaults = const BuilderOptions({'foo': 'bar', 'baz': 'bop'});
      var overridden = defaults.overrideWith(
          const BuilderOptions({'baz': 'different', 'more': 'added'}));
      expect(overridden.config,
          {'foo': 'bar', 'baz': 'different', 'more': 'added'});
      expect(overridden.isRoot, isFalse);
    });

    test('overrides isRoot', () {
      var defaults = const BuilderOptions({}, isRoot: false);
      var overridden = defaults.overrideWith(BuilderOptions.forRoot);
      expect(overridden.isRoot, isTrue);
    });

    test('config doesnt change when overriding with empty options', () {
      var defaults = const BuilderOptions({'foo': 'bar', 'baz': 'bop'});
      var overridden = defaults.overrideWith(BuilderOptions.empty);
      expect(overridden.config, equals(defaults.config));
      expect(overridden.isRoot, equals(defaults.isRoot));
    });

    test('changes nothing when overriding with null options', () {
      var defaults = const BuilderOptions({'foo': 'bar', 'baz': 'bop'});
      var overridden = defaults.overrideWith(null);
      expect(overridden, same(defaults));
    });
  });
}
