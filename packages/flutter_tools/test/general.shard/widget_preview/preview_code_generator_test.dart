// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/flutter_manifest.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/widget_preview/preview_code_generator.dart';
import 'package:flutter_tools/src/widget_preview/preview_detector.dart';
import 'package:test/test.dart';

import '../../src/context.dart';

void main() {
  group('$PreviewCodeGenerator', () {
    late PreviewCodeGenerator codeGenerator;
    late FlutterProject project;

    setUp(() {
      final FileSystem fs = MemoryFileSystem.test();
      final FlutterManifest manifest = FlutterManifest.empty(logger: BufferLogger.test());
      final Directory projectDir =
          fs.currentDirectory.childDirectory('project')
            ..createSync()
            ..childDirectory('lib/src').createSync(recursive: true);
      project = FlutterProject(projectDir, manifest, manifest);
      codeGenerator = PreviewCodeGenerator(widgetPreviewScaffoldProject: project, fs: fs);
    });

    testUsingContext(
      'correctly generates ${PreviewCodeGenerator.generatedPreviewFilePath}',
      () async {
        // Check that the generated preview file doesn't exist yet.
        final File generatedPreviewFile = project.directory.childFile(
          PreviewCodeGenerator.generatedPreviewFilePath,
        );
        expect(generatedPreviewFile, isNot(exists));

        // Populate the generated preview file.
        codeGenerator.populatePreviewsInGeneratedPreviewScaffold(
          <PreviewPath, List<PreviewDetails>>{
            (path: '', uri: Uri(path: 'foo.dart')): <PreviewDetails>[
              PreviewDetails(functionName: 'preview', isBuilder: false),
            ],
            (path: '', uri: Uri(path: 'src/bar.dart')): <PreviewDetails>[
              PreviewDetails(functionName: 'barPreview1', isBuilder: false),
              PreviewDetails(functionName: 'barPreview2', isBuilder: false),
              PreviewDetails.test(
                functionName: 'barPreview3',
                isBuilder: true,
                name: 'Foo',
                width: '123',
                height: '456',
                textScaleFactor: '50',
                wrapper: 'wrapper',
                wrapperLibraryUri: 'wrapper.dart',
              ),
            ],
          },
        );
        expect(generatedPreviewFile, exists);

        // Check that the generated file contains:
        // - An import of the widget preview library
        // - Prefixed imports for both 'foo.dart' and 'src/bar.dart'
        // - A top-level function 'List<WidgetPreview> previews()'
        // - A returned list containing function calls to 'preview()' from 'foo.dart' and
        //   'barPreview1()', 'barPreview2()', and 'barPreview3()' from 'src/bar.dart'
        //
        // The generated file is unfortunately unformatted.
        const String expectedGeneratedPreviewFileContents = '''
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'widget_preview.dart' as _i1;import 'foo.dart' as _i2;import 'src/bar.dart' as _i3;import 'wrapper.dart' as _i4;import 'package:flutter/widgets.dart' as _i5;List<_i1.WidgetPreview> previews() => [_i1.WidgetPreview(builder: () => _i2.preview()), _i1.WidgetPreview(builder: () => _i3.barPreview1()), _i1.WidgetPreview(builder: () => _i3.barPreview2()), _i1.WidgetPreview(name: Foo, height: 456.0, width: 123.0, textScaleFactor: 50.0, builder: () => _i4.wrapper(_i5.Builder(builder: _i3.barPreview3())), ), ];''';
        expect(generatedPreviewFile.readAsStringSync(), expectedGeneratedPreviewFileContents);

        // Regenerate the generated file with no previews.
        codeGenerator.populatePreviewsInGeneratedPreviewScaffold(
          const <PreviewPath, List<PreviewDetails>>{},
        );
        expect(generatedPreviewFile, exists);

        // The generated file should only contain:
        // - An import of the widget preview library
        // - A top-level function 'List<WidgetPreview> previews()' that returns an empty list.
        const String emptyGeneratedPreviewFileContents = '''
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'widget_preview.dart' as _i1;List<_i1.WidgetPreview> previews() => [];''';
        expect(generatedPreviewFile.readAsStringSync(), emptyGeneratedPreviewFileContents);
      },
    );
  });
}
