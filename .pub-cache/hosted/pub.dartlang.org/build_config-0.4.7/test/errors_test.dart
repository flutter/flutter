// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_config/build_config.dart';
import 'package:term_glyph/term_glyph.dart' as glyph;
import 'package:test/test.dart';

void main() {
  // Ensures consistent rendering on windows/linux.
  glyph.ascii = false;

  test('for missing default target', () {
    var buildYaml = r'''
targets:
  not_package_name:
    sources: ["lib/**"]
''';

    _expectThrows(buildYaml, r'''
line 2, column 3 of build.yaml: Unsupported value for "targets". Must specify a target with the name `package_name` or `$default`.
  ╷
2 │ ┌   not_package_name:
3 │ └     sources: ["lib/**"]
  ╵''');
  });

  test('for bad build extensions', () {
    var buildYaml = r'''
builders:
  some_builder:
    build_extensions:
      .dart:
      - .dart
    builder_factories: ["someFactory"]
    import: package:package_name/builders.dart
''';
    _expectThrows(buildYaml, r'''
line 4, column 7 of build.yaml: Unsupported value for "build_extensions". May not overwrite an input, the output extensions must not contain the input extension
  ╷
4 │ ┌       .dart:
5 │ │       - .dart
6 │ │     builder_factories: ["someFactory"]
  │ └────^
  ╵''');
  });

  test('for empty include globs', () {
    var buildYaml = r'''
targets:
  $default:
    builders:
      some_package:some_builder:
        generate_for:
        -
''';

    _expectThrows(buildYaml, r'''
line 6, column 9 of build.yaml: Unsupported value for "generate_for". Include globs must not be empty
  ╷
6 │         -
  │         ^
  ╵''');
  });
}

void _expectThrows(String buildYaml, Object matcher) => expect(
    () => BuildConfig.parse('package_name', [], buildYaml,
        configYamlPath: 'build.yaml'),
    _throwsError(matcher));

Matcher _throwsError(Object matcher) => throwsA(
      isA<ArgumentError>().having(
        (e) {
          printOnFailure("ACTUAL\nr'''\n${e.message}'''");
          return e.message;
        },
        'message',
        matcher,
      ),
    );
