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

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = createResolvedTempDirectorySync('android_gradle_asset_merging.');
  });

  tearDown(() {
    tryToDelete(tempDir);
  });

  Archive readApkArchive(File apkFile) {
    expect(apkFile, exists);
    final List<int> bytes = apkFile.readAsBytesSync();
    return ZipDecoder().decodeBytes(bytes);
  }

  String readArchiveFileString(ArchiveFile file) {
    final dynamic rawContent = file.content;
    final List<int> content = rawContent is List<int> ? rawContent : <int>[];
    return utf8.decode(content, allowMalformed: true);
  }

  void addAssetsToPubspec(File pubspecFile, List<String> assets) {
    final String content = pubspecFile.readAsStringSync();
    expect(
      content.contains('uses-material-design: true'),
      isTrue,
      reason: 'pubspec.yaml missing uses-material-design entry',
    );
    final String assetLines = assets.map((String a) => '    - $a').join('\n');
    final String updated = content.replaceFirst(
      'uses-material-design: true',
      'uses-material-design: true\n  assets:\n$assetLines',
    );
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

  Future<File> buildApk(Directory projectDir, {String mode = '--debug', String? flavor}) async {
    final ProcessResult buildResult = await processManager.run(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'build',
      'apk',
      mode,
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

  testWithoutContext(
    'Flutter assets, directory assets, resolution variants, and native Android assets coexist in APK',
    () async {
      final Directory projectDir = await createApp(tempDir);

      // Create Flutter assets.
      final Directory assetsDir = projectDir.childDirectory('assets');
      final Directory nestedDir = assetsDir.childDirectory('nested');
      final Directory resolutionDir = assetsDir.childDirectory('2.0x');
      assetsDir.createSync(recursive: true);
      nestedDir.createSync(recursive: true);
      resolutionDir.createSync(recursive: true);

      final File singleAsset = assetsDir.childFile('single_asset.txt');
      singleAsset.writeAsStringSync('flutter_single_asset_content');

      final File nestedAsset = nestedDir.childFile('dir_asset.txt');
      nestedAsset.writeAsStringSync('flutter_nested_asset_content');

      final File baseImage = assetsDir.childFile('image.png');
      baseImage.writeAsStringSync('flutter_image_1x_content');

      final File resImage = resolutionDir.childFile('image.png');
      resImage.writeAsStringSync('flutter_image_2x_content');

      // Create native Android assets under android/app/src/main/assets/.
      final Directory nativeAssetsDir = projectDir
          .childDirectory('android')
          .childDirectory('app')
          .childDirectory('src')
          .childDirectory('main')
          .childDirectory('assets');
      final Directory nativeCustomDir = nativeAssetsDir.childDirectory('custom');
      nativeCustomDir.createSync(recursive: true);

      final File nativeAsset = nativeAssetsDir.childFile('native_asset.txt');
      nativeAsset.writeAsStringSync('native_asset_content');

      final File nativeNested = nativeCustomDir.childFile('config.json');
      nativeNested.writeAsStringSync('{"native_config": true}');

      // Configure pubspec.yaml with Flutter asset references.
      final File pubspecFile = projectDir.childFile('pubspec.yaml');
      expect(pubspecFile, exists);
      addAssetsToPubspec(pubspecFile, <String>[
        'assets/single_asset.txt',
        'assets/nested/',
        'assets/image.png',
        'assets/2.0x/image.png',
      ]);

      final File apkFile = await buildApk(projectDir);
      final Archive archive = readApkArchive(apkFile);

      // Verify Flutter assets packaged under assets/flutter_assets/.
      final ArchiveFile? singleAssetEntry = archive.findFile(
        'assets/flutter_assets/assets/single_asset.txt',
      );
      expect(singleAssetEntry, isNotNull);
      expect(readArchiveFileString(singleAssetEntry!), 'flutter_single_asset_content');

      final ArchiveFile? nestedAssetEntry = archive.findFile(
        'assets/flutter_assets/assets/nested/dir_asset.txt',
      );
      expect(nestedAssetEntry, isNotNull);
      expect(readArchiveFileString(nestedAssetEntry!), 'flutter_nested_asset_content');

      final ArchiveFile? baseImageEntry = archive.findFile(
        'assets/flutter_assets/assets/image.png',
      );
      expect(baseImageEntry, isNotNull);
      expect(readArchiveFileString(baseImageEntry!), 'flutter_image_1x_content');

      final ArchiveFile? resImageEntry = archive.findFile(
        'assets/flutter_assets/assets/2.0x/image.png',
      );
      expect(resImageEntry, isNotNull);
      expect(readArchiveFileString(resImageEntry!), 'flutter_image_2x_content');

      // Verify native Android assets packaged under assets/.
      final ArchiveFile? nativeAssetEntry = archive.findFile('assets/native_asset.txt');
      expect(nativeAssetEntry, isNotNull);
      expect(readArchiveFileString(nativeAssetEntry!), 'native_asset_content');

      final ArchiveFile? nativeNestedEntry = archive.findFile('assets/custom/config.json');
      expect(nativeNestedEntry, isNotNull);
      expect(readArchiveFileString(nativeNestedEntry!), '{"native_config": true}');
    },
  );

  testWithoutContext('incremental asset add and remove synchronizes output APK cleanly', () async {
    final Directory projectDir = await createApp(tempDir);

    final Directory assetsDir = projectDir.childDirectory('assets');
    assetsDir.createSync(recursive: true);

    final File asset1 = assetsDir.childFile('asset1.txt');
    asset1.writeAsStringSync('asset_one_initial');

    final File asset2 = assetsDir.childFile('asset2.txt');
    asset2.writeAsStringSync('asset_two_initial');

    final File pubspecFile = projectDir.childFile('pubspec.yaml');
    expect(pubspecFile, exists);
    addAssetsToPubspec(pubspecFile, <String>['assets/asset1.txt', 'assets/asset2.txt']);

    // Build 1: Initial debug APK.
    final File apkFile = await buildApk(projectDir);
    Archive archive = readApkArchive(apkFile);

    expect(archive.findFile('assets/flutter_assets/assets/asset1.txt'), isNotNull);
    expect(archive.findFile('assets/flutter_assets/assets/asset2.txt'), isNotNull);

    // Mutate assets: delete asset2, add asset3, update pubspec.yaml.
    asset2.deleteSync();
    final File asset3 = assetsDir.childFile('asset3.txt');
    asset3.writeAsStringSync('asset_three_added');

    final String currentPubspec = pubspecFile.readAsStringSync();
    final String updatedPubspec = currentPubspec.replaceFirst(
      '- assets/asset2.txt',
      '- assets/asset3.txt',
    );
    pubspecFile.writeAsStringSync(updatedPubspec);

    // Build 2: Incremental debug APK without clean.
    await buildApk(projectDir);

    archive = readApkArchive(apkFile);

    expect(archive.findFile('assets/flutter_assets/assets/asset1.txt'), isNotNull);
    expect(archive.findFile('assets/flutter_assets/assets/asset3.txt'), isNotNull);
    expect(
      archive.findFile('assets/flutter_assets/assets/asset2.txt'),
      isNull,
      reason: 'asset2.txt should have been pruned from the APK during incremental sync',
    );
  });

  testWithoutContext(
    'generated Flutter assets take precedence over static src/main/assets on path collision without build failure',
    () async {
      final Directory projectDir = await createApp(tempDir);

      // Create a Flutter asset in assets/collision.txt.
      final Directory assetsDir = projectDir.childDirectory('assets');
      assetsDir.createSync(recursive: true);
      final File flutterAsset = assetsDir.childFile('collision.txt');
      flutterAsset.writeAsStringSync('flutter_version');

      // Create a native asset at android/app/src/main/assets/flutter_assets/assets/collision.txt.
      final Directory nativeCollisionDir = projectDir
          .childDirectory('android')
          .childDirectory('app')
          .childDirectory('src')
          .childDirectory('main')
          .childDirectory('assets')
          .childDirectory('flutter_assets')
          .childDirectory('assets');
      nativeCollisionDir.createSync(recursive: true);
      final File nativeAsset = nativeCollisionDir.childFile('collision.txt');
      nativeAsset.writeAsStringSync('native_override_version');

      final File pubspecFile = projectDir.childFile('pubspec.yaml');
      addAssetsToPubspec(pubspecFile, <String>['assets/collision.txt']);

      final File apkFile = await buildApk(projectDir);
      final Archive archive = readApkArchive(apkFile);

      final ArchiveFile? collisionEntry = archive.findFile(
        'assets/flutter_assets/assets/collision.txt',
      );
      expect(collisionEntry, isNotNull);
      expect(
        readArchiveFileString(collisionEntry!),
        'flutter_version',
        reason:
            'AGP resolves asset collisions deterministically, giving generated source directories precedence over main assets',
      );
    },
  );

  testWithoutContext(
    'flavor-specific native assets are packaged into corresponding flavor APKs',
    () async {
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

      // Create flavor-specific assets.
      final Directory freeAssetsDir = projectDir
          .childDirectory('android')
          .childDirectory('app')
          .childDirectory('src')
          .childDirectory('free')
          .childDirectory('assets');
      freeAssetsDir.createSync(recursive: true);
      final File freeAsset = freeAssetsDir.childFile('flavor_free.txt');
      freeAsset.writeAsStringSync('free_flavor_asset_data');

      final Directory paidAssetsDir = projectDir
          .childDirectory('android')
          .childDirectory('app')
          .childDirectory('src')
          .childDirectory('paid')
          .childDirectory('assets');
      paidAssetsDir.createSync(recursive: true);
      final File paidAsset = paidAssetsDir.childFile('flavor_paid.txt');
      paidAsset.writeAsStringSync('paid_flavor_asset_data');

      // Create standard Flutter asset.
      final Directory assetsDir = projectDir.childDirectory('assets');
      assetsDir.createSync(recursive: true);
      final File sharedAsset = assetsDir.childFile('shared.txt');
      sharedAsset.writeAsStringSync('shared_flutter_asset');

      final File pubspecFile = projectDir.childFile('pubspec.yaml');
      addAssetsToPubspec(pubspecFile, <String>['assets/shared.txt']);

      // Build flavor "free".
      final File freeApkFile = await buildApk(projectDir, flavor: 'free');
      final Archive freeArchive = readApkArchive(freeApkFile);

      // Free flavor must contain shared Flutter asset and free flavor asset, but not paid asset.
      expect(freeArchive.findFile('assets/flutter_assets/assets/shared.txt'), isNotNull);
      final ArchiveFile? freeAssetEntry = freeArchive.findFile('assets/flavor_free.txt');
      expect(freeAssetEntry, isNotNull);
      expect(readArchiveFileString(freeAssetEntry!), 'free_flavor_asset_data');
      expect(freeArchive.findFile('assets/flavor_paid.txt'), isNull);
    },
  );
}
