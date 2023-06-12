// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'package:build_runner/src/build_script_generate/builder_ordering.dart';

import 'package:_test_common/build_configs.dart';

void main() {
  group('Builder ordering', () {
    test('orders builders with `runs_before`', () async {
      final buildConfigs = parseBuildConfigs({
        'a': {
          'builders': {
            'runs_second': {
              'builder_factories': ['createBuilder'],
              'build_extensions': <String, List<String>>{},
              'target': '',
              'import': '',
            },
            'runs_first': {
              'builder_factories': ['createBuilder'],
              'build_extensions': {},
              'target': '',
              'import': '',
              'runs_before': [':runs_second'],
            },
          }
        }
      });
      final orderedBuilders = findBuilderOrder(
          buildConfigs.values.expand((v) => v.builderDefinitions.values));
      final orderedKeys = orderedBuilders.map((b) => b.key);
      expect(orderedKeys, ['a:runs_first', 'a:runs_second']);
    });

    test('orders builders with `required_inputs`', () async {
      final buildConfigs = parseBuildConfigs({
        'a': {
          'builders': {
            'runs_second': {
              'builder_factories': ['createBuilder'],
              'build_extensions': {},
              'target': '',
              'import': '',
              'required_inputs': ['.first_output'],
            },
            'runs_first': {
              'builder_factories': ['createBuilder'],
              'build_extensions': {
                '.anything': ['.first_output']
              },
              'target': '',
              'import': '',
            },
          }
        }
      });
      final orderedBuilders = findBuilderOrder(
          buildConfigs.values.expand((v) => v.builderDefinitions.values));
      final orderedKeys = orderedBuilders.map((b) => b.key);
      expect(orderedKeys, ['a:runs_first', 'a:runs_second']);
    });

    test('disallows cycles', () async {
      final buildConfigs = parseBuildConfigs({
        'a': {
          'builders': {
            'builder_a': {
              'builder_factories': ['createBuilder'],
              'build_extensions': {},
              'target': '',
              'import': '',
              'required_inputs': ['.output_b'],
              'runs_before': [':builder_b'],
            },
            'builder_b': {
              'builder_factories': ['createBuilder'],
              'build_extensions': {
                '.anything': ['.output_b']
              },
              'target': '',
              'import': '',
            },
          }
        }
      });
      expect(
          () => findBuilderOrder(
              buildConfigs.values.expand((v) => v.builderDefinitions.values)),
          throwsA(anything));
    });
  });
}
