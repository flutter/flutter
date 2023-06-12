// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'package:test/test.dart';

import 'package:test_core/src/runner/configuration.dart';
import 'package:test_core/src/runner/configuration/reporters.dart';
import 'package:test_core/src/util/io.dart';

import '../../utils.dart';

void main() {
  group('merge', () {
    group('for most fields', () {
      test('if neither is defined, preserves the default', () {
        var merged = configuration().merge(configuration());
        expect(merged.help, isFalse);
        expect(merged.version, isFalse);
        expect(merged.pauseAfterLoad, isFalse);
        expect(merged.debug, isFalse);
        expect(merged.color, equals(canUseSpecialChars));
        expect(merged.configurationPath, equals('dart_test.yaml'));
        expect(merged.reporter, equals(defaultReporter));
        expect(merged.fileReporters, isEmpty);
        expect(merged.pubServeUrl, isNull);
        expect(merged.shardIndex, isNull);
        expect(merged.totalShards, isNull);
        expect(merged.testRandomizeOrderingSeed, isNull);
        expect(merged.paths.single.testPath, 'test');
      });

      test("if only the old configuration's is defined, uses it", () {
        var merged = configuration(
            help: true,
            version: true,
            pauseAfterLoad: true,
            debug: true,
            color: true,
            configurationPath: 'special_test.yaml',
            reporter: 'json',
            fileReporters: {'json': 'out.json'},
            pubServePort: 1234,
            shardIndex: 3,
            totalShards: 10,
            testRandomizeOrderingSeed: 123,
            paths: [PathConfiguration(testPath: 'bar')]).merge(configuration());

        expect(merged.help, isTrue);
        expect(merged.version, isTrue);
        expect(merged.pauseAfterLoad, isTrue);
        expect(merged.debug, isTrue);
        expect(merged.color, isTrue);
        expect(merged.configurationPath, equals('special_test.yaml'));
        expect(merged.reporter, equals('json'));
        expect(merged.fileReporters, equals({'json': 'out.json'}));
        expect(merged.pubServeUrl!.port, equals(1234));
        expect(merged.shardIndex, equals(3));
        expect(merged.totalShards, equals(10));
        expect(merged.testRandomizeOrderingSeed, 123);
        expect(merged.paths.single.testPath, 'bar');
      });

      test("if only the new configuration's is defined, uses it", () {
        var merged = configuration().merge(configuration(
            help: true,
            version: true,
            pauseAfterLoad: true,
            debug: true,
            color: true,
            configurationPath: 'special_test.yaml',
            reporter: 'json',
            fileReporters: {'json': 'out.json'},
            pubServePort: 1234,
            shardIndex: 3,
            totalShards: 10,
            testRandomizeOrderingSeed: 123,
            paths: [PathConfiguration(testPath: 'bar')]));

        expect(merged.help, isTrue);
        expect(merged.version, isTrue);
        expect(merged.pauseAfterLoad, isTrue);
        expect(merged.debug, isTrue);
        expect(merged.color, isTrue);
        expect(merged.configurationPath, equals('special_test.yaml'));
        expect(merged.reporter, equals('json'));
        expect(merged.fileReporters, equals({'json': 'out.json'}));
        expect(merged.pubServeUrl!.port, equals(1234));
        expect(merged.shardIndex, equals(3));
        expect(merged.totalShards, equals(10));
        expect(merged.testRandomizeOrderingSeed, 123);
        expect(merged.paths.single.testPath, 'bar');
      });

      test(
          "if the two configurations conflict, uses the new configuration's "
          'values', () {
        var older = configuration(
            help: true,
            version: false,
            pauseAfterLoad: true,
            debug: true,
            color: false,
            configurationPath: 'special_test.yaml',
            reporter: 'json',
            fileReporters: {'json': 'old.json'},
            pubServePort: 1234,
            shardIndex: 2,
            totalShards: 4,
            testRandomizeOrderingSeed: 0,
            paths: [PathConfiguration(testPath: 'bar')]);
        var newer = configuration(
            help: false,
            version: true,
            pauseAfterLoad: false,
            debug: false,
            color: true,
            configurationPath: 'test_special.yaml',
            reporter: 'compact',
            fileReporters: {'json': 'new.json'},
            pubServePort: 5678,
            shardIndex: 3,
            totalShards: 10,
            testRandomizeOrderingSeed: 123,
            paths: [PathConfiguration(testPath: 'blech')]);
        var merged = older.merge(newer);

        expect(merged.help, isFalse);
        expect(merged.version, isTrue);
        expect(merged.pauseAfterLoad, isFalse);
        expect(merged.debug, isFalse);
        expect(merged.color, isTrue);
        expect(merged.configurationPath, equals('test_special.yaml'));
        expect(merged.reporter, equals('compact'));
        expect(merged.fileReporters, equals({'json': 'new.json'}));
        expect(merged.pubServeUrl!.port, equals(5678));
        expect(merged.shardIndex, equals(3));
        expect(merged.totalShards, equals(10));
        expect(merged.testRandomizeOrderingSeed, 123);
        expect(merged.paths.single.testPath, 'blech');
      });
    });

    group('for chosenPresets', () {
      test('if neither is defined, preserves the default', () {
        var merged = configuration().merge(configuration());
        expect(merged.chosenPresets, isEmpty);
      });

      test("if only the old configuration's is defined, uses it", () {
        var merged = configuration(chosenPresets: ['baz', 'bang'])
            .merge(configuration());
        expect(merged.chosenPresets, equals(['baz', 'bang']));
      });

      test("if only the new configuration's is defined, uses it", () {
        var merged = configuration()
            .merge(configuration(chosenPresets: ['baz', 'bang']));
        expect(merged.chosenPresets, equals(['baz', 'bang']));
      });

      test('if both are defined, unions them', () {
        var merged = configuration(chosenPresets: ['baz', 'bang'])
            .merge(configuration(chosenPresets: ['qux']));
        expect(merged.chosenPresets, equals(['baz', 'bang', 'qux']));
      });
    });

    group('for presets', () {
      test('merges each nested configuration', () {
        var merged = configuration(presets: {
          'bang': configuration(pauseAfterLoad: true),
          'qux': configuration(color: true)
        }).merge(configuration(presets: {
          'qux': configuration(color: false),
          'zap': configuration(help: true)
        }));

        expect(merged.presets['bang']!.pauseAfterLoad, isTrue);
        expect(merged.presets['qux']!.color, isFalse);
        expect(merged.presets['zap']!.help, isTrue);
      });

      test('automatically resolves a matching chosen preset', () {
        var config = configuration(
            presets: {'foo': configuration(color: true)},
            chosenPresets: ['foo']);
        expect(config.presets, isEmpty);
        expect(config.chosenPresets, equals(['foo']));
        expect(config.knownPresets, equals(['foo']));
        expect(config.color, isTrue);
      });

      test('resolves a chosen presets in order', () {
        var config = configuration(presets: {
          'foo': configuration(color: true),
          'bar': configuration(color: false)
        }, chosenPresets: [
          'foo',
          'bar'
        ]);
        expect(config.presets, isEmpty);
        expect(config.chosenPresets, equals(['foo', 'bar']));
        expect(config.knownPresets, unorderedEquals(['foo', 'bar']));
        expect(config.color, isFalse);

        config = configuration(presets: {
          'foo': configuration(color: true),
          'bar': configuration(color: false)
        }, chosenPresets: [
          'bar',
          'foo'
        ]);
        expect(config.presets, isEmpty);
        expect(config.chosenPresets, equals(['bar', 'foo']));
        expect(config.knownPresets, unorderedEquals(['foo', 'bar']));
        expect(config.color, isTrue);
      });

      test('ignores inapplicable chosen presets', () {
        var config = configuration(presets: {}, chosenPresets: ['baz']);
        expect(config.presets, isEmpty);
        expect(config.chosenPresets, equals(['baz']));
        expect(config.knownPresets, equals(isEmpty));
      });

      test('resolves presets through merging', () {
        var config = configuration(presets: {'foo': configuration(color: true)})
            .merge(configuration(chosenPresets: ['foo']));

        expect(config.presets, isEmpty);
        expect(config.chosenPresets, equals(['foo']));
        expect(config.knownPresets, equals(['foo']));
        expect(config.color, isTrue);
      });

      test('preserves known presets through merging', () {
        var config = configuration(
            presets: {'foo': configuration(color: true)},
            chosenPresets: ['foo']).merge(configuration());

        expect(config.presets, isEmpty);
        expect(config.chosenPresets, equals(['foo']));
        expect(config.knownPresets, equals(['foo']));
        expect(config.color, isTrue);
      });
    });
  });
}
