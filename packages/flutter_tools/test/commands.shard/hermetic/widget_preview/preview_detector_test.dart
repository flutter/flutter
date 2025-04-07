// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

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
      final List<PreviewDetails> expectedPreviewDetails = <PreviewDetails>[
        PreviewDetails.test(functionName: 'previews', isBuilder: false, name: 'Top-level preview'),
        PreviewDetails.test(
          functionName: 'builderPreview',
          isBuilder: true,
          name: 'Builder preview',
        ),
        PreviewDetails.test(
          functionName: 'attributesPreview',
          isBuilder: false,
          name: 'Attributes preview',
          width: '100.0',
          height: '100',
          textScaleFactor: '2',
          wrapper: 'testWrapper',
        ),
        PreviewDetails.test(
          functionName: 'MyWidget.preview',
          isBuilder: false,
          name: 'Constructor preview',
        ),
        PreviewDetails.test(
          functionName: 'MyWidget.factoryPreview',
          isBuilder: false,
          name: 'Factory constructor preview',
        ),
        PreviewDetails.test(
          functionName: 'MyWidget.previewStatic',
          isBuilder: false,
          name: 'Static preview',
        ),
      ];

      // Create two files with existing previews and one without.
      final PreviewMapping expectedInitialMapping = <PreviewPath, List<PreviewDetails>>{
        addPreviewContainingFile(projectRoot, <String>['foo.dart']): expectedPreviewDetails,
        addPreviewContainingFile(projectRoot, <String>['src', 'bar.dart']): expectedPreviewDetails,
      };
      final PreviewPath nonPreviewContainingFile = addNonPreviewContainingFile(
        projectRoot,
        <String>['baz.dart'],
      );

      Completer<void> completer = Completer<void>();
      onChangeDetected = (PreviewMapping updated) {
        // The new preview in baz.dart should be included in the preview mapping.
        expect(stripNonDeterministicFields(updated), <PreviewPath, List<PreviewDetails>>{
          ...expectedInitialMapping,
          nonPreviewContainingFile: expectedPreviewDetails,
        });
        completer.complete();
      };
      // Initialize the file watcher.
      final PreviewMapping initialPreviews = await previewDetector.initialize();
      expect(stripNonDeterministicFields(initialPreviews), expectedInitialMapping);

      // Update the file without an existing preview to include a preview and ensure it triggers
      // the preview detector.
      addPreviewContainingFile(projectRoot, <String>['baz.dart']);
      await completer.future;

      completer = Completer<void>();
      onChangeDetected = (PreviewMapping updated) {
        // The removed preview in baz.dart should not longer be included in the preview mapping.
        expect(stripNonDeterministicFields(updated), expectedInitialMapping);
        completer.complete();
      };

      // Update the file with an existing preview to remove the preview and ensure it triggers
      // the preview detector.
      addNonPreviewContainingFile(projectRoot, <String>['baz.dart']);
      await completer.future;
    });

    testUsingContext('can detect previews in newly added files', () async {
      final List<PreviewDetails> expectedPreviewDetails = <PreviewDetails>[
        PreviewDetails.test(functionName: 'previews', isBuilder: false, name: 'Top-level preview'),
        PreviewDetails.test(
          functionName: 'builderPreview',
          isBuilder: true,
          name: 'Builder preview',
        ),
        PreviewDetails.test(
          functionName: 'attributesPreview',
          isBuilder: false,
          name: 'Attributes preview',
          width: '100.0',
          height: '100',
          textScaleFactor: '2',
          wrapper: 'testWrapper',
        ),
        PreviewDetails.test(
          functionName: 'MyWidget.preview',
          isBuilder: false,
          name: 'Constructor preview',
        ),
        PreviewDetails.test(
          functionName: 'MyWidget.factoryPreview',
          isBuilder: false,
          name: 'Factory constructor preview',
        ),
        PreviewDetails.test(
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
        expect(stripNonDeterministicFields(updated), <PreviewPath, List<PreviewDetails>>{
          previewContainingFilePath: expectedPreviewDetails,
        });
        completer.complete();
      };

      // Initialize the file watcher.
      final PreviewMapping initialPreviews = await previewDetector.initialize();
      expect(stripNonDeterministicFields(initialPreviews), expectedInitialMapping);

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

/// Creates a copy of [mapping] with [PreviewDetails] entries that have non-deterministic values
/// that differ per run (e.g., temporary file paths).
PreviewMapping stripNonDeterministicFields(PreviewMapping mapping) {
  return mapping.map<PreviewPath, List<PreviewDetails>>((
    PreviewPath key,
    List<PreviewDetails> value,
  ) {
    return MapEntry<PreviewPath, List<PreviewDetails>>(
      key,
      value.map((PreviewDetails details) => details.copyWith(wrapperLibraryUri: '')).toList(),
    );
  });
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

@Preview(name: 'Attributes preview', height: 100, width: 100.0, textScaleFactor: 2, wrapper: testWrapper)
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
