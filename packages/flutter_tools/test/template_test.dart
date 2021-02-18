// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/template.dart';
import 'package:flutter_tools/src/template.dart';
import 'src/common.dart';

void main() {
  testWithoutContext('Template.render throws ToolExit when FileSystem exception is raised', () {
    final FileExceptionHandler handler = FileExceptionHandler();
    final MemoryFileSystem fileSystem = MemoryFileSystem.test(opHandle: handler.opHandle);
    final Template template = Template(
      fileSystem.directory('examples'),
      fileSystem.currentDirectory,
      null,
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      templateRenderer: FakeTemplateRenderer(),
      templateManifest: null,
    );
    final Directory directory = fileSystem.directory('foo');
    handler.addError(directory, FileSystemOp.create, const FileSystemException());

    expect(() => template.render(directory, <String, Object>{}),
      throwsToolExit());
  });

  testWithoutContext('Template.render replaces .img.tmpl files with files from the image source', () {
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    final Directory templateDir = fileSystem.directory('templates');
    final Directory imageSourceDir = fileSystem.directory('template_images');
    final Directory destination = fileSystem.directory('target');
    const String imageName = 'some_image.png';
    templateDir.childFile('$imageName.img.tmpl').createSync(recursive: true);
    final File sourceImage = imageSourceDir.childFile(imageName);
    sourceImage.createSync(recursive: true);
    sourceImage.writeAsStringSync('Ceci n\'est pas une pipe');

    final Template template = Template(
      templateDir,
      templateDir,
      imageSourceDir,
      fileSystem: fileSystem,
      templateManifest: null,
      logger: BufferLogger.test(),
      templateRenderer: FakeTemplateRenderer(),
    );
    template.render(destination, <String, Object>{});

    final File destinationImage = destination.childFile(imageName);
    expect(destinationImage, exists);
    expect(destinationImage.readAsBytesSync(), equals(sourceImage.readAsBytesSync()));
  });
}

class FakeTemplateRenderer extends TemplateRenderer {
  @override
  String renderString(String template, dynamic context, {bool htmlEscapeValues = false}) {
    return '';
  }
}
