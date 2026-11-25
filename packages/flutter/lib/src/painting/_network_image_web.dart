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
        } else if (_hasEphemeralErrorListener) {
          _attachInnerEphemeralErrorForwarder();
        } else if (_hadOuterErrorListener) {
          completer.addEphemeralErrorListener(_noopErrorListener);
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

  ImageStreamCompleterHandle? _completerHandle;
  bool _subscribed = false;
  bool _deferInnerErrors = false;
  Object? _lastError;
  ({Object exception, StackTrace? stackTrace})? _pendingError;
  bool _hasImage = false;
  bool _hadOuterErrorListener = false;
  bool _propagatedErrorSuppression = false;
  bool _hasEphemeralErrorListener = false;
  bool _innerEphemeralForwarderAttached = false;
  bool _disposed = false;

  static void _disposeImage(ImageInfo image, bool synchronousCall) {
    image.dispose();
  }

  static void _noopErrorListener(Object exception, StackTrace? stackTrace) {}

  static const ImageStreamListener _errorSuppressionListener = ImageStreamListener(
    _disposeImage,
    reportErrors: false,
  );

  static const ImageStreamListener _suppressDuplicateReportListener = ImageStreamListener(
    _disposeImage,
    onError: _noopErrorListener,
  );

  late final ImageStreamListener _innerListener = ImageStreamListener(
    (ImageInfo image, bool synchronousCall) {
      setImage(image);
    },
    onChunk: (ImageChunkEvent event) {
      reportImageChunkEvent(event);
    },
    onError: (Object exception, StackTrace? stackTrace) {
      if (_deferInnerErrors) {
        if (!identical(exception, _lastError)) {
          _pendingError = (exception: exception, stackTrace: stackTrace);
        }
        return;
      }
      reportError(exception: exception, stack: stackTrace);
    },
  );

  void _onInnerEphemeralError(Object exception, StackTrace? stackTrace) {
    _innerEphemeralForwarderAttached = false;
    if (_deferInnerErrors) {
      if (!identical(exception, _lastError)) {
        _pendingError = (exception: exception, stackTrace: stackTrace);
      }
      return;
    }
    if (_disposed || _subscribed) {
      return;
    }
    reportError(exception: exception, stack: stackTrace);
  }

  void _attachInnerEphemeralErrorForwarder({bool deferErrors = false}) {
    if (!resolved || _subscribed || _disposed || _innerEphemeralForwarderAttached) {
      return;
    }
    if (!_hasImage) {
      _innerEphemeralForwarderAttached = true;
    }
    final bool previousDefer = _deferInnerErrors;
    _deferInnerErrors = deferErrors;
    try {
      completer.addEphemeralErrorListener(_onInnerEphemeralError);
    } finally {
      _deferInnerErrors = previousDefer;
    }
  }

  void _recordSilentInnerError(Object exception, StackTrace? stackTrace) {
    if (_lastError == null && !_hasImage) {
      super.addEphemeralErrorListener(_noopErrorListener);
      reportError(exception: exception, stack: stackTrace);
      return;
    }
    super.addListener(_suppressDuplicateReportListener);
    try {
      reportError(exception: exception, stack: stackTrace);
    } finally {
      super.removeListener(_suppressDuplicateReportListener);
    }
  }

  @protected
  @override
  void setImage(ImageInfo image) {
    _hasImage = true;
    _hasEphemeralErrorListener = false;
    _innerEphemeralForwarderAttached = false;
    super.setImage(image);
  }

  @override
  void reportError({
    DiagnosticsNode? context,
    required Object exception,
    StackTrace? stack,
    InformationCollector? informationCollector,
    bool silent = false,
  }) {
    _lastError = exception;
    _hasEphemeralErrorListener = false;
    super.reportError(
      context: context,
      exception: exception,
      stack: stack,
      informationCollector: informationCollector,
      silent: silent,
    );
  }

  @override
  void addEphemeralErrorListener(ImageErrorListener listener) {
    if (!_disposed && resolved && !_subscribed) {
      _attachInnerEphemeralErrorForwarder(deferErrors: true);
      final ({Object exception, StackTrace? stackTrace})? pendingError = _pendingError;
      _pendingError = null;
      if (pendingError != null) {
        _recordSilentInnerError(pendingError.exception, pendingError.stackTrace);
      }
    }
    super.addEphemeralErrorListener(listener);
    if (_lastError == null && !_hasImage) {
      _hasEphemeralErrorListener = true;
    }
  }

  @override
  void addListener(ImageStreamListener listener) {
    if (!_disposed) {
      if (!listener.reportErrors) {
        _hadOuterErrorListener = true;
      }
      // Subscribe before adding, so the child's synchronous replay of its
      // current frame lands in setImage while this completer has no listeners
      // yet. The new listener then receives exactly one frame, from
      // super.addListener's own replay. Defer inner error reporting so any
      // unseen inner error updates _currentError before super.addListener
      // replays it to listener.
      if (!hasListeners) {
        _subscribeToCompleter(deferErrors: true);
      }
    }
    final ({Object exception, StackTrace? stackTrace})? pendingError = _pendingError;
    _pendingError = null;
    if (pendingError != null) {
      // Temporarily attach a reportErrors: true listener with onError set so
      // reportError updates _currentError without calling
      // FlutterError.reportError a second time (the inner completer already
      // reported or suppressed the error when it occurred while unsubscribed),
      // then register listener so super.addListener replays only the latest
      // _currentError.
      super.addListener(_suppressDuplicateReportListener);
      try {
        reportError(exception: pendingError.exception, stack: pendingError.stackTrace);
        super.addListener(listener);
      } finally {
        super.removeListener(_suppressDuplicateReportListener);
        if (!hasListeners) {
          _unsubscribeFromCompleter();
        }
      }
      return;
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

  void _subscribeToCompleter({bool deferErrors = false}) {
    if (!resolved || _subscribed) {
      return;
    }
    // Set before calling addListener: when called from task.then with active
    // listeners (where hasListeners is already true) and an already-resolved
    // inner image, the child may synchronously emit a frame and a listener
    // reacting to it may remove itself, re-entering _unsubscribeFromCompleter.
    _subscribed = true;
    _deferInnerErrors = deferErrors;
    try {
      completer.addListener(_innerListener);
    } finally {
      _deferInnerErrors = false;
    }
  }

  void _propagateErrorSuppression() {
    if (!_hadOuterErrorListener || _propagatedErrorSuppression || !resolved || !_subscribed) {
      return;
    }
    _propagatedErrorSuppression = true;
    // Attach and remove a reportErrors: false listener while _innerListener is
    // still subscribed (so completer.hasListeners is true and does not start
    // a decode) so completer._hadErrorListener becomes true even when a frame
    // has already loaded (where addEphemeralErrorListener is a no-op).
    completer.addListener(_errorSuppressionListener);
    completer.removeListener(_errorSuppressionListener);
  }

  void _unsubscribeFromCompleter() {
    if (!_subscribed) {
      return;
    }
    _propagateErrorSuppression();
    _subscribed = false;
    completer.removeListener(_innerListener);
    if (_hasEphemeralErrorListener) {
      _attachInnerEphemeralErrorForwarder();
    }
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
