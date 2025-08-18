// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/signals.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/flutter_manifest.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/widget_preview/analytics.dart';
import 'package:flutter_tools/src/widget_preview/dependency_graph.dart';
import 'package:flutter_tools/src/widget_preview/preview_code_generator.dart';
import 'package:flutter_tools/src/widget_preview/preview_detector.dart';
import 'package:process/process.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';
import '../../../src/fakes.dart';

const kPubspec = '''
name: foo_project
environment:
  sdk: ^3.7.0-0

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  flutter_test:
    sdk: flutter
''';

const kFooDart = '''
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

@Preview()
Widget preview() => Text('Foo');
''';

const kBarDart = '''
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

import 'brightness.dart';
import 'localizations.dart';
import 'theme.dart';
import 'wrapper.dart';

@Preview()
Widget barPreview1() => Text('Foo');

@Preview(brightness: brightnessConstant)
Widget barPreview2() => Text('Foo');

@Preview(
  name: 'Foo',
  size: Size(123, 456),
  textScaleFactor: 50,
  wrapper: wrapper,
  brightness: Brightness.dark,
  theme: myThemeData,
  localizations: myLocalizations,
)
WidgetBuilder barPreview3() => (BuildContext context) {
  return Text('Foo');
};
''';

const kBrightnessDart = '''
import 'package:flutter/material.dart';

const Brightness brightnessConstant = Brightness.dark;
''';

const kThemeDart = '''
import 'package:flutter/widget_previews.dart';

PreviewThemeData myThemeData() => PreviewThemeData();
''';

const kWrapperDart = '''
import 'package:flutter/widgets.dart';

Widget wrapper(Widget widget) {
  return widget;
}
''';

const kLocalizationsDart = '''
import 'dart:ui';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

PreviewLocalizationsData myLocalizations() {
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
    localeListResolutionCallback: (List<Locale>? locales, Iterable<Locale> supportedLocales) => null,
    localeResolutionCallback: (Locale? locale, Iterable<Locale> supportedLocales) => null,
  );
}''';

const kErrorContainingLibrary = '''
invalid-symbol;

import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

@Preview()
Widget preview() => Text('Error in library');
''';

const kTransitiveErrorLibrary = '''
import 'error.dart';

import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

@Preview()
Widget preview() => Text('Error in dependency');
''';

// Note: this test isn't under the general.shard since tests under that directory
// have a 2000ms time out and these tests write to the real file system and watch
// directories for changes. This can be slow on heavily loaded machines and cause
// flaky failures.

void main() {
  group('$PreviewCodeGenerator', () {
    late PreviewCodeGenerator codeGenerator;
    late FlutterProject project;
    late PreviewDetector previewDetector;
    // We perform this initialization just so we can build the generated file path for test
    // descriptions.
    var fs = LocalFileSystem.test(signals: Signals.test());

    setUp(() async {
      Cache.flutterRoot = getFlutterRoot();
      // Note: we don't use a MemoryFileSystem since we don't have a way to
      // provide it to package:analyzer APIs without writing a significant amount
      // of wrapper logic.
      fs = LocalFileSystem.test(signals: Signals.test());
      final logger = BufferLogger.test();
      FlutterManifest.empty(logger: logger);
      final Directory projectDir = fs.systemTempDirectory.createTempSync('project')
        ..childDirectory('lib/src').createSync(recursive: true)
        ..childFile('pubspec.yaml').writeAsStringSync(kPubspec)
        ..childFile('lib/foo.dart').writeAsStringSync(kFooDart)
        ..childFile('lib/src/bar.dart').writeAsStringSync(kBarDart)
        ..childFile('lib/src/brightness.dart').writeAsStringSync(kBrightnessDart)
        ..childFile('lib/src/localizations.dart').writeAsStringSync(kLocalizationsDart)
        ..childFile('lib/src/wrapper.dart').writeAsStringSync(kWrapperDart)
        ..childFile('lib/src/theme.dart').writeAsStringSync(kThemeDart)
        ..childFile('lib/src/error.dart').writeAsStringSync(kErrorContainingLibrary)
        ..childFile('lib/src/transitive_error.dart').writeAsStringSync(kTransitiveErrorLibrary);
      project = FlutterProject.fromDirectoryTest(projectDir);
      previewDetector = PreviewDetector(
        platform: FakePlatform(),
        previewAnalytics: WidgetPreviewAnalytics(
          analytics: getInitializedFakeAnalyticsInstance(
            // We don't care about anything written to the file system by analytics, so we're safe
            // to use a different file system here.
            fs: MemoryFileSystem.test(),
            fakeFlutterVersion: FakeFlutterVersion(),
          ),
        ),
        projectRoot: projectDir,
        fs: fs,
        logger: logger,
        onChangeDetected: (_) {},
        onPubspecChangeDetected: (String path) {},
      );
      codeGenerator = PreviewCodeGenerator(widgetPreviewScaffoldProject: project, fs: fs);
      final pub = Pub.test(
        fileSystem: fs,
        logger: logger,
        processManager: const LocalProcessManager(),
        platform: const LocalPlatform(),
        botDetector: const FakeBotDetector(true),
        stdio: FakeStdio(),
      );
      await pub.get(context: PubContext.flutterTests, project: project);
    });

    tearDown(() async {
      // There shouldn't be any state to clean up, but this doesn't hurt.
      await previewDetector.dispose();
      project.directory.deleteSync(recursive: true);
    });

    testUsingContext(
      'correctly generates ${PreviewCodeGenerator.getGeneratedPreviewFilePath(fs)}',
      () async {
        // Check that the generated preview file doesn't exist yet.
        final File generatedPreviewFile = project.directory.childFile(
          PreviewCodeGenerator.getGeneratedPreviewFilePath(fs),
        );
        expect(generatedPreviewFile, isNot(exists));
        final PreviewDependencyGraph details = await previewDetector.initialize();

        // Populate the generated preview file.
        codeGenerator.populatePreviewsInGeneratedPreviewScaffold(details);
        expect(generatedPreviewFile, exists);

        // Check that the generated file contains:
        // - An import of the widget preview library
        // - Prefixed imports for 'foo.dart', 'src/bar.dart', 'wrapper.dart',
        //   'brightness.dart', and 'theme.dart'
        // - A top-level function 'List<WidgetPreview> previews()'
        // - A returned list containing function calls to 'preview()' from 'foo.dart' and
        //   'barPreview1()', 'barPreview2()', and 'barPreview3()' from 'src/bar.dart'
        const expectedGeneratedPreviewFileContents = '''
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'widget_preview.dart' as _i1;
import 'package:foo_project/foo.dart' as _i2;
import 'package:foo_project/src/bar.dart' as _i3;
import 'package:foo_project/src/brightness.dart' as _i4;
import 'dart:ui' as _i5;
import 'package:foo_project/src/theme.dart' as _i6;
import 'package:foo_project/src/localizations.dart' as _i7;
import 'package:foo_project/src/wrapper.dart' as _i8;
import 'package:flutter/widgets.dart' as _i9;
import 'package:flutter/material.dart' as _i10;

List<_i1.WidgetPreview> previews() => [
      _i1.WidgetPreview(
        packageName: 'foo_project',
        builder: () => _i2.preview(),
      ),
      _i1.WidgetPreview(
        packageName: 'foo_project',
        builder: () => _i3.barPreview1(),
      ),
      _i1.WidgetPreview(
        packageName: 'foo_project',
        brightness: _i4.brightnessConstant,
        builder: () => _i3.barPreview2(),
      ),
      _i1.WidgetPreview(
        packageName: 'foo_project',
        name: 'Foo',
        size: const _i5.Size(
          123,
          456,
        ),
        textScaleFactor: 50,
        theme: _i6.myThemeData(),
        brightness: _i5.Brightness.dark,
        localizations: _i7.myLocalizations(),
        builder: () => _i8.wrapper(_i9.Builder(builder: _i3.barPreview3())),
      ),
      _i1.WidgetPreview(
          builder: () =>
              _i10.Text('package:foo_project/src/error.dart has errors!')),
      _i1.WidgetPreview(
          builder: () => _i10.Text(
              'Dependency of package:foo_project/src/transitive_error.dart has errors!')),
    ];
''';
        expect(generatedPreviewFile.readAsStringSync(), expectedGeneratedPreviewFileContents);

        // Regenerate the generated file with no previews.
        codeGenerator.populatePreviewsInGeneratedPreviewScaffold(
          const <PreviewPath, LibraryPreviewNode>{},
        );
        expect(generatedPreviewFile, exists);

        // The generated file should only contain:
        // - An import of the widget preview library
        // - A top-level function 'List<WidgetPreview> previews()' that returns an empty list.
        const emptyGeneratedPreviewFileContents = '''
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'widget_preview.dart' as _i1;

List<_i1.WidgetPreview> previews() => [];
''';
        expect(generatedPreviewFile.readAsStringSync(), emptyGeneratedPreviewFileContents);
      },
    );
  });
}
