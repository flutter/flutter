// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show hashValues;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'image_provider.dart';

import 'image_resolution.dart' as image_resolution;

const String _kAssetManifestFileName = 'AssetManifest.json';

/// The dart:io implementation of [image_resolution.AssetImage].
class AssetImage extends AssetBundleImageProvider implements image_resolution.AssetImage {
  /// Creates an object that fetches an image from an asset bundle.
  ///
  /// The [assetName] argument must not be null. It should name the main asset
  /// from the set of images to choose from. The [package] argument must be
  /// non-null when fetching an asset that is included in package. See the
  /// documentation for the [AssetImage] class itself for details.
  const AssetImage(
    this.assetName, {
    this.bundle,
    this.package,
  }) : assert(assetName != null);

  @override
  final String assetName;

  @override
  String get keyName => package == null ? assetName : 'packages/$package/$assetName';

  @override
  final AssetBundle bundle;

  @override
  final String package;

  // We assume the main asset is designed for a device pixel ratio of 1.0
  static const double _naturalResolution = 1.0;

  @override
  Future<AssetBundleImageKey> obtainKey(ImageConfiguration configuration) {
    // This function tries to return a SynchronousFuture if possible. We do this
    // because otherwise showing an image would always take at least one frame,
    // which would be sad. (This code is called from inside build/layout/paint,
    // which all happens in one call frame; using native Futures would guarantee
    // that we resolve each future in a new call frame, and thus not in this
    // build/layout/paint sequence.)
    final AssetBundle chosenBundle = bundle ?? configuration.bundle ?? rootBundle;
    Completer<AssetBundleImageKey> completer;
    Future<AssetBundleImageKey> result;

    chosenBundle.loadStructuredData<Map<String, List<String>>>(_kAssetManifestFileName, _manifestParser).then<void>(
      (Map<String, List<String>> manifest) {
        final String chosenName = _chooseVariant(
          keyName,
          configuration,
          manifest == null ? null : manifest[keyName],
        );
        final double chosenScale = _parseScale(chosenName);
        final AssetBundleImageKey key = AssetBundleImageKey(
          bundle: chosenBundle,
          name: chosenName,
          scale: chosenScale,
        );
        if (completer != null) {
          // We already returned from this function, which means we are in the
          // asynchronous mode. Pass the value to the completer. The completer's
          // future is what we returned.
          completer.complete(key);
        } else {
          // We haven't yet returned, so we must have been called synchronously
          // just after loadStructuredData returned (which means it provided us
          // with a SynchronousFuture). Let's return a SynchronousFuture
          // ourselves.
          result = SynchronousFuture<AssetBundleImageKey>(key);
        }
      }
    ).catchError((dynamic error, StackTrace stack) {
      // We had an error. (This guarantees we weren't called synchronously.)
      // Forward the error to the caller.
      assert(completer != null);
      assert(result == null);
      completer.completeError(error, stack);
    });
    if (result != null) {
      // The code above ran synchronously, and came up with an answer.
      // Return the SynchronousFuture that we created above.
      return result;
    }
    // The code above hasn't yet run its "then" handler yet. Let's prepare a
    // completer for it to use when it does run.
    completer = Completer<AssetBundleImageKey>();
    return completer.future;
  }

  static Future<Map<String, List<String>>> _manifestParser(String jsonData) {
    if (jsonData == null)
      return SynchronousFuture<Map<String, List<String>>>(null);
    // TODO(ianh): JSON decoding really shouldn't be on the main thread.
    final Map<String, dynamic> parsedJson = json.decode(jsonData);
    final Iterable<String> keys = parsedJson.keys;
    final Map<String, List<String>> parsedManifest =
        Map<String, List<String>>.fromIterables(keys,
          keys.map<List<String>>((String key) => List<String>.from(parsedJson[key])));
    // TODO(ianh): convert that data structure to the right types.
    return SynchronousFuture<Map<String, List<String>>>(parsedManifest);
  }

  String _chooseVariant(String main, ImageConfiguration config, List<String> candidates) {
    if (config.devicePixelRatio == null || candidates == null || candidates.isEmpty)
      return main;
    // TODO(ianh): Consider moving this parsing logic into _manifestParser.
    final SplayTreeMap<double, String> mapping = SplayTreeMap<double, String>();
    for (String candidate in candidates)
      mapping[_parseScale(candidate)] = candidate;
    // TODO(ianh): implement support for config.locale, config.textDirection,
    // config.size, config.platform (then document this over in the Image.asset
    // docs)
    return _findNearest(mapping, config.devicePixelRatio);
  }

  // Return the value for the key in a [SplayTreeMap] nearest the provided key.
  String _findNearest(SplayTreeMap<double, String> candidates, double value) {
    if (candidates.containsKey(value))
      return candidates[value];
    final double lower = candidates.lastKeyBefore(value);
    final double upper = candidates.firstKeyAfter(value);
    if (lower == null)
      return candidates[upper];
    if (upper == null)
      return candidates[lower];
    if (value > (lower + upper) / 2)
      return candidates[upper];
    else
      return candidates[lower];
  }

  static final RegExp _extractRatioRegExp = RegExp(r'/?(\d+(\.\d*)?)x$');

  double _parseScale(String key) {
    if (key == assetName) {
      return _naturalResolution;
    }

    final File assetPath = File(key);
    final Directory assetDir = assetPath.parent;

    final Match match = _extractRatioRegExp.firstMatch(assetDir.path);
    if (match != null && match.groupCount > 0)
      return double.parse(match.group(1));
    return _naturalResolution; // i.e. default to 1.0x
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType)
      return false;
    final AssetImage typedOther = other;
    return keyName == typedOther.keyName
        && bundle == typedOther.bundle;
  }

  @override
  int get hashCode => hashValues(keyName, bundle);

  @override
  String toString() => '$runtimeType(bundle: $bundle, name: "$keyName")';
}
