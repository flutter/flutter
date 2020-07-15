// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/template.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:mockito/mockito.dart';

import 'src/common.dart';
import 'src/testbed.dart';

void main() {
  Testbed testbed;

  setUp(() {
    testbed = Testbed();
  });

  test('Template.render throws ToolExit when FileSystem exception is raised', () => testbed.run(() {
    final Template template = Template(
      globals.fs.directory('examples'),
      globals.fs.currentDirectory,
      null,
      fileSystem: globals.fs,
      templateManifest: null,
    );
    final MockDirectory mockDirectory = MockDirectory();
    when(mockDirectory.createSync(recursive: true)).thenThrow(const FileSystemException());

    expect(() => template.render(mockDirectory, <String, Object>{}),
        throwsToolExit());
  }));

  test('Template.render replaces .img.tmpl files with files from the image source', () => testbed.run(() {
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
    );
    template.render(destination, <String, Object>{});

    final File destinationImage = destination.childFile(imageName);
    expect(destinationImage.existsSync(), true);
    expect(destinationImage.readAsBytesSync(), equals(sourceImage.readAsBytesSync()));
  }));

  test('Template.fromName runs pub get if .packages is missing', () => testbed.run(() async {
    final MemoryFileSystem fileSystem = MemoryFileSystem();

    // Attempting to run pub in a test throws.
    await expectLater(Template.fromName('app', fileSystem: fileSystem, templateManifest: null),
      throwsUnsupportedError);
  }));

  test('Template.fromName runs pub get if .packages is missing flutter_template_images', () => testbed.run(() async {
    final MemoryFileSystem fileSystem = MemoryFileSystem();
    Cache.flutterRoot = '/flutter';
    final File packagesFile = fileSystem.directory(Cache.flutterRoot)
        .childDirectory('packages')
        .childDirectory('flutter_tools')
        .childFile('.packages');
    packagesFile.createSync(recursive: true);

    // Attempting to run pub in a test throws.
    await expectLater(Template.fromName('app', fileSystem: fileSystem, templateManifest: null),
      throwsUnsupportedError);
  }));

  test('Template.fromName runs pub get if flutter_template_images directory is missing', () => testbed.run(() async {
    final MemoryFileSystem fileSystem = MemoryFileSystem();
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
    )).thenAnswer((Invocation invocation) async {
      // Create valid package entry.
      packagesFile.writeAsStringSync('flutter_template_images:file:///flutter_template_images');
    });

    await Template.fromName('app', fileSystem: fileSystem, templateManifest: null);
  }, overrides: <Type, Generator>{
    Pub: () => MockPub(),
  }));
}

class MockPub extends Mock implements Pub {}
class MockDirectory extends Mock implements Directory {}
