// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';
import 'dart:ui' as ui;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../web.dart' as web;
import '_web_image_info_web.dart';
import 'image_provider.dart' as image_provider;
import 'image_stream.dart';

/// The type for an overridable factory function for creating an HTTP request,
/// used for testing purposes.
typedef HttpRequestFactory = web.XMLHttpRequest Function();

/// The type for an overridable factory function for creating HTML elements to
/// display images, used for testing purposes.
typedef HtmlElementFactory = web.HTMLImageElement Function();

// Method signature for _loadAsync decode callbacks.
typedef _SimpleDecoderCallback = Future<ui.Codec> Function(ui.ImmutableBuffer buffer);

/// The default HTTP client.
web.XMLHttpRequest _httpClient() {
  return web.XMLHttpRequest();
}

/// Creates an overridable factory function.
@visibleForTesting
HttpRequestFactory httpRequestFactory = _httpClient;

/// Restores the default HTTP request factory.
@visibleForTesting
void debugRestoreHttpRequestFactory() {
  httpRequestFactory = _httpClient;
}

/// The default HTML element factory.
web.HTMLImageElement _imgElementFactory() {
  return web.document.createElement('img') as web.HTMLImageElement;
}

/// The factory function that creates HTML elements, can be overridden for
/// tests.
@visibleForTesting
HtmlElementFactory imgElementFactory = _imgElementFactory;

/// Restores the default HTML element factory.
@visibleForTesting
void debugRestoreImgElementFactory() {
  imgElementFactory = _imgElementFactory;
}

/// The web implementation of [image_provider.NetworkImage].
///
/// NetworkImage on the web does not support decoding to a specified size.
@immutable
class NetworkImage extends image_provider.ImageProvider<image_provider.NetworkImage>
    implements image_provider.NetworkImage {
  /// Creates an object that fetches the image at the given URL.
  const NetworkImage(
    this.url, {
    this.scale = 1.0,
    this.headers,
    this.webHtmlElementStrategy = image_provider.WebHtmlElementStrategy.never,
  });

  @override
  final String url;

  @override
  final double scale;

  @override
  final Map<String, String>? headers;

  @override
  final image_provider.WebHtmlElementStrategy webHtmlElementStrategy;

  @override
  Future<NetworkImage> obtainKey(image_provider.ImageConfiguration configuration) {
    return SynchronousFuture<NetworkImage>(this);
  }

  @override
  ImageStreamCompleter loadBuffer(
    image_provider.NetworkImage key,
    image_provider.DecoderBufferCallback decode,
  ) {
    return _ForwardingImageStreamCompleter(
      _loadAsync(key as NetworkImage, decode),
      informationCollector: _imageStreamInformationCollector(key),
      debugLabel: key.url,
    );
  }

  @override
  ImageStreamCompleter loadImage(
    image_provider.NetworkImage key,
    image_provider.ImageDecoderCallback decode,
  ) {
    return _ForwardingImageStreamCompleter(
      _loadAsync(key as NetworkImage, decode),
      informationCollector: _imageStreamInformationCollector(key),
      debugLabel: key.url,
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

  Future<ImageStreamCompleter> _loadAsync(NetworkImage key, _SimpleDecoderCallback decode) async {
    assert(key == this);

    Future<ImageStreamCompleter> loadViaDecode() async {
      // Resolve the Codec before passing it to
      // `MultiFrameImageStreamCompleter` so any errors aren't reported
      // twice (once from the `MultiFrameImageStreamCompleter` and again
      // from the wrapping `_ForwardingImageStreamCompleter`).
      final ui.Codec codec = await _fetchImageBytes(decode);
      return MultiFrameImageStreamCompleter(
        codec: Future<ui.Codec>.value(codec),
        scale: key.scale,
        debugLabel: key.url,
        informationCollector: _imageStreamInformationCollector(key),
      );
    }

    Future<ImageStreamCompleter> loadViaImgElement() async {
      // If we failed to fetch the bytes, try to load the image in an <img>
      // element instead.
      final web.HTMLImageElement imageElement = imgElementFactory();
      imageElement.src = key.url;
      // Decode the <img> element before creating the ImageStreamCompleter
      // to avoid double reporting the error.
      await imageElement.decode().toDart;
      return OneFrameImageStreamCompleter(
        Future<ImageInfo>.value(WebImageInfo(imageElement, debugLabel: key.url)),
        informationCollector: _imageStreamInformationCollector(key),
      )..debugLabel = key.url;
    }

    final bool containsNetworkImageHeaders = key.headers?.isNotEmpty ?? false;
    // When headers are set, the image can only be loaded by decoding.
    //
    // For CanvasKit and Skwasm, it is not possible to load an <img> element and
    // pass the headers with the request to fetch the image. Since the user has
    // provided headers, this function should assume the headers are required to
    // resolve to the correct resource and should not attempt to load the image
    // in an <img> tag without the headers.
    if (containsNetworkImageHeaders) {
      return loadViaDecode();
    }

    switch (webHtmlElementStrategy) {
      case image_provider.WebHtmlElementStrategy.never:
        return loadViaDecode();
      case image_provider.WebHtmlElementStrategy.prefer:
        return loadViaImgElement();
      case image_provider.WebHtmlElementStrategy.fallback:
        try {
          // Await here so that errors occurred during the asynchronous process
          // of `loadViaDecode` are caught and triggers `loadViaImgElement`.
          return await loadViaDecode();
        } catch (e) {
          return loadViaImgElement();
        }
    }
  }

  Future<ui.Codec> _fetchImageBytes(_SimpleDecoderCallback decode) async {
    final Uri resolved = Uri.base.resolve(url);

    final bool containsNetworkImageHeaders = headers?.isNotEmpty ?? false;

    final completer = Completer<web.XMLHttpRequest>();
    final web.XMLHttpRequest request = httpRequestFactory();

    request.open('GET', url, true);
    request.responseType = 'arraybuffer';
    if (containsNetworkImageHeaders) {
      headers!.forEach((String header, String value) {
        request.setRequestHeader(header, value);
      });
    }

    request.addEventListener(
      'load',
      (web.Event e) {
        final int status = request.status;
        final bool accepted = status >= 200 && status < 300;
        final fileUri = status == 0; // file:// URIs have status of 0.
        final notModified = status == 304;
        final bool unknownRedirect = status > 307 && status < 400;
        final bool success = accepted || fileUri || notModified || unknownRedirect;

        if (success) {
          completer.complete(request);
        } else {
          completer.completeError(
            image_provider.NetworkImageLoadException(statusCode: status, uri: resolved),
          );
        }
      }.toJS,
    );

    request.addEventListener(
      'error',
      ((JSObject e) => completer.completeError(
        image_provider.NetworkImageLoadException(statusCode: request.status, uri: resolved),
      )).toJS,
    );

    request.send();

    await completer.future;

    final Uint8List bytes = (request.response! as JSArrayBuffer).toDart.asUint8List();

    if (bytes.lengthInBytes == 0) {
      throw image_provider.NetworkImageLoadException(statusCode: request.status, uri: resolved);
    }

    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is NetworkImage &&
        other.url == url &&
        other.scale == scale &&
        other.webHtmlElementStrategy == webHtmlElementStrategy &&
        mapEquals(other.headers, headers);
  }

  @override
  int get hashCode => Object.hash(
    url,
    scale,
    webHtmlElementStrategy,
    const MapEquality<String, String>().hash(headers),
  );

  @override
  String toString() =>
      '${objectRuntimeType(this, 'NetworkImage')}("$url", scale: ${scale.toStringAsFixed(1)}, webHtmlElementStrategy: ${webHtmlElementStrategy.name}, headers: $headers)';
}

/// An [ImageStreamCompleter] that delegates to another [ImageStreamCompleter]
/// that is loaded asynchronously.
///
/// The child completer is kept alive with a keep-alive handle until this
/// completer is disposed, but is only listened to while this completer has
/// listeners, so that a child such as [MultiFrameImageStreamCompleter] can
/// pause decoding when nothing is listening.
class _ForwardingImageStreamCompleter extends ImageStreamCompleter {
  _ForwardingImageStreamCompleter(
    this.task, {
    InformationCollector? informationCollector,
    String? debugLabel,
  }) {
    this.debugLabel = debugLabel;
    task.then(
      (ImageStreamCompleter value) {
        resolved = true;
        if (_disposed) {
          value.maybeDispose();
          return;
        }
        completer = value;
        _completerHandle = completer.keepAlive();
        if (hasListeners) {
          _subscribeToCompleter();
        }
      },
      onError: (Object error, StackTrace stack) {
        reportError(
          context: ErrorDescription('resolving an image stream completer'),
          exception: error,
          stack: stack,
          informationCollector: informationCollector,
          silent: true,
        );
      },
    );
  }

  final Future<ImageStreamCompleter> task;
  bool resolved = false;
  late final ImageStreamCompleter completer;

  /// Keeps [completer] alive while this completer is not listening to it.
  ///
  /// Without it, [completer] would be disposed as soon as this completer
  /// removes [_innerListener]. Released in [onDisposed].
  ImageStreamCompleterHandle? _completerHandle;

  /// Whether [_innerListener] is currently added to [completer].
  ///
  /// This is true only while this completer has listeners of its own, so that
  /// [completer] sees no listeners, and can pause, when nothing is listening.
  bool _subscribed = false;

  /// The last error forwarded from [completer] to this completer.
  ///
  /// When this completer subscribes again, [completer] immediately replays
  /// its last error. If that error was already forwarded, the replay is
  /// ignored so it is not reported twice.
  Object? _lastForwardedError;

  bool _disposed = false;

  // reportErrors is false because this completer reports forwarded errors to
  // its own listeners. An error that reaches [completer] while this completer
  // is not subscribed is kept by [completer] and forwarded when a listener is
  // added again, instead of being sent to FlutterError.onError by [completer].
  late final ImageStreamListener _innerListener = ImageStreamListener(
    (ImageInfo image, bool synchronousCall) {
      setImage(image);
    },
    onChunk: (ImageChunkEvent event) {
      reportImageChunkEvent(event);
    },
    onError: (Object exception, StackTrace? stackTrace) {
      if (identical(exception, _lastForwardedError)) {
        return;
      }
      _lastForwardedError = exception;
      reportError(exception: exception, stack: stackTrace);
    },
    reportErrors: false,
  );

  @override
  void addListener(ImageStreamListener listener) {
    // Subscribe before adding, so the child's synchronous replay of its
    // current frame lands in setImage while this completer has no listeners
    // yet. The new listener then receives exactly one frame, from
    // super.addListener's own replay.
    if (!_disposed && !hasListeners) {
      _subscribeToCompleter();
    }
    super.addListener(listener);
  }

  @override
  void removeListener(ImageStreamListener listener) {
    super.removeListener(listener);
    // super.removeListener may already have disposed this completer (no
    // listeners and no handles), in which case onDisposed unsubscribed and
    // this is a no-op.
    if (!hasListeners) {
      _unsubscribeFromCompleter();
    }
  }

  void _subscribeToCompleter() {
    if (!resolved || _subscribed) {
      return;
    }
    // Set before calling addListener: the child may synchronously emit a
    // frame, and a listener reacting to it may remove itself, re-entering
    // _unsubscribeFromCompleter.
    _subscribed = true;
    completer.addListener(_innerListener);
  }

  void _unsubscribeFromCompleter() {
    if (!_subscribed) {
      return;
    }
    _subscribed = false;
    completer.removeListener(_innerListener);
  }

  @override
  void onDisposed() {
    _disposed = true;
    _unsubscribeFromCompleter();
    _completerHandle?.dispose();
    _completerHandle = null;
    super.onDisposed();
  }
}
