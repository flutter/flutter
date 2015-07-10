// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:sky' as sky;
import 'dart:sky.internals' as internals;
import 'dart:typed_data';

import 'package:mojo/core.dart' as core;
import 'package:mojom/mojo/asset_bundle/asset_bundle.mojom.dart';

import 'net/fetch.dart';
import 'net/image_cache.dart' as image_cache;
import 'shell.dart' as shell;

abstract class AssetBundle {
  void close();
  Future<sky.Image> loadImage(String key);
  Future<String> loadString(String key);
}

class NetworkAssetBundle extends AssetBundle {
  NetworkAssetBundle(Uri baseUrl) : _baseUrl = baseUrl;

  final Uri _baseUrl;

  void close() { }

  Future<sky.Image> loadImage(String key) {
    return image_cache.load(_baseUrl.resolve(key).toString());
  }

  Future<String> loadString(String key) {
    return fetchString(_baseUrl.resolve(key).toString());
  }
}

Future _fetchAndUnpackBundle(String relativeUrl, AssetBundleProxy bundle) async {
  core.MojoDataPipeConsumer bundleData = (await fetchUrl(relativeUrl)).body;
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

  final AssetBundleProxy _bundle;
  Map<String, Future<sky.Image>> _imageCache = new Map<String, Future<sky.Image>>();
  Map<String, Future<String>> _stringCache = new Map<String, Future<String>>();

  void close() {
    _bundle.close();
    _bundle = null;
    _imageCache = null;
  }

  Future<sky.Image> loadImage(String key) {
    return _imageCache.putIfAbsent(key, () {
      Completer<sky.Image> completer = new Completer<sky.Image>();
      _bundle.ptr.getAsStream(key).then((response) {
        new sky.ImageDecoder(response.assetData.handle.h, completer.complete);
      });
      return completer.future;
    });
  }

  Future<String> _fetchString(String key) async {
    core.MojoDataPipeConsumer pipe = (await _bundle.ptr.getAsStream(key)).assetData;
    ByteData data = await core.DataPipeDrainer.drainHandle(pipe);
    return new String.fromCharCodes(new Uint8List.view(data.buffer));
  }

  Future<String> loadString(String key) {
    return _stringCache.putIfAbsent(key, () => _fetchString(key));
  }
}

AssetBundle _initRootBundle() {
  try {
    AssetBundleProxy bundle = new AssetBundleProxy.fromHandle(
        new core.MojoHandle(internals.takeRootBundleHandle()));
    return new MojoAssetBundle(bundle);
  } catch (e) {
    return null;
  }
}

final AssetBundle rootBundle = _initRootBundle();
