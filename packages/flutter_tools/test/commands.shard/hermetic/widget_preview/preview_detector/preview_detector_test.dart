// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/widget_preview/analytics.dart';
import 'package:flutter_tools/src/widget_preview/dependency_graph.dart';
import 'package:flutter_tools/src/widget_preview/preview_detector.dart';
import 'package:test/test.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../../../src/common.dart';
import '../../../../src/context.dart';
import '../utils/preview_details_matcher.dart';
import '../utils/preview_detector_test_utils.dart';
import '../utils/preview_project.dart';

// Note: this test isn't under the general.shard since tests under that directory
// have a 2000ms time out and these tests write to the real file system and watch
// directories for changes. This can be slow on heavily loaded machines and cause
// flaky failures.

/// Creates a project with files containing previews that attempt to use as many widget preview
/// properties as possible.
class BasicProjectWithExhaustivePreviews extends WidgetPreviewProject {
  BasicProjectWithExhaustivePreviews._({
    required super.projectRoot,
    required List<String> pathsWithPreviews,
    required List<String> pathsWithoutPreviews,
  }) {
    final initialSources = <WidgetPreviewSourceFile>[];
    for (final path in pathsWithPreviews) {
      initialSources.add((path: path, source: _previewContainingFileContents));
      librariesWithPreviews.add(toPreviewPath(path));
    }
    for (final path in pathsWithoutPreviews) {
      initialSources.add((path: path, source: _nonPreviewContainingFileContents));
      librariesWithoutPreviews.add(toPreviewPath(path));
    }
    initialSources.forEach(writeFile);
  }
  static Future<BasicProjectWithExhaustivePreviews> create({
    required Directory projectRoot,
    required List<String> pathsWithPreviews,
    required List<String> pathsWithoutPreviews,
  }) async {
    final project = BasicProjectWithExhaustivePreviews._(
      projectRoot: projectRoot,
      pathsWithPreviews: pathsWithPreviews,
      pathsWithoutPreviews: pathsWithoutPreviews,
    );
    await project.initializePubspec();
    return project;
  }

  Map<PreviewPath, List<PreviewDetailsMatcher>> get matcherMapping =>
      <PreviewPath, List<PreviewDetailsMatcher>>{
        for (final PreviewPath path in librariesWithPreviews) path: _expectedPreviewDetails,
      };

  final librariesWithPreviews = <PreviewPath>{};
  final librariesWithoutPreviews = <PreviewPath>{};

  /// Adds a file containing previews at [path].
  void addPreviewContainingFile({required String path}) {
    writeFile((path: path, source: _previewContainingFileContents));
    final PreviewPath previewPath = toPreviewPath(path);
    librariesWithoutPreviews.remove(previewPath);
    librariesWithPreviews.add(previewPath);
  }

  /// Adds a file with no previews at [path].
  void addNonPreviewContainingFile({required String path}) {
    writeFile((path: path, source: _nonPreviewContainingFileContents));
    final PreviewPath previewPath = toPreviewPath(path);
    librariesWithPreviews.remove(previewPath);
    librariesWithoutPreviews.add(previewPath);
  }

  /// Adds a new library with a part at [path].
  ///
  /// If the file name specified by [path] is 'path.dart', the part file will be named
  /// 'path_part.dart'.
  void addLibraryWithPartsContainingPreviews({required String path}) {
    final String partPath = path.replaceAll('.dart', '_part.dart');
    writeFile((
      path: partPath,
      source:
          '''
part of '$path';

$_previewContainingFileContents
''',
    ));

    writeFile((
      path: path,
      source:
          '''
part '$partPath';
''',
    ));
    final PreviewPath previewPath = toPreviewPath(path);
    librariesWithoutPreviews.remove(previewPath);
    librariesWithPreviews.add(previewPath);
  }

  @override
  // ignore: must_call_super, always throws
  void removeDirectoryContaining(WidgetPreviewSourceFile file) {
    throw UnimplementedError('Not supported for $BasicProjectWithExhaustivePreviews');
  }

  late final _expectedPreviewDetails = <PreviewDetailsMatcher>[
    PreviewDetailsMatcher(
      packageName: packageName,
      functionName: 'previews',
      isBuilder: false,
      name: 'Top-level preview',
    ),
    PreviewDetailsMatcher(
      packageName: packageName,
      functionName: 'builderPreview',
      isBuilder: true,
      name: 'Builder preview',
    ),
    PreviewDetailsMatcher(
      packageName: packageName,
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
      packageName: packageName,
      functionName: 'MyWidget.preview',
      isBuilder: false,
      name: 'Constructor preview',
    ),
    PreviewDetailsMatcher(
      packageName: packageName,
      functionName: 'MyWidget.factoryPreview',
      isBuilder: false,
      name: 'Factory constructor preview',
    ),
    PreviewDetailsMatcher(
      packageName: packageName,
      functionName: 'MyWidget.previewStatic',
      isBuilder: false,
      name: 'Static preview',
    ),
  ];

  static const _previewContainingFileContents = '''
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

  static const _nonPreviewContainingFileContents = '''
String foo() => 'bar';
''';
}

void main() {
  initializeTestPreviewDetectorState();
  group('$PreviewDetector', () {
    // Note: we don't use a MemoryFileSystem since we don't have a way to
    // provide it to package:analyzer APIs without writing a significant amount
    // of wrapper logic.
    late PreviewDetector previewDetector;
    late BasicProjectWithExhaustivePreviews project;
    late FakeAnalytics analytics;

    setUp(() {
      previewDetector = createTestPreviewDetector();
      analytics = previewDetector.previewAnalytics.analytics as FakeAnalytics;
    });

    tearDown(() async {
      await previewDetector.dispose();
    });

    void expectNPreviewReloadTimingEvents(int n) {
      expect(analytics.sentEvents, hasLength(n));
      for (final Event event in analytics.sentEvents) {
        if (event.eventData case {
          'workflow': final String workflow,
          'variableName': final String variableName,
        }) {
          expect(workflow, WidgetPreviewAnalytics.kWorkflow);
          expect(variableName, WidgetPreviewAnalytics.kPreviewReloadTime);
        } else {
          throw StateError('${event.eventData} is missing keys!');
        }
      }
    }

    testUsingContext('can detect previews in existing files', () async {
      project = await BasicProjectWithExhaustivePreviews.create(
        projectRoot: previewDetector.projectRoot,
        pathsWithPreviews: <String>[
          'foo.dart',
          platformPath(<String>['src', 'bar.dart']),
        ],
        pathsWithoutPreviews: <String>['baz'],
      );
      final PreviewDependencyGraph mapping = await previewDetector.initialize();
      expect(mapping.nodesWithPreviews.keys, unorderedMatches(project.librariesWithPreviews));
    });

    testUsingContext('can detect previews in updated files', () async {
      // Create two files with existing previews and one without.
      project = await BasicProjectWithExhaustivePreviews.create(
        projectRoot: previewDetector.projectRoot,
        pathsWithPreviews: <String>[
          'foo.dart',
          platformPath(<String>['src', 'bar.dart']),
        ],
        pathsWithoutPreviews: <String>['baz'],
      );

      // Initialize the file watcher.
      final PreviewDependencyGraph initialPreviews = await previewDetector.initialize();
      expectContainsPreviews(initialPreviews, project.matcherMapping);
      expectNPreviewReloadTimingEvents(0);

      await waitForChangeDetected(
        onChangeDetected: (PreviewDependencyGraph updated) {
          // The new preview in baz.dart should be included in the preview mapping.
          expectContainsPreviews(updated, project.matcherMapping);
        },
        changeOperation: () => project.addPreviewContainingFile(path: 'baz.dart'),
      );
      expectNPreviewReloadTimingEvents(1);

      // Update the file with an existing preview to remove the preview and ensure it triggers
      // the preview detector.
      await waitForChangeDetected(
        onChangeDetected: (PreviewDependencyGraph updated) {
          // The removed preview in baz.dart should not longer be included in the preview mapping.
          expectContainsPreviews(updated, project.matcherMapping);
        },
        changeOperation: () => project.addNonPreviewContainingFile(path: 'baz.dart'),
      );
      expectNPreviewReloadTimingEvents(2);
    });

    testUsingContext('can detect previews in newly added files', () async {
      project = await BasicProjectWithExhaustivePreviews.create(
        projectRoot: previewDetector.projectRoot,
        pathsWithPreviews: <String>[],
        pathsWithoutPreviews: <String>[],
      );
      // The initial mapping should be empty as there's no files containing previews.
      const expectedInitialMapping = <PreviewPath, LibraryPreviewNode>{};

      // Initialize the file watcher.
      final PreviewDependencyGraph initialPreviews = await previewDetector.initialize();
      expect(initialPreviews, expectedInitialMapping);
      expectNPreviewReloadTimingEvents(0);

      await waitForChangeDetected(
        onChangeDetected: (PreviewDependencyGraph updated) {
          // The new previews in baz.dart should be included in the preview mapping.
          expectContainsPreviews(updated, project.matcherMapping);
        },
        // Create baz.dart, which contains previews.
        changeOperation: () => project.addPreviewContainingFile(path: 'baz.dart'),
      );
      expectNPreviewReloadTimingEvents(1);
    });

    testUsingContext('can detect previews in existing libraries with parts', () async {
      project =
          await BasicProjectWithExhaustivePreviews.create(
              projectRoot: previewDetector.projectRoot,
              pathsWithPreviews: <String>[],
              pathsWithoutPreviews: <String>[],
            )
            ..addLibraryWithPartsContainingPreviews(path: 'foo.dart');
      final PreviewDependencyGraph mapping = await previewDetector.initialize();
      expect(mapping.nodesWithPreviews.keys, unorderedMatches(project.librariesWithPreviews));
    });

    testUsingContext('can detect previews in newly added libraries with parts', () async {
      project = await BasicProjectWithExhaustivePreviews.create(
        projectRoot: previewDetector.projectRoot,
        pathsWithPreviews: <String>[],
        pathsWithoutPreviews: <String>[],
      );
      // The initial mapping should be empty as there's no files containing previews.
      const expectedInitialMapping = <PreviewPath, LibraryPreviewNode>{};

      final PreviewDependencyGraph mapping = await previewDetector.initialize();
      expect(mapping.nodesWithPreviews, expectedInitialMapping);
      expectNPreviewReloadTimingEvents(0);

      // Add a library with a part file, which will cause a change detected event for each file.
      await waitForNChangesDetected(
        n: 2,
        changeOperation: () => project.addLibraryWithPartsContainingPreviews(path: 'foo.dart'),
      );
      final PreviewDependencyGraph nodesWithPreviews =
          previewDetector.dependencyGraph.nodesWithPreviews;
      expect(nodesWithPreviews, isNotEmpty);
      expect(nodesWithPreviews.keys, unorderedMatches(project.librariesWithPreviews));
      expectNPreviewReloadTimingEvents(2);
    });

    testUsingContext('can detect changes in the pubspec.yaml', () async {
      // Create an initial pubspec.
      project = await BasicProjectWithExhaustivePreviews.create(
        projectRoot: previewDetector.projectRoot,
        pathsWithPreviews: <String>[],
        pathsWithoutPreviews: <String>[],
      );

      // Initialize the file watcher.
      final PreviewDependencyGraph initialPreviews = await previewDetector.initialize();
      expect(initialPreviews, isEmpty);

      // Change the contents of the pubspec and verify the callback is invoked.
      await waitForPubspecChangeDetected(changeOperation: () => project.touchPubspec());

      // There should be no reload timing events for a pubspec change.
      expectNPreviewReloadTimingEvents(0);
    });
  });
}
