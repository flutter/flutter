// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dart_style/dart_style.dart';
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/widget_preview/dtd_types.dart';
import 'package:flutter_tools/src/widget_preview/preview_code_generator.dart';
import 'package:pub_semver/pub_semver.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';

void main() {
  group('$PreviewCodeGenerator', () {
    late PreviewCodeGenerator codeGenerator;
    late FlutterProject project;
    var fs = MemoryFileSystem.test();

    setUp(() {
      fs = MemoryFileSystem.test();
      final Directory projectDir = fs.currentDirectory.childDirectory('project')..createSync();
      project = FlutterProject.fromDirectoryTest(projectDir);
      codeGenerator = PreviewCodeGenerator(
        widgetPreviewScaffoldProject: FlutterProject.fromDirectoryTest(
          project.widgetPreviewScaffold,
        ),
        fs: fs,
      );
    });

    testUsingContext(
      'correctly generates ${PreviewCodeGenerator.getGeneratedPreviewFilePath(fs)} for LSP updates',
      () async {
        final File generatedPreviewFile = project.widgetPreviewScaffold.childFile(
          PreviewCodeGenerator.getGeneratedPreviewFilePath(fs),
        );
        expect(generatedPreviewFile, isNot(exists));
        generatedPreviewFile.createSync(recursive: true);

        final update = FlutterWidgetPreviews(
          namespaces: <String, String>{
            'widget_preview.dart': '_i1',
            'utils.dart': '_i2',
            'package:foo_project/foo.dart': '_i3',
            'package:flutter/src/widget_previews/widget_previews.dart': '_i4',
            'package:foo_project/src/custom_previews.dart': '_i5',
            'package:foo_project/src/error.dart': '_i6',
          },
          previews: <FlutterWidgetPreviewDetails>[
            FlutterWidgetPreviewDetails(
              functionName: 'preview',
              hasError: false,
              dependencyHasErrors: false,
              isBuilder: false,
              isMultiPreview: false,
              packageName: 'foo_project',
              position: const Position(character: 1, line: 4),
              previewAnnotation: 'const _i4.Preview()',
              scriptUri: Uri.file('/user/flutter_project/lib/foo.dart'),
              libraryUri: Uri.parse('package:foo_project/foo.dart'),
            ),
            FlutterWidgetPreviewDetails(
              functionName: 'multiPreview',
              hasError: false,
              dependencyHasErrors: false,
              isBuilder: false,
              isMultiPreview: true,
              packageName: 'foo_project',
              position: const Position(character: 1, line: 10),
              previewAnnotation: "const _i5.BrightnessPreview(name: 'Foo')",
              scriptUri: Uri.file('/user/flutter_project/lib/src/custom_previews.dart'),
              libraryUri: Uri.parse('package:foo_project/src/custom_previews.dart'),
            ),
            FlutterWidgetPreviewDetails(
              functionName: 'errorPreview',
              hasError: true,
              dependencyHasErrors: false,
              isBuilder: false,
              isMultiPreview: false,
              packageName: 'foo_project',
              position: const Position(character: 1, line: 6),
              previewAnnotation: 'const _i4.Preview()',
              scriptUri: Uri.file('/user/flutter_project/lib/src/error.dart'),
              libraryUri: Uri.parse('package:foo_project/src/error.dart'),
            ),
          ],
          scriptUris: <Uri>[
            Uri.file('/user/flutter_project/lib/foo.dart'),
            Uri.file('/user/flutter_project/lib/src/custom_previews.dart'),
            Uri.file('/user/flutter_project/lib/src/error.dart'),
          ],
        );

        codeGenerator.populatePreviewsInGeneratedPreviewScaffoldLsp(update);

        const expectedGeneratedPreviewFileContents = '''
// ignore_for_file: implementation_imports

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'widget_preview.dart' as _i1;
import 'utils.dart' as _i2;
import 'package:foo_project/foo.dart' as _i3;
import 'package:flutter/src/widget_previews/widget_previews.dart' as _i4;
import 'package:foo_project/src/custom_previews.dart' as _i5;
import 'package:foo_project/src/error.dart' as _i6;

List<_i1.WidgetPreview> previews() => [
  _i2.buildWidgetPreview(
    packageName: 'foo_project',
    scriptUri: 'file:///user/flutter_project/lib/foo.dart',
    line: 4,
    column: 1,
    previewFunction: () => _i3.preview(),
    transformedPreview: const _i4.Preview().transform(),
  ),
  ..._i2.buildMultiWidgetPreview(
    packageName: 'foo_project',
    scriptUri: 'file:///user/flutter_project/lib/src/custom_previews.dart',
    line: 10,
    column: 1,
    previewFunction: () => _i5.multiPreview(),
    preview: const _i5.BrightnessPreview(name: 'Foo'),
  ),
  _i2.buildWidgetPreviewError(
    packageName: 'foo_project',
    scriptUri: 'file:///user/flutter_project/lib/src/error.dart',
    line: 6,
    column: 1,
    packageUri: 'package:foo_project/src/error.dart',
    functionName: 'errorPreview',
    dependencyHasErrors: false,
  ),
];
''';
        expect(generatedPreviewFile.readAsStringSync(), expectedGeneratedPreviewFileContents);
      },
    );

    testUsingContext('ignores previews with null packageName for LSP updates', () async {
      final File generatedPreviewFile = project.widgetPreviewScaffold.childFile(
        PreviewCodeGenerator.getGeneratedPreviewFilePath(fs),
      );
      generatedPreviewFile.createSync(recursive: true);

      final update = FlutterWidgetPreviews(
        namespaces: <String, String>{
          'widget_preview.dart': '_i1',
          'utils.dart': '_i2',
          'package:foo_project/preview.dart': '_i3',
          'preview.dart': '_i4',
          'package:flutter/src/widget_previews/widget_previews.dart': '_i5',
        },
        previews: <FlutterWidgetPreviewDetails>[
          FlutterWidgetPreviewDetails(
            functionName: 'validPreview',
            hasError: false,
            dependencyHasErrors: false,
            isBuilder: false,
            isMultiPreview: false,
            packageName: 'foo_project',
            position: const Position(character: 1, line: 4),
            previewAnnotation: "const _i5.Preview(name: 'valid')",
            scriptUri: Uri.file('/user/flutter_project/lib/preview.dart'),
            libraryUri: Uri.parse('package:foo_project/preview.dart'),
          ),
          FlutterWidgetPreviewDetails(
            functionName: 'rootPreview',
            hasError: false,
            dependencyHasErrors: false,
            isBuilder: false,
            isMultiPreview: false,
            position: const Position(character: 1, line: 4),
            previewAnnotation: "const _i5.Preview(name: 'root')",
            scriptUri: Uri.file('/user/flutter_project/preview.dart'),
            libraryUri: Uri.parse('preview.dart'),
          ),
        ],
        scriptUris: <Uri>[
          Uri.file('/user/flutter_project/lib/preview.dart'),
          Uri.file('/user/flutter_project/preview.dart'),
        ],
      );

      codeGenerator.populatePreviewsInGeneratedPreviewScaffoldLsp(update);

      const expectedGeneratedPreviewFileContents = '''
// ignore_for_file: implementation_imports

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'widget_preview.dart' as _i1;
import 'utils.dart' as _i2;
import 'package:foo_project/preview.dart' as _i3;
import 'preview.dart' as _i4;
import 'package:flutter/src/widget_previews/widget_previews.dart' as _i5;

List<_i1.WidgetPreview> previews() => [
  _i2.buildWidgetPreview(
    packageName: 'foo_project',
    scriptUri: 'file:///user/flutter_project/lib/preview.dart',
    line: 4,
    column: 1,
    previewFunction: () => _i3.validPreview(),
    transformedPreview: const _i5.Preview(name: 'valid').transform(),
  ),
];
''';
      expect(generatedPreviewFile.readAsStringSync(), expectedGeneratedPreviewFileContents);
    });

    testUsingContext(
      'correctly generates ${PreviewCodeGenerator.getGeneratedDtdConnectionInfoFilePath(fs)}',
      () async {
        final File generatedDtdConnectionInfoFile = project.widgetPreviewScaffold.childFile(
          PreviewCodeGenerator.getGeneratedDtdConnectionInfoFilePath(fs),
        );
        expect(generatedDtdConnectionInfoFile, isNot(exists));
        generatedDtdConnectionInfoFile.createSync(recursive: true);

        final Uri dtdUri = Uri.parse('ws://localhost:1234');
        codeGenerator.populateDtdConnectionInfo(
          dtdUri: dtdUri,
          widgetPreviewServiceName: 'widget-preview-service',
          widgetPreviewScaffoldStreamName: 'widget-preview-stream',
          projectRootPath: project.directory.absolute.path,
        );

        final String expectedDtdConnectionInfo = DartFormatter(languageVersion: Version.none)
            .format('''
// ignore_for_file: implementation_imports

const String kWidgetPreviewDtdUri = '$dtdUri';
const String kWidgetPreviewService = 'widget-preview-service';
const String kWidgetPreviewScaffoldStream = 'widget-preview-stream';
const String kProjectRootPath = r'${project.directory.absolute.path}';
''');
        expect(generatedDtdConnectionInfoFile.readAsStringSync(), expectedDtdConnectionInfo);
      },
    );
  });
}
