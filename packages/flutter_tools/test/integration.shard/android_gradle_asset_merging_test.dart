// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@Timeout(Duration(minutes: 10))
library;

import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:file/file.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

Archive readApkArchive(File apkFile) {
  expect(apkFile, exists);
  final List<int> bytes = apkFile.readAsBytesSync();
  return ZipDecoder().decodeBytes(bytes);
}

void expectApkEntry(Archive archive, String path, String expectedContents, {String? reason}) {
  final ArchiveFile? file = archive.findFile(path);
  expect(file, isNotNull, reason: reason ?? 'APK is missing expected entry $path');
  final dynamic rawContent = file!.content;
  final List<int> content = rawContent is List<int> ? rawContent : <int>[];
  final String actualContents = utf8.decode(content, allowMalformed: true);
  expect(actualContents, expectedContents, reason: reason);
}

void expectNoApkEntry(Archive archive, String path, {required String reason}) {
  expect(archive.findFile(path), isNull, reason: reason);
}

void writeFlutterAsset(Directory projectDir, String relativePath, String contents) {
  final File file = projectDir.childFile(relativePath);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(contents);
}

void writeAndroidSourceSetAsset(
  Directory projectDir,
  String sourceSet,
  String relativePath,
  String contents,
) {
  final File file = projectDir
      .childDirectory('android')
      .childDirectory('app')
      .childDirectory('src')
      .childDirectory(sourceSet)
      .childDirectory('assets')
      .childFile(relativePath);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(contents);
}

void addAssetsToPubspec(File pubspecFile, List<String> assets) {
  final String content = pubspecFile.readAsStringSync();
  final flutterSection = RegExp(r'^flutter:$', multiLine: true);
  expect(
    flutterSection.hasMatch(content),
    isTrue,
    reason: 'pubspec.yaml missing top-level flutter: section',
  );
  final String assetLines = assets.map((String a) => '    - $a').join('\n');
  final String updated = content.replaceFirst(flutterSection, 'flutter:\n  assets:\n$assetLines');
  pubspecFile.writeAsStringSync(updated);
}

Future<Directory> createApp(Directory workingDir, {String name = 'app'}) async {
  final ProcessResult createResult = await processManager.run(<String>[
    flutterBin,
    'create',
    '--template=app',
    '--platforms=android',
    name,
  ], workingDirectory: workingDir.path);
  expect(createResult, const ProcessResultMatcher());
  return workingDir.childDirectory(name);
}

/// Builds a debug APK and returns it from the `flutter-apk` output directory.
///
/// Debug-only on purpose. The APK file name encodes the build mode
/// (`app-[<flavor>-]<mode>.apk`), so a mode parameter would have to be threaded into both the
/// command line and the expected file name to stay correct. No test here needs another mode.
Future<File> buildApk(Directory projectDir, {String? flavor}) async {
  final ProcessResult buildResult = await processManager.run(<String>[
    flutterBin,
    ...getLocalEngineArguments(),
    'build',
    'apk',
    '--debug',
    if (flavor != null) ...<String>['--flavor', flavor],
  ], workingDirectory: projectDir.path);
  expect(buildResult, const ProcessResultMatcher());

  final apkName = flavor == null ? 'app-debug.apk' : 'app-$flavor-debug.apk';
  final File apkFile = projectDir
      .childDirectory('build')
      .childDirectory('app')
      .childDirectory('outputs')
      .childDirectory('flutter-apk')
      .childFile(apkName);
  expect(apkFile, exists);
  return apkFile;
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = createResolvedTempDirectorySync('android_gradle_asset_merging.');
  });

  tearDown(() {
    tryToDelete(tempDir);
  });

  testWithoutContext('Flutter assets, directory assets, resolution variants, and native Android assets coexist in APK', () async {
    final Directory projectDir = await createApp(tempDir);

    // Every file this test packages is declared in one of the two tables below. To cover a new
    // asset type, add a row to the matching table.
    //
    // For Flutter assets:
    //  * source is written into the project,
    //  * pubspecEntry is what `pubspec.yaml` declares, or null when the tool finds the file
    //    without a declaration, which is how resolution variants work,
    //  * apkEntry is where the file has to end up inside the APK.
    final flutterAssets =
        <({String source, String? pubspecEntry, String apkEntry, String contents})>[
          (
            source: 'assets/single_asset.txt',
            pubspecEntry: 'assets/single_asset.txt',
            apkEntry: 'assets/flutter_assets/assets/single_asset.txt',
            contents: 'flutter_single_asset_content',
          ),
          (
            source: 'assets/nested/dir_asset.txt',
            pubspecEntry: 'assets/nested/',
            apkEntry: 'assets/flutter_assets/assets/nested/dir_asset.txt',
            contents: 'flutter_nested_asset_content',
          ),
          (
            source: 'assets/image.png',
            pubspecEntry: 'assets/image.png',
            apkEntry: 'assets/flutter_assets/assets/image.png',
            contents: 'flutter_image_base_content',
          ),
          // Declaring the base image also packages its density variants.
          (
            source: 'assets/3.0x/image.png',
            pubspecEntry: null,
            apkEntry: 'assets/flutter_assets/assets/3.0x/image.png',
            contents: 'flutter_image_3x_content',
          ),
          (
            source: 'assets/4.0x/image.png',
            pubspecEntry: null,
            apkEntry: 'assets/flutter_assets/assets/4.0x/image.png',
            contents: 'flutter_image_4x_content',
          ),
        ];

    // Native Android assets need no pubspec entry. AGP merges src/main/assets into the APK.
    final nativeAndroidAssets = <({String source, String apkEntry, String contents})>[
      (
        source: 'native_asset.txt',
        apkEntry: 'assets/native_asset.txt',
        contents: 'native_asset_content',
      ),
      (
        source: 'custom/config.json',
        apkEntry: 'assets/custom/config.json',
        contents: '{"native_config": true}',
      ),
    ];

    for (final asset in flutterAssets) {
      writeFlutterAsset(projectDir, asset.source, asset.contents);
    }
    for (final asset in nativeAndroidAssets) {
      writeAndroidSourceSetAsset(projectDir, 'main', asset.source, asset.contents);
    }
    addAssetsToPubspec(projectDir.childFile('pubspec.yaml'), <String>[
      for (final asset in flutterAssets)
        if (asset.pubspecEntry case final String entry) entry,
    ]);

    final File apkFile = await buildApk(projectDir);
    final Archive archive = readApkArchive(apkFile);

    for (final asset in flutterAssets) {
      expectApkEntry(archive, asset.apkEntry, asset.contents);
    }
    for (final asset in nativeAndroidAssets) {
      expectApkEntry(archive, asset.apkEntry, asset.contents);
    }
  });

  // Verifies that assets removed from pubspec.yaml are pruned from the APK on a
  // subsequent build, rather than lingering from the previous build's output.
  //
  // Note: this deliberately does not assert that the second build was Gradle
  // *incremental* (e.g. by scraping task stdout for UP-TO-DATE). A full rebuild
  // that produced a correct APK would also satisfy this test, and that is the
  // intended contract: the assertion is about stale output never surviving into
  // the artifact, which is the regression `FileSystemOperations.sync` prevents.
  testWithoutContext('assets removed from pubspec are pruned from the APK on rebuild', () async {
    final Directory projectDir = await createApp(tempDir);

    writeFlutterAsset(projectDir, 'assets/asset1.txt', 'asset_one_initial');
    writeFlutterAsset(projectDir, 'assets/asset2.txt', 'asset_two_initial');

    final File pubspecFile = projectDir.childFile('pubspec.yaml');
    addAssetsToPubspec(pubspecFile, <String>['assets/asset1.txt', 'assets/asset2.txt']);

    // Build 1: Initial debug APK.
    final File apkFile = await buildApk(projectDir);
    Archive archive = readApkArchive(apkFile);

    expectApkEntry(archive, 'assets/flutter_assets/assets/asset1.txt', 'asset_one_initial');
    expectApkEntry(archive, 'assets/flutter_assets/assets/asset2.txt', 'asset_two_initial');

    // Mutate assets: delete asset2, add asset3, update pubspec.yaml.
    projectDir.childFile('assets/asset2.txt').deleteSync();
    writeFlutterAsset(projectDir, 'assets/asset3.txt', 'asset_three_added');

    final String currentPubspec = pubspecFile.readAsStringSync();
    final String updatedPubspec = currentPubspec.replaceFirst(
      '- assets/asset2.txt',
      '- assets/asset3.txt',
    );
    pubspecFile.writeAsStringSync(updatedPubspec);

    // Build 2: rebuild in place, without a clean.
    await buildApk(projectDir);

    archive = readApkArchive(apkFile);

    expectApkEntry(archive, 'assets/flutter_assets/assets/asset1.txt', 'asset_one_initial');
    expectApkEntry(archive, 'assets/flutter_assets/assets/asset3.txt', 'asset_three_added');
    expectNoApkEntry(
      archive,
      'assets/flutter_assets/assets/asset2.txt',
      reason:
          'asset2.txt was removed from pubspec.yaml and must not survive from the '
          'previous build into the rebuilt APK',
    );
  });

  // Asserts a documented AGP guarantee, not incidental merge ordering.
  //
  // `SourceDirectories.addGeneratedSourceDirectory` places the directory in the
  // "Variant" overlay. Per the AGP API docs on `SourceDirectories`:
  //
  //   "Adding directories is always added to the 'Variant' overlay and will
  //    therefore carry the highest possible priority among all directories for
  //    the source type."
  //
  // and on `addGeneratedSourceDirectory` itself:
  //
  //   "The [Directory] is added last to the variant's list of source
  //    directories. In case there is merging for the source type, the
  //    [Directory] will have the highest priority."
  //
  // So on a path collision the generated Flutter assets win over
  // `src/main/assets`, and the build must not fail.
  testWithoutContext('generated Flutter assets take precedence over static src/main/assets on path collision without build failure', () async {
    final Directory projectDir = await createApp(tempDir);

    writeFlutterAsset(projectDir, 'assets/collision.txt', 'flutter_version');
    writeAndroidSourceSetAsset(
      projectDir,
      'main',
      'flutter_assets/assets/collision.txt',
      'native_override_version',
    );

    final File pubspecFile = projectDir.childFile('pubspec.yaml');
    addAssetsToPubspec(pubspecFile, <String>['assets/collision.txt']);

    final File apkFile = await buildApk(projectDir);
    final Archive archive = readApkArchive(apkFile);

    expectApkEntry(
      archive,
      'assets/flutter_assets/assets/collision.txt',
      'flutter_version',
      reason:
          'Per the AGP SourceDirectories contract, addGeneratedSourceDirectory adds to '
          'the Variant overlay, giving it the highest possible priority during merge '
          'over src/main/assets',
    );
  });

  // Covers both Android source-set dimensions that vary per variant: product
  // flavor (`src/<flavor>/assets`) and build type (`src/<buildType>/assets`).
  // Both are asserted against a single `freeDebug` build so this costs one
  // Gradle invocation rather than two.
  testWithoutContext('flavor-specific and buildType-specific native assets are packaged into the matching variant APK', () async {
    final Directory projectDir = await createApp(tempDir);

    // Add product flavors to build.gradle.kts.
    final File buildGradleFile = projectDir
        .childDirectory('android')
        .childDirectory('app')
        .childFile('build.gradle.kts');
    expect(buildGradleFile, exists);
    String buildGradleContents = buildGradleFile.readAsStringSync();
    buildGradleContents = buildGradleContents.replaceFirst('android {', '''
android {
    flavorDimensions += "default"
    productFlavors {
        create("free") {
            dimension = "default"
        }
        create("paid") {
            dimension = "default"
        }
    }''');
    buildGradleFile.writeAsStringSync(buildGradleContents);

    // Flavor-specific assets: only the selected flavor should be packaged.
    writeAndroidSourceSetAsset(projectDir, 'free', 'flavor_free.txt', 'free_flavor_asset_data');
    writeAndroidSourceSetAsset(projectDir, 'paid', 'flavor_paid.txt', 'paid_flavor_asset_data');

    // BuildType-specific assets: only the selected build type should be packaged.
    writeAndroidSourceSetAsset(
      projectDir,
      'debug',
      'buildtype_debug.txt',
      'debug_buildtype_asset_data',
    );
    writeAndroidSourceSetAsset(
      projectDir,
      'release',
      'buildtype_release.txt',
      'release_buildtype_asset_data',
    );

    // Create standard Flutter asset.
    writeFlutterAsset(projectDir, 'assets/shared.txt', 'shared_flutter_asset');

    final File pubspecFile = projectDir.childFile('pubspec.yaml');
    addAssetsToPubspec(pubspecFile, <String>['assets/shared.txt']);

    // Build the freeDebug variant.
    final File freeApkFile = await buildApk(projectDir, flavor: 'free');
    final Archive freeArchive = readApkArchive(freeApkFile);

    // Flutter assets are packaged regardless of flavor or build type.
    expectApkEntry(freeArchive, 'assets/flutter_assets/assets/shared.txt', 'shared_flutter_asset');

    // The selected flavor's assets are present; the other flavor's are not.
    expectApkEntry(freeArchive, 'assets/flavor_free.txt', 'free_flavor_asset_data');
    expectNoApkEntry(
      freeArchive,
      'assets/flavor_paid.txt',
      reason: 'the paid flavor source set must not contribute assets to a free build',
    );

    // The selected build type's assets are present; the other's are not.
    expectApkEntry(
      freeArchive,
      'assets/buildtype_debug.txt',
      'debug_buildtype_asset_data',
      reason: 'src/debug/assets must be merged into a debug variant APK',
    );
    expectNoApkEntry(
      freeArchive,
      'assets/buildtype_release.txt',
      reason: 'the release source set must not contribute assets to a debug build',
    );
  });
}
