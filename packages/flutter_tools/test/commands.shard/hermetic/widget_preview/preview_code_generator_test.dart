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
import 'utils/preview_detector_test_utils.dart';

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

@Preview(group: 'group')
Widget barPreview1() => Text('Foo');

@Preview(brightness: brightnessConstant)
Widget barPreview2() => Text('Foo');

@Preview(
  group: 'group',
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

const kCustomPreviews = r'''
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

base class BrightnessPreview extends MultiPreview {
  const BrightnessPreview({required this.name});

  final String name;

  @override
  final previews = const <Preview>[
    Preview(name: '(Light)', brightness: Brightness.light),
    Preview(name: '(Dark)', brightness: Brightness.dark),
  ];

  Widget _wrapper(Widget child) {
    return Container(child: child);
  }

  @override
  List<Preview> transform() {
    final parentPreviews = super.transform();
    final transformed = <Preview>[];
    for (final preview in parentPreviews) {
      final builder = preview.toBuilder()
        ..name = '$name ${preview.name}'
        ..addWrapper(_wrapper);
      transformed.add(builder.build());
    }
    return transformed;
  }
}

base class FixedSizePreview extends Preview {
  const FixedSizePreview({required super.name})
    : super(size: const Size(100, 100));

  Widget _wrapper(Widget child) {
    return Container(child: child);
  }

  @override
  Preview transform() {
    final parent = super.transform();
    final builder = parent.toBuilder()
      ..name = 'FixedSizePreview: $name'
      ..addWrapper(_wrapper);
    return builder.build();
  }
}

@BrightnessPreview(name: 'Foo')
@FixedSizePreview(name: 'Bar')
Widget preview() => Text('Brightness Preview');
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
        ..childFile('lib/src/transitive_error.dart').writeAsStringSync(kTransitiveErrorLibrary)
        ..childFile('lib/src/custom_previews.dart').writeAsStringSync(kCustomPreviews);
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
        project: project,
        fs: fs,
        logger: logger,
        onChangeDetected: (_) {},
        onPubspecChangeDetected: (String path) {},
      );
      codeGenerator = PreviewCodeGenerator(
        widgetPreviewScaffoldProject: FlutterProject.fromDirectoryTest(
          project.widgetPreviewScaffold,
        ),
        fs: fs,
      );
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
        final File generatedPreviewFile = project.widgetPreviewScaffold.childFile(
          PreviewCodeGenerator.getGeneratedPreviewFilePath(fs),
        );
        expect(generatedPreviewFile, isNot(exists));
        generatedPreviewFile.createSync(recursive: true);
        final PreviewDependencyGraph details = await previewDetector.initialize();

        // Populate the generated preview file.
        codeGenerator.populatePreviewsInGeneratedPreviewScaffold(details);

        const expectedGeneratedPreviewFileContents = '''
// ignore_for_file: implementation_imports

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'widget_preview.dart' as _i1;
import 'utils.dart' as _i2;
import 'package:foo_project/foo.dart' as _i3;
import 'package:flutter/src/widget_previews/widget_previews.dart' as _i4;
import 'package:foo_project/src/bar.dart' as _i5;
import 'package:foo_project/src/brightness.dart' as _i6;
import 'dart:ui' as _i7;
import 'package:foo_project/src/wrapper.dart' as _i8;
import 'package:foo_project/src/theme.dart' as _i9;
import 'package:foo_project/src/localizations.dart' as _i10;
import 'package:foo_project/src/custom_previews.dart' as _i11;

List<_i1.WidgetPreview> previews() => [
      _i2.buildWidgetPreview(
        packageName: 'foo_project',
        scriptUri: 'STRIPPED',
        line: 4,
        column: 1,
        previewFunction: () => _i3.preview(),
        transformedPreview: const _i4.Preview().transform(),
      ),
      _i2.buildWidgetPreview(
        packageName: 'foo_project',
        scriptUri: 'STRIPPED',
        line: 10,
        column: 1,
        previewFunction: () => _i5.barPreview1(),
        transformedPreview: const _i4.Preview(group: 'group').transform(),
      ),
      _i2.buildWidgetPreview(
        packageName: 'foo_project',
        scriptUri: 'STRIPPED',
        line: 13,
        column: 1,
        previewFunction: () => _i5.barPreview2(),
        transformedPreview:
            const _i4.Preview(brightness: _i6.brightnessConstant).transform(),
      ),
      _i2.buildWidgetPreview(
        packageName: 'foo_project',
        scriptUri: 'STRIPPED',
        line: 16,
        column: 1,
        previewFunction: () => _i5.barPreview3(),
        transformedPreview: const _i4.Preview(
          group: 'group',
          name: 'Foo',
          size: _i7.Size(
            123.0,
            456.0,
          ),
          textScaleFactor: 50.0,
          wrapper: _i8.wrapper,
          brightness: _i7.Brightness.dark,
          theme: _i9.myThemeData,
          localizations: _i10.myLocalizations,
        ).transform(),
      ),
      ..._i2.buildMultiWidgetPreview(
        packageName: 'foo_project',
        scriptUri: 'STRIPPED',
        line: 51,
        column: 1,
        previewFunction: () => _i11.preview(),
        preview: const _i11.BrightnessPreview(name: 'Foo'),
      ),
      _i2.buildWidgetPreview(
        packageName: 'foo_project',
        scriptUri: 'STRIPPED',
        line: 52,
        column: 1,
        previewFunction: () => _i11.preview(),
        transformedPreview:
            const _i11.FixedSizePreview(name: 'Bar').transform(),
      ),
      _i2.buildWidgetPreviewError(
        packageName: 'foo_project',
        scriptUri: 'STRIPPED',
        line: 6,
        column: 1,
        packageUri: 'package:foo_project/src/error.dart',
        functionName: 'preview',
        dependencyHasErrors: false,
      ),
      _i2.buildWidgetPreviewError(
        packageName: 'foo_project',
        scriptUri: 'STRIPPED',
        line: 6,
        column: 1,
        packageUri: 'package:foo_project/src/transitive_error.dart',
        functionName: 'preview',
        dependencyHasErrors: true,
      ),
    ];
''';
        expect(
          generatedPreviewFile.readAsStringSync().stripScriptUris,
          expectedGeneratedPreviewFileContents,
        );

        // Regenerate the generated file with no previews.
        codeGenerator.populatePreviewsInGeneratedPreviewScaffold(
          const <PreviewPath, LibraryPreviewNode>{},
        );

        // The generated file should only contain:
        // - An import of the widget preview library
        // - A top-level function 'List<WidgetPreviewGroup> previews()' that returns an empty list.
        const emptyGeneratedPreviewFileContents = '''
// ignore_for_file: implementation_imports

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'widget_preview.dart' as _i1;

List<_i1.WidgetPreview> previews() => [];
''';
        expect(generatedPreviewFile.readAsStringSync(), emptyGeneratedPreviewFileContents);
      },
    );

    testUsingContext(
      'correctly generates ${PreviewCodeGenerator.getGeneratedDtdConnectionInfoFilePath(fs)}',
      () async {
        // Check that the generated preview file doesn't exist yet.
        final File generatedDtdConnectionInfoFile = project.widgetPreviewScaffold.childFile(
          PreviewCodeGenerator.getGeneratedDtdConnectionInfoFilePath(fs),
        );
        expect(generatedDtdConnectionInfoFile, isNot(exists));
        generatedDtdConnectionInfoFile.createSync(recursive: true);

        // Populate the DTD connection info.
        final Uri dtdUri = Uri.parse('ws://localhost:1234');
        codeGenerator.populateDtdConnectionInfo(dtdUri);

        final expectedDtdConnectionInfo =
            '''
// ignore_for_file: implementation_imports

const String kWidgetPreviewDtdUri = '$dtdUri';
''';
        expect(generatedDtdConnectionInfoFile.readAsStringSync(), expectedDtdConnectionInfo);
      },
    );
  });
}
