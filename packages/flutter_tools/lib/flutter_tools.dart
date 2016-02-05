// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library flutter_tools;

import 'dart:async';

import 'package:archive/archive.dart';

import 'src/flx.dart' as flx;

/// Assembles a Flutter .flx file from a pre-existing manifest descriptor
/// and a pre-compiled snapshot.
Future<int> assembleFlx({
  Map manifestDescriptor: const {},
  ArchiveFile snapshotFile: null,
  String assetBasePath: flx.defaultAssetBasePath,
  String materialAssetBasePath: flx.defaultMaterialAssetBasePath,
  String outputPath: flx.defaultFlxOutputPath,
  String privateKeyPath: flx.defaultPrivateKeyPath
}) async {
  return flx.assemble(
      manifestDescriptor: manifestDescriptor,
      snapshotFile: snapshotFile,
      assetBasePath: assetBasePath,
      materialAssetBasePath: materialAssetBasePath,
      outputPath: outputPath,
      privateKeyPath: privateKeyPath
  );
}
