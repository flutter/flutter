// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/tasks/integration_tests.dart';
import 'package:path/path.dart' as path;
import 'package:standard_message_codec/standard_message_codec.dart';

import '../common.dart';

Uint8List _encodeAssetManifest(Map<String, List<Object?>> entries) {
  final ByteData encoded = const StandardMessageCodec().encodeMessage(entries)!;
  return encoded.buffer.asUint8List(encoded.offsetInBytes, encoded.lengthInBytes);
}

File _writeApk(
  Directory tempDir, {
  String name = 'app-paid-debug.apk',
  Uint8List? assetManifestBytes,
  bool compress = true,
}) {
  final archive = Archive();
  // Minimal 4-byte Dalvik executable magic header ('dex\n') to populate a non-empty APK zip.
  final dexHeaderBytes = Uint8List.fromList(<int>[0x64, 0x65, 0x78, 0x0a]);
  archive.addFile(ArchiveFile('classes.dex', dexHeaderBytes.length, dexHeaderBytes));
  if (assetManifestBytes != null) {
    final manifestEntry = ArchiveFile(
      'assets/flutter_assets/AssetManifest.bin',
      assetManifestBytes.length,
      assetManifestBytes,
    )..compress = compress;
    archive.addFile(manifestEntry);
  }
  final apkFile = File(path.join(tempDir.path, name));
  apkFile.writeAsBytesSync(ZipEncoder().encode(archive)!);
  return apkFile;
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('flavors_test.');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('succeeds when APK AssetManifest.bin includes paid asset and excludes free asset', () {
    final File apk = _writeApk(
      tempDir,
      assetManifestBytes: _encodeAssetManifest(<String, List<Object?>>{
        'assets/paid/paid.txt': <Object?>[
          <String, Object?>{'asset': 'assets/paid/paid.txt'},
        ],
      }),
    );

    final TaskResult result = checkFlavorAssetManifestInApk(
      apk,
      flavor: 'paid',
      includedAsset: 'assets/paid/paid.txt',
      excludedAsset: 'assets/free/free.txt',
      excludedFlavor: 'free',
    );
    expect(result.succeeded, isTrue, reason: result.message);
  });

  test('succeeds when AssetManifest.bin entry is stored uncompressed in APK', () {
    final File apk = _writeApk(
      tempDir,
      compress: false,
      assetManifestBytes: _encodeAssetManifest(<String, List<Object?>>{
        'assets/paid/paid.txt': <Object?>[
          <String, Object?>{'asset': 'assets/paid/paid.txt'},
        ],
      }),
    );

    final TaskResult result = checkFlavorAssetManifestInApk(
      apk,
      flavor: 'paid',
      includedAsset: 'assets/paid/paid.txt',
      excludedAsset: 'assets/free/free.txt',
      excludedFlavor: 'free',
    );
    expect(result.succeeded, isTrue, reason: result.message);
  });

  test('fails when APK file does not exist', () {
    final missingApk = File(path.join(tempDir.path, 'missing.apk'));

    final TaskResult result = checkFlavorAssetManifestInApk(
      missingApk,
      flavor: 'paid',
      includedAsset: 'assets/paid/paid.txt',
      excludedAsset: 'assets/free/free.txt',
      excludedFlavor: 'free',
    );
    expect(result.failed, isTrue);
    expect(result.message, contains(missingApk.path));
  });

  test('fails when APK does not contain AssetManifest.bin', () {
    final File apk = _writeApk(tempDir);

    final TaskResult result = checkFlavorAssetManifestInApk(
      apk,
      flavor: 'paid',
      includedAsset: 'assets/paid/paid.txt',
      excludedAsset: 'assets/free/free.txt',
      excludedFlavor: 'free',
    );
    expect(result.failed, isTrue);
    expect(result.message, contains('assets/flutter_assets/AssetManifest.bin'));
  });

  test('fails when AssetManifest.bin includes excluded flavor asset', () {
    final File apk = _writeApk(
      tempDir,
      assetManifestBytes: _encodeAssetManifest(<String, List<Object?>>{
        'assets/paid/paid.txt': <Object?>[],
        'assets/free/free.txt': <Object?>[],
      }),
    );

    final TaskResult result = checkFlavorAssetManifestInApk(
      apk,
      flavor: 'paid',
      includedAsset: 'assets/paid/paid.txt',
      excludedAsset: 'assets/free/free.txt',
      excludedFlavor: 'free',
    );
    expect(result.failed, isTrue);
    expect(result.message, contains('assets/free/free.txt'));
  });

  test('fails when AssetManifest.bin omits expected flavor asset', () {
    final File apk = _writeApk(
      tempDir,
      assetManifestBytes: _encodeAssetManifest(<String, List<Object?>>{}),
    );

    final TaskResult result = checkFlavorAssetManifestInApk(
      apk,
      flavor: 'paid',
      includedAsset: 'assets/paid/paid.txt',
      excludedAsset: 'assets/free/free.txt',
      excludedFlavor: 'free',
    );
    expect(result.failed, isTrue);
    expect(result.message, contains('assets/paid/paid.txt'));
  });
}
