// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/signals.dart';
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

void populatePubspec(Directory projectRoot, String contents) {
  projectRoot.childFile('pubspec.yaml')
    ..createSync(recursive: true)
    ..writeAsStringSync(contents);
}

PreviewPath addPreviewContainingFile(Directory projectRoot, List<String> path) {
  final File file =
      projectRoot.childDirectory('lib').childFile(path.join(const LocalPlatform().pathSeparator))
        ..createSync(recursive: true)
        ..writeAsStringSync(previewContainingFileContents);
  return (path: file.path, uri: file.uri);
}

PreviewPath addNonPreviewContainingFile(Directory projectRoot, List<String> path) {
  final File file =
      projectRoot.childDirectory('lib').childFile(path.join(const LocalPlatform().pathSeparator))
        ..createSync(recursive: true)
        ..writeAsStringSync(nonPreviewContainingFileContents);
  return (path: file.path, uri: file.uri);
}

void main() {
  group('$PreviewDetector', () {
    // Note: we don't use a MemoryFileSystem since we don't have a way to
    // provide it to package:analyzer APIs without writing a significant amount
    // of wrapper logic.
    late LocalFileSystem fs;
    late Logger logger;
    late PreviewDetector previewDetector;
    late Directory projectRoot;
    void Function(PreviewMapping)? onChangeDetected;
    void Function()? onPubspecChangeDetected;

    void onChangeDetectedRoot(PreviewMapping mapping) {
      onChangeDetected!(mapping);
    }

    void onPubspecChangeDetectedRoot() {
      onPubspecChangeDetected!();
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
      onChangeDetected = null;
    });

    testUsingContext('can detect previews in existing files', () async {
      final List<PreviewPath> previewFiles = <PreviewPath>[
        addPreviewContainingFile(projectRoot, <String>['foo.dart']),
        addPreviewContainingFile(projectRoot, <String>['src', 'bar.dart']),
      ];
      addNonPreviewContainingFile(projectRoot, <String>['baz.dart']);
      final PreviewMapping mapping = await previewDetector.findPreviewFunctions(projectRoot);
      expect(mapping.keys.toSet(), previewFiles.toSet());
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
            addPreviewContainingFile(projectRoot, <String>['foo.dart']): expectedPreviewDetails,
            addPreviewContainingFile(projectRoot, <String>['src', 'bar.dart']):
                expectedPreviewDetails,
          };
      final PreviewPath nonPreviewContainingFile = addNonPreviewContainingFile(
        projectRoot,
        <String>['baz.dart'],
      );

      Completer<void> completer = Completer<void>();
      onChangeDetected = (PreviewMapping updated) {
        // The new preview in baz.dart should be included in the preview mapping.
        expect(updated, <PreviewPath, List<PreviewDetailsMatcher>>{
          ...expectedInitialMapping,
          nonPreviewContainingFile: expectedPreviewDetails,
        });
        completer.complete();
      };
      // Initialize the file watcher.
      final PreviewMapping initialPreviews = await previewDetector.initialize();
      expect(initialPreviews, expectedInitialMapping);

      // Update the file without an existing preview to include a preview and ensure it triggers
      // the preview detector.
      addPreviewContainingFile(projectRoot, <String>['baz.dart']);
      await completer.future;

      completer = Completer<void>();
      onChangeDetected = (PreviewMapping updated) {
        // The removed preview in baz.dart should not longer be included in the preview mapping.
        expect(updated, expectedInitialMapping);
        completer.complete();
      };

      // Update the file with an existing preview to remove the preview and ensure it triggers
      // the preview detector.
      addNonPreviewContainingFile(projectRoot, <String>['baz.dart']);
      await completer.future;
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
      final PreviewMapping expectedInitialMapping = <PreviewPath, List<PreviewDetails>>{};

      final Completer<void> completer = Completer<void>();
      late final PreviewPath previewContainingFilePath;
      onChangeDetected = (PreviewMapping updated) {
        if (completer.isCompleted) {
          return;
        }
        // The new previews in baz.dart should be included in the preview mapping.
        expect(updated, <PreviewPath, List<PreviewDetailsMatcher>>{
          previewContainingFilePath: expectedPreviewDetails,
        });
        completer.complete();
      };

      // Initialize the file watcher.
      final PreviewMapping initialPreviews = await previewDetector.initialize();
      expect(initialPreviews, expectedInitialMapping);

      // Create baz.dart, which contains previews.
      previewContainingFilePath = addPreviewContainingFile(projectRoot, <String>['baz.dart']);
      await completer.future;
    });

    testUsingContext('can detect changes in the pubspec.yaml', () async {
      // Create an initial pubspec.
      populatePubspec(projectRoot, 'abc');

      final Completer<void> completer = Completer<void>();
      onPubspecChangeDetected = () {
        completer.complete();
      };
      // Initialize the file watcher.
      final PreviewMapping initialPreviews = await previewDetector.initialize();
      expect(initialPreviews, isEmpty);

      // Change the contents of the pubspec and verify the callback is invoked.
      populatePubspec(projectRoot, 'foo');
      await completer.future;
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
    return matches;
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

const String kAttributesPreview = 'Attributes preview';
@Preview(name: kAttributesPreview, size: Size(100.0, 100), textScaleFactor: 2.0, wrapper: testWrapper, theme: theming, brightness: Brightness.dark)
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
