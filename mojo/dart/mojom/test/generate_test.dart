// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:mojom/generate.dart' as generate;
import 'package:path/path.dart' as path;
import 'package:unittest/unittest.dart';

final mojomContents = '''
[DartPackage="generated"]
module generated;

struct Transform {
  // Row major order.
  array<float, 16> matrix;
};
''';

final dldMojomContents1 = '''
[DartPackage="downloaded"]
module downloaded;

struct Downloaded1 {
  int32 status;
};
''';

final dldMojomContents2 = '''
[DartPackage="downloaded"]
module downloaded;

struct Downloaded2 {
  int32 status;
};
''';

main() async {
  String mojoSdk;
  if (Platform.environment['MOJO_SDK'] != null) {
    mojoSdk = Platform.environment['MOJO_SDK'];
  } else {
    mojoSdk = path.normalize(path.join(
        path.dirname(Platform.script.path), '..', '..', '..', 'public'));
  }
  if (!await new Directory(mojoSdk).exists()) {
    fail("Could not find the Mojo SDK");
  }

  final scriptPath = path.dirname(Platform.script.path);
  final testPackagePath = path.join(scriptPath, 'test_packages');
  final testMojomPath = path.join(testPackagePath, 'mojom');
  final testMojomLinkPath = path.join(scriptPath, 'mojom_link_target');
  final testMojomLibPath = path.join(testMojomLinkPath, 'lib');
  final fakeGeneratePath = path.join(testMojomLibPath, 'generate.dart');

  final pregenPath = path.join(testPackagePath, 'pregen');
  final pregenFilePath =
      path.join(pregenPath, 'mojom', 'pregen', 'pregen.mojom.dart');

  final additionalRootPath = path.join(scriptPath, 'additional_dir');
  final additionalPath =
      path.join(additionalRootPath, 'additional', 'additional.mojom.dart');

  final generatedPackagePath = path.join(testPackagePath, 'generated');

  final downloadedPackagePath = path.join(testPackagePath, 'downloaded');
  final dotMojomsPath = path.join(downloadedPackagePath, '.mojoms');

  setUp(() async {
    await new File(pregenFilePath).create(recursive: true);
    await new File(additionalPath).create(recursive: true);
    await new File(fakeGeneratePath).create(recursive: true);
    await new Link(testMojomPath).create(testMojomLibPath);

    final generatedMojomFile = new File(path.join(testPackagePath, 'generated',
        'mojom', 'generated', 'public', 'interfaces', 'generated.mojom'));
    await generatedMojomFile.create(recursive: true);
    await generatedMojomFile.writeAsString(mojomContents);

    await new Directory(downloadedPackagePath).create(recursive: true);
  });

  tearDown(() async {
    await new Directory(additionalRootPath).delete(recursive: true);
    await new Directory(testPackagePath).delete(recursive: true);
    await new Directory(testMojomLinkPath).delete(recursive: true);
  });

  group('No Download', () {
    test('No-op', () async {
      await generate.main(['-p', testPackagePath, '-m', mojoSdk]);
      final mojomPackageDir = new Directory(testMojomPath);
      final generateFile = new File(path.join(testMojomPath, 'generate.dart'));
      expect(await mojomPackageDir.exists(), isTrue);
      expect(await generateFile.exists(), isTrue);
    });

    test('Additional', () async {
      await generate.main(
          ['-p', testPackagePath, '-m', mojoSdk, '-a', additionalRootPath]);
      final mojomPackageDir = new Directory(testMojomPath);
      final generateFile = new File(path.join(testMojomPath, 'generate.dart'));
      final additionalFile = new File(
          path.join(testMojomPath, 'additional', 'additional.mojom.dart'));
      expect(await mojomPackageDir.exists(), isTrue);
      expect(await generateFile.exists(), isTrue);
      expect(await additionalFile.exists(), isTrue);
    });

    test('Generated', () async {
      await generate.main(['-g', '-p', testPackagePath, '-m', mojoSdk]);
      final generatedFile = new File(
          path.join(generatedPackagePath, 'generated', 'generated.mojom.dart'));
      expect(await generatedFile.exists(), isTrue);
    });

    test('All', () async {
      await generate.main([
        '-g',
        '-p',
        testPackagePath,
        '-m',
        mojoSdk,
        '-a',
        additionalRootPath
      ]);

      final additionalFile = new File(
          path.join(testMojomPath, 'additional', 'additional.mojom.dart'));
      expect(await additionalFile.exists(), isTrue);

      final generatedFile = new File(
          path.join(generatedPackagePath, 'generated', 'generated.mojom.dart'));
      expect(await generatedFile.exists(), isTrue);
    });
  });

  group('Download', () {
    var httpServer;
    setUp(() async {
      httpServer = await HttpServer.bind("localhost", 0);
      httpServer.listen((HttpRequest request) {
        String path = request.uri.path;
        if (path.endsWith('path/to/mojom/download_one.mojom')) {
          request.response.write(dldMojomContents1);
        } else if (path.endsWith('path/to/mojom/download_two.mojom')) {
          request.response.write(dldMojomContents2);
        } else {
          request.response.statusCode = HttpStatus.NOT_FOUND;
        }
        request.response.close();
      });
    });

    tearDown(() async {
      await httpServer.close();
      httpServer = null;
    });

    test('simple', () async {
      final mojomsFile = new File(dotMojomsPath);
      await mojomsFile.create(recursive: true);
      await mojomsFile.writeAsString(
          "root: http://localhost:${httpServer.port}\n"
          "path/to/mojom/download_one.mojom\n");
      await generate.main(['-p', testPackagePath, '-m', mojoSdk, '-d', '-g']);
      final downloadedFile = new File(path.join(
          downloadedPackagePath, 'downloaded', 'download_one.mojom.dart'));
      expect(await downloadedFile.exists(), isTrue);
      await mojomsFile.delete();
    });

    test('two files', () async {
      final mojomsFile = new File(dotMojomsPath);
      await mojomsFile.create(recursive: true);
      await mojomsFile.writeAsString(
          "root: http://localhost:${httpServer.port}\n"
          "path/to/mojom/download_one.mojom\n"
          "path/to/mojom/download_two.mojom\n");
      await generate.main(['-p', testPackagePath, '-m', mojoSdk, '-d', '-g']);
      final downloaded1File = new File(path.join(
          downloadedPackagePath, 'downloaded', 'download_one.mojom.dart'));
      expect(await downloaded1File.exists(), isTrue);
      final downloaded2File = new File(path.join(
          downloadedPackagePath, 'downloaded', 'download_two.mojom.dart'));
      expect(await downloaded2File.exists(), isTrue);
      await mojomsFile.delete();
    });

    test('two roots', () async {
      final mojomsFile = new File(dotMojomsPath);
      await mojomsFile.create(recursive: true);
      await mojomsFile.writeAsString(
          "root: http://localhost:${httpServer.port}\n"
          "path/to/mojom/download_one.mojom\n"
          "root: http://localhost:${httpServer.port}\n"
          "path/to/mojom/download_two.mojom\n");
      await generate.main(['-p', testPackagePath, '-m', mojoSdk, '-d', '-g']);
      final downloaded1File = new File(path.join(
          downloadedPackagePath, 'downloaded', 'download_one.mojom.dart'));
      expect(await downloaded1File.exists(), isTrue);
      final downloaded2File = new File(path.join(
          downloadedPackagePath, 'downloaded', 'download_two.mojom.dart'));
      expect(await downloaded2File.exists(), isTrue);
      await mojomsFile.delete();
    });

    test('simple-comment', () async {
      final mojomsFile = new File(dotMojomsPath);
      await mojomsFile.create(recursive: true);
      await mojomsFile.writeAsString("# Comments are allowed\n"
          " root: http://localhost:${httpServer.port}\n\n\n\n"
          "          # Here too\n"
          " path/to/mojom/download_one.mojom\n"
          "# And here\n");
      await generate.main(['-p', testPackagePath, '-m', mojoSdk, '-d', '-g']);
      final downloadedFile = new File(path.join(
          downloadedPackagePath, 'downloaded', 'download_one.mojom.dart'));
      expect(await downloadedFile.exists(), isTrue);
      await mojomsFile.delete();
    });

    test('404', () async {
      final mojomsFile = new File(dotMojomsPath);
      await mojomsFile.create(recursive: true);
      await mojomsFile.writeAsString(
          "root: http://localhost:${httpServer.port}\n"
          "blah\n");
      var fail = false;
      try {
        await generate.main(['-p', testPackagePath, '-m', mojoSdk, '-d', '-g']);
      } on generate.DownloadError {
        fail = true;
      }
      expect(fail, isTrue);
      await mojomsFile.delete();
    });
  });

  group('Failures', () {
    test('Bad Package Root', () async {
      final dummyPackageRoot = path.join(scriptPath, 'dummyPackageRoot');
      var fail = false;
      try {
        await generate.main(['-p', dummyPackageRoot, '-m', mojoSdk]);
      } on generate.CommandLineError {
        fail = true;
      }
      expect(fail, isTrue);
    });

    test('Non-absolute PackageRoot', () async {
      final dummyPackageRoot = 'dummyPackageRoot';
      var fail = false;
      try {
        await generate.main(['-p', dummyPackageRoot, '-m', mojoSdk]);
      } on generate.CommandLineError {
        fail = true;
      }
      expect(fail, isTrue);
    });

    test('Bad Additional Dir', () async {
      final dummyAdditional = path.join(scriptPath, 'dummyAdditional');
      var fail = false;
      try {
        await generate.main(
            ['-a', dummyAdditional, '-p', testPackagePath, '-m', mojoSdk]);
      } on generate.CommandLineError {
        fail = true;
      }
      expect(fail, isTrue);
    });

    test('Non-absolute Additional Dir', () async {
      final dummyAdditional = 'dummyAdditional';
      var fail = false;
      try {
        await generate.main(
            ['-a', dummyAdditional, '-p', testPackagePath, '-m', mojoSdk]);
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
        await generate.main(['-p', dummyPackageRoot, '-m', mojoSdk]);
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

    test('Download No Server', () async {
      final mojomsFile = new File(dotMojomsPath);
      await mojomsFile.create(recursive: true);
      await mojomsFile.writeAsString("root: http://localhots\n"
          "path/to/mojom/download_one.mojom\n");
      var fail = false;
      try {
        await generate.main(['-p', testPackagePath, '-m', mojoSdk, '-d', '-g']);
      } on generate.DownloadError {
        fail = true;
      }
      expect(fail, isTrue);
      await mojomsFile.delete();
    });

    test('.mojoms no root', () async {
      final mojomsFile = new File(dotMojomsPath);
      await mojomsFile.create(recursive: true);
      await mojomsFile.writeAsString("path/to/mojom/download_one.mojom\n");
      var fail = false;
      try {
        await generate.main(['-p', testPackagePath, '-m', mojoSdk, '-d', '-g']);
      } on generate.DownloadError {
        fail = true;
      }
      expect(fail, isTrue);
      await mojomsFile.delete();
    });

    test('.mojoms blank root', () async {
      final mojomsFile = new File(dotMojomsPath);
      await mojomsFile.create(recursive: true);
      await mojomsFile.writeAsString("root:\n"
          "path/to/mojom/download_one.mojom\n");
      var fail = false;
      try {
        await generate.main(['-p', testPackagePath, '-m', mojoSdk, '-d', '-g']);
      } on generate.DownloadError {
        fail = true;
      }
      expect(fail, isTrue);
      await mojomsFile.delete();
    });

    test('.mojoms root malformed', () async {
      final mojomsFile = new File(dotMojomsPath);
      await mojomsFile.create(recursive: true);
      await mojomsFile.writeAsString("root: gobledygook\n"
          "path/to/mojom/download_one.mojom\n");
      var fail = false;
      try {
        await generate.main(['-p', testPackagePath, '-m', mojoSdk, '-d', '-g']);
      } on generate.DownloadError {
        fail = true;
      }
      expect(fail, isTrue);
      await mojomsFile.delete();
    });

    test('.mojoms root without mojom', () async {
      final mojomsFile = new File(dotMojomsPath);
      await mojomsFile.create(recursive: true);
      await mojomsFile.writeAsString("root: http://localhost\n"
          "root: http://localhost\n"
          "path/to/mojom/download_one.mojom\n");
      var fail = false;
      try {
        await generate.main(['-p', testPackagePath, '-m', mojoSdk, '-d', '-g']);
      } on generate.DownloadError {
        fail = true;
      }
      expect(fail, isTrue);
      await mojomsFile.delete();
    });
  });
}
