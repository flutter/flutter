// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' show Platform;
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:path/path.dart' as path;

import '../run_command.dart';
import '../utils.dart';
import 'run_android_engine_tests.dart';

String _impellerBackendMetadata({required String value}) =>
    '<meta-data android:name="io.flutter.embedding.android.ImpellerBackend" android:value="$value" />';

void _copyDirectory(Directory source, Directory destination) {
  destination.createSync(recursive: true);
  for (final FileSystemEntity entity in source.listSync(recursive: true)) {
    if (entity is File) {
      final String relativePath = path.relative(entity.path, from: source.path);
      final String destPath = path.join(destination.path, relativePath);
      entity.fileSystem.file(destPath).parent.createSync(recursive: true);
      entity.copySync(destPath);
    }
  }
}

void _cleanGoldensDirectory(Directory directory) {
  if (!directory.existsSync()) {
    return;
  }
  for (final FileSystemEntity entity in directory.listSync(recursive: true)) {
    if (entity is File && path.basename(entity.path) != 'README.md') {
      entity.deleteSync();
    }
  }
}

/// Runs the Android Hardware Smoke Test golden suite in CI.
Future<void> runAndroidHardwareSmokeTests({
  required ImpellerBackend backend,
  bool runInstrumented = false,
}) async {
  printProgress('Running Android Hardware Smoke Tests Shard (backend=${backend.name})');

  final String testDir = path.join('dev', 'integration_tests', 'android_hardware_smoke_test');

  // Regenerate standard Android Gradle wrappers
  await runCommand('flutter', <String>[
    'create',
    '--platform=android',
    '--no-overwrite',
    '.',
  ], workingDirectory: testDir);

  final String androidDir = path.join(testDir, 'android');
  final File androidManifestXml = const LocalFileSystem().file(
    path.join(androidDir, 'app', 'src', 'main', 'AndroidManifest.xml'),
  );
  final String androidManifestContents = androidManifestXml.readAsStringSync();

  final Directory destinationDir = const LocalFileSystem().directory(
    path.join(testDir, 'test_driver', 'goldens'),
  );
  final Directory sourceDir = const LocalFileSystem().directory(
    path.join(testDir, 'android_hardware_smoke_test.${backend.name}.goldens'),
  );

  try {
    // Replace whatever the current backend is with the specified backend.
    final impellerBackendMetadata = RegExp(_impellerBackendMetadata(value: '[^"]*'));
    if (!impellerBackendMetadata.hasMatch(androidManifestContents)) {
      throw StateError(
        'Could not find io.flutter.embedding.android.ImpellerBackend meta-data tag inside AndroidManifest.xml',
      );
    }
    androidManifestXml.writeAsStringSync(
      androidManifestContents.replaceFirst(
        impellerBackendMetadata,
        _impellerBackendMetadata(value: backend.name),
      ),
    );

    // 1. Run driver tests to generate reference screenshots
    await runCommand('flutter', <String>[
      'drive',
      '--driver=test_driver/driver_test.dart',
      '--target=integration_test/integration_test_wrapper.dart',
      '--no-dds',
      '--no-enable-dart-profiling',
    ], workingDirectory: testDir);

    if (runInstrumented) {
      // 2. Copy the generated goldens to the assets directory so they get packaged with the APK.
      // In CI, the Skia Gold comparator downloads the baseline images into a temporary prefixed
      // directory (sourceDir) instead of the default assets directory (destinationDir).
      if (sourceDir.existsSync()) {
        _copyDirectory(sourceDir, destinationDir);
      }

      final String gradle = path.absolute(
        path.join(androidDir, Platform.isWindows ? 'gradlew.bat' : 'gradlew'),
      );

      // 3. Build and run the instrumented tests.
      await runCommand(gradle, <String>[
        ':app:connectedDebugAndroidTest',
        '-Pandroid.testInstrumentationRunnerArguments.class=com.example.android_hardware_smoke_test.FlutterActivityTest',
        '-s',
      ], workingDirectory: androidDir);
    }
  } finally {
    // Restore original contents.
    androidManifestXml.writeAsStringSync(androidManifestContents);

    // Clean up copied goldens to keep Git worktree completely clean
    _cleanGoldensDirectory(destinationDir);

    // Clean up the temporary prefixed goldens directory
    if (sourceDir.existsSync()) {
      sourceDir.deleteSync(recursive: true);
    }
  }
}
