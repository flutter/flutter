// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:mojom/generate.dart' as generate;
import 'package:path/path.dart' as path;
import 'package:unittest/unittest.dart';

final mojomContents = '''
module generated;

struct Transform {
  // Row major order.
  array<float, 16> matrix;
};
''';

void main() {
  final scriptPath = path.dirname(Platform.script.path);
  final testPackagePath = path.join(scriptPath, 'test_packages');
  final testMojomPath = path.join(testPackagePath, 'mojom');

  final pregenPath = path.join(testPackagePath, 'pregen');
  final pregenFilePath =
      path.join(pregenPath, 'mojom', 'pregen', 'pregen.mojom.dart');

  final additionalRootPath = path.join(scriptPath, 'additional_dir');
  final additionalPath = path.join(
      additionalRootPath, 'additional', 'additional.mojom.dart');

  setUp(() async {
    await new Directory(testMojomPath).create(recursive: true);
    await new File(pregenFilePath).create(recursive: true);
    await new File(additionalPath).create(recursive: true);

    final generatedMojomFile = new File(path.join(testPackagePath, 'generated',
        'mojom', 'generated', 'public', 'interfaces', 'generated.mojom'));
    await generatedMojomFile.create(recursive: true);
    await generatedMojomFile.writeAsString(mojomContents);
  });

  tearDown(() async {
    await new Directory(additionalRootPath).delete(recursive: true);
    await new Directory(testPackagePath).delete(recursive: true);
  });

  group('end-to-end', () {
    test('Copy', () async {
      await generate.main(['-p', testPackagePath]);
      final pregenFile = new File(
          path.join(testMojomPath, 'pregen', 'pregen.mojom.dart'));
      expect(await pregenFile.exists(), isTrue);
    });

    test('Copy and Additional', () async {
      await generate.main(['-p', testPackagePath, '-a', additionalRootPath]);
      final additionalFile = new File(
          path.join(testMojomPath, 'additional', 'additional.mojom.dart'));
      expect(await additionalFile.exists(), isTrue);
    });

    test('Copy and Generate', () async {
      if (Platform.environment['MOJO_SDK'] != null) {
        await generate.main(['-g', '-p', testPackagePath]);
        final generatedFile = new File(
            path.join(testMojomPath, 'generated', 'generated.mojom.dart'));
        expect(await generatedFile.exists(), isTrue);
      }
    });

    test('All', () async {
      if (Platform.environment['MOJO_SDK'] != null) {
        await generate.main([
            '-g', '-p', testPackagePath, '-a', additionalRootPath]);

        final pregenFile = new File(
            path.join(testMojomPath, 'pregen', 'pregen.mojom.dart'));
        expect(await pregenFile.exists(), isTrue);

        final additionalFile = new File(
            path.join(testMojomPath, 'additional', 'additional.mojom.dart'));
        expect(await additionalFile.exists(), isTrue);

        final generatedFile = new File(
            path.join(testMojomPath, 'generated', 'generated.mojom.dart'));
        expect(await generatedFile.exists(), isTrue);
      }
    });
  });

  group('Failures', () {
    test('Bad Package Root',() async {
      final dummyPackageRoot = path.join(scriptPath, 'dummyPackageRoot');
      var fail = false;
      try {
        await generate.main(['-p', dummyPackageRoot]);
      } on generate.CommandLineError {
        fail = true;
      }
      expect(fail, isTrue);
    });

    test('Non-absolute PackageRoot', () async {
      final dummyPackageRoot = 'dummyPackageRoot';
      var fail = false;
      try {
        await generate.main(['-p', dummyPackageRoot]);
      } on generate.CommandLineError {
        fail = true;
      }
      expect(fail, isTrue);
    });

    test('Bad Additional Dir', () async {
      final dummyAdditional = path.join(scriptPath, 'dummyAdditional');
      var fail = false;
      try {
        await generate.main(['-a', dummyAdditional, '-p', testPackagePath]);
      } on generate.CommandLineError {
        fail = true;
      }
      expect(fail, isTrue);
    });

    test('Non-absolute Additional Dir', () async {
      final dummyAdditional = 'dummyAdditional';
      var fail = false;
      try {
        await generate.main(['-a', dummyAdditional, '-p', testPackagePath]);
      } on generate.CommandLineError {
        fail = true;
      }
      expect(fail, isTrue);
    });

    test('No Mojo Package', () async {
      final dummyPackageRoot = path.join(scriptPath, 'dummyPackageRoot');
      final dummyPackageDir = new Directory(dummyPackageRoot);
      await dummyPackageDir.create(recursive: true);

      var fail = false;
      try {
        await generate.main(['-p', dummyPackageRoot]);
      } on generate.CommandLineError {
        fail = true;
      }
      await dummyPackageDir.delete(recursive: true);
      expect(fail, isTrue);
    });

    test('Bad Mojo SDK', () async {
      final dummySdk = path.join(scriptPath, 'dummySdk');
      var fail = false;
      try {
        await generate.main(['-g', '-m', dummySdk, '-p', testPackagePath]);
      } on generate.CommandLineError {
        fail = true;
      }
      expect(fail, isTrue);
    });
  });
}
