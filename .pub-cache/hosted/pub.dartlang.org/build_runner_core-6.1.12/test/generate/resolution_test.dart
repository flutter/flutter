// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:test/test.dart';

import 'package:_test_common/test_phases.dart';

void main() {
  test('should resolve a dart file with a part file', () async {
    await testBuilders([
      applyToRoot(ListClassesAndHierarchyBuilder())
    ], {
      'a|lib/a.dart': r'''
        library a;

        part 'a_impl.dart';

        class Example {}
      ''',
      'a|lib/a_impl.dart': r'''
        part of a;

        class ExamplePrime implements Example {}
      ''',
    }, outputs: {
      'a|lib/a.txt': ''
          'Example: [Object]\n'
          'ExamplePrime: [Object, Example]\n',
    });
  });
}

class ListClassesAndHierarchyBuilder implements Builder {
  @override
  Future<void> build(BuildStep buildStep) async {
    // Ignore part files.
    if (!await buildStep.resolver.isLibrary(buildStep.inputId)) {
      return;
    }
    // Process both the main and part files of a given library.
    final library = await buildStep.inputLibrary;
    final types = [
      library.definingCompilationUnit.types,
      library.parts.map((p) => p.types).expand((t) => t),
    ].expand((t) => t);
    final output = StringBuffer();
    final outputId = buildStep.inputId.changeExtension('.txt');
    for (final type in types) {
      output
        ..write('${type.name}: [')
        ..writeAll(type.allSupertypes.map((t) => t.element.name), ', ')
        ..writeln(']');
    }
    await buildStep.writeAsString(outputId, output.toString());
  }

  @override
  final buildExtensions = const {
    'dart': ['txt'],
  };
}
