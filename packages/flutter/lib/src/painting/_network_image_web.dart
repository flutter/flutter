// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';
import 'dart:ui' as ui;
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import 'image_provider.dart' as image_provider;
import 'image_stream.dart';

/// Creates a type for an overridable factory function for testing purposes.
typedef HttpRequestFactory = web.XMLHttpRequest Function();

// Method signature for _loadAsync decode callbacks.
typedef _SimpleDecoderCallback = Future<ui.Codec> Function(ui.ImmutableBuffer buffer);

/// Default HTTP client.
web.XMLHttpRequest _httpClient() {
  return web.XMLHttpRequest();
}

/// Creates an overridable factory function.
HttpRequestFactory httpRequestFactory = _httpClient;

/// Restores to the default HTTP request factory.
void debugRestoreHttpRequestFactory() {
  httpRequestFactory = _httpClient;
}

/// The web implementation of [image_provider.NetworkImage].
///
/// NetworkImage on the web does not support decoding to a specified size.
@immutable
class NetworkImage
    extends image_provider.ImageProvider<image_provider.NetworkImage>
    implements image_provider.NetworkImage {
  /// Creates an object that fetches the image at the given URL.
  const NetworkImage(this.url, {this.scale = 1.0, this.headers});

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
  ImageStreamCompleter loadBuffer(image_provider.NetworkImage key, image_provider.DecoderBufferCallback decode) {
    // Ownership of this controller is handed off to [_loadAsync]; it is that
    // method's responsibility to close the controller's stream when the image
    // has been loaded or an error is thrown.
    final StreamController<ImageChunkEvent> chunkEvents =
        StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleter(
      chunkEvents: chunkEvents.stream,
      codec: _loadAsync(key as NetworkImage, decode, chunkEvents),
      scale: key.scale,
      debugLabel: key.url,
      informationCollector: _imageStreamInformationCollector(key),
    );
  }

  @override
  ImageStreamCompleter loadImage(image_provider.NetworkImage key, image_provider.ImageDecoderCallback decode) {
    // Ownership of this controller is handed off to [_loadAsync]; it is that
    // method's responsibility to close the controller's stream when the image
    // has been loaded or an error is thrown.
    final StreamController<ImageChunkEvent> chunkEvents = StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleter(
      chunkEvents: chunkEvents.stream,
      codec: _loadAsync(key as NetworkImage, decode, chunkEvents),
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

  // Html renderer does not support decoding network images to a specified size. The decode parameter
  // here is ignored and `ui_web.createImageCodecFromUrl` will be used directly
  // in place of the typical `instantiateImageCodec` method.
  Future<ui.Codec> _loadAsync(
    NetworkImage key,
    _SimpleDecoderCallback decode,
    StreamController<ImageChunkEvent> chunkEvents,
  ) async {
    assert(key == this);

    final Uri resolved = Uri.base.resolve(key.url);

    final bool containsNetworkImageHeaders = key.headers?.isNotEmpty ?? false;

    // We use a different method when headers are set because the
    // `ui_web.createImageCodecFromUrl` method is not capable of handling headers.
    if (isCanvasKit || containsNetworkImageHeaders) {
      final Completer<web.XMLHttpRequest> completer =
          Completer<web.XMLHttpRequest>();
      final web.XMLHttpRequest request = httpRequestFactory();

      request.open('GET', key.url, true);
      request.responseType = 'arraybuffer';
      if (containsNetworkImageHeaders) {
        key.headers!.forEach((String header, String value) {
          request.setRequestHeader(header, value);
        });
      }

      request.addEventListener('load', (web.Event e) {
        final int status = request.status;
        final bool accepted = status >= 200 && status < 300;
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
              statusCode: status, uri: resolved);
        }
      }.toJS);

      request.addEventListener('error',
          ((JSObject e) => completer.completeError(e)).toJS);

      request.send();

      await completer.future;

      final Uint8List bytes = (request.response! as JSArrayBuffer).toDart.asUint8List();

      if (bytes.lengthInBytes == 0) {
        throw image_provider.NetworkImageLoadException(
            statusCode: request.status, uri: resolved);
      }
      return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
    } else {
      return ui_web.createImageCodecFromUrl(
        resolved,
        chunkCallback: (int bytes, int total) {
          chunkEvents.add(ImageChunkEvent(
              cumulativeBytesLoaded: bytes, expectedTotalBytes: total));
        },
      );
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
  String toString() => '${objectRuntimeType(this, 'NetworkImage')}("$url", scale: ${scale.toStringAsFixed(1)})';
}
