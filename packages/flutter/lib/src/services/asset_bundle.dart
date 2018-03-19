// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'http_client.dart';
import 'platform_messages.dart';

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
/// [rootBundle] for your application, add them to the `assets` subsection of
/// the `flutter` section of your application's `pubspec.yaml` manifest.
///
/// For example:
///
/// ```yaml
/// name: my_awesome_application
/// flutter:
///   assets:
///    - images/hamilton.jpeg
///    - images/lafayette.jpeg
/// ```
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
  ///
  /// Throws an exception if the asset is not found.
  Future<ByteData> load(String key);

  /// Retrieve a string from the asset bundle.
  ///
  /// Throws an exception if the asset is not found.
  ///
  /// If the `cache` argument is set to false, then the data will not be
  /// cached, and reading the data may bypass the cache. This is useful if the
  /// caller is going to be doing its own caching. (It might not be cached if
  /// it's set to true either, that depends on the asset bundle
  /// implementation.)
  Future<String> loadString(String key, { bool cache: true });

  /// Retrieve a string from the asset bundle, parse it with the given function,
  /// and return the function's result.
  ///
  /// Implementations may cache the result, so a particular key should only be
  /// used with one parser for the lifetime of the asset bundle.
  Future<T> loadStructuredData<T>(String key, Future<T> parser(String value));

  /// If this is a caching asset bundle, and the given key describes a cached
  /// asset, then evict the asset from the cache so that the next time it is
  /// loaded, the cache will be reread from the asset bundle.
  void evict(String key) { }

  @override
  String toString() => '${describeIdentity(this)}()';
}

/// An [AssetBundle] that loads resources over the network.
///
/// This asset bundle does not cache any resources, though the underlying
/// network stack may implement some level of caching itself.
class NetworkAssetBundle extends AssetBundle {
  /// Creates an network asset bundle that resolves asset keys as URLs relative
  /// to the given base URL.
  NetworkAssetBundle(Uri baseUrl)
    : _baseUrl = baseUrl,
      _httpClient = createHttpClient();

  final Uri _baseUrl;
  final http.Client _httpClient;

  String _urlFromKey(String key) => _baseUrl.resolve(key).toString();

  @override
  Future<ByteData> load(String key) async {
    final http.Response response = await _httpClient.get(_urlFromKey(key));
    if (response.statusCode != 200)
      throw new FlutterError('Unable to load asset: $key');
    return response.bodyBytes.buffer.asByteData();
  }

  @override
  Future<String> loadString(String key, { bool cache: true }) async {
    final http.Response response = await _httpClient.get(_urlFromKey(key));
    if (response.statusCode != 200)
      throw new FlutterError(
          'Unable to load asset: $key\n'
          'HTTP status code: ${response.statusCode}'
      );
    return response.body;
  }

  /// Retrieve a string from the asset bundle, parse it with the given function,
  /// and return the function's result.
  ///
  /// The result is not cached. The parser is run each time the resource is
  /// fetched.
  @override
  Future<T> loadStructuredData<T>(String key, Future<T> parser(String value)) async {
    assert(key != null);
    assert(parser != null);
    return parser(await loadString(key));
  }

  // TODO(ianh): Once the underlying network logic learns about caching, we
  // should implement evict().

  @override
  String toString() => '${describeIdentity(this)}($_baseUrl)';
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
    final ByteData data = await load(key);
    if (data == null)
      throw new FlutterError('Unable to load asset: $key');
    if (data.lengthInBytes < 10 * 1024) {
      // 10KB takes about 3ms to parse on a Pixel 2 XL.
      // See: https://github.com/dart-lang/sdk/issues/31954
      return utf8.decode(data.buffer.asUint8List());
    }
    return compute(_utf8decode, data, debugLabel: 'UTF8 decode for "$key"');
  }

  static String _utf8decode(ByteData data) {
    return utf8.decode(data.buffer.asUint8List());
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
  Future<T> loadStructuredData<T>(String key, Future<T> parser(String value)) {
    assert(key != null);
    assert(parser != null);
    if (_structuredDataCache.containsKey(key))
      return _structuredDataCache[key];
    Completer<T> completer;
    Future<T> result;
    loadString(key, cache: false).then<T>(parser).then<void>((T value) {
      result = new SynchronousFuture<T>(value);
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
    completer = new Completer<T>();
    _structuredDataCache[key] = completer.future;
    return completer.future;
  }

  @override
  void evict(String key) {
    _stringCache.remove(key);
    _structuredDataCache.remove(key);
  }
}

/// An [AssetBundle] that loads resources using platform messages.
class PlatformAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final Uint8List encoded = utf8.encoder.convert(new Uri(path: key).path);
    final ByteData asset =
        await BinaryMessages.send('flutter/assets', encoded.buffer.asByteData());
    if (asset == null)
      throw new FlutterError('Unable to load asset: $key');
    return asset;
  }
}

AssetBundle _initRootBundle() {
  return new PlatformAssetBundle();
}

/// The [AssetBundle] from which this application was loaded.
///
/// The [rootBundle] contains the resources that were packaged with the
/// application when it was built. To add resources to the [rootBundle] for your
/// application, add them to the `assets` subsection of the `flutter` section of
/// your application's `pubspec.yaml` manifest.
///
/// For example:
///
/// ```yaml
/// name: my_awesome_application
/// flutter:
///   assets:
///    - images/hamilton.jpeg
///    - images/lafayette.jpeg
/// ```
///
/// Rather than using [rootBundle] directly, consider obtaining the
/// [AssetBundle] for the current [BuildContext] using [DefaultAssetBundle.of].
/// This layer of indirection lets ancestor widgets substitute a different
/// [AssetBundle] at runtime (e.g., for testing or localization) rather than
/// directly replying upon the [rootBundle] created at build time. For
/// convenience, the [WidgetsApp] or [MaterialApp] widget at the top of the
/// widget hierarchy configures the [DefaultAssetBundle] to be the [rootBundle].
///
/// See also:
///
///  * [DefaultAssetBundle]
///  * [NetworkAssetBundle]
final AssetBundle rootBundle = _initRootBundle();
