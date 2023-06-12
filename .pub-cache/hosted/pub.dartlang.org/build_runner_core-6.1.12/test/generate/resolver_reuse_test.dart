// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build_config/build_config.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'package:build_runner_core/build_runner_core.dart';

import 'package:_test_common/common.dart';

void main() {
  group('Resolver Reuse', () {
    test('Does not remove sources due to crawling for an earlier phase',
        () async {
      // If there is an asset which can't be read by an optional phase, but can
      // be read by a later non-optional phase, and the optional phase starts
      // later we need to avoid hiding that file from the later-phased reader.
      var optionalWithResolver = TestBuilder(
          buildExtensions: appendExtension('.foo'),
          build: (buildStep, _) async {
            // Use the resolver so ensure that the entry point is crawled
            await buildStep.inputLibrary;
            // If this was non-optional then the the `.imported.dart` file would
            // not be visible, but we don't care whether it is.
            return buildStep.writeAsString(
                buildStep.inputId.addExtension('.foo'), 'anything');
          });
      var nonOptionalWritesImportedFile = TestBuilder(
          buildExtensions: replaceExtension('.dart', '.imported.dart'),
          build: (buildStep, _) => buildStep.writeAsString(
              buildStep.inputId.changeExtension('.imported.dart'),
              'class SomeClass {}'));
      var nonOptionalResolveImportedFile = TestBuilder(
          buildExtensions: appendExtension('.bar'),
          build: (buildStep, _) async {
            // Fetch the resolver so the imports get crawled.
            var inputLibrary = await buildStep.inputLibrary;
            // Force the optional builder to run
            await buildStep.canRead(buildStep.inputId.addExtension('.foo'));
            // Check that the `.imported.dart` library is still reachable
            // through the resolver.
            var importedLibrary = inputLibrary.importedLibraries.firstWhere(
                (l) => l.source.uri.path.endsWith('.imported.dart'));
            var classNames = importedLibrary.definingCompilationUnit.types
                .map((c) => c.name)
                .toList();
            return buildStep.writeAsString(
                buildStep.inputId.addExtension('.bar'), '$classNames');
          });
      await testBuilders([
        applyToRoot(optionalWithResolver, isOptional: true),
        applyToRoot(nonOptionalWritesImportedFile,
            generateFor: InputSet(include: ['lib/file.dart'])),
        applyToRoot(nonOptionalResolveImportedFile,
            generateFor: InputSet(include: ['lib/file.dart'])),
      ], {
        'a|lib/file.dart': 'import "file.imported.dart";',
      }, outputs: {
        'a|lib/file.dart.bar': '[SomeClass]',
        'a|lib/file.dart.foo': 'anything',
        'a|lib/file.imported.dart': 'class SomeClass {}',
      });
    });

    test('A hidden generated file does not poison resolving', () async {
      final slowBuilderCompleter = Completer<void>();
      final builders = [
        applyToRoot(
            TestBuilder(
                buildExtensions: replaceExtension('.dart', '.g1.dart'),
                build: (buildStep, _) async {
                  // Put the analysis driver into the bad state.
                  await buildStep.inputLibrary;
                  await buildStep.writeAsString(
                      buildStep.inputId.changeExtension('.g1.dart'),
                      'class Annotation {const Annotation();}');
                }),
            generateFor: InputSet(include: ['lib/a.dart'])),
        applyToRoot(
            TestBuilder(
                buildExtensions: replaceExtension('.dart', '.g2.dart'),
                build: (buildStep, _) async {
                  var library = await buildStep.inputLibrary;
                  var annotation = library
                      .topLevelElements.single.metadata.single
                      .computeConstantValue();
                  await buildStep.writeAsString(
                      buildStep.inputId.changeExtension('.g2.dart'),
                      '//$annotation');
                  slowBuilderCompleter.complete();
                }),
            isOptional: true,
            generateFor: InputSet(include: ['lib/a.dart'])),
        applyToRoot(
            TestBuilder(
                buildExtensions: replaceExtension('.dart', '.slow.dart'),
                build: (buildStep, _) async {
                  await slowBuilderCompleter.future;
                  await buildStep.writeAsString(
                      buildStep.inputId.changeExtension('.slow.dart'), '');
                }),
            isOptional: true,
            generateFor: InputSet(include: ['lib/b.dart'])),
        applyToRoot(
            TestBuilder(
                buildExtensions: replaceExtension('.dart', '.root'),
                build: (buildStep, _) async {
                  await buildStep.inputLibrary;
                }),
            generateFor: InputSet(include: ['lib/b.dart'])),
      ];
      await testBuilders(builders, {
        'a|lib/a.dart': '''
import 'a.g1.dart';
import 'a.g2.dart';

@Annotation()
int x() => 1;
''',
        'a|lib/b.dart': r'''
import 'a.g1.dart';
import 'a.g2.dart';
import 'b.slow.dart';
'''
      }, outputs: {
        'a|lib/a.g1.dart': 'class Annotation {const Annotation();}',
        'a|lib/a.g2.dart': '//Annotation ()',
        'a|lib/b.slow.dart': '',
      });
    });
  });
}
