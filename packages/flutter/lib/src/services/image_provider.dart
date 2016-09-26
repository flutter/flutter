// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' show Size, Locale, hashValues;
import 'dart:ui' as ui show Image;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:mojo/core.dart' as mojo;

import 'asset_bundle.dart';
import 'image_cache.dart';
import 'image_decoder.dart';
import 'image_stream.dart';

/// Configuration information passed to the [ImageProvider.resolve] method to
/// select a specific image.
class ImageConfiguration {
  /// Creates an object holding the configuration information for an [ImageProvider].
  ///
  /// All the arguments are optional. Configuration information is merely
  /// advisory and best-effort.
  const ImageConfiguration({
    this.bundle,
    this.devicePixelRatio,
    this.locale,
    this.size,
    this.platform
  });

  /// Creates an object holding the configuration information for an [ImageProvider].
  ///
  /// All the arguments are optional. Configuration information is merely
  /// advisory and best-effort.
  ImageConfiguration copyWith({
    AssetBundle bundle,
    double devicePixelRatio,
    Locale locale,
    Size size,
    String platform
  }) {
    return new ImageConfiguration(
      bundle: bundle ?? this.bundle,
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
      locale: locale ?? this.locale,
      size: size ?? this.size,
      platform: platform ?? this.platform
    );
  }

  /// The preferred [AssetBundle] to use if the [ImageProvider] needs one and
  /// does not have one already selected.
  final AssetBundle bundle;

  /// The device pixel ratio where the image will be shown.
  final double devicePixelRatio;

  /// The language and region for which to select the image.
  final Locale locale;

  /// The size at which the image will be rendered.
  final Size size;

  /// A string (same as [Platform.operatingSystem]) that represents the platform
  /// for which assets should be used. This allows images to be specified in a
  /// platform-neutral fashion yet use different assets on different platforms,
  /// to match local conventions e.g. for color matching or shadows.
  final String platform;

  /// An image configuration that provides no additional information.
  ///
  /// Useful when resolving an [ImageProvider] without any context.
  static const ImageConfiguration empty = const ImageConfiguration();

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType)
      return false;
    final ImageConfiguration typedOther = other;
    return typedOther.bundle == bundle
        && typedOther.devicePixelRatio == devicePixelRatio
        && typedOther.locale == locale
        && typedOther.size == size
        && typedOther.platform == platform;
  }

  @override
  int get hashCode => hashValues(bundle, devicePixelRatio, locale, size, platform);

  @override
  String toString() {
    StringBuffer result = new StringBuffer();
    result.write('ImageConfiguration(');
    bool hasArguments = false;
    if (bundle != null) {
      if (hasArguments)
        result.write(', ');
      result.write('bundle: $bundle');
      hasArguments = true;
    }
    if (devicePixelRatio != null) {
      if (hasArguments)
        result.write(', ');
      result.write('devicePixelRatio: $devicePixelRatio');
      hasArguments = true;
    }
    if (locale != null) {
      if (hasArguments)
        result.write(', ');
      result.write('locale: $locale');
      hasArguments = true;
    }
    if (size != null) {
      if (hasArguments)
        result.write(', ');
      result.write('size: $size');
      hasArguments = true;
    }
    if (platform != null) {
      if (hasArguments)
        result.write(', ');
      result.write('platform: $platform');
      hasArguments = true;
    }
    result.write(')');
    return result.toString();
  }
}

/// Identifies an image without committing to the precise final asset. This
/// allows a set of images to be identified and for the precise image to later
/// be resolved based on the environment, e.g. the device pixel ratio.
///
/// To obtain an [ImageStream] from an [ImageProvider], call [resolve],
/// passing it an [ImageConfiguration] object.
///
/// ImageProvides uses the global [imageCache] to cache images.
///
/// The type argument `T` is the type of the object used to represent a resolved
/// configuration. This is also the type used for the key in the image cache. It
/// should be immutable and implement [operator ==] and [hashCode]. Subclasses should
/// subclass a variant of [ImageProvider] with an explicit `T` type argument.
///
/// The type argument does not have to be specified when using the type as an
/// argument (where any image provider is acceptable).
@optionalTypeArgs
abstract class ImageProvider<T> {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const ImageProvider();

  /// Resolves this image provider using the given `configuration`, returning
  /// an [ImageStream].
  ///
  /// This is the public entry-point of the [ImageProvider] class hierarchy.
  ///
  /// Subclasses should implement [obtainKey] and [load], which are used by this
  /// method.
  ImageStream resolve(ImageConfiguration configuration) {
    assert(configuration != null);
    final ImageStream stream = new ImageStream();
    T obtainedKey;
    obtainKey(configuration).then((T key) {
      obtainedKey = key;
      stream.setCompleter(imageCache.putIfAbsent(key, () => load(key)));
    }).catchError(
      (dynamic exception, StackTrace stack) async {
        FlutterError.reportError(new FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'services library',
          context: 'while resolving an image',
          silent: true, // could be a network error or whatnot
          informationCollector: (StringBuffer information) {
            information.writeln('Image provider: $this');
            information.writeln('Image configuration: $configuration');
            if (obtainedKey != null)
              information.writeln('Image key: $obtainedKey');
          }
        ));
        return null;
      }
    );
    return stream;
  }

  /// Converts an ImageProvider's settings plus an ImageConfiguration to a key
  /// that describes the precise image to load.
  ///
  /// The type of the key is determined by the subclass. It is a value that
  /// unambiguously identifies the image (_including its scale_) that the [load]
  /// method will fetch. Different [ImageProvider]s given the same constructor
  /// arguments and [ImageConfiguration] objects should return keys that are
  /// '==' to each other (possibly by using a class for the key that itself
  /// implements [operator ==]).
  @protected
  Future<T> obtainKey(ImageConfiguration configuration);

  /// Converts a key into an [ImageStreamCompleter], and begins fetching the
  /// image.
  @protected
  ImageStreamCompleter load(T key);

  @override
  String toString() => '$runtimeType()';
}

/// A subclass of [ImageProvider] that knows how to invoke
/// [decodeImageFromDataPipe].
///
/// This factors out the common logic of many [ImageProvider] classes,
/// simplifying what subclasses must implement to just three small methods:
///
/// * [obtainKey], to resolve an [ImageConfiguration].
/// * [getScale], to determine the scale of the image associated with a
///   particular key.
/// * [loadDataPipe], to obtain the [mojo.MojoDataPipeConsumer] object that
///   contains the actual image data.
abstract class DataPipeImageProvider<T> extends ImageProvider<T> {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const DataPipeImageProvider();

  /// Converts a key into an [ImageStreamCompleter], and begins fetching the
  /// image using [loadAsync].
  @override
  ImageStreamCompleter load(T key) {
    return new OneFrameImageStreamCompleter(
      loadAsync(key),
      informationCollector: (StringBuffer information) {
        information.writeln('Image provider: $this');
        information.write('Image key: $key');
      }
    );
  }

  /// Fetches the image from the data pipe, decodes it, and returns a
  /// corresponding [ImageInfo] object.
  ///
  /// This function is used by [load].
  @protected
  Future<ImageInfo> loadAsync(T key) async {
    final mojo.MojoDataPipeConsumer dataPipe = await loadDataPipe(key);
    if (dataPipe == null)
      throw 'Unable to read data';
    final ui.Image image = await decodeImage(dataPipe);
    if (image == null)
      throw 'Unable to decode image data';
    return new ImageInfo(image: image, scale: getScale(key));
  }

  /// Converts raw image data from a [mojo.MojoDataPipeConsumer] data pipe into
  /// a decoded [ui.Image] which can be passed to a [Canvas].
  ///
  /// By default, this just uses [decodeImageFromDataPipe]. This method could be
  /// overridden in subclasses (e.g. for testing).
  Future<ui.Image> decodeImage(mojo.MojoDataPipeConsumer pipe) => decodeImageFromDataPipe(pipe);

  /// Returns the data pipe that contains the image data to decode.
  ///
  /// Must be implemented by subclasses of [DataPipeImageProvider].
  @protected
  Future<mojo.MojoDataPipeConsumer> loadDataPipe(T key);

  /// Returns the scale to use when creating the [ImageInfo] for the given key.
  ///
  /// Must be implemented by subclasses of [DataPipeImageProvider].
  @protected
  double getScale(T key);
}

/// Fetches the given URL from the network, associating it with the given scale.
///
/// Cache headers from the server are ignored.
// TODO(ianh): Find some way to honour cache headers to the extent that when the
// last reference to an image is released, we proactively evict the image from
// our cache if the headers describe the image as having expired at that point.
class NetworkImage extends ImageProvider<NetworkImage> {
  /// Creates an object that fetches the image at the given URL.
  ///
  /// The arguments must not be null.
  const NetworkImage(this.url, { this.scale: 1.0 });

  /// The URL from which the image will be fetched.
  final String url;

  /// The scale to place in the [ImageInfo] object of the image.
  final double scale;

  @override
  Future<NetworkImage> obtainKey(ImageConfiguration configuration) {
    return new SynchronousFuture<NetworkImage>(this);
  }

  @override
  ImageStreamCompleter load(NetworkImage key) {
    return new OneFrameImageStreamCompleter(
      _loadAsync(key),
      informationCollector: (StringBuffer information) {
        information.writeln('Image provider: $this');
        information.write('Image key: $key');
      }
    );
  }

  Future<ImageInfo> _loadAsync(NetworkImage key) async {
    assert(key == this);

    final Uri resolved = Uri.base.resolve(key.url);
    final http.Response response = await http.get(resolved);
    if (response == null || response.statusCode != 200)
      return null;

    Uint8List bytes = response.bodyBytes;
    if (bytes.lengthInBytes == 0)
      return null;

    final ui.Image image = await decodeImageFromList(bytes);
    if (image == null)
      return null;

    return new ImageInfo(
      image: image,
      scale: key.scale,
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType)
      return false;
    final NetworkImage typedOther = other;
    return url == typedOther.url
        && scale == typedOther.scale;
  }

  @override
  int get hashCode => hashValues(url, scale);

  @override
  String toString() => '$runtimeType("$url", scale: $scale)';
}

/// Key for the image obtained by an [AssetImage] or [AssetBundleImageProvider].
///
/// This is used to identify the precise resource in the [imageCache].
class AssetBundleImageKey {
  /// Creates the key for an [AssetImage] or [AssetBundleImageProvider].
  ///
  /// The arguments must not be null.
  const AssetBundleImageKey({
    @required this.bundle,
    @required this.name,
    @required this.scale
  });

  /// The bundle from which the image will be obtained.
  ///
  /// The image is obtained by calling [AssetBundle.load] on the given [bundle]
  /// using the key given by [name].
  final AssetBundle bundle;

  /// The key to use to obtain the resource from the [bundle]. This is the
  /// argument passed to [AssetBundle.load].
  final String name;

  /// The scale to place in the [ImageInfo] object of the image.
  final double scale;

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType)
      return false;
    final AssetBundleImageKey typedOther = other;
    return bundle == typedOther.bundle
        && name == typedOther.name
        && scale == typedOther.scale;
  }

  @override
  int get hashCode => hashValues(bundle, name, scale);

  @override
  String toString() => '$runtimeType(bundle: $bundle, name: $name, scale: $scale)';
}

/// A subclass of [DataPipeImageProvider] that knows about [AssetBundle]s.
///
/// This factors out the common logic of [AssetBundle]-based [ImageProvider]
/// classes, simplifying what subclasses must implement to just [obtainKey].
abstract class AssetBundleImageProvider extends DataPipeImageProvider<AssetBundleImageKey> {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const AssetBundleImageProvider();

  @override
  Future<AssetBundleImageKey> obtainKey(ImageConfiguration configuration);

  @override
  Future<mojo.MojoDataPipeConsumer> loadDataPipe(AssetBundleImageKey key) {
    return key.bundle.load(key.name);
  }

  @override
  double getScale(AssetBundleImageKey key) {
    return key.scale;
  }
}

/// Fetches an image from an [AssetBundle], associating it with the given scale.
///
/// This implementation requires an explicit final [name] and [scale] on
/// construction, and ignores the device pixel ratio and size in the
/// configuration passed into [resolve]. For a resolution-aware variant that
/// uses the configuration to pick an appropriate image based on the device
/// pixel ratio and size, see [AssetImage].
class ExactAssetImage extends AssetBundleImageProvider {
  /// Creates an object that fetches the given image from an asset bundle.
  ///
  /// The [name] and [scale] arguments must not be null. The [scale] arguments
  /// defaults to 1.0. The [bundle] argument may be null, in which case the
  /// bundle provided in the [ImageConfiguration] passed to the [resolve] call
  /// will be used instead.
  ExactAssetImage(this.name, {
    this.scale: 1.0,
    this.bundle
  }) {
    assert(name != null);
    assert(scale != null);
  }

  /// The key to use to obtain the resource from the [bundle]. This is the
  /// argument passed to [AssetBundle.load].
  final String name;

  /// The scale to place in the [ImageInfo] object of the image.
  final double scale;

  /// The bundle from which the image will be obtained.
  ///
  /// If the provided [bundle] is null, the bundle provided in the
  /// [ImageConfiguration] passed to the [resolve] call will be used instead. If
  /// that is also null, the [rootBundle] is used.
  ///
  /// The image is obtained by calling [AssetBundle.load] on the given [bundle]
  /// using the key given by [name].
  final AssetBundle bundle;

  @override
  Future<AssetBundleImageKey> obtainKey(ImageConfiguration configuration) {
    return new SynchronousFuture<AssetBundleImageKey>(new AssetBundleImageKey(
      bundle: bundle ?? configuration.bundle ?? rootBundle,
      name: name,
      scale: scale
    ));
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType)
      return false;
    final ExactAssetImage typedOther = other;
    return name == typedOther.name
        && scale == typedOther.scale
        && bundle == typedOther.bundle;
  }

  @override
  int get hashCode => hashValues(name, scale, bundle);

  @override
  String toString() => '$runtimeType(name: $name, scale: $scale, bundle: $bundle)';
}
