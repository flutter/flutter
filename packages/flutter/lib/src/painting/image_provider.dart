// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui show Codec;
import 'dart:ui' show Size, Locale, TextDirection, hashValues;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'binding.dart';
import 'image_cache.dart';
import 'image_stream.dart';

/// Configuration information passed to the [ImageProvider.resolve] method to
/// select a specific image.
///
/// See also:
///
///  * [createLocalImageConfiguration], which creates an [ImageConfiguration]
///    based on ambient configuration in a [Widget] environment.
///  * [ImageProvider], which uses [ImageConfiguration] objects to determine
///    which image to obtain.
@immutable
class ImageConfiguration {
  /// Creates an object holding the configuration information for an [ImageProvider].
  ///
  /// All the arguments are optional. Configuration information is merely
  /// advisory and best-effort.
  const ImageConfiguration({
    this.bundle,
    this.devicePixelRatio,
    this.locale,
    this.textDirection,
    this.size,
    this.platform,
  });

  /// Creates an object holding the configuration information for an [ImageProvider].
  ///
  /// All the arguments are optional. Configuration information is merely
  /// advisory and best-effort.
  ImageConfiguration copyWith({
    AssetBundle bundle,
    double devicePixelRatio,
    Locale locale,
    TextDirection textDirection,
    Size size,
    String platform,
  }) {
    return ImageConfiguration(
      bundle: bundle ?? this.bundle,
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
      locale: locale ?? this.locale,
      textDirection: textDirection ?? this.textDirection,
      size: size ?? this.size,
      platform: platform ?? this.platform,
    );
  }

  /// The preferred [AssetBundle] to use if the [ImageProvider] needs one and
  /// does not have one already selected.
  final AssetBundle bundle;

  /// The device pixel ratio where the image will be shown.
  final double devicePixelRatio;

  /// The language and region for which to select the image.
  final Locale locale;

  /// The reading direction of the language for which to select the image.
  final TextDirection textDirection;

  /// The size at which the image will be rendered.
  final Size size;

  /// The [TargetPlatform] for which assets should be used. This allows images
  /// to be specified in a platform-neutral fashion yet use different assets on
  /// different platforms, to match local conventions e.g. for color matching or
  /// shadows.
  final TargetPlatform platform;

  /// An image configuration that provides no additional information.
  ///
  /// Useful when resolving an [ImageProvider] without any context.
  static const ImageConfiguration empty = ImageConfiguration();

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType)
      return false;
    final ImageConfiguration typedOther = other;
    return typedOther.bundle == bundle
        && typedOther.devicePixelRatio == devicePixelRatio
        && typedOther.locale == locale
        && typedOther.textDirection == textDirection
        && typedOther.size == size
        && typedOther.platform == platform;
  }

  @override
  int get hashCode => hashValues(bundle, devicePixelRatio, locale, size, platform);

  @override
  String toString() {
    final StringBuffer result = StringBuffer();
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
      result.write('devicePixelRatio: ${devicePixelRatio.toStringAsFixed(1)}');
      hasArguments = true;
    }
    if (locale != null) {
      if (hasArguments)
        result.write(', ');
      result.write('locale: $locale');
      hasArguments = true;
    }
    if (textDirection != null) {
      if (hasArguments)
        result.write(', ');
      result.write('textDirection: $textDirection');
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
      result.write('platform: ${describeEnum(platform)}');
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
/// [ImageProvider] uses the global [imageCache] to cache images.
///
/// The type argument `T` is the type of the object used to represent a resolved
/// configuration. This is also the type used for the key in the image cache. It
/// should be immutable and implement the [==] operator and the [hashCode]
/// getter. Subclasses should subclass a variant of [ImageProvider] with an
/// explicit `T` type argument.
///
/// The type argument does not have to be specified when using the type as an
/// argument (where any image provider is acceptable).
///
/// The following image formats are supported: {@macro flutter.dart:ui.imageFormats}
///
/// {@tool sample}
///
/// The following shows the code required to write a widget that fully conforms
/// to the [ImageProvider] and [Widget] protocols. (It is essentially a
/// bare-bones version of the [widgets.Image] widget.)
///
/// ```dart
/// class MyImage extends StatefulWidget {
///   const MyImage({
///     Key key,
///     @required this.imageProvider,
///   }) : assert(imageProvider != null),
///        super(key: key);
///
///   final ImageProvider imageProvider;
///
///   @override
///   _MyImageState createState() => _MyImageState();
/// }
///
/// class _MyImageState extends State<MyImage> {
///   ImageStream _imageStream;
///   ImageInfo _imageInfo;
///
///   @override
///   void didChangeDependencies() {
///     super.didChangeDependencies();
///     // We call _getImage here because createLocalImageConfiguration() needs to
///     // be called again if the dependencies changed, in case the changes relate
///     // to the DefaultAssetBundle, MediaQuery, etc, which that method uses.
///     _getImage();
///   }
///
///   @override
///   void didUpdateWidget(MyImage oldWidget) {
///     super.didUpdateWidget(oldWidget);
///     if (widget.imageProvider != oldWidget.imageProvider)
///       _getImage();
///   }
///
///   void _getImage() {
///     final ImageStream oldImageStream = _imageStream;
///     _imageStream = widget.imageProvider.resolve(createLocalImageConfiguration(context));
///     if (_imageStream.key != oldImageStream?.key) {
///       // If the keys are the same, then we got the same image back, and so we don't
///       // need to update the listeners. If the key changed, though, we must make sure
///       // to switch our listeners to the new image stream.
///       oldImageStream?.removeListener(_updateImage);
///       _imageStream.addListener(_updateImage);
///     }
///   }
///
///   void _updateImage(ImageInfo imageInfo, bool synchronousCall) {
///     setState(() {
///       // Trigger a build whenever the image changes.
///       _imageInfo = imageInfo;
///     });
///   }
///
///   @override
///   void dispose() {
///     _imageStream.removeListener(_updateImage);
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return RawImage(
///       image: _imageInfo?.image, // this is a dart:ui Image object
///       scale: _imageInfo?.scale ?? 1.0,
///     );
///   }
/// }
/// ```
/// {@end-tool}
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
    final ImageStream stream = ImageStream();
    T obtainedKey;
    obtainKey(configuration).then<void>((T key) {
      obtainedKey = key;
      stream.setCompleter(PaintingBinding.instance.imageCache.putIfAbsent(key, () => load(key)));
    }).catchError(
      (dynamic exception, StackTrace stack) async {
        FlutterError.reportError(FlutterErrorDetails(
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

  /// Evicts an entry from the image cache.
  ///
  /// Returns a [Future] which indicates whether the value was successfully
  /// removed.
  ///
  /// The [ImageProvider] used does not need to be the same instance that was
  /// passed to an [Image] widget, but it does need to create a key which is
  /// equal to one.
  ///
  /// The [cache] is optional and defaults to the global image cache.
  ///
  /// The [configuration] is optional and defaults to
  /// [ImageConfiguration.empty].
  ///
  /// {@tool sample}
  ///
  /// The following sample code shows how an image loaded using the [Image]
  /// widget can be evicted using a [NetworkImage] with a matching url.
  ///
  /// ```dart
  /// class MyWidget extends StatelessWidget {
  ///   final String url = '...';
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     return Image.network(url);
  ///   }
  ///
  ///   void evictImage() {
  ///     final NetworkImage provider = NetworkImage(url);
  ///     provider.evict().then<void>((bool success) {
  ///       if (success)
  ///         debugPrint('removed image!');
  ///     });
  ///   }
  /// }
  /// ```
  /// {@end-tool}
  Future<bool> evict({ImageCache cache, ImageConfiguration configuration = ImageConfiguration.empty}) async {
    cache ??= imageCache;
    final T key = await obtainKey(configuration);
    return cache.evict(key);
  }

  /// Converts an ImageProvider's settings plus an ImageConfiguration to a key
  /// that describes the precise image to load.
  ///
  /// The type of the key is determined by the subclass. It is a value that
  /// unambiguously identifies the image (_including its scale_) that the [load]
  /// method will fetch. Different [ImageProvider]s given the same constructor
  /// arguments and [ImageConfiguration] objects should return keys that are
  /// '==' to each other (possibly by using a class for the key that itself
  /// implements [==]).
  @protected
  Future<T> obtainKey(ImageConfiguration configuration);

  /// Converts a key into an [ImageStreamCompleter], and begins fetching the
  /// image.
  @protected
  ImageStreamCompleter load(T key);

  @override
  String toString() => '$runtimeType()';
}

/// Key for the image obtained by an [AssetImage] or [ExactAssetImage].
///
/// This is used to identify the precise resource in the [imageCache].
@immutable
class AssetBundleImageKey {
  /// Creates the key for an [AssetImage] or [AssetBundleImageProvider].
  ///
  /// The arguments must not be null.
  const AssetBundleImageKey({
    @required this.bundle,
    @required this.name,
    @required this.scale
  }) : assert(bundle != null),
       assert(name != null),
       assert(scale != null);

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
  String toString() => '$runtimeType(bundle: $bundle, name: "$name", scale: $scale)';
}

/// A subclass of [ImageProvider] that knows about [AssetBundle]s.
///
/// This factors out the common logic of [AssetBundle]-based [ImageProvider]
/// classes, simplifying what subclasses must implement to just [obtainKey].
abstract class AssetBundleImageProvider extends ImageProvider<AssetBundleImageKey> {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const AssetBundleImageProvider();

  /// Converts a key into an [ImageStreamCompleter], and begins fetching the
  /// image using [loadAsync].
  @override
  ImageStreamCompleter load(AssetBundleImageKey key) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key),
      scale: key.scale,
      informationCollector: (StringBuffer information) {
        information.writeln('Image provider: $this');
        information.write('Image key: $key');
      }
    );
  }

  /// Fetches the image from the asset bundle, decodes it, and returns a
  /// corresponding [ImageInfo] object.
  ///
  /// This function is used by [load].
  @protected
  Future<ui.Codec> _loadAsync(AssetBundleImageKey key) async {
    final ByteData data = await key.bundle.load(key.name);
    if (data == null)
      throw 'Unable to read data';
    return await PaintingBinding.instance.instantiateImageCodec(data.buffer.asUint8List());
  }
}

/// Fetches the given URL from the network, associating it with the given scale.
///
/// The image will be cached regardless of cache headers from the server.
///
/// See also:
///
///  * [Image.network] for a shorthand of an [Image] widget backed by [NetworkImage].
// TODO(ianh): Find some way to honour cache headers to the extent that when the
// last reference to an image is released, we proactively evict the image from
// our cache if the headers describe the image as having expired at that point.
class NetworkImage extends ImageProvider<NetworkImage> {
  /// Creates an object that fetches the image at the given URL.
  ///
  /// The arguments must not be null.
  const NetworkImage(this.url, { this.scale = 1.0 , this.headers })
      : assert(url != null),
        assert(scale != null);

  /// The URL from which the image will be fetched.
  final String url;

  /// The scale to place in the [ImageInfo] object of the image.
  final double scale;

  /// The HTTP headers that will be used with [HttpClient.get] to fetch image from network.
  final Map<String, String> headers;

  @override
  Future<NetworkImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<NetworkImage>(this);
  }

  @override
  ImageStreamCompleter load(NetworkImage key) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key),
      scale: key.scale,
      informationCollector: (StringBuffer information) {
        information.writeln('Image provider: $this');
        information.write('Image key: $key');
      }
    );
  }

  static final HttpClient _httpClient = HttpClient();

  Future<ui.Codec> _loadAsync(NetworkImage key) async {
    assert(key == this);

    final Uri resolved = Uri.base.resolve(key.url);
    final HttpClientRequest request = await _httpClient.getUrl(resolved);
    headers?.forEach((String name, String value) {
      request.headers.add(name, value);
    });
    final HttpClientResponse response = await request.close();
    if (response.statusCode != HttpStatus.ok)
      throw Exception('HTTP request failed, statusCode: ${response?.statusCode}, $resolved');

    final Uint8List bytes = await consolidateHttpClientResponseBytes(response);
    if (bytes.lengthInBytes == 0)
      throw Exception('NetworkImage is an empty file: $resolved');

    return await PaintingBinding.instance.instantiateImageCodec(bytes);
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

/// Decodes the given [File] object as an image, associating it with the given
/// scale.
///
/// See also:
///
///  * [Image.file] for a shorthand of an [Image] widget backed by [FileImage].
class FileImage extends ImageProvider<FileImage> {
  /// Creates an object that decodes a [File] as an image.
  ///
  /// The arguments must not be null.
  const FileImage(this.file, { this.scale = 1.0 })
      : assert(file != null),
        assert(scale != null);

  /// The file to decode into an image.
  final File file;

  /// The scale to place in the [ImageInfo] object of the image.
  final double scale;

  @override
  Future<FileImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<FileImage>(this);
  }

  @override
  ImageStreamCompleter load(FileImage key) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key),
      scale: key.scale,
      informationCollector: (StringBuffer information) {
        information.writeln('Path: ${file?.path}');
      }
    );
  }

  Future<ui.Codec> _loadAsync(FileImage key) async {
    assert(key == this);

    final Uint8List bytes = await file.readAsBytes();
    if (bytes.lengthInBytes == 0)
      return null;

    return await PaintingBinding.instance.instantiateImageCodec(bytes);
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType)
      return false;
    final FileImage typedOther = other;
    return file?.path == typedOther.file?.path
        && scale == typedOther.scale;
  }

  @override
  int get hashCode => hashValues(file?.path, scale);

  @override
  String toString() => '$runtimeType("${file?.path}", scale: $scale)';
}

/// Decodes the given [Uint8List] buffer as an image, associating it with the
/// given scale.
///
/// The provided [bytes] buffer should not be changed after it is provided
/// to a [MemoryImage]. To provide an [ImageStream] that represents an image
/// that changes over time, consider creating a new subclass of [ImageProvider]
/// whose [load] method returns a subclass of [ImageStreamCompleter] that can
/// handle providing multiple images.
///
/// See also:
///
///  * [Image.memory] for a shorthand of an [Image] widget backed by [MemoryImage].
class MemoryImage extends ImageProvider<MemoryImage> {
  /// Creates an object that decodes a [Uint8List] buffer as an image.
  ///
  /// The arguments must not be null.
  const MemoryImage(this.bytes, { this.scale = 1.0 })
      : assert(bytes != null),
        assert(scale != null);

  /// The bytes to decode into an image.
  final Uint8List bytes;

  /// The scale to place in the [ImageInfo] object of the image.
  final double scale;

  @override
  Future<MemoryImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<MemoryImage>(this);
  }

  @override
  ImageStreamCompleter load(MemoryImage key) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key),
      scale: key.scale
    );
  }

  Future<ui.Codec> _loadAsync(MemoryImage key) {
    assert(key == this);

    return PaintingBinding.instance.instantiateImageCodec(bytes);
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType)
      return false;
    final MemoryImage typedOther = other;
    return bytes == typedOther.bytes
        && scale == typedOther.scale;
  }

  @override
  int get hashCode => hashValues(bytes.hashCode, scale);

  @override
  String toString() => '$runtimeType(${describeIdentity(bytes)}, scale: $scale)';
}

/// Fetches an image from an [AssetBundle], associating it with the given scale.
///
/// This implementation requires an explicit final [assetName] and [scale] on
/// construction, and ignores the device pixel ratio and size in the
/// configuration passed into [resolve]. For a resolution-aware variant that
/// uses the configuration to pick an appropriate image based on the device
/// pixel ratio and size, see [AssetImage].
///
/// ## Fetching assets
///
/// When fetching an image provided by the app itself, use the [assetName]
/// argument to name the asset to choose. For instance, consider a directory
/// `icons` with an image `heart.png`. First, the [pubspec.yaml] of the project
/// should specify its assets in the `flutter` section:
///
/// ```yaml
/// flutter:
///   assets:
///     - icons/heart.png
/// ```
///
/// Then, to fetch the image and associate it with scale `1.5`, use
///
/// ```dart
/// AssetImage('icons/heart.png', scale: 1.5)
/// ```
///
///## Assets in packages
///
/// To fetch an asset from a package, the [package] argument must be provided.
/// For instance, suppose the structure above is inside a package called
/// `my_icons`. Then to fetch the image, use:
///
/// ```dart
/// AssetImage('icons/heart.png', scale: 1.5, package: 'my_icons')
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
///```
///
/// To include, say the first image, the `pubspec.yaml` of the app should specify
/// it in the `assets` section:
///
/// ```yaml
///  assets:
///    - packages/fancy_backgrounds/backgrounds/background1.png
/// ```
///
/// The `lib/` is implied, so it should not be included in the asset path.
///
/// See also:
///
///  * [Image.asset] for a shorthand of an [Image] widget backed by
///    [ExactAssetImage] when using a scale.
class ExactAssetImage extends AssetBundleImageProvider {
  /// Creates an object that fetches the given image from an asset bundle.
  ///
  /// The [assetName] and [scale] arguments must not be null. The [scale] arguments
  /// defaults to 1.0. The [bundle] argument may be null, in which case the
  /// bundle provided in the [ImageConfiguration] passed to the [resolve] call
  /// will be used instead.
  ///
  /// The [package] argument must be non-null when fetching an asset that is
  /// included in a package. See the documentation for the [ExactAssetImage] class
  /// itself for details.
  const ExactAssetImage(this.assetName, {
    this.scale = 1.0,
    this.bundle,
    this.package,
  }) : assert(assetName != null),
       assert(scale != null);

  /// The name of the asset.
  final String assetName;

  /// The key to use to obtain the resource from the [bundle]. This is the
  /// argument passed to [AssetBundle.load].
  String get keyName => package == null ? assetName : 'packages/$package/$assetName';

  /// The scale to place in the [ImageInfo] object of the image.
  final double scale;

  /// The bundle from which the image will be obtained.
  ///
  /// If the provided [bundle] is null, the bundle provided in the
  /// [ImageConfiguration] passed to the [resolve] call will be used instead. If
  /// that is also null, the [rootBundle] is used.
  ///
  /// The image is obtained by calling [AssetBundle.load] on the given [bundle]
  /// using the key given by [keyName].
  final AssetBundle bundle;

  /// The name of the package from which the image is included. See the
  /// documentation for the [ExactAssetImage] class itself for details.
  final String package;

  @override
  Future<AssetBundleImageKey> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<AssetBundleImageKey>(AssetBundleImageKey(
      bundle: bundle ?? configuration.bundle ?? rootBundle,
      name: keyName,
      scale: scale
    ));
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType)
      return false;
    final ExactAssetImage typedOther = other;
    return keyName == typedOther.keyName
        && scale == typedOther.scale
        && bundle == typedOther.bundle;
  }

  @override
  int get hashCode => hashValues(keyName, scale, bundle);

  @override
  String toString() => '$runtimeType(name: "$keyName", scale: $scale, bundle: $bundle)';
}
