// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:sky' as sky;

import 'package:mojo/core.dart' as core;
import 'package:mojom/mojo/asset_bundle/asset_bundle.mojom.dart';

import 'net/fetch.dart';
import 'net/image_cache.dart' as image_cache;
import 'shell.dart' as shell;

abstract class AssetBundle {
  void close();
  Future<sky.Image> loadImage(String key);
}

class NetworkAssetBundle extends AssetBundle {
  NetworkAssetBundle(Uri baseUrl) : _baseUrl = baseUrl;

  final Uri _baseUrl;

  void close() { }

  Future<sky.Image> loadImage(String name) {
    Uri url = _baseUrl.resolve(name);
    return image_cache.load(url.toString());
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
    return new MojoAssetBundle(bundle);
  }

  AssetBundleProxy _bundle;
  Map<String, Future<sky.Image>> _imageCache = new Map<String, Future<sky.Image>>();

  void close() {
    _bundle.close();
    _bundle = null;
    _imageCache = null;
  }

  Future<sky.Image> loadImage(String name) {
    return _imageCache.putIfAbsent(name, () {
      Completer<sky.Image> completer = new Completer<sky.Image>();
      _bundle.ptr.getAsStream(name).then((response) {
        new sky.ImageDecoder(response.assetData.handle.h, completer.complete);
      });
      return completer.future;
    });
  }
}
