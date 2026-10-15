// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as path;

import '../run_command.dart';
import '../utils.dart';

/// The root of the `android_engine_test` integration test project.
final String _androidEngineTestPath = path.join('dev', 'integration_tests', 'android_engine_test');

/// To run this test locally:
///
/// 1. Connect an Android device or emulator.
/// 2. Run `dart pub get` in dev/bots
/// 3. Run the following command from the root of the Flutter repository:
///
/// ```sh
/// # Generate a baseline of local golden files.
/// SHARD=android_engine_vulkan_tests UPDATE_GOLDENS=1 bin/cache/dart-sdk/bin/dart dev/bots/test.dart
/// # Or for HCPP tests:
/// SHARD=android_engine_hcpp_tests UPDATE_GOLDENS=1 bin/cache/dart-sdk/bin/dart dev/bots/test.dart
/// ```
///
/// 4. Then, re-run the command against the baseline images:
///
/// ```sh
/// SHARD=android_engine_vulkan_tests bin/cache/dart-sdk/bin/dart dev/bots/test.dart
/// # Or for HCPP tests:
/// SHARD=android_engine_hcpp_tests bin/cache/dart-sdk/bin/dart dev/bots/test.dart
/// ```
///
/// If you are trying to debug a commit, you will want to run step (3) first,
/// then apply the commit (or flag), and then run step (4). If you are trying
/// to determine flakiness in the *same* state, or want better debugging, see
/// `dev/integration_tests/android_engine_test/README.md`.
///
/// This runs every test *except* the HCPP tests, which are their own shard; see
/// [runAndroidEngineHcppTests].
Future<void> runAndroidEngineTests({required ImpellerBackend impellerBackend}) async {
  print('Running Flutter Driver Android tests (backend=$impellerBackend)');

  await _withPatchedManifest(impellerBackend, (List<FileSystemEntity> mains, File _) async {
    for (final file in mains) {
      if (file.path.contains('hcpp')) {
        continue;
      }
      await _runTest(file, impellerBackend: impellerBackend);
    }
  });
}

/// Runs the HCPP (Hybrid Composition++) subset of the Android engine tests.
///
/// These live in `dev/integration_tests/android_engine_test/lib/hcpp` and only
/// run on Vulkan, as HCPP requires `SurfaceControl`. They are a separate shard
/// (`android_engine_hcpp_tests`) rather than part of [runAndroidEngineTests] so
/// that flakiness in the other Android engine tests cannot suppress the
/// dashboard signal for HCPP regressions.
///
/// Unlike [runAndroidEngineTests], this toggles the `EnableHcpp` manifest
/// metadata part-way through the run:
///
/// 1. `upgrade_legacy_pv_types` runs with `--enable-hcpp` while the manifest
///    still has HCPP disabled, verifying the flag alone turns HCPP on.
/// 2. The manifest is flipped to enable HCPP and the same test runs again with
///    `--no-enable-hcpp`, verifying the flag overrides the manifest.
/// 3. The remaining HCPP tests run with the manifest enabled and no flag.
///
/// See [runAndroidEngineTests] for how to run these locally.
Future<void> runAndroidEngineHcppTests() async {
  const ImpellerBackend impellerBackend = ImpellerBackend.vulkan;
  print('Running Flutter Driver Android HCPP tests (backend=$impellerBackend)');

  await _withPatchedManifest(impellerBackend, (
    List<FileSystemEntity> mains,
    File androidManifestXml,
  ) async {
    final runFirstTests = <String>[
      // Run upgrade_legacy_pv_types first, as it is testing the flag and not the manifest
      'upgrade_legacy_pv_types',
    ];

    for (final testName in runFirstTests) {
      final FileSystemEntity testFile = mains.firstWhere(
        (FileSystemEntity file) => file.path.contains(testName),
        orElse: () => throw StateError('Could not find test file matching "$testName"'),
      );
      await _runTest(testFile, impellerBackend: impellerBackend, useHCPPFlag: true);
    }

    androidManifestXml.writeAsStringSync(
      androidManifestXml.readAsStringSync().replaceFirst(
        kHcppMetadataDisabled,
        kHcppMetadataEnabled,
      ),
    );

    // Verify that --no-enable-hcpp disables HCPP even when the manifest enables it.
    for (final testName in runFirstTests) {
      final FileSystemEntity testFile = mains.firstWhere(
        (FileSystemEntity file) => file.path.contains(testName),
        orElse: () => throw StateError('Could not find test file matching "$testName"'),
      );
      await _runTest(
        testFile,
        impellerBackend: impellerBackend,
        useHCPPFlag: false,
        additionalEnvironment: const <String, String>{'EXPECT_HCPP': 'false'},
      );
    }

    for (final file in mains) {
      // This statement catches all tests inside of the
      // dev/integration_tests/android_engine_test/lib/hcpp
      // directory, except for upgrade_legacy_pv_types which we already ran.
      if (!file.path.contains('hcpp') ||
          runFirstTests.any((String name) => file.path.contains(name))) {
        continue;
      }
      await _runTest(file, impellerBackend: impellerBackend);
    }
  });
}

/// Points the test app's `AndroidManifest.xml` at [impellerBackend], invokes
/// [body], and restores the original manifest afterwards.
///
/// [body] is passed the list of `*_main.dart` entrypoints discovered under
/// `lib/`, and the manifest file itself so that callers can make further edits
/// (such as toggling `EnableHcpp`) that are also reverted on completion.
Future<void> _withPatchedManifest(
  ImpellerBackend impellerBackend,
  Future<void> Function(List<FileSystemEntity> mains, File androidManifestXml) body,
) async {
  final List<FileSystemEntity> mains = Glob('$_androidEngineTestPath/lib/**_main.dart').listSync();

  final File androidManifestXml = const LocalFileSystem().file(
    path.join(_androidEngineTestPath, 'android', 'app', 'src', 'main', 'AndroidManifest.xml'),
  );
  final String androidManifestContents = androidManifestXml.readAsStringSync();

  try {
    // Replace whatever the current backend is with the specified backend.
    final impellerBackendMetadata = RegExp(_impellerBackendMetadata(value: '.*'));
    androidManifestXml.writeAsStringSync(
      androidManifestContents.replaceFirst(
        impellerBackendMetadata,
        _impellerBackendMetadata(value: impellerBackend.name),
      ),
    );

    await body(mains, androidManifestXml);
  } finally {
    // Restore original contents.
    androidManifestXml.writeAsStringSync(androidManifestContents);
  }
}

Future<void> _runTest(
  FileSystemEntity file, {
  required ImpellerBackend impellerBackend,
  bool? useHCPPFlag,
  Map<String, String>? additionalEnvironment,
}) async {
  final CommandResult result = await runCommand(
    'flutter',
    <String>[
      'drive',
      path.relative(file.path, from: _androidEngineTestPath),
      // There are no reason to enable development flags for this test.
      // Disable them to work around flakiness issues, and in general just
      // make less things start up unnecessarily.
      '--no-dds',
      '--no-enable-dart-profiling',
      if (useHCPPFlag == true) '--enable-hcpp',
      if (useHCPPFlag == false) '--no-enable-hcpp',
      '--test-arguments=test',
      '--test-arguments=--reporter=expanded',
    ],
    workingDirectory: _androidEngineTestPath,
    environment: <String, String>{
      'ANDROID_ENGINE_TEST_GOLDEN_VARIANT': impellerBackend.name,
      ...?additionalEnvironment,
    },
  );

  // TODO(matanlurey): Also assert that the backend reported on stdout matches
  // [impellerBackend]. Stdout produces "Using the Impeller rendering backend
  // (<backend>)", but this cannot be checked until `flutter drive` retains
  // error logs. https://github.com/flutter/flutter/issues/162087
  if (result.flattenedStdout == null) {
    foundError(<String>['No stdout produced.']);
  }
}

const String kHcppMetadataDisabled =
    '<meta-data android:name="io.flutter.embedding.android.EnableHcpp" android:value="false" />';
const String kHcppMetadataEnabled =
    '<meta-data android:name="io.flutter.embedding.android.EnableHcpp" android:value="true" />';

String _impellerBackendMetadata({required String value}) {
  return '<meta-data android:name="io.flutter.embedding.android.ImpellerBackend" android:value="$value" />';
}

enum ImpellerBackend { vulkan, opengles }
