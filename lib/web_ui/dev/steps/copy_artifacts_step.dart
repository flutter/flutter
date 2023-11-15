// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show JsonEncoder;
import 'dart:io' as io;

import 'package:path/path.dart' as pathlib;

import '../environment.dart';
import '../exceptions.dart';
import '../felt_config.dart';
import '../pipeline.dart';
import '../utils.dart';

class CopyArtifactsStep implements PipelineStep {
  CopyArtifactsStep(this.artifactDeps, { required this.runtimeMode });

  final ArtifactDependencies artifactDeps;
  final RuntimeMode runtimeMode;

  @override
  String get description => 'copy_artifacts';

  @override
  bool get isSafeToInterrupt => true;

  @override
  Future<void> interrupt() async {
    await cleanup();
  }

  @override
  Future<void> run() async {
    await environment.webTestsArtifactsDir.create(recursive: true);
    await copyTestBootstrapScripts();
    await buildHostPage();
    await copyTestFonts();
    await copySkiaTestImages();
    await copyFlutterJsFiles();
    if (artifactDeps.canvasKit) {
      print('Copying CanvasKit...');
      await copyCanvasKitFiles('canvaskit', 'canvaskit');
    }
    if (artifactDeps.canvasKitChromium) {
      print('Copying CanvasKit (Chromium)...');
      await copyCanvasKitFiles('canvaskit_chromium', 'canvaskit/chromium');
    }
    if (artifactDeps.skwasm) {
      print('Copying Skwasm...');
      await copySkwasm();
    }
  }

  Future<void> copyTestBootstrapScripts() async {
    for (final String filename in <String>[
      'test_dart2js.js',
      'test_dart2wasm.js',
    ]) {
      final io.File sourceFile = io.File(pathlib.join(
        environment.webUiDevDir.path,
        filename,
      ));
      final io.File targetFile = io.File(pathlib.join(
        environment.webTestsArtifactsDir.path,
        filename,
      ));
      await sourceFile.copy(targetFile.path);
    }
  }

  Future<void> copyTestFonts() async {
    const Map<String, String> testFonts = <String, String>{
      'Ahem': 'ahem.ttf',
      'Roboto': 'Roboto-Regular.ttf',
      'RobotoVariable': 'RobotoSlab-VariableFont_wght.ttf',
      'Noto Naskh Arabic UI': 'NotoNaskhArabic-Regular.ttf',
      'Noto Color Emoji': 'NotoColorEmoji.ttf',
    };

    final String fontsPath = pathlib.join(
      environment.flutterDirectory.path,
      'third_party',
      'txt',
      'third_party',
      'fonts',
    );

    final List<dynamic> fontManifest = <dynamic>[];
    for (final MapEntry<String, String> fontEntry in testFonts.entries) {
      final String family = fontEntry.key;
      final String fontFile = fontEntry.value;

      fontManifest.add(<String, dynamic>{
        'family': family,
        'fonts': <dynamic>[
          <String, String>{
            'asset': 'fonts/$fontFile',
          },
        ],
      });

      final io.File sourceTtf = io.File(pathlib.join(fontsPath, fontFile));
      final io.File destinationTtf = io.File(pathlib.join(
        environment.webTestsArtifactsDir.path,
        'assets',
        'fonts',
        fontFile,
      ));
      await destinationTtf.create(recursive: true);
      await sourceTtf.copy(destinationTtf.path);
    }

    final io.File fontManifestFile = io.File(pathlib.join(
      environment.webTestsArtifactsDir.path,
      'assets',
      'FontManifest.json',
    ));
    await fontManifestFile.create(recursive: true);
    await fontManifestFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(fontManifest),
    );

    final io.Directory fallbackFontsSource = io.Directory(pathlib.join(
      environment.engineSrcDir.path,
      'third_party',
      'google_fonts_for_unit_tests',
    ));
    final String fallbackFontsDestinationPath = pathlib.join(
      environment.webTestsArtifactsDir.path,
      'assets',
      'fallback_fonts',
    );
    for (final io.File file in
      fallbackFontsSource.listSync(recursive: true).whereType<io.File>()
    ) {
      final String relativePath = pathlib.relative(file.path, from: fallbackFontsSource.path);
      final io.File destinationFile = io.File(pathlib.join(fallbackFontsDestinationPath, relativePath));
      if (!destinationFile.parent.existsSync()) {
        destinationFile.parent.createSync(recursive: true);
      }
      file.copySync(destinationFile.path);
    }
  }

  Future<void> copySkiaTestImages() async {
    final io.Directory testImagesDir = io.Directory(pathlib.join(
      environment.engineSrcDir.path,
      'flutter',
      'third_party',
      'skia',
      'resources',
      'images',
    ));

    for (final io.File imageFile in testImagesDir.listSync(recursive: true).whereType<io.File>()) {
      final io.File destination = io.File(pathlib.join(
        environment.webTestsArtifactsDir.path,
        'test_images',
        pathlib.relative(imageFile.path, from: testImagesDir.path),
      ));
      destination.createSync(recursive: true);
      await imageFile.copy(destination.path);
    }
  }

  Future<void> copyFlutterJsFiles() async {
    final io.Directory flutterJsInputDirectory = io.Directory(pathlib.join(
      outBuildPath,
      'flutter_web_sdk',
      'flutter_js',
    ));
    final String targetDirectoryPath = pathlib.join(
      environment.webTestsArtifactsDir.path,
      'flutter_js',
    );

    for (final io.File sourceFile in flutterJsInputDirectory
      .listSync(recursive: true)
      .whereType<io.File>()
    ) {
      final String relativePath = pathlib.relative(
        sourceFile.path,
        from: flutterJsInputDirectory.path
      );
      final String targetPath = pathlib.join(
        targetDirectoryPath,
        relativePath,
      );
      final io.File targetFile = io.File(targetPath);
      if (!targetFile.parent.existsSync()) {
        targetFile.parent.createSync(recursive: true);
      }
      sourceFile.copySync(targetPath);
    }
  }

  Future<void> copyCanvasKitFiles(String sourcePath, String destinationPath) async {
    final String sourceDirectoryPath = pathlib.join(
      outBuildPath,
      sourcePath,
    );

    final String targetDirectoryPath = pathlib.join(
      environment.webTestsArtifactsDir.path,
      destinationPath,
    );

    for (final String filename in <String>[
      'canvaskit.js',
      'canvaskit.wasm',
      'canvaskit.wasm.map',
    ]) {
      final io.File sourceFile = io.File(pathlib.join(
        sourceDirectoryPath,
        filename,
      ));
      final io.File targetFile = io.File(pathlib.join(
        targetDirectoryPath,
        filename,
      ));
      if (!sourceFile.existsSync()) {
        if (filename.endsWith('.map')) {
          // Sourcemaps are only generated under certain build conditions, so
          // they are optional.
          continue;
        } {
          throw ToolExit('Built CanvasKit artifact not found at path "$sourceFile".');
        }
      }
      await targetFile.create(recursive: true);
      await sourceFile.copy(targetFile.path);
    }
  }

  String get outBuildPath => getBuildDirectoryForRuntimeMode(runtimeMode).path;

  Future<void> copySkwasm() async {
    final io.Directory targetDir = io.Directory(pathlib.join(
      environment.webTestsArtifactsDir.path,
      'canvaskit',
    ));

    await targetDir.create(recursive: true);

    for (final String fileName in <String>[
      'skwasm.wasm',
      'skwasm.wasm.map',
      'skwasm.js',
      'skwasm.worker.js',
    ]) {
      final io.File sourceFile = io.File(pathlib.join(
        outBuildPath,
        'flutter_web_sdk',
        'canvaskit',
        fileName,
      ));
      if (!sourceFile.existsSync()) {
        if (fileName.endsWith('.map')) {
          // Sourcemaps are only generated under certain build conditions, so
          // they are optional.
          continue;
        } {
          throw ToolExit('Built Skwasm artifact not found at path "$sourceFile".');
        }
      }
      final io.File targetFile = io.File(pathlib.join(
        targetDir.path,
        fileName,
      ));
      await sourceFile.copy(targetFile.path);
    }
  }

  Future<void> buildHostPage() async {
    final String hostDartPath = pathlib.join('lib', 'static', 'host.dart');
    final io.File hostDartFile = io.File(pathlib.join(
      environment.webEngineTesterRootDir.path,
      hostDartPath,
    ));
    final String targetDirectoryPath = pathlib.join(
      environment.webTestsArtifactsDir.path,
      'host',
    );
    io.Directory(targetDirectoryPath).createSync(recursive: true);
    final String targetFilePath = pathlib.join(
      targetDirectoryPath,
      'host.dart',
    );

    const List<String> staticFiles = <String>[
      'favicon.ico',
      'host.css',
      'index.html',
    ];
    for (final String staticFilePath in staticFiles) {
      final io.File source = io.File(pathlib.join(
        environment.webEngineTesterRootDir.path,
        'lib',
        'static',
        staticFilePath,
      ));
      final io.File destination = io.File(pathlib.join(
        targetDirectoryPath,
        staticFilePath,
      ));
      await source.copy(destination.path);
    }

    final io.File timestampFile = io.File(pathlib.join(
      environment.webEngineTesterRootDir.path,
      '$targetFilePath.js.timestamp',
    ));

    final String timestamp =
        hostDartFile.statSync().modified.millisecondsSinceEpoch.toString();
    if (timestampFile.existsSync()) {
      final String lastBuildTimestamp = timestampFile.readAsStringSync();
      if (lastBuildTimestamp == timestamp) {
        // The file is still fresh. No need to rebuild.
        return;
      } else {
        // Record new timestamp, but don't return. We need to rebuild.
        print('${hostDartFile.path} timestamp changed. Rebuilding.');
      }
    } else {
      print('Building ${hostDartFile.path}.');
    }

    int exitCode = await runProcess(
      environment.dartExecutable,
      <String>[
        'pub',
        'get',
      ],
      workingDirectory: environment.webEngineTesterRootDir.path
    );

    if (exitCode != 0) {
      throw ToolExit(
        'Failed to run pub get for web_engine_tester, exit code $exitCode',
        exitCode: exitCode,
      );
    }

    exitCode = await runProcess(
      environment.dartExecutable,
      <String>[
        'compile',
        'js',
        hostDartPath,
        '-o',
        '$targetFilePath.js',
      ],
      workingDirectory: environment.webEngineTesterRootDir.path,
    );

    if (exitCode != 0) {
      throw ToolExit(
        'Failed to compile ${hostDartFile.path}. Compiler '
        'exited with exit code $exitCode',
        exitCode: exitCode,
      );
    }

    // Record the timestamp to avoid rebuilding unless the file changes.
    timestampFile.writeAsStringSync(timestamp);
  }
}
