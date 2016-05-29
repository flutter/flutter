// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/http.dart' as http;
import 'package:mojo/core.dart' as core;
import 'package:mojo_services/mojo/asset_bundle/asset_bundle.mojom.dart' as mojom;

import 'image_cache.dart';
import 'image_decoder.dart';
import 'image_resource.dart';
import 'shell.dart';

/// A collection of resources used by the application.
///
/// Asset bundles contain resources, such as images and strings, that can be
/// used by an application. Access to these resources is asynchronous so that
/// they can be transparently loaded over a network (e.g., from a
/// [NetworkAssetBundle]) or from the local file system without blocking the
/// application's user interface.
///
/// Applications have a [rootBundle], which contains the resources that were
/// packaged with the application when it was built. To add resources to the
/// [rootBundle] for your application, add them to the `assets` section of your
/// `flutter.yaml` manifest.
///
/// Rather than accessing the [rootBundle] global static directly, consider
/// obtaining the [AssetBundle] for the current [BuildContext] using
/// [DefaultAssetBundle.of]. This layer of indirection lets ancestor widgets
/// substitute a different [AssetBundle] (e.g., for testing or localization) at
/// runtime rather than directly replying upon the [rootBundle] created at build
/// time. For convenience, the [WidgetsApp] or [MaterialApp] widget at the top
/// of the widget hierarchy configures the [DefaultAssetBundle] to be the
/// [rootBundle].
///
/// See also:
///
///  * [DefaultAssetBundle]
///  * [NetworkAssetBundle]
///  * [rootBundle]
abstract class AssetBundle {
  /// Retrieve an image from the asset bundle.
  ImageResource loadImage(String key);

  /// Retrieve string from the asset bundle.
  Future<String> loadString(String key);

  /// Retrieve a binary resource from the asset bundle as a data stream.
  Future<core.MojoDataPipeConsumer> load(String key);

  @override
  String toString() => '$runtimeType@$hashCode()';
}

/// An [AssetBundle] that loads resources over the network.
class NetworkAssetBundle extends AssetBundle {
  /// Creates an network asset bundle that resolves asset keys as URLs relative
  /// to the given base URL.
  NetworkAssetBundle(Uri baseUrl) : _baseUrl = baseUrl;

  final Uri _baseUrl;

  String _urlFromKey(String key) => _baseUrl.resolve(key).toString();

  @override
  Future<core.MojoDataPipeConsumer> load(String key) async {
    return await http.readDataPipe(_urlFromKey(key));
  }

  /// Retrieve an image from the asset bundle.
  ///
  /// Images are cached in the [imageCache].
  @override
  ImageResource loadImage(String key) => imageCache.load(_urlFromKey(key));

  @override
  Future<String> loadString(String key) async {
    return (await http.get(_urlFromKey(key))).body;
  }

  @override
  String toString() => '$runtimeType@$hashCode($_baseUrl)';
}

/// An [AssetBundle] that adds a layer of caching to an asset bundle.
abstract class CachingAssetBundle extends AssetBundle {
  final Map<String, ImageResource> _imageResourceCache =
    <String, ImageResource>{};
  final Map<String, Future<String>> _stringCache =
    <String, Future<String>>{};

  /// Override to alter how images are retrieved from the underlying [AssetBundle].
  ///
  /// For example, the resolution-aware asset bundle created by [AssetVendor]
  /// overrides this function to fetch an image with the appropriate resolution.
  Future<ImageInfo> fetchImage(String key) async {
    return new ImageInfo(image: await decodeImageFromDataPipe(await load(key)));
  }

  @override
  ImageResource loadImage(String key) {
    return _imageResourceCache.putIfAbsent(key, () {
      return new ImageResource(fetchImage(key));
    });
  }

  Future<String> _fetchString(String key) async {
    core.MojoDataPipeConsumer pipe = await load(key);
    ByteData data = await core.DataPipeDrainer.drainHandle(pipe);
    return new String.fromCharCodes(new Uint8List.view(data.buffer));
  }

  @override
  Future<String> loadString(String key) {
    return _stringCache.putIfAbsent(key, () => _fetchString(key));
  }
}

/// An [AssetBundle] that loads resources from a Mojo service.
class MojoAssetBundle extends CachingAssetBundle {
  /// Creates an [AssetBundle] interface around the given [mojom.AssetBundleProxy] Mojo service.
  MojoAssetBundle(this._bundle);

  /// Retrieves the asset bundle located at the given URL, unpacks it, and provides it contents.
  factory MojoAssetBundle.fromNetwork(String relativeUrl) {
    mojom.AssetBundleProxy bundle = new mojom.AssetBundleProxy.unbound();
    _fetchAndUnpackBundle(relativeUrl, bundle);
    return new MojoAssetBundle(bundle);
  }

  static Future<Null> _fetchAndUnpackBundle(String relativeUrl, mojom.AssetBundleProxy bundle) async {
    core.MojoDataPipeConsumer bundleData = await http.readDataPipe(Uri.base.resolve(relativeUrl));
    mojom.AssetUnpackerProxy unpacker = shell.connectToApplicationService(
      'mojo:asset_bundle', mojom.AssetUnpacker.connectToService);
    unpacker.unpackZipStream(bundleData, bundle);
    unpacker.close();
  }

  mojom.AssetBundleProxy _bundle;

  @override
  Future<core.MojoDataPipeConsumer> load(String key) async {
    return (await _bundle.getAsStream(key)).assetData;
  }
}

AssetBundle _initRootBundle() {
  int h = ui.MojoServices.takeRootBundle();
  if (h == core.MojoHandle.INVALID)
    return new NetworkAssetBundle(Uri.base);
  core.MojoHandle handle = new core.MojoHandle(h);
  return new MojoAssetBundle(new mojom.AssetBundleProxy.fromHandle(handle));
}

/// The [AssetBundle] from which this application was loaded.
///
/// The [rootBundle] contains the resources that were packaged with the
/// application when it was built. To add resources to the [rootBundle] for your
/// application, add them to the `assets` section of your `flutter.yaml`
/// manifest.
///
/// Rather than using [rootBundle] directly, consider obtaining the
/// [AssetBundle] for the current [BuildContext] using [DefaultAssetBundle.of].
/// This layer of indirection lets ancestor widgets substitute a different
/// [AssetBundle] (e.g., for testing or localization) at runtime rather than
/// directly replying upon the [rootBundle] created at build time. For
/// convenience, the [WidgetsApp] or [MaterialApp] widget at the top of the
/// widget hierarchy configures the [DefaultAssetBundle] to be the [rootBundle].
///
/// See also:
///
///  * [DefaultAssetBundle]
///  * [NetworkAssetBundle]
final AssetBundle rootBundle = _initRootBundle();
