// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/signals.dart';
import 'package:flutter_tools/src/widget_preview/dependency_graph.dart';
import 'package:flutter_tools/src/widget_preview/preview_details.dart';
import 'package:flutter_tools/src/widget_preview/preview_detector.dart';
import 'package:test/test.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';

// Note: this test isn't under the general.shard since tests under that directory
// have a 2000ms time out and these tests write to the real file system and watch
// directories for changes. This can be slow on heavily loaded machines and cause
// flaky failures.

Directory createBasicProjectStructure(FileSystem fs) {
  return fs.systemTempDirectory.createTempSync('root');
}

String platformPath(List<String> pathSegments) =>
    pathSegments.join(const LocalPlatform().pathSeparator);

void populatePubspec(Directory projectRoot, String contents) {
  projectRoot.childFile('pubspec.yaml')
    ..createSync(recursive: true)
    ..writeAsStringSync(contents);
}

extension on PreviewDependencyGraph {
  Map<PreviewPath, PreviewDependencyNode> get nodesWithPreviews {
    return Map<PreviewPath, PreviewDependencyNode>.fromEntries(
      entries.where(
        (MapEntry<PreviewPath, PreviewDependencyNode> element) =>
            element.value.filePreviews.isNotEmpty,
      ),
    );
  }
}

const String previewContainingFileContents = '''
@Preview(name: 'Top-level preview')
Widget previews() => Text('Foo');

@Preview(name: 'Builder preview')
WidgetBuilder builderPreview() {
  return (BuildContext context) {
    return Text('Builder');
  };
}

Widget testWrapper(Widget child) {
  return child;
}

PreviewThemeData theming() => PreviewThemeData(
  materialLight: ThemeData(colorScheme: ColorScheme.light(primary: Colors.red)),
  materialDark: ThemeData(colorScheme: ColorScheme.dark(primary: Colors.blue)),
  cupertinoLight: CupertinoThemeData(primaryColor: Colors.yellow),
  cupertinoDark: CupertinoThemeData(primaryColor: Colors.purple),
);

PreviewLocalizationsData localizations() {
  return PreviewLocalizationsData(
    locale: Locale('en'),
    localizationsDelegates: [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: [
      Locale('en'), // English
      Locale('es'), // Spanish
    ],
    localeListResolutionCallback:
        (List<Locale>? locales, Iterable<Locale> supportedLocales) => null,
    localeResolutionCallback: (Locale? locale, Iterable<Locale> supportedLocales) => null,
  );
}

const String kAttributesPreview = 'Attributes preview';
@Preview(
  name: kAttributesPreview,
  size: Size(100.0, 100),
  textScaleFactor: 2.0,
  wrapper: testWrapper,
  theme: theming,
  brightness: Brightness.dark,
  localizations: localizations,
)
Widget attributesPreview() {
  return Text('Attributes');
}

class MyWidget extends StatelessWidget {
  @Preview(name: 'Constructor preview')
  MyWidget.preview();

  @Preview(name: 'Factory constructor preview')
  MyWidget.factoryPreview() => MyWidget.preview();

  @Preview(name: 'Static preview')
  static Widget previewStatic() => Text('Static');

  @override
  Widget build(BuildContext context) {
    return Text('MyWidget');
  }
}
''';

const String nonPreviewContainingFileContents = '''
String foo() => 'bar';
''';

typedef TestSource = ({String name, String source});

void main() {
  group('$PreviewDetector', () {
    // Note: we don't use a MemoryFileSystem since we don't have a way to
    // provide it to package:analyzer APIs without writing a significant amount
    // of wrapper logic.
    late LocalFileSystem fs;
    late Logger logger;
    late PreviewDetector previewDetector;
    late Directory projectRoot;
    void Function(PreviewDependencyGraph)? onChangeDetectedImpl;
    void Function()? onPubspecChangeDetected;

    void onChangeDetectedRoot(PreviewDependencyGraph mapping) {
      onChangeDetectedImpl!(mapping);
    }

    void onPubspecChangeDetectedRoot() {
      onPubspecChangeDetected!();
    }

    PreviewPath previewPathForFile(String path) {
      final File file = projectRoot.childDirectory('lib').childFile(path);
      return (path: file.path, uri: file.uri);
    }

    PreviewPath addProjectFile(Object path, String contents) {
      final PreviewPath previewPath = switch (path) {
        final String previewPath => previewPathForFile(previewPath),
        final PreviewPath previewPath => previewPath,
        _ => throw StateError('path must be either PreviewPath or String: ${path.runtimeType}'),
      };

      fs.file(previewPath.path)
        ..createSync(recursive: true)
        ..writeAsStringSync(contents);
      return previewPath;
    }

    void removeProjectFile(Object path) {
      final PreviewPath previewPath = switch (path) {
        final String previewPath => previewPathForFile(previewPath),
        final PreviewPath previewPath => previewPath,
        _ => throw StateError('path must be either PreviewPath or String: ${path.runtimeType}'),
      };

      fs.file(previewPath.path).deleteSync();
    }

    void removeProjectDirectory(String path) {
      fs.directory(path).deleteSync(recursive: true);
    }

    PreviewPath addPreviewContainingFile(Object previewPath) =>
        addProjectFile(previewPath, previewContainingFileContents);

    PreviewPath addNonPreviewContainingFile(Object previewPath) =>
        addProjectFile(previewPath, nonPreviewContainingFileContents);

    Future<void> waitForChangeDetected({
      required void Function(PreviewDependencyGraph) onChangeDetected,
      required void Function() changeOperation,
    }) async {
      final Completer<void> completer = Completer<void>();
      onChangeDetectedImpl = (PreviewDependencyGraph updated) {
        if (completer.isCompleted) {
          return;
        }
        onChangeDetected(updated);
        completer.complete();
      };
      changeOperation();
      await completer.future;
    }

    void expectPreviewDependencyGraphIsWellFormed(
      PreviewDependencyGraph graph, {
      Set<PreviewPath> expectedFilesWithErrors = const <PreviewPath>{},
    }) {
      final Set<PreviewDependencyNode> nodesWithErrors = <PreviewDependencyNode>{};
      for (final PreviewDependencyNode node in graph.values) {
        expect(fs.file(node.previewPath.path), exists);
        if (node.hasErrors) {
          nodesWithErrors.add(node);
        }
        for (final PreviewDependencyNode upstream in node.dependedOnBy) {
          expect(upstream.dependsOn, contains(node));
        }
        for (final PreviewDependencyNode downstream in node.dependsOn) {
          expect(downstream.dependedOnBy, contains(node));
        }
      }

      // Validates that all upstream dependencies are marked as having a transitive dependency
      // containing errors.
      final Set<PreviewPath> filesWithTransitiveErrors = <PreviewPath>{};
      void dependencyHasErrorsValidator(PreviewDependencyNode node) {
        filesWithTransitiveErrors.add(node.previewPath);
        expect(node.dependencyHasErrors, true);
        node.dependedOnBy.forEach(dependencyHasErrorsValidator);
      }

      for (final PreviewDependencyNode node in nodesWithErrors) {
        filesWithTransitiveErrors.add(node.previewPath);
        node.dependedOnBy.forEach(dependencyHasErrorsValidator);
      }

      // Verify we've found all the files expected to have transitive errors.
      expect(filesWithTransitiveErrors, expectedFilesWithErrors);
    }

    Future<void> expectHasErrors({
      required void Function() changeOperation,
      required Set<PreviewPath> filesWithErrors,
    }) async {
      await waitForChangeDetected(
        onChangeDetected:
            (PreviewDependencyGraph updated) => expectPreviewDependencyGraphIsWellFormed(
              updated,
              expectedFilesWithErrors: filesWithErrors,
            ),
        changeOperation: changeOperation,
      );
    }

    Future<void> expectHasNoErrors({required void Function() changeOperation}) async {
      await expectHasErrors(
        changeOperation: changeOperation,
        filesWithErrors: const <PreviewPath>{},
      );
    }

    void expectContainsPreviews(
      Map<PreviewPath, PreviewDependencyNode> actual,
      Map<PreviewPath, List<PreviewDetailsMatcher>> expected,
    ) {
      for (final MapEntry<PreviewPath, List<PreviewDetailsMatcher>>(
            key: PreviewPath previewPath,
            value: List<PreviewDetailsMatcher> filePreviews,
          )
          in expected.entries) {
        expect(actual.containsKey(previewPath), true);
        expect(actual[previewPath]!.filePreviews, filePreviews);
      }
    }

    setUp(() {
      fs = LocalFileSystem.test(signals: Signals.test());
      projectRoot = createBasicProjectStructure(fs);
      logger = BufferLogger.test();
      previewDetector = PreviewDetector(
        projectRoot: projectRoot,
        logger: logger,
        fs: fs,
        onChangeDetected: onChangeDetectedRoot,
        onPubspecChangeDetected: onPubspecChangeDetectedRoot,
      );
    });

    tearDown(() async {
      await previewDetector.dispose();
      projectRoot.deleteSync(recursive: true);
      onChangeDetectedImpl = null;
    });

    testUsingContext('can detect previews in existing files', () async {
      final List<PreviewPath> previewFiles = <PreviewPath>[
        addPreviewContainingFile('foo.dart'),
        addPreviewContainingFile(platformPath(<String>['src', 'bar.dart'])),
      ];
      addNonPreviewContainingFile('baz.dart');
      final PreviewDependencyGraph mapping = await previewDetector.initialize();
      expect(mapping.nodesWithPreviews.keys, unorderedMatches(previewFiles));
    });

    testUsingContext('can detect previews in updated files', () async {
      final List<PreviewDetailsMatcher> expectedPreviewDetails = <PreviewDetailsMatcher>[
        PreviewDetailsMatcher(
          functionName: 'previews',
          isBuilder: false,
          name: 'Top-level preview',
        ),
        PreviewDetailsMatcher(
          functionName: 'builderPreview',
          isBuilder: true,
          name: 'Builder preview',
        ),
        PreviewDetailsMatcher(
          functionName: 'attributesPreview',
          isBuilder: false,
          nameSymbol: 'kAttributesPreview',
          size: 'Size(100.0, 100)',
          textScaleFactor: '2.0',
          wrapper: 'testWrapper',
          theme: 'theming',
          brightness: 'Brightness.dark',
          localizations: 'localizations',
        ),
        PreviewDetailsMatcher(
          functionName: 'MyWidget.preview',
          isBuilder: false,
          name: 'Constructor preview',
        ),
        PreviewDetailsMatcher(
          functionName: 'MyWidget.factoryPreview',
          isBuilder: false,
          name: 'Factory constructor preview',
        ),
        PreviewDetailsMatcher(
          functionName: 'MyWidget.previewStatic',
          isBuilder: false,
          name: 'Static preview',
        ),
      ];

      // Create two files with existing previews and one without.
      final Map<PreviewPath, List<PreviewDetailsMatcher>> expectedInitialMapping =
          <PreviewPath, List<PreviewDetailsMatcher>>{
            addPreviewContainingFile('foo.dart'): expectedPreviewDetails,
            addPreviewContainingFile(platformPath(<String>['src', 'bar.dart'])):
                expectedPreviewDetails,
          };
      final PreviewPath nonPreviewContainingFile = addNonPreviewContainingFile('baz.dart');

      // Initialize the file watcher.
      final PreviewDependencyGraph initialPreviews = await previewDetector.initialize();
      expectContainsPreviews(initialPreviews, expectedInitialMapping);

      await waitForChangeDetected(
        onChangeDetected: (PreviewDependencyGraph updated) {
          // The new preview in baz.dart should be included in the preview mapping.
          expectContainsPreviews(updated, <PreviewPath, List<PreviewDetailsMatcher>>{
            ...expectedInitialMapping,
            nonPreviewContainingFile: expectedPreviewDetails,
          });
        },
        changeOperation: () => addPreviewContainingFile('baz.dart'),
      );

      // Update the file with an existing preview to remove the preview and ensure it triggers
      // the preview detector.
      await waitForChangeDetected(
        onChangeDetected: (PreviewDependencyGraph updated) {
          // The removed preview in baz.dart should not longer be included in the preview mapping.
          expectContainsPreviews(updated, expectedInitialMapping);
        },
        changeOperation: () => addNonPreviewContainingFile('baz.dart'),
      );
    });

    testUsingContext('can detect previews in newly added files', () async {
      final List<PreviewDetailsMatcher> expectedPreviewDetails = <PreviewDetailsMatcher>[
        PreviewDetailsMatcher(
          functionName: 'previews',
          isBuilder: false,
          name: 'Top-level preview',
        ),
        PreviewDetailsMatcher(
          functionName: 'builderPreview',
          isBuilder: true,
          name: 'Builder preview',
        ),
        PreviewDetailsMatcher(
          functionName: 'attributesPreview',
          isBuilder: false,
          nameSymbol: 'kAttributesPreview',
          size: 'Size(100.0, 100)',
          textScaleFactor: '2.0',
          wrapper: 'testWrapper',
          theme: 'theming',
          brightness: 'Brightness.dark',
          localizations: 'localizations',
        ),
        PreviewDetailsMatcher(
          functionName: 'MyWidget.preview',
          isBuilder: false,
          name: 'Constructor preview',
        ),
        PreviewDetailsMatcher(
          functionName: 'MyWidget.factoryPreview',
          isBuilder: false,
          name: 'Factory constructor preview',
        ),
        PreviewDetailsMatcher(
          functionName: 'MyWidget.previewStatic',
          isBuilder: false,
          name: 'Static preview',
        ),
      ];

      // The initial mapping should be empty as there's no files containing previews.
      final PreviewDependencyGraph expectedInitialMapping = <PreviewPath, PreviewDependencyNode>{};

      late final PreviewPath previewContainingFilePath;

      // Initialize the file watcher.
      final PreviewDependencyGraph initialPreviews = await previewDetector.initialize();
      expect(initialPreviews, expectedInitialMapping);

      await waitForChangeDetected(
        onChangeDetected: (PreviewDependencyGraph updated) {
          // The new previews in baz.dart should be included in the preview mapping.
          expectContainsPreviews(updated, <PreviewPath, List<PreviewDetailsMatcher>>{
            previewContainingFilePath: expectedPreviewDetails,
          });
        },
        // Create baz.dart, which contains previews.
        changeOperation: () => previewContainingFilePath = addPreviewContainingFile('baz.dart'),
      );
    });

    testUsingContext('can detect changes in the pubspec.yaml', () async {
      // Create an initial pubspec.
      populatePubspec(projectRoot, 'abc');

      final Completer<void> completer = Completer<void>();
      onPubspecChangeDetected = () {
        completer.complete();
      };
      // Initialize the file watcher.
      final PreviewDependencyGraph initialPreviews = await previewDetector.initialize();
      expect(initialPreviews, isEmpty);

      // Change the contents of the pubspec and verify the callback is invoked.
      populatePubspec(projectRoot, 'foo');
      await completer.future;
    });

    testUsingContext('dependency graph cycle smoke test', () async {
      // Simple test to ensure graph cycles don't cause infinite recursion during traversal.
      const TestSource a = (name: 'foo.dart', source: "import 'bar.dart';");
      const TestSource b = (name: 'bar.dart', source: "import 'foo.dart';");

      final Set<PreviewPath> projectFiles = <PreviewPath>{
        addProjectFile(a.name, a.source),
        addProjectFile(b.name, b.source),
      };
      final PreviewDependencyGraph graph = await previewDetector.initialize();
      expect(graph.keys, containsAll(projectFiles));
      expectPreviewDependencyGraphIsWellFormed(graph);
    });

    group('dependency errors', () {
      const TestSource main = (
        name: 'main.dart',
        source: '''
import 'foo.dart';
void main() => foo();
''',
      );
      const TestSource foo = (
        name: 'foo.dart',
        source: '''
import 'bar.dart';
void foo() => bar();
''',
      );

      const TestSource bar = (
        name: 'bar.dart',
        source: '''
void bar() => null;
''',
      );

      late Set<PreviewPath> initialProjectFiles;

      setUp(() {
        initialProjectFiles = <PreviewPath>{
          addProjectFile(main.name, main.source),
          addProjectFile(foo.name, foo.source),
          addProjectFile(bar.name, bar.source),
        };
      });

      testUsingContext('entire directory removed', () async {
        final PreviewPath c = addProjectFile(
          platformPath(<String>['dir', 'c.dart']),
          'void foo() {}',
        );
        final Set<PreviewPath> directoryFiles = <PreviewPath>{
          addProjectFile(platformPath(<String>['dir', 'a.dart']), "import 'b.dart';"),
          addProjectFile(platformPath(<String>['dir', 'b.dart']), "import 'c.dart';"),
          c,
        };

        final PreviewDependencyGraph initialGraph = await previewDetector.initialize();
        expect(
          initialGraph.keys,
          containsAll(<PreviewPath>{...initialProjectFiles, ...directoryFiles}),
        );

        // Validate the files in dir/ all have transistive errors.
        await expectHasErrors(
          changeOperation: () => addProjectFile(c, 'invalid-symbol'),
          filesWithErrors: directoryFiles,
        );

        // Delete dir/. This will cause 3 change events to be reported, one for each file in the
        // deleted directory. Until all 3 events have been processed, the dependency graph will not
        // be consistent as the files have already been deleted on disk.
        int changeCount = 0;
        final Completer<void> completer = Completer<void>();
        onChangeDetectedImpl = (PreviewDependencyGraph _) {
          changeCount++;
          if (changeCount >= 3) {
            completer.complete();
          }
        };
        removeProjectDirectory(fs.path.dirname(directoryFiles.first.path));
        await completer.future;

        // Verify the graph is well formed once the deletion events have been processed.
        expectPreviewDependencyGraphIsWellFormed(initialGraph);
      });

      testUsingContext('smoke test', () async {
        final PreviewDependencyGraph initialGraph = await previewDetector.initialize();
        expect(initialGraph.keys, containsAll(initialProjectFiles));

        // Verify there's no errors in the project.
        for (final PreviewDependencyNode node in initialGraph.values) {
          expect(node.dependencyHasErrors, false);
          expect(node.hasErrors, false);
        }

        // Introduce an error into bar.dart and verify files that have transitive dependencies on
        // bar.dart are marked as having errors.
        await expectHasErrors(
          changeOperation: () => addProjectFile(bar.name, 'invalid-symbol'),
          filesWithErrors: initialProjectFiles,
        );

        // Remove the error from bar.dart and ensure no files have errors.
        await expectHasNoErrors(changeOperation: () => addProjectFile(bar.name, bar.source));
      });

      testUsingContext('file with error added and removed', () async {
        final PreviewDependencyGraph initialGraph = await previewDetector.initialize();
        expect(initialGraph.keys, containsAll(initialProjectFiles));

        // Verify there's no errors in the project.
        for (final PreviewDependencyNode node in initialGraph.values) {
          expect(node.dependencyHasErrors, false);
          expect(node.hasErrors, false);
        }

        // Add baz.dart, which contains errors. Since no other files import baz.dart, it should be
        // the only file with errors.
        const TestSource baz = (name: 'baz.dart', source: 'invalid.symbol');
        final PreviewPath bazPath = previewPathForFile(baz.name);
        await expectHasErrors(
          changeOperation: () => addProjectFile(bazPath, baz.source),
          filesWithErrors: <PreviewPath>{bazPath},
        );

        // Update main.dart to import baz.dart. All files in the project should now have transitive
        // errors.
        await expectHasErrors(
          changeOperation: () => addProjectFile(main.name, "import '${baz.name}';\n${main.source}"),
          filesWithErrors: <PreviewPath>{previewPathForFile(main.name), bazPath},
        );

        // Delete baz.dart. main.dart should continue to have an error.
        await expectHasErrors(
          changeOperation: () => removeProjectFile(baz.name),
          filesWithErrors: <PreviewPath>{previewPathForFile(main.name)},
        );

        // Restore main.dart to remove the baz.dart import and clear the errors.
        await expectHasNoErrors(changeOperation: () => addProjectFile(main.name, main.source));
      });

      testUsingContext(
        'error added into dependency in the middle of the graph and removed',
        () async {
          final PreviewDependencyGraph initialGraph = await previewDetector.initialize();
          expect(initialGraph.keys, containsAll(initialProjectFiles));

          // Verify there's no errors in the project.
          for (final PreviewDependencyNode node in initialGraph.values) {
            expect(node.dependencyHasErrors, false);
            expect(node.hasErrors, false);
          }

          // Add baz.dart, which contains errors. Since no other files import baz.dart, it should be
          // the only file with errors.
          final PreviewPath fooPath = previewPathForFile(foo.name);
          final PreviewPath mainPath = previewPathForFile(main.name);
          await expectHasErrors(
            changeOperation: () => addProjectFile(fooPath, 'invalid-symbol;${foo.source}'),
            filesWithErrors: <PreviewPath>{fooPath, mainPath},
          );

          // Delete baz.dart. main.dart should continue to have an error.
          await expectHasNoErrors(changeOperation: () => addProjectFile(fooPath, foo.source));
        },
      );
    });
  });
}

typedef _PreviewDetailsMatcherMismatchPair = ({Object? expected, Object? actual});

class PreviewDetailsMatcher extends Matcher {
  PreviewDetailsMatcher({
    required this.functionName,
    required this.isBuilder,
    this.name,
    this.nameSymbol,
    this.size,
    this.textScaleFactor,
    this.wrapper,
    this.theme,
    this.brightness,
    this.localizations,
  }) {
    if (name != null && nameSymbol != null) {
      fail('name and nameSymbol cannot both be provided.');
    }
  }

  final String functionName;
  final bool isBuilder;

  // Proivde when the expected expression for 'name' is a literal.
  final String? name;

  // Provide when the expected expression for 'name' is not a literal.
  final String? nameSymbol;
  final String? size;
  final String? textScaleFactor;
  final String? wrapper;
  final String? theme;
  final String? brightness;
  final String? localizations;

  @override
  Description describe(Description description) {
    description.add('PreviewDetailsMatcher');
    return description;
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map<Object?, Object?> matchState,
    bool verbose,
  ) {
    mismatchDescription.add('has the following mismatches:\n\n');
    for (final MapEntry<String, _PreviewDetailsMatcherMismatchPair>(
          :String key,
          value: _PreviewDetailsMatcherMismatchPair(:Object? actual, :Object? expected),
        )
        in matchState.cast<String, _PreviewDetailsMatcherMismatchPair>().entries) {
      mismatchDescription.add("- $key = '$actual' differs from the expected value '$expected'\n");
    }
    return mismatchDescription;
  }

  @override
  bool matches(dynamic item, Map<Object?, Object?> matchState) {
    if (item is! PreviewDetails) {
      return false;
    }

    bool matches = true;
    void checkPropertyMatch({
      required String name,
      required Object? actual,
      required Object? expected,
    }) {
      if (actual is Expression) {
        actual = actual.toSource();
      }
      if (actual != expected) {
        matchState[name] = (actual: actual, expected: expected);
        matches = false;
      }
    }

    checkPropertyMatch(name: 'functionName', actual: item.functionName, expected: functionName);
    checkPropertyMatch(name: 'isBuilder', actual: item.isBuilder, expected: isBuilder);
    checkPropertyMatch(
      name: PreviewDetails.kName,
      actual: item.name,
      expected: name != null ? "'$name'" : nameSymbol,
    );
    checkPropertyMatch(name: PreviewDetails.kSize, actual: item.size, expected: size);
    checkPropertyMatch(
      name: PreviewDetails.kTextScaleFactor,
      actual: item.textScaleFactor,
      expected: textScaleFactor,
    );
    checkPropertyMatch(name: PreviewDetails.kWrapper, actual: item.wrapper, expected: wrapper);
    checkPropertyMatch(name: PreviewDetails.kTheme, actual: item.theme, expected: theme);
    checkPropertyMatch(
      name: PreviewDetails.kBrightness,
      actual: item.brightness,
      expected: brightness,
    );
    checkPropertyMatch(
      name: PreviewDetails.kLocalizations,
      actual: item.localizations,
      expected: localizations,
    );
    return matches;
  }
}
