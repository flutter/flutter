// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:sky' as sky;
import 'dart:typed_data';

import 'package:mojo/core.dart' as core;
import 'package:mojom/mojo/asset_bundle/asset_bundle.mojom.dart';

import 'shell.dart' as shell;
import 'net/fetch.dart';

Future<sky.Image> _decodeImage(core.MojoDataPipeConsumer assetData) {
  Completer<sky.Image> completer = new Completer();
  new sky.ImageDecoder(assetData.handle.h, completer.complete);
  return completer.future;
}

class AssetBundle {
  AssetBundle(AssetBundleProxy this._bundle);

  void close() {
    _bundle.close();
    _bundle = null;
  }

  Future<sky.Image> fetchImage(String path) async {
    core.MojoDataPipeConsumer assetData =
        (await _bundle.ptr.getAsStream(path)).assetData;
    return await _decodeImage(assetData);
  }

  AssetBundleProxy _bundle;
}

Future<AssetBundle> fetchAssetBundle(String url) async {
  core.MojoDataPipeConsumer bundleData = (await fetchUrl(url)).body;

  AssetUnpackerProxy unpacker = new AssetUnpackerProxy.unbound();
  shell.requestService("mojo:asset_bundle", unpacker);
  AssetBundleProxy bundle = new AssetBundleProxy.unbound();
  unpacker.ptr.unpackZipStream(bundleData, bundle);
  unpacker.close();

  return new AssetBundle(bundle);
}
