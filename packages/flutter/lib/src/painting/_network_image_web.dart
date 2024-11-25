// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';
import 'dart:ui' as ui;
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';

import '../web.dart' as web;
import '_web_image_info_web.dart';
import 'image_provider.dart' as image_provider;
import 'image_stream.dart';

/// Creates a type for an overridable factory function for testing purposes.
typedef HttpRequestFactory = web.XMLHttpRequest Function();

/// Creates a type for an overridable factory function for creating <img>
/// elements for testing purposes.
typedef ImgElementFactory = web.HTMLImageElement Function();

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

/// Default <img> element factory.
web.HTMLImageElement _imgElementFactory() {
  return web.document.createElement('img') as web.HTMLImageElement;
}

/// Creates an overridable factory function to create an <img> element.
ImgElementFactory imgElementFactory = _imgElementFactory;

/// Restores to the default <img> element factory.
void debugRestoreImgElementFactory() {
  imgElementFactory = _imgElementFactory;
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

    return MultiFrameImageStreamCompleter.fromIterator(
      chunkEvents: chunkEvents.stream,
      iterator: _loadAsync(key as NetworkImage, decode, chunkEvents),
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

    return MultiFrameImageStreamCompleter.fromIterator(
      chunkEvents: chunkEvents.stream,
      iterator: _loadAsync(key as NetworkImage, decode, chunkEvents),
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
  Future<ImageFrameIterator> _loadAsync(
    NetworkImage key,
    _SimpleDecoderCallback decode,
    StreamController<ImageChunkEvent> chunkEvents,
  ) async {
    assert(key == this);

    final Uri resolved = Uri.base.resolve(key.url);

    final bool containsNetworkImageHeaders = key.headers?.isNotEmpty ?? false;

    // We use a different method when headers are set because the
    // `ui_web.createImageCodecFromUrl` method is not capable of handling headers.
    if (isSkiaWeb || containsNetworkImageHeaders) {
      if (containsNetworkImageHeaders) {
        // Don't even attempt to fall back to an <img> element if there are
        // headers.
        return _fetchImageBytes(key, decode);
      }

      return _fetchImageBytes(key, decode)
          .catchError((Object error, StackTrace? stackTrace) async {
        // If we failed to fetch the bytes, try to load the image in an <img>
        // element instead.
        final web.HTMLImageElement imageElement = imgElementFactory();
        imageElement.src = key.url;
        await imageElement.decode().toDart;
        return _SingleWebImageFrameIterator(imageElement);
      });
    } else {
      return ui_web.createImageCodecFromUrl(
        resolved,
        chunkCallback: (int bytes, int total) {
          chunkEvents.add(ImageChunkEvent(
              cumulativeBytesLoaded: bytes, expectedTotalBytes: total));
        },
      ).then((ui.Codec codec) => ImageFrameIterator.fromCodec(codec));
    }
  }

  Future<ImageFrameIterator> _fetchImageBytes(
    NetworkImage key,
    _SimpleDecoderCallback decode,
  ) async {
    assert(key == this);

    final Uri resolved = Uri.base.resolve(key.url);

    final bool containsNetworkImageHeaders = key.headers?.isNotEmpty ?? false;

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
        completer.completeError(image_provider.NetworkImageLoadException(
            statusCode: status, uri: resolved));
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

    return decode(await ui.ImmutableBuffer.fromUint8List(bytes))
        .then((ui.Codec codec) => ImageFrameIterator.fromCodec(codec));
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

class _SingleWebImageFrameIterator extends ImageFrameIterator {
  _SingleWebImageFrameIterator(this.imageElement);

  final web.HTMLImageElement imageElement;

  @override
  int get frameCount => 1;

  @override
  Future<ImageFrame> getNextFrame() {
    return SynchronousFuture<ImageFrame>(_HtmlImageElementFrame(imageElement));
  }

  @override
  int get repetitionCount => 0;
}

class _HtmlImageElementFrame extends ImageFrame {
  _HtmlImageElementFrame(this.imageElement);

  final web.HTMLImageElement imageElement;

  @override
  ImageInfo asImageInfo({required double scale, String? debugLabel}) {
    return WebImageInfo(imageElement, debugLabel: debugLabel);
  }

  @override
  void dispose() {
    // Do nothing. The <img> element will be garbage collected when there are
    // no more live references to it.
  }

  @override
  Duration get duration => Duration.zero;
}
