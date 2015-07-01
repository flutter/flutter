// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:sky' as sky;

import 'package:mojo/core.dart' as core;
import 'package:mojom/mojo/asset_bundle/asset_bundle.mojom.dart';

import 'shell.dart' as shell;
import 'net/fetch.dart';

Future<sky.Image> _decodeImage(core.MojoDataPipeConsumer assetData) {
  Completer<sky.Image> completer = new Completer<sky.Image>();
  new sky.ImageDecoder(assetData.handle.h, completer.complete);
  return completer.future;
}

abstract class AssetBundle {
  void close();
  Future<sky.Image> fetchImage(String key);
}

class NetworkAssetBundle extends AssetBundle {
  NetworkAssetBundle(Uri base_url) : _base_url = base_url;

  final Uri _base_url;

  void close() { }

  Future<sky.Image> fetchImage(String name) async {
    Uri url = _base_url.resolve(name);
    core.MojoDataPipeConsumer assetData = (await fetchUrl(url.toString())).body;
    return await _decodeImage(assetData);
  }
}

Future _fetchAndUnpackBundle(String relativeUrl, AssetBundleProxy bundle) async {
  core.MojoDataPipeConsumer bundleData = (await fetchUrl(url)).body;
  AssetUnpackerProxy unpacker = new AssetUnpackerProxy.unbound();
  shell.requestService("mojo:asset_bundle", unpacker);
  unpacker.ptr.unpackZipStream(bundleData, bundle);
  unpacker.close();
}

class MojoAssetBundle extends AssetBundle {
  MojoAssetBundle(AssetBundleProxy this._bundle);

  factory MojoAssetBundle.fromNetwork(String relativeUrl) {
    AssetBundleProxy bundle = new AssetBundleProxy.unbound();
    _fetchAndUnpackBundle(relativeUrl, bundle);
    return new AssetBundle(bundle);
  }

  AssetBundleProxy _bundle;

  void close() {
    _bundle.close();
    _bundle = null;
  }

  Future<sky.Image> fetchImage(String name) async {
    core.MojoDataPipeConsumer assetData =
        (await _bundle.ptr.getAsStream(name)).assetData;
    return await _decodeImage(assetData);
  }
}
