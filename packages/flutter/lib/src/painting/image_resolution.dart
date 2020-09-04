// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:ui' show hashValues;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'image_provider.dart';

const String _kAssetManifestFileName = 'AssetManifest.json';

/// Fetches an image from an [AssetBundle], having determined the exact image to
/// use based on the context.
///
/// Given a main asset and a set of variants, AssetImage chooses the most
/// appropriate asset for the current context, based on the device pixel ratio
/// and size given in the configuration passed to [resolve].
///
/// To show a specific image from a bundle without any asset resolution, use an
/// [AssetBundleImageProvider].
///
/// ## Naming assets for matching with different pixel densities
///
/// Main assets are presumed to match a nominal pixel ratio of 1.0. To specify
/// assets targeting different pixel ratios, place the variant assets in
/// the application bundle under subdirectories named in the form "Nx", where
/// N is the nominal device pixel ratio for that asset.
///
/// For example, suppose an application wants to use an icon named
/// "heart.png". This icon has representations at 1.0 (the main icon), as well
/// as 1.5 and 2.0 pixel ratios (variants). The asset bundle should then contain
/// the following assets:
///
/// ```
/// heart.png
/// 1.5x/heart.png
/// 2.0x/heart.png
/// ```
///
/// On a device with a 1.0 device pixel ratio, the image chosen would be
/// heart.png; on a device with a 1.3 device pixel ratio, the image chosen
/// would be 1.5x/heart.png.
///
/// The directory level of the asset does not matter as long as the variants are
/// at the equivalent level; that is, the following is also a valid bundle
/// structure:
///
/// ```
/// icons/heart.png
/// icons/1.5x/heart.png
/// icons/2.0x/heart.png
/// ```
///
/// assets/icons/3.0x/heart.png would be a valid variant of
/// assets/icons/heart.png.
///
///
/// ## Fetching assets
///
/// When fetching an image provided by the app itself, use the [assetName]
/// argument to name the asset to choose. For instance, consider the structure
/// above. First, the `pubspec.yaml` of the project should specify its assets in
/// the `flutter` section:
///
/// ```yaml
/// flutter:
///   assets:
///     - icons/heart.png
/// ```
///
/// Then, to fetch the image, use:
/// ```dart
/// AssetImage('icons/heart.png')
/// ```
///
/// ## Assets in packages
///
/// To fetch an asset from a package, the [package] argument must be provided.
/// For instance, suppose the structure above is inside a package called
/// `my_icons`. Then to fetch the image, use:
///
/// ```dart
/// AssetImage('icons/heart.png', package: 'my_icons')
/// ```
///
/// Assets used by the package itself should also be fetched using the [package]
/// argument as above.
///
/// If the desired asset is specified in the `pubspec.yaml` of the package, it
/// is bundled automatically with the app. In particular, assets used by the
/// package itself must be specified in its `pubspec.yaml`.
///
/// A package can also choose to have assets in its 'lib/' folder that are not
/// specified in its `pubspec.yaml`. In this case for those images to be
/// bundled, the app has to specify which ones to include. For instance a
/// package named `fancy_backgrounds` could have:
///
/// ```
/// lib/backgrounds/background1.png
/// lib/backgrounds/background2.png
/// lib/backgrounds/background3.png
/// ```
///
/// To include, say the first image, the `pubspec.yaml` of the app should specify
/// it in the `assets` section:
///
/// ```yaml
///   assets:
///     - packages/fancy_backgrounds/backgrounds/background1.png
/// ```
///
/// The `lib/` is implied, so it should not be included in the asset path.
///
/// See also:
///
///  * [Image.asset] for a shorthand of an [Image] widget backed by [AssetImage]
///    when used without a scale.
@immutable
class AssetImage extends AssetBundleImageProvider {
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

  /// The name of the main asset from the set of images to choose from. See the
  /// documentation for the [AssetImage] class itself for details.
  final String assetName;

  /// The name used to generate the key to obtain the asset. For local assets
  /// this is [assetName], and for assets from packages the [assetName] is
  /// prefixed 'packages/<package_name>/'.
  String get keyName => package == null ? assetName : 'packages/$package/$assetName';

  /// The bundle from which the image will be obtained.
  ///
  /// If the provided [bundle] is null, the bundle provided in the
  /// [ImageConfiguration] passed to the [resolve] call will be used instead. If
  /// that is also null, the [rootBundle] is used.
  ///
  /// The image is obtained by calling [AssetBundle.load] on the given [bundle]
  /// using the key given by [keyName].
  final AssetBundle? bundle;

  /// The name of the package from which the image is included. See the
  /// documentation for the [AssetImage] class itself for details.
  final String? package;

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
    Completer<AssetBundleImageKey>? completer;
    Future<AssetBundleImageKey>? result;

    chosenBundle.loadStructuredData<Map<String, List<String>>?>(_kAssetManifestFileName, _manifestParser).then<void>(
      (Map<String, List<String>>? manifest) {
        final String chosenName = _chooseVariant(
          keyName,
          configuration,
          manifest == null ? null : manifest[keyName],
        )!;
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
    ).catchError((Object error, StackTrace stack) {
      // We had an error. (This guarantees we weren't called synchronously.)
      // Forward the error to the caller.
      assert(completer != null);
      assert(result == null);
      completer!.completeError(error, stack);
    });
    if (result != null) {
      // The code above ran synchronously, and came up with an answer.
      // Return the SynchronousFuture that we created above.
      return result!;
    }
    // The code above hasn't yet run its "then" handler yet. Let's prepare a
    // completer for it to use when it does run.
    completer = Completer<AssetBundleImageKey>();
    return completer.future;
  }

  static Future<Map<String, List<String>>?> _manifestParser(String? jsonData) {
    if (jsonData == null)
      return SynchronousFuture<Map<String, List<String>>?>(null);
    // TODO(ianh): JSON decoding really shouldn't be on the main thread.
    final Map<String, dynamic> parsedJson = json.decode(jsonData) as Map<String, dynamic>;
    final Iterable<String> keys = parsedJson.keys;
    final Map<String, List<String>> parsedManifest =
        Map<String, List<String>>.fromIterables(keys,
          keys.map<List<String>>((String key) => List<String>.from(parsedJson[key] as List<dynamic>)));
    // TODO(ianh): convert that data structure to the right types.
    return SynchronousFuture<Map<String, List<String>>?>(parsedManifest);
  }

  String? _chooseVariant(String main, ImageConfiguration config, List<String>? candidates) {
    if (config.devicePixelRatio == null || candidates == null || candidates.isEmpty)
      return main;
    // TODO(ianh): Consider moving this parsing logic into _manifestParser.
    final SplayTreeMap<double, String> mapping = SplayTreeMap<double, String>();
    for (final String candidate in candidates)
      mapping[_parseScale(candidate)] = candidate;
    // TODO(ianh): implement support for config.locale, config.textDirection,
    // config.size, config.platform (then document this over in the Image.asset
    // docs)
    return _findNearest(mapping, config.devicePixelRatio!);
  }

  // Return the value for the key in a [SplayTreeMap] nearest the provided key.
  String? _findNearest(SplayTreeMap<double, String> candidates, double value) {
    if (candidates.containsKey(value))
      return candidates[value]!;
    final double? lower = candidates.lastKeyBefore(value);
    final double? upper = candidates.firstKeyAfter(value);
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

    final Uri assetUri = Uri.parse(key);
    String directoryPath = '';
    if (assetUri.pathSegments.length > 1) {
      directoryPath = assetUri.pathSegments[assetUri.pathSegments.length - 2];
    }

    final Match? match = _extractRatioRegExp.firstMatch(directoryPath);
    if (match != null && match.groupCount > 0)
      return double.parse(match.group(1)!);
    return _naturalResolution; // i.e. default to 1.0x
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType)
      return false;
    return other is AssetImage
        && other.keyName == keyName
        && other.bundle == bundle;
  }

  @override
  int get hashCode => hashValues(keyName, bundle);

  @override
  String toString() => '${objectRuntimeType(this, 'AssetImage')}(bundle: $bundle, name: "$keyName")';
}
