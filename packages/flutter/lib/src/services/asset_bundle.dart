// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/http.dart' as http;
import 'package:mojo/core.dart' as core;
import 'package:flutter_services/mojo/asset_bundle/asset_bundle.dart' as mojom;

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
  /// Retrieve a binary resource from the asset bundle as a data stream.
  Future<core.MojoDataPipeConsumer> load(String key);

  /// Retrieve a string from the asset bundle.
  ///
  /// If the `cache` argument is set to `false`, then the data will not be
  /// cached, and reading the data may bypass the cache. This is useful if the
  /// caller is going to be doing its own caching. (It might not be cached if
  /// it's set to `true` either, that depends on the asset bundle
  /// implementation.)
  Future<String> loadString(String key, { bool cache: true });

  /// Retrieve a string from the asset bundle, parse it with the given function,
  /// and return the function's result.
  ///
  /// Implementations may cache the result, so a particular key should only be
  /// used with one parser for the lifetime of the asset bundle.
  Future<dynamic> loadStructuredData(String key, Future<dynamic> parser(String value));

  /// If this is a caching asset bundle, and the given key describes a cached
  /// asset, then evict the asset from the cache so that the next time it is
  /// loaded, the cache will be reread from the asset bundle.
  void evict(String key) { }

  @override
  String toString() => '$runtimeType@$hashCode()';
}

/// An [AssetBundle] that loads resources over the network.
///
/// This asset bundle does not cache any resources, though the underlying
/// network stack may implement some level of caching itself.
class NetworkAssetBundle extends AssetBundle {
  /// Creates an network asset bundle that resolves asset keys as URLs relative
  /// to the given base URL.
  NetworkAssetBundle(Uri baseUrl) : _baseUrl = baseUrl;

  final Uri _baseUrl;

  String _urlFromKey(String key) => _baseUrl.resolve(key).toString();

  @override
  Future<core.MojoDataPipeConsumer> load(String key) async {
    http.Response response = await http.get(_urlFromKey(key));
    if (response.statusCode == 200)
      return null;
    core.MojoDataPipe pipe = new core.MojoDataPipe();
    core.DataPipeFiller.fillHandle(pipe.producer, response.bodyBytes.buffer.asByteData());
    return pipe.consumer;
  }

  @override
  Future<String> loadString(String key, { bool cache: true }) async {
    http.Response response = await http.get(_urlFromKey(key));
    return response.statusCode == 200 ? response.body : null;
  }

  /// Retrieve a string from the asset bundle, parse it with the given function,
  /// and return the function's result.
  ///
  /// The result is not cached. The parser is run each time the resource is
  /// fetched.
  @override
  Future<dynamic> loadStructuredData(String key, Future<dynamic> parser(String value)) async {
    assert(key != null);
    assert(parser != null);
    return parser(await loadString(key));
  }

  // TODO(ianh): Once the underlying network logic learns about caching, we
  // should implement evict().

  @override
  String toString() => '$runtimeType@$hashCode($_baseUrl)';
}

/// An [AssetBundle] that permanently caches string and structured resources
/// that have been fetched.
///
/// Strings (for [loadString] and [loadStructuredData]) are decoded as UTF-8.
/// Data that is cached is cached for the lifetime of the asset bundle
/// (typically the lifetime of the application).
///
/// Binary resources (from [load]) are not cached.
abstract class CachingAssetBundle extends AssetBundle {
  // TODO(ianh): Replace this with an intelligent cache, see https://github.com/flutter/flutter/issues/3568
  final Map<String, Future<String>> _stringCache = <String, Future<String>>{};
  final Map<String, Future<dynamic>> _structuredDataCache = <String, Future<dynamic>>{};

  @override
  Future<String> loadString(String key, { bool cache: true }) {
    if (cache)
      return _stringCache.putIfAbsent(key, () => _fetchString(key));
    return _fetchString(key);
  }

  Future<String> _fetchString(String key) async {
    final core.MojoDataPipeConsumer pipe = await load(key);
    final ByteData data = await core.DataPipeDrainer.drainHandle(pipe);
    return UTF8.decode(new Uint8List.view(data.buffer));
  }

  /// Retrieve a string from the asset bundle, parse it with the given function,
  /// and return the function's result.
  ///
  /// The result of parsing the string is cached (the string itself is not,
  /// unless you also fetch it with [loadString]). For any given `key`, the
  /// `parser` is only run the first time.
  ///
  /// Once the value has been parsed, the future returned by this function for
  /// subsequent calls will be a [SynchronousFuture], which resolves its
  /// callback synchronously.
  @override
  Future<dynamic> loadStructuredData(String key, Future<dynamic> parser(String value)) {
    assert(key != null);
    assert(parser != null);
    if (_structuredDataCache.containsKey(key))
      return _structuredDataCache[key];
    Completer<dynamic> completer;
    Future<dynamic> result;
    loadString(key, cache: false).then(parser).then((dynamic value) {
      result = new SynchronousFuture<dynamic>(value);
      _structuredDataCache[key] = result;
      if (completer != null) {
        // We already returned from the loadStructuredData function, which means
        // we are in the asynchronous mode. Pass the value to the completer. The
        // completer's future is what we returned.
        completer.complete(value);
      }
    });
    if (result != null) {
      // The code above ran synchronously, and came up with an answer.
      // Return the SynchronousFuture that we created above.
      return result;
    }
    // The code above hasn't yet run its "then" handler yet. Let's prepare a
    // completer for it to use when it does run.
    completer = new Completer<dynamic>();
    _structuredDataCache[key] = completer.future;
    return completer.future;
  }

  @override
  void evict(String key) {
    _stringCache.remove(key);
    _structuredDataCache.remove(key);
  }
}

/// An [AssetBundle] that loads resources from a Mojo service.
class MojoAssetBundle extends CachingAssetBundle {
  /// Creates an [AssetBundle] interface around the given [mojom.AssetBundleProxy] Mojo service.
  MojoAssetBundle(this._bundle);

  mojom.AssetBundleProxy _bundle;

  @override
  Future<core.MojoDataPipeConsumer> load(String key) {
    Completer<core.MojoDataPipeConsumer> completer = new Completer<core.MojoDataPipeConsumer>();
    _bundle.getAsStream(key, (core.MojoDataPipeConsumer assetData) {
      completer.complete(assetData);
    });
    return completer.future;
  }
}

AssetBundle _initRootBundle() {
  int h = ui.MojoServices.takeRootBundle();
  if (h == core.MojoHandle.INVALID) {
    assert(() {
      if (!Platform.environment.containsKey('FLUTTER_TEST')) {
        FlutterError.reportError(new FlutterErrorDetails(
          exception:
            'dart:ui MojoServices.takeRootBundle() returned an invalid handle.\n'
            'This might happen if the Dart VM was restarted without restarting the underlying Flutter engine, '
            'or if the Flutter framework\'s rootBundle object was first accessed after some other code called '
            'takeRootBundle. The root bundle handle can only be obtained once in the lifetime of the Flutter '
            'engine. Mojo handles cannot be shared.\n'
            'The rootBundle object will be initialised with a NetworkAssetBundle instead of a MojoAssetBundle. '
            'This may cause subsequent network errors.',
          library: 'services library',
          context: 'while initialising the root bundle'
        ));
      }
      return true;
    });
    return new NetworkAssetBundle(Uri.base);
  }
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
/// [AssetBundle] at runtime (e.g., for testing or localization) rather than
/// directly replying upon the [rootBundle] created at build time. For
/// convenience, the [WidgetsApp] or [MaterialApp] widget at the top of the
/// widget hierarchy configures the [DefaultAssetBundle] to be the [rootBundle].
///
/// In normal operation, the [rootBundle] is a [MojoAssetBundle], though it can
/// also end up being a [NetworkAssetBundle] in some cases (e.g. if the
/// application's resources are being served from a local HTTP server).
///
/// See also:
///
///  * [DefaultAssetBundle]
///  * [NetworkAssetBundle]
final AssetBundle rootBundle = _initRootBundle();
