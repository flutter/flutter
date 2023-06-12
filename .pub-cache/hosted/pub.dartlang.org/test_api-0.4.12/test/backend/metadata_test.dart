// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:boolean_selector/boolean_selector.dart';
import 'package:test/test.dart';
import 'package:test_api/src/backend/metadata.dart';
import 'package:test_api/src/backend/platform_selector.dart';
import 'package:test_api/src/backend/runtime.dart';
import 'package:test_api/src/backend/suite_platform.dart';

void main() {
  group('tags', () {
    test('parses an Iterable', () {
      expect(
          Metadata.parse(tags: ['a', 'b']).tags, unorderedEquals(['a', 'b']));
    });

    test('parses a String', () {
      expect(Metadata.parse(tags: 'a').tags, unorderedEquals(['a']));
    });

    test('parses null', () {
      expect(Metadata.parse().tags, unorderedEquals([]));
    });

    test('parse refuses an invalid type', () {
      expect(() => Metadata.parse(tags: 1), throwsArgumentError);
    });

    test('parse refuses an invalid type in a list', () {
      expect(() => Metadata.parse(tags: [1]), throwsArgumentError);
    });

    test('merges tags by computing the union of the two tag sets', () {
      var merged = Metadata(tags: ['a', 'b']).merge(Metadata(tags: ['b', 'c']));
      expect(merged.tags, unorderedEquals(['a', 'b', 'c']));
    });

    test('serializes and deserializes tags', () {
      var metadata = Metadata(tags: ['a', 'b']).serialize();
      expect(Metadata.deserialize(metadata).tags, unorderedEquals(['a', 'b']));
    });
  });

  group('constructor', () {
    test("returns the normal metadata if there's no forTag", () {
      var metadata = Metadata(verboseTrace: true, tags: ['foo', 'bar']);
      expect(metadata.verboseTrace, isTrue);
      expect(metadata.tags, equals(['foo', 'bar']));
    });

    test("returns the normal metadata if there's no tags", () {
      var metadata = Metadata(
          verboseTrace: true,
          forTag: {BooleanSelector.parse('foo'): Metadata(skip: true)});
      expect(metadata.verboseTrace, isTrue);
      expect(metadata.skip, isFalse);
      expect(metadata.forTag, contains(BooleanSelector.parse('foo')));
      expect(metadata.forTag[BooleanSelector.parse('foo')]?.skip, isTrue);
    });

    test("returns the normal metadata if forTag doesn't match tags", () {
      var metadata = Metadata(
          verboseTrace: true,
          tags: ['bar', 'baz'],
          forTag: {BooleanSelector.parse('foo'): Metadata(skip: true)});

      expect(metadata.verboseTrace, isTrue);
      expect(metadata.skip, isFalse);
      expect(metadata.tags, unorderedEquals(['bar', 'baz']));
      expect(metadata.forTag, contains(BooleanSelector.parse('foo')));
      expect(metadata.forTag[BooleanSelector.parse('foo')]?.skip, isTrue);
    });

    test('resolves forTags that match tags', () {
      var metadata = Metadata(verboseTrace: true, tags: [
        'foo',
        'bar',
        'baz'
      ], forTag: {
        BooleanSelector.parse('foo'): Metadata(skip: true),
        BooleanSelector.parse('baz'): Metadata(timeout: Timeout.none),
        BooleanSelector.parse('qux'): Metadata(skipReason: 'blah')
      });

      expect(metadata.verboseTrace, isTrue);
      expect(metadata.skip, isTrue);
      expect(metadata.skipReason, isNull);
      expect(metadata.timeout, equals(Timeout.none));
      expect(metadata.tags, unorderedEquals(['foo', 'bar', 'baz']));
      expect(metadata.forTag.keys, equals([BooleanSelector.parse('qux')]));
    });

    test('resolves forTags that adds a behavioral tag', () {
      var metadata = Metadata(tags: [
        'foo'
      ], forTag: {
        BooleanSelector.parse('baz'): Metadata(skip: true),
        BooleanSelector.parse('bar'):
            Metadata(verboseTrace: true, tags: ['baz']),
        BooleanSelector.parse('foo'): Metadata(tags: ['bar'])
      });

      expect(metadata.verboseTrace, isTrue);
      expect(metadata.skip, isTrue);
      expect(metadata.tags, unorderedEquals(['foo', 'bar', 'baz']));
      expect(metadata.forTag, isEmpty);
    });

    test('resolves forTags that adds circular tags', () {
      var metadata = Metadata(tags: [
        'foo'
      ], forTag: {
        BooleanSelector.parse('foo'): Metadata(tags: ['bar']),
        BooleanSelector.parse('bar'): Metadata(tags: ['baz']),
        BooleanSelector.parse('baz'): Metadata(tags: ['foo'])
      });

      expect(metadata.tags, unorderedEquals(['foo', 'bar', 'baz']));
      expect(metadata.forTag, isEmpty);
    });

    test('base metadata takes precedence over forTags', () {
      var metadata = Metadata(verboseTrace: true, tags: [
        'foo'
      ], forTag: {
        BooleanSelector.parse('foo'): Metadata(verboseTrace: false)
      });

      expect(metadata.verboseTrace, isTrue);
    });
  });

  group('onPlatform', () {
    test('parses a valid map', () {
      var metadata = Metadata.parse(onPlatform: {
        'chrome': Timeout.factor(2),
        'vm': [Skip(), Timeout.factor(3)]
      });

      var key = metadata.onPlatform.keys.first;
      expect(key.evaluate(SuitePlatform(Runtime.chrome)), isTrue);
      expect(key.evaluate(SuitePlatform(Runtime.vm)), isFalse);
      var value = metadata.onPlatform.values.first;
      expect(value.timeout.scaleFactor, equals(2));

      key = metadata.onPlatform.keys.last;
      expect(key.evaluate(SuitePlatform(Runtime.vm)), isTrue);
      expect(key.evaluate(SuitePlatform(Runtime.chrome)), isFalse);
      value = metadata.onPlatform.values.last;
      expect(value.skip, isTrue);
      expect(value.timeout.scaleFactor, equals(3));
    });

    test('refuses an invalid value', () {
      expect(() {
        Metadata.parse(onPlatform: {'chrome': TestOn('chrome')});
      }, throwsArgumentError);
    });

    test('refuses an invalid value in a list', () {
      expect(() {
        Metadata.parse(onPlatform: {
          'chrome': [TestOn('chrome')]
        });
      }, throwsArgumentError);
    });

    test('refuses an invalid platform selector', () {
      expect(() {
        Metadata.parse(onPlatform: {'vm &&': Skip()});
      }, throwsFormatException);
    });

    test('refuses multiple Timeouts', () {
      expect(() {
        Metadata.parse(onPlatform: {
          'chrome': [Timeout.factor(2), Timeout.factor(3)]
        });
      }, throwsArgumentError);
    });

    test('refuses multiple Skips', () {
      expect(() {
        Metadata.parse(onPlatform: {
          'chrome': [Skip(), Skip()]
        });
      }, throwsArgumentError);
    });
  });

  group('validatePlatformSelectors', () {
    test('succeeds if onPlatform uses valid platforms', () {
      Metadata.parse(onPlatform: {'vm || browser': Skip()})
          .validatePlatformSelectors({'vm'});
    });

    test('succeeds if testOn uses valid platforms', () {
      Metadata.parse(testOn: 'vm || browser').validatePlatformSelectors({'vm'});
    });

    test('fails if onPlatform uses an invalid platform', () {
      expect(() {
        Metadata.parse(onPlatform: {'unknown': Skip()})
            .validatePlatformSelectors({'vm'});
      }, throwsFormatException);
    });

    test('fails if testOn uses an invalid platform', () {
      expect(() {
        Metadata.parse(testOn: 'unknown').validatePlatformSelectors({'vm'});
      }, throwsFormatException);
    });
  });

  group('change', () {
    test('preserves all fields if no parameters are passed', () {
      var metadata = Metadata(
          testOn: PlatformSelector.parse('linux'),
          timeout: Timeout.factor(2),
          skip: true,
          skipReason: 'just because',
          verboseTrace: true,
          tags: [
            'foo',
            'bar'
          ],
          onPlatform: {
            PlatformSelector.parse('mac-os'): Metadata(skip: false)
          },
          forTag: {
            BooleanSelector.parse('slow'): Metadata(timeout: Timeout.factor(4))
          });
      expect(metadata.serialize(), equals(metadata.change().serialize()));
    });

    test('updates a changed field', () {
      var metadata = Metadata(timeout: Timeout.factor(2));
      expect(metadata.change(timeout: Timeout.factor(3)).timeout,
          equals(Timeout.factor(3)));
    });
  });
}
