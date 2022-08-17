// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import 'image_provider.dart' as image_provider;
import 'image_stream.dart';

/// Creates a type for an overridable factory function for testing purposes.
typedef HttpRequestFactory = html.HttpRequest Function();

/// Default HTTP client.
html.HttpRequest _httpClient() {
  return html.HttpRequest();
}

/// Creates an overridable factory function.
HttpRequestFactory httpRequestFactory = _httpClient;

/// Restores to the default HTTP request factory.
void debugRestoreHttpRequestFactory() {
  httpRequestFactory = _httpClient;
}

/// The dart:html implementation of [image_provider.NetworkImage].
///
/// NetworkImage on the web does not support decoding to a specified size.
@immutable
class NetworkImage
    extends image_provider.ImageProvider<image_provider.NetworkImage>
    implements image_provider.NetworkImage {
  /// Creates an object that fetches the image at the given URL.
  ///
  /// The arguments [url] and [scale] must not be null.
  const NetworkImage(this.url, {this.scale = 1.0, this.headers})
      : assert(url != null),
        assert(scale != null);

  @override
  final String url;

  @override
  final double scale;

  @override
  final Map<String, String>? headers;

  @override
  Future<NetworkImage> obtainKey(image_provider.ImageConfiguration configuration) {
    return SynchronousFuture<NetworkImage>(this);
  }

  @override
  ImageStreamCompleter load(image_provider.NetworkImage key, image_provider.DecoderCallback decode) {
    // Ownership of this controller is handed off to [_loadAsync]; it is that
    // method's responsibility to close the controller's stream when the image
    // has been loaded or an error is thrown.
    final StreamController<ImageChunkEvent> chunkEvents =
        StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleter(
      chunkEvents: chunkEvents.stream,
      codec: _loadAsync(key as NetworkImage, null, decode, chunkEvents),
      scale: key.scale,
      debugLabel: key.url,
      informationCollector: _imageStreamInformationCollector(key),
    );
  }

  @override
  ImageStreamCompleter loadBuffer(image_provider.NetworkImage key, image_provider.DecoderBufferCallback decode) {
    // Ownership of this controller is handed off to [_loadAsync]; it is that
    // method's responsibility to close the controller's stream when the image
    // has been loaded or an error is thrown.
    final StreamController<ImageChunkEvent> chunkEvents =
        StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleter(
      chunkEvents: chunkEvents.stream,
      codec: _loadAsync(key as NetworkImage, decode, null, chunkEvents),
      scale: key.scale,
      debugLabel: key.url,
      informationCollector: _imageStreamInformationCollector(key),
    );
  }

  InformationCollector? _imageStreamInformationCollector(image_provider.NetworkImage key) {
    InformationCollector? collector;
    assert(() {
      collector = () => <DiagnosticsNode>[
        DiagnosticsProperty<image_provider.ImageProvider>('Image provider', this),
        DiagnosticsProperty<NetworkImage>('Image key', key as NetworkImage),
      ];
      return true;
    }());
    return collector;
  }

  // TODO(garyq): We should eventually support custom decoding of network images on Web as
  // well, see https://github.com/flutter/flutter/issues/42789.
  //
  // Web does not support decoding network images to a specified size. The decode parameter
  // here is ignored and the web-only `ui.webOnlyInstantiateImageCodecFromUrl` will be used
  // directly in place of the typical `instantiateImageCodec` method.
  Future<ui.Codec> _loadAsync(
    NetworkImage key,
    image_provider.DecoderBufferCallback? decode,
    image_provider.DecoderCallback? decodeDepreacted,
    StreamController<ImageChunkEvent> chunkEvents,
  ) async {
    assert(key == this);

    final Uri resolved = Uri.base.resolve(key.url);

    // We use a different method when headers are set because the
    // `ui.webOnlyInstantiateImageCodecFromUrl` method is not capable of handling headers.
    if (key.headers?.isNotEmpty ?? false) {
      final Completer<html.HttpRequest> completer =
          Completer<html.HttpRequest>();
      final html.HttpRequest request = httpRequestFactory();

      request.open('GET', key.url, async: true);
      request.responseType = 'arraybuffer';
      key.headers!.forEach((String header, String value) {
        request.setRequestHeader(header, value);
      });

      request.onLoad.listen((html.ProgressEvent e) {
        final int? status = request.status;
        final bool accepted = status! >= 200 && status < 300;
        final bool fileUri = status == 0; // file:// URIs have status of 0.
        final bool notModified = status == 304;
        final bool unknownRedirect = status > 307 && status < 400;
        final bool success =
            accepted || fileUri || notModified || unknownRedirect;

        if (success) {
          completer.complete(request);
        } else {
          completer.completeError(e);
          throw image_provider.NetworkImageLoadException(
              statusCode: request.status ?? 400, uri: resolved);
        }
      });

      request.onError.listen(completer.completeError);

      request.send();

      await completer.future;

      final Uint8List bytes = (request.response as ByteBuffer).asUint8List();

      if (bytes.lengthInBytes == 0) {
        throw image_provider.NetworkImageLoadException(
            statusCode: request.status!, uri: resolved);
      }

      if (decode != null) {
        final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
        return decode(buffer);
      } else {
        assert(decodeDepreacted != null);
        return decodeDepreacted!(bytes);
      }
    } else {
      // This API only exists in the web engine implementation and is not
      // contained in the analyzer summary for Flutter.
      // ignore: undefined_function, avoid_dynamic_calls
      return ui.webOnlyInstantiateImageCodecFromUrl(
        resolved,
        chunkCallback: (int bytes, int total) {
          chunkEvents.add(ImageChunkEvent(
              cumulativeBytesLoaded: bytes, expectedTotalBytes: total));
        },
      ) as Future<ui.Codec>;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is NetworkImage && other.url == url && other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(url, scale);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'NetworkImage')}("$url", scale: $scale)';
}
