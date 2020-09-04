// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/template.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/template.dart';
import 'package:mockito/mockito.dart';
import 'src/common.dart';

void main() {
  testWithoutContext('Template.render throws ToolExit when FileSystem exception is raised', () {
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    final Template template = Template(
      fileSystem.directory('examples'),
      fileSystem.currentDirectory,
      null,
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      templateRenderer: FakeTemplateRenderer(),
      templateManifest: null,
    );
    final MockDirectory mockDirectory = MockDirectory();
    when(mockDirectory.createSync(recursive: true)).thenThrow(const FileSystemException());

    expect(() => template.render(mockDirectory, <String, Object>{}),
        throwsToolExit());
  });

  testWithoutContext('Template.render attempts to read byte from template file before copying', () {
    final MemoryFileSystem baseFileSystem = MemoryFileSystem.test();
    baseFileSystem.file('templates/foo.copy.tmpl').createSync(recursive: true);
    final ConfiguredFileSystem fileSystem = ConfiguredFileSystem(
      baseFileSystem,
      entities: <String, FileSystemEntity>{
        '/templates/foo.copy.tmpl': FakeFile('/templates/foo.copy.tmpl'),
      },
    );

    final Template template = Template(
      fileSystem.directory('templates'),
      fileSystem.currentDirectory,
      null,
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      templateRenderer: FakeTemplateRenderer(),
      templateManifest: null,
    );

    expect(() => template.render(fileSystem.directory('out'), <String, Object>{}),
      throwsA(isA<FileSystemException>()));
  });

  testWithoutContext('Template.render replaces .img.tmpl files with files from the image source', () {
    final MemoryFileSystem fileSystem = MemoryFileSystem();
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

  testWithoutContext('Template.fromName runs pub get if .packages is missing', () async {
    final MemoryFileSystem fileSystem = MemoryFileSystem();
    final MockPub pub = MockPub();
    when(pub.get(
      context: PubContext.pubGet,
      directory: anyNamed('directory'),
      generateSyntheticPackage: false,
    )).thenThrow(UnsupportedError(''));
    Cache.flutterRoot = '/flutter';

    // Attempting to run pub in a test throws.
    await expectLater(Template.fromName(
        'app',
        fileSystem: fileSystem,
        templateManifest: null,
        logger: BufferLogger.test(),
        pub: pub,
        templateRenderer: FakeTemplateRenderer(),
      ),
      throwsUnsupportedError,
    );
  });

  testWithoutContext('Template.fromName runs pub get if .packages is missing flutter_template_images', () async {
    final MemoryFileSystem fileSystem = MemoryFileSystem();
    final MockPub pub = MockPub();
    when(pub.get(
      context: PubContext.pubGet,
      directory: anyNamed('directory'),
      generateSyntheticPackage: false,
    )).thenThrow(UnsupportedError(''));

    Cache.flutterRoot = '/flutter';
    final File packagesFile = fileSystem.directory(Cache.flutterRoot)
      .childDirectory('packages')
      .childDirectory('flutter_tools')
      .childFile('.packages');
    packagesFile.createSync(recursive: true);

    // Attempting to run pub in a test throws.
    await expectLater(
      Template.fromName(
        'app',
        fileSystem: fileSystem,
        templateManifest: null,
        logger: BufferLogger.test(),
        pub: pub,
        templateRenderer: FakeTemplateRenderer(),
      ),
      throwsUnsupportedError,
    );
  });

  testWithoutContext('Template.fromName runs pub get if flutter_template_images directory is missing', () async {
    final MemoryFileSystem fileSystem = MemoryFileSystem();
    final MockPub pub = MockPub();
    Cache.flutterRoot = '/flutter';
    final File packagesFile = fileSystem.directory(Cache.flutterRoot)
      .childDirectory('packages')
      .childDirectory('flutter_tools')
      .childFile('.packages');
    packagesFile.createSync(recursive: true);
    packagesFile.writeAsStringSync('\n');

    when(pub.get(
      context: PubContext.pubGet,
      directory: anyNamed('directory'),
      generateSyntheticPackage: false,
    )).thenAnswer((Invocation invocation) async {
      // Create valid package entry.
      packagesFile.writeAsStringSync('flutter_template_images:file:///flutter_template_images');
    });

    await Template.fromName(
      'app',
      fileSystem: fileSystem,
      templateManifest: null,
      logger: BufferLogger.test(),
      templateRenderer: FakeTemplateRenderer(),
      pub: pub,
    );
  });
}

class MockPub extends Mock implements Pub {}
class MockDirectory extends Mock implements Directory {}

class FakeFile extends Fake implements File {
  FakeFile(this.path);

  @override
  final String path;

  @override
  int lengthSync() {
    throw const FileSystemException('', '', OSError('', 5));
  }
}

class FakeTemplateRenderer extends TemplateRenderer {
  @override
  String renderString(String template, dynamic context, {bool htmlEscapeValues = false}) {
    return '';
  }
}
