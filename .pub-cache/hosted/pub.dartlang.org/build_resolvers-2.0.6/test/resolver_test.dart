// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:isolate';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:build/build.dart';
import 'package:build/experiments.dart';
import 'package:build_resolvers/src/analysis_driver.dart';
import 'package:build_resolvers/src/resolver.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:package_config/package_config.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  final entryPoint = AssetId('a', 'web/main.dart');

  group('Resolver', () {
    test('should handle initial files', () {
      return resolveSources({
        'a|web/main.dart': ' main() {}',
      }, (resolver) async {
        var lib = await resolver.libraryFor(entryPoint);
        expect(lib, isNotNull);
      }, resolvers: AnalyzerResolvers());
    });

    test('should follow imports', () {
      return resolveSources({
        'a|web/main.dart': '''
              import 'a.dart';

              main() {
              } ''',
        'a|web/a.dart': '''
              library a;
              ''',
      }, (resolver) async {
        var lib = await resolver.libraryFor(entryPoint);
        expect(lib.importedLibraries.length, 2);
        var libA = lib.importedLibraries.where((l) => l.name == 'a').single;
        expect(libA.getType('Foo'), isNull);
      }, resolvers: AnalyzerResolvers());
    });

    test('should follow package imports', () {
      return resolveSources({
        'a|web/main.dart': '''
              import 'package:b/b.dart';

              main() {
              } ''',
        'b|lib/b.dart': '''
              library b;
              ''',
      }, (resolver) async {
        var lib = await resolver.libraryFor(entryPoint);
        expect(lib.importedLibraries.length, 2);
        var libB = lib.importedLibraries.where((l) => l.name == 'b').single;
        expect(libB.getType('Foo'), isNull);
      }, resolvers: AnalyzerResolvers());
    });

    test('should still crawl transitively after a call to isLibrary', () {
      return resolveSources({
        'a|web/main.dart': '''
              import 'package:b/b.dart';

              main() {
              } ''',
        'b|lib/b.dart': '''
              library b;
              ''',
      }, (resolver) async {
        await resolver.isLibrary(entryPoint);
        var libs = await resolver.libraries.toList();
        expect(libs, contains(predicate((LibraryElement l) => l.name == 'b')));
      }, resolvers: AnalyzerResolvers());
    });

    test('should still crawl transitively after a call to compilationUnitFor',
        () {
      return resolveSources({
        'a|web/main.dart': '''
              import 'package:b/b.dart';

              main() {
              } ''',
        'b|lib/b.dart': '''
              library b;
              ''',
      }, (resolver) async {
        await resolver.compilationUnitFor(entryPoint);
        var libs = await resolver.libraries.toList();
        expect(libs, contains(predicate((LibraryElement l) => l.name == 'b')));
      }, resolvers: AnalyzerResolvers());
    });

    group('language versioning', () {
      test('gives a correct languageVersion based on comments', () async {
        await resolveSources({
          'a|web/main.dart': '// @dart=2.1\n\nmain() {}',
        }, (resolver) async {
          var lib = await resolver.libraryFor(entryPoint);
          expect(lib.languageVersion.effective.major, 2);
          expect(lib.languageVersion.effective.minor, 1);
        }, resolvers: AnalyzerResolvers());
      });

      test('defaults to the current isolate package config', () async {
        await resolveSources({
          'a|web/main.dart': 'main() {}',
        }, (resolver) async {
          var buildResolversId =
              AssetId('build_resolvers', 'lib/build_resolvers.dart');
          var lib = await resolver.libraryFor(buildResolversId);
          var currentPackageConfig =
              await loadPackageConfigUri((await Isolate.packageConfig)!);
          var expectedVersion =
              currentPackageConfig['build_resolvers']!.languageVersion!;
          expect(lib.languageVersion.effective.major, expectedVersion.major);
          expect(lib.languageVersion.effective.minor, expectedVersion.minor);
        }, resolvers: AnalyzerResolvers());
      });

      test('uses the overridden package config if provided', () async {
        // An arbitrary past version that could never be selected for this
        // package.
        var customVersion = LanguageVersion(2, 1);
        var customPackageConfig = PackageConfig([
          Package('a', Uri.file('/fake/a/'),
              packageUriRoot: Uri.file('/fake/a/lib/'),
              languageVersion: customVersion)
        ]);
        await resolveSources({
          'a|web/main.dart': 'main() {}',
        }, (resolver) async {
          var lib = await resolver.libraryFor(entryPoint);
          expect(lib.languageVersion.effective.major, customVersion.major);
          expect(lib.languageVersion.effective.minor, customVersion.minor);
        }, resolvers: AnalyzerResolvers(null, null, customPackageConfig));
      });

      test('gives the current language version if not provided', () async {
        var customPackageConfig = PackageConfig([
          Package('a', Uri.file('/fake/a/'),
              packageUriRoot: Uri.file('/fake/a/lib/'), languageVersion: null),
        ]);
        await resolveSources({
          'a|web/main.dart': 'main() {}',
        }, (resolver) async {
          var lib = await resolver.libraryFor(entryPoint);
          expect(lib.languageVersion.effective.major, sdkLanguageVersion.major);
          expect(lib.languageVersion.effective.minor, sdkLanguageVersion.minor);
        }, resolvers: AnalyzerResolvers(null, null, customPackageConfig));
      });

      test('allows a version of analyzer compatibile with the current sdk',
          () async {
        var originalLevel = Logger.root.level;
        Logger.root.level = Level.WARNING;
        var listener = Logger.root.onRecord.listen((record) {
          fail('Got an unexpected warning during analysis:\n\n$record');
        });
        addTearDown(() {
          Logger.root.level = originalLevel;
          listener.cancel();
        });
        await resolveSources({
          'a|web/main.dart': 'main() {}',
        }, (resolver) async {
          await resolver.libraryFor(entryPoint);
        }, resolvers: AnalyzerResolvers());
      }, skip: _skipOnPreRelease);
    });

    group('assets that aren\'t a transitive import of input', () {
      Future _runWith(Future Function(Resolver) test) {
        return resolveSources({
          'a|web/main.dart': '''
          main() {}
        ''',
          'a|lib/other.dart': '''
          library other;
        '''
        }, test, resolvers: AnalyzerResolvers());
      }

      test('can be resolved', () {
        return _runWith((resolver) async {
          final main = await resolver.libraryFor(entryPoint);
          expect(main, isNotNull);

          final other =
              await resolver.libraryFor(AssetId.parse('a|lib/other.dart'));
          expect(other.name, 'other');
        });
      });

      test('are included in library stream', () {
        return _runWith((resolver) async {
          expect(resolver.libraries.map((l) => l.name), neverEmits('other'));

          await resolver.libraryFor(entryPoint);

          expect(resolver.libraries.map((l) => l.name), emits('other'));
        });
      });

      test('can be found by name', () {
        return _runWith((resolver) async {
          await resolver.libraryFor(entryPoint);

          expect(resolver.findLibraryByName('other'), completion(isNotNull));
        });
      });
    });

    test('handles missing files', () {
      return resolveSources({
        'a|web/main.dart': '''
              import 'package:b/missing.dart';

              part 'missing.g.dart';

              main() {
              } ''',
      }, (resolver) async {
        var lib = await resolver.libraryFor(entryPoint);
        expect(lib.imports.length, 2);
        expect(lib.parts.length, 1);
      }, resolvers: AnalyzerResolvers());
    });

    test('handles discovering previously missing parts', () async {
      var resolvers = AnalyzerResolvers();
      await resolveSources({
        'a|web/main.dart': '''
              part 'main.g.dart';

              class A implements B {}
              ''',
      }, (resolver) async {
        var lib = await resolver.libraryFor(entryPoint);
        var clazz = lib.getType('A');
        expect(clazz, isNotNull);
        expect(clazz!.interfaces, isEmpty);
      }, resolvers: resolvers);

      await resolveSources({
        'a|web/main.dart': '''
              part 'main.g.dart';

              class A implements B {}
              ''',
        'a|web/main.g.dart': '''
              part of 'main.dart';
              class B {}
              ''',
      }, (resolver) async {
        var lib = await resolver.libraryFor(entryPoint);
        var clazz = lib.getType('A');
        expect(clazz, isNotNull);
        expect(clazz!.interfaces, hasLength(1));
        expect(clazz.interfaces.first.getDisplayString(withNullability: false),
            'B');
      }, resolvers: resolvers);
    });

    test('should list all libraries', () {
      return resolveSources({
        'a|web/main.dart': '''
              library a.main;
              import 'package:a/a.dart';
              import 'package:a/b.dart';
              export 'package:a/d.dart';
              ''',
        'a|lib/a.dart': 'library a.a;\n import "package:a/c.dart";',
        'a|lib/b.dart': 'library a.b;\n import "c.dart";',
        'a|lib/c.dart': 'library a.c;',
        'a|lib/d.dart': 'library a.d;'
      }, (resolver) async {
        var libs = await resolver.libraries.where((l) => !l.isInSdk).toList();
        expect(
            libs.map((l) => l.name),
            unorderedEquals([
              'a.main',
              'a.a',
              'a.b',
              'a.c',
              'a.d',
            ]));
      }, resolvers: AnalyzerResolvers());
    });

    test('should resolve types and library uris', () {
      return resolveSources({
        'a|web/main.dart': '''
              // dart and dart-ext uris should be ignored
              import 'dart:core';
              import 'dart-ext:some-ext';

              // package: and relative uris should be available
              import 'package:a/a.dart';
              import 'package:a/b.dart';
              import 'sub_dir/d.dart';
              class Foo {}
              ''',
        'a|lib/a.dart': 'library a.a;\n import "package:a/c.dart";',
        'a|lib/b.dart': 'library a.b;\n import "c.dart";',
        'a|lib/c.dart': '''
                library a.c;
                class Bar {}
                ''',
        'a|web/sub_dir/d.dart': '''
                library a.web.sub_dir.d;
                class Baz{}
                ''',
      }, (resolver) async {
        var a = await resolver.findLibraryByName('a.a');
        expect(a, isNotNull);

        var main = await resolver.findLibraryByName('');
        expect(main, isNotNull);
      }, resolvers: AnalyzerResolvers());
    });

    test('resolves constants transitively', () {
      return resolveSources({
        'a|web/main.dart': '''
              library web.main;

              import 'package:a/dont_resolve.dart';
              export 'package:a/dont_resolve.dart';

              class Foo extends Bar {}
              ''',
        'a|lib/dont_resolve.dart': '''
              library a.dont_resolve;

              const int annotation = 0;
              @annotation
              class Bar {}''',
      }, (resolver) async {
        var main = (await resolver.findLibraryByName('web.main'))!;
        var meta = main.getType('Foo')!.supertype!.element.metadata[0];
        expect(meta, isNotNull);
        expect(meta.computeConstantValue()?.toIntValue(), 0);
      }, resolvers: AnalyzerResolvers());
    });

    test('handles circular imports', () {
      return resolveSources({
        'a|web/main.dart': '''
                library main;
                import 'package:a/a.dart'; ''',
        'a|lib/a.dart': '''
                library a;
                import 'package:a/b.dart'; ''',
        'a|lib/b.dart': '''
                library b;
                import 'package:a/a.dart'; ''',
      }, (resolver) async {
        var libs = await resolver.libraries.map((lib) => lib.name).toList();
        expect(libs.contains('a'), isTrue);
        expect(libs.contains('b'), isTrue);
      }, resolvers: AnalyzerResolvers());
    });

    test('assetIdForElement', () {
      return resolveSources({
        'a|lib/a.dart': '''
              import 'b.dart';

              main() {
                SomeClass();
              } ''',
        'a|lib/b.dart': '''
            class SomeClass {}
              ''',
      }, (resolver) async {
        var entry = await resolver.libraryFor(AssetId('a', 'lib/a.dart'));
        var classDefinition = entry.importedLibraries
            .map((l) => l.getType('SomeClass'))
            .singleWhere((c) => c != null)!;
        expect(await resolver.assetIdForElement(classDefinition),
            AssetId('a', 'lib/b.dart'));
      }, resolvers: AnalyzerResolvers());
    });

    test('assetIdForElement throws for ambigious elements', () {
      return resolveSources({
        'a|lib/a.dart': '''
              import 'b.dart';

              class SomeClass {}

              main() {
                SomeClass();
              } ''',
        'a|lib/b.dart': '''
            class SomeClass {}
              ''',
      }, (resolver) async {
        var entry = await resolver.libraryFor(AssetId('a', 'lib/a.dart'));
        var classDefinition = entry.importedLibraries
            .map((l) => l.getType('SomeClass'))
            .singleWhere((c) => c != null)!;
        expect(() => resolver.assetIdForElement(classDefinition),
            throwsA(isA<UnresolvableAssetException>()));
      }, resolvers: AnalyzerResolvers());
    });

    test('Respects withEnabledExperiments', () async {
      Logger.root.level = Level.ALL;
      Logger.root.onRecord.listen(print);
      await withEnabledExperiments(
          () => resolveSources({
                'a|web/main.dart': '''
// @dart=${sdkLanguageVersion.major}.${sdkLanguageVersion.minor}
int? get x => 1;
                ''',
              }, (resolver) async {
                var lib = await resolver.libraryFor(entryPoint);
                expect(lib.languageVersion.effective.major,
                    sdkLanguageVersion.major);
                expect(lib.languageVersion.effective.minor,
                    sdkLanguageVersion.minor);
                var errors = await lib.session.getErrors('/a/web/main.dart')
                    as ErrorsResult;
                expect(errors.errors, isEmpty);
              }, resolvers: AnalyzerResolvers()),
          ['non-nullable']);
    }, skip: _skipOnPreRelease);

    test('can get a new analysis session after resolving additional assets',
        () async {
      var resolvers = AnalyzerResolvers();
      await resolveSources({
        'a|web/main.dart': '',
        'a|web/other.dart': '',
      }, (resolver) async {
        var lib = await resolver.libraryFor(entryPoint);
        expect(await resolver.isLibrary(AssetId('a', 'web/other.dart')), true);
        var newLib =
            await resolver.libraryFor(await resolver.assetIdForElement(lib));
        expect(await newLib.session.getResolvedLibraryByElement(newLib),
            isA<ResolvedLibraryResult>());
      }, resolvers: resolvers);
    });

    group('syntax errors', () {
      test('are reported', () {
        return resolveSources({
          'a|errors.dart': '''
             library a_library;

             void withSyntaxErrors() {
               String x = ;
             }
          ''',
        }, (resolver) async {
          await expectLater(
            resolver.libraryFor(AssetId.parse('a|errors.dart')),
            throwsA(isA<SyntaxErrorInAssetException>()),
          );
          await expectLater(
            resolver.compilationUnitFor(AssetId.parse('a|errors.dart')),
            throwsA(isA<SyntaxErrorInAssetException>()),
          );
        });
      });

      test('are reported for part files with errors', () {
        return resolveSources({
          'a|lib.dart': '''
            library a_library;
            part 'errors.dart';
            part 'does_not_exist.dart';
          ''',
          'a|errors.dart': '''
             part of 'lib.dart';

             void withSyntaxErrors() {
               String x = ;
             }
          ''',
        }, (resolver) async {
          await expectLater(
            resolver.libraryFor(AssetId.parse('a|lib.dart')),
            throwsA(
              isA<SyntaxErrorInAssetException>()
                  .having((e) => e.syntaxErrors, 'syntaxErrors', hasLength(1)),
            ),
          );
          await expectLater(
            resolver.compilationUnitFor(AssetId.parse('a|errors.dart')),
            throwsA(
              isA<SyntaxErrorInAssetException>()
                  .having((e) => e.syntaxErrors, 'syntaxErrors', hasLength(1)),
            ),
          );
        });
      });

      test('are not reported when disabled', () {
        return resolveSources({
          'a|errors.dart': '''
             library a_library;

             void withSyntaxErrors() {
               String x = ;
             }
          ''',
        }, (resolver) async {
          await expectLater(
            resolver.libraryFor(AssetId.parse('a|errors.dart'),
                allowSyntaxErrors: true),
            completion(isNotNull),
          );
          await expectLater(
            resolver.compilationUnitFor(AssetId.parse('a|errors.dart'),
                allowSyntaxErrors: true),
            completion(isNotNull),
          );
        });
      });

      test('are truncated if necessary', () {
        return resolveSources({
          'a|errors.dart': '''
             library a_library;

             void withSyntaxErrors() {
               String x = ;
               String x = ;
               String x = ;
               String x = ;
               String x = ;
             }
          ''',
        }, (resolver) async {
          var expectation = throwsA(
            isA<SyntaxErrorInAssetException>().having(
              (e) => e.toString(),
              'toString()',
              contains(RegExp(r'And \d more')),
            ),
          );
          await expectLater(
            resolver.libraryFor(AssetId.parse('a|errors.dart')),
            expectation,
          );
          await expectLater(
            resolver.compilationUnitFor(AssetId.parse('a|errors.dart')),
            expectation,
          );
        });
      });

      test('do not report semantic errors', () {
        return resolveSources({
          'a|errors.dart': '''
             library a_library;

             void withSemanticErrors() {
               String x = withSemanticErrors();
               String x = null;
             }
          ''',
        }, (resolver) async {
          await expectLater(
            resolver.libraryFor(AssetId.parse('a|errors.dart')),
            completion(isNotNull),
          );
          await expectLater(
            resolver.compilationUnitFor(AssetId.parse('a|errors.dart')),
            completion(isNotNull),
          );
        });
      });
    });
  });

  test('throws when reading a part-of file', () {
    return resolveSources(
      {
        'a|lib/a.dart': '''
          part 'b.dart';
        ''',
        'a|lib/b.dart': '''
          part of 'a.dart';
        '''
      },
      (resolver) async {
        final assetId = AssetId.parse('a|lib/b.dart');
        await expectLater(
          () => resolver.libraryFor(assetId),
          throwsA(const TypeMatcher<NonLibraryAssetException>()
              .having((e) => e.assetId, 'assetId', equals(assetId))),
        );
      },
    );
  });

  group('The ${isFlutter ? 'flutter' : 'dart'} sdk', () {
    test('can${isFlutter ? '' : ' not'} resolve types from dart:ui', () async {
      return resolveSources({
        'a|lib/a.dart': '''
              import 'dart:ui';

              class MyClass {
                final Color color;

                MyClass(this.color);
              } ''',
      }, (resolver) async {
        var entry = await resolver.libraryFor(AssetId('a', 'lib/a.dart'));
        var classDefinition = entry.getType('MyClass')!;
        var color = classDefinition.getField('color')!;

        if (isFlutter) {
          expect(color.type.element!.name, equals('Color'));
          expect(color.type.element!.library!.name, equals('dart.ui'));
          expect(
              color.type.element!.library!.definingCompilationUnit.source.uri
                  .toString(),
              equals('dart:ui'));
        } else {
          expect(color.type.element!.name, equals('dynamic'));
        }
      }, resolvers: AnalyzerResolvers());
    });
  });

  test('generated part files are not considered libraries', () async {
    var writer = InMemoryAssetWriter();
    var reader = InMemoryAssetReader.shareAssetCache(writer.assets);
    var input = AssetId('a', 'lib/input.dart');
    writer.assets[input] = utf8.encode("part 'input.a.dart';");

    var builder = TestBuilder(
        buildExtensions: {
          '.dart': ['.a.dart']
        },
        build: (buildStep, buildExtensions) async {
          var isLibrary = await buildStep.resolver.isLibrary(buildStep.inputId);
          if (buildStep.inputId == input) {
            await buildStep.writeAsString(
                buildStep.inputId
                    .changeExtension(buildExtensions['.dart']!.first),
                "part of 'input.dart';");
            expect(isLibrary, true);
          } else {
            expect(isLibrary, false,
                reason:
                    '${buildStep.inputId} should not be considered a library');
          }
        });
    var resolvers = AnalyzerResolvers();
    await runBuilder(builder, [input], reader, writer, resolvers);

    await runBuilder(
        builder, [input.changeExtension('.a.dart')], reader, writer, resolvers);
  });

  test('missing files are not considered libraries', () async {
    var writer = InMemoryAssetWriter();
    var reader = InMemoryAssetReader.shareAssetCache(writer.assets);
    var input = AssetId('a', 'lib/input.dart');
    writer.assets[input] = utf8.encode('void doStuff() {}');

    var builder = TestBuilder(
        buildExtensions: {
          '.dart': ['.a.dart']
        },
        build: expectAsync2((buildStep, _) async {
          expect(
              await buildStep.resolver.isLibrary(
                  buildStep.inputId.changeExtension('doesnotexist.dart')),
              false);
        }));
    var resolvers = AnalyzerResolvers();
    await runBuilder(builder, [input], reader, writer, resolvers);
  });

  test('assets with extensions other than `.dart` are not considered libraries',
      () async {
    var writer = InMemoryAssetWriter();
    var reader = InMemoryAssetReader.shareAssetCache(writer.assets);
    var input = AssetId('a', 'lib/input.dart');
    writer.assets[input] = utf8.encode('void doStuff() {}');

    var otherFile = AssetId('a', 'lib/input.notdart');
    writer.assets[otherFile] = utf8.encode('Not a Dart file');

    var builder = TestBuilder(
        buildExtensions: {
          '.dart': ['.a.dart']
        },
        build: expectAsync2((buildStep, _) async {
          var other = buildStep.inputId.changeExtension('.notdart');
          expect(await buildStep.canRead(other), true);
          expect(await buildStep.resolver.isLibrary(other), false);
        }));
    var resolvers = AnalyzerResolvers();
    await runBuilder(builder, [input], reader, writer, resolvers);
  });

  group('compilationUnitFor', () {
    test('can parse a given input', () {
      return resolveSources({
        'a|web/main.dart': ' main() {}',
      }, (resolver) async {
        var unit = await resolver.compilationUnitFor(entryPoint);
        expect(unit, isNotNull);
        expect(unit.declarations.length, 1);
        expect(
            unit.declarations.first,
            isA<FunctionDeclaration>()
                .having((d) => d.name.name, 'main', 'main'));
      }, resolvers: AnalyzerResolvers());
    });
  });

  group('astNodeFor', () {
    test('can return an unresolved ast', () {
      return resolveSources({
        'a|web/main.dart': ' main() {}',
      }, (resolver) async {
        var lib = await resolver.libraryFor(entryPoint);
        var unit = await resolver.astNodeFor(lib.topLevelElements.first);
        expect(unit, isA<FunctionDeclaration>());
        expect(unit!.toSource(), 'main() {}');
        expect((unit as FunctionDeclaration).declaredElement, isNull);
      }, resolvers: AnalyzerResolvers());
    });

    test('can return an resolved ast', () {
      return resolveSources({
        'a|web/main.dart': 'main() {}',
      }, (resolver) async {
        var lib = await resolver.libraryFor(entryPoint);
        var unit = await resolver.astNodeFor(lib.topLevelElements.first,
            resolve: true);
        expect(
          unit,
          isA<FunctionDeclaration>()
              .having((fd) => fd.toSource(), 'toSource()', 'main() {}')
              .having((fd) => fd.declaredElement, 'declaredElement', isNotNull),
        );
      }, resolvers: AnalyzerResolvers());
    });

    test(
        'can get an unresolved AstNode for an old Element after resolving '
        'additional assets', () async {
      var resolvers = AnalyzerResolvers();
      await resolveSources({
        'a|web/main.dart': 'int x;',
      }, (resolver) async {
        var lib = await resolver.libraryFor(entryPoint);
        var x = lib.topLevelElements.firstWhere((x) => !x.isSynthetic);
        expect(x.name, 'x');
        (x.library!.session.resourceProvider as MemoryResourceProvider)
            .modifyFile('/a/web/main.dart', 'int x = 1;');

        // Validate that direct session usage would throw
        expect(() => lib.session.getParsedLibraryByElement(x.library!),
            throwsA(isA<InconsistentAnalysisException>()),
            skip: 'https://github.com/dart-lang/build/issues/3202');

        var astNode = await resolver.astNodeFor(x);
        expect(astNode, isA<VariableDeclaration>());
        expect((astNode as VariableDeclaration).name.name, 'x');
        expect(astNode.declaredElement, isNull);
      }, resolvers: resolvers);
    });

    test(
        'can get a resolved AstNode for an old Element after resolving '
        'additional assets', () async {
      var resolvers = AnalyzerResolvers();
      await resolveSources({
        'a|web/main.dart': 'int x;',
      }, (resolver) async {
        var lib = await resolver.libraryFor(entryPoint);
        var x = lib.topLevelElements.firstWhere((x) => !x.isSynthetic);
        expect(x.name, 'x');
        (x.library!.session.resourceProvider as MemoryResourceProvider)
            .modifyFile('/a/web/main.dart', 'int x = 1;');

        // Validate that direct session usage would throw
        expect(() => lib.session.getParsedLibraryByElement(x.library!),
            throwsA(isA<InconsistentAnalysisException>()),
            skip: 'https://github.com/dart-lang/build/issues/3202');

        var astNode = await resolver.astNodeFor(x, resolve: true);
        expect(astNode, isA<VariableDeclaration>());
        expect((astNode as VariableDeclaration).name.name, 'x');
        expect(astNode.declaredElement, isNotNull);
      }, resolvers: resolvers);
    });

    test('library results can be used even if the session is invalidated',
        () async {
      var resolvers = AnalyzerResolvers();
      await resolveSources({
        'a|web/main.dart': 'int x;',
      }, (resolver) async {
        var lib = await resolver.libraryFor(entryPoint);
        var x = lib.topLevelElements.firstWhere((x) => !x.isSynthetic);
        expect(x.name, 'x');
        var originalResult = await lib.session
            .getResolvedLibrary(lib.source.fullName) as ResolvedLibraryResult;
        (x.library!.session.resourceProvider as MemoryResourceProvider)
            .modifyFile('/a/web/main.dart', 'int x = 1;');

        // Validate that direct session usage would throw
        expect(() => lib.session.getResolvedLibrary(lib.source.fullName),
            throwsA(isA<InconsistentAnalysisException>()),
            skip: 'https://github.com/dart-lang/build/issues/3202');

        var astNode = originalResult.getElementDeclaration(x)!.node;
        expect(astNode, isA<VariableDeclaration>());
        expect((astNode as VariableDeclaration).name.name, 'x');
        expect(astNode.declaredElement, isNotNull);
      }, resolvers: resolvers);
    });
  });
}

final _skipOnPreRelease =
    Version.parse(Platform.version.split(' ').first).isPreRelease
        ? 'Skipped on prerelease sdks'
        : null;
