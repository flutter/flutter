// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'src/flx.dart' as flx;

/// Assembles a Flutter .flx file from a pre-existing manifest descriptor and a
/// pre-compiled snapshot.
Future<int> assembleFlx({
  Map<String, dynamic> manifestDescriptor: const <String, dynamic>{},
  File snapshotFile: null,
  String assetBasePath: flx.defaultAssetBasePath,
  Map<String, String> assetPathOverrides: const <String, String>{},
  String outputPath: flx.defaultFlxOutputPath,
  String privateKeyPath: flx.defaultPrivateKeyPath
}) async {
  return flx.assemble(
    manifestDescriptor: manifestDescriptor,
    snapshotFile: snapshotFile,
    assetBasePath: assetBasePath,
    assetPathOverrides: assetPathOverrides,
    outputPath: outputPath,
    privateKeyPath: privateKeyPath
  );
}
