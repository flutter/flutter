// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import 'binding.dart';
import 'debug.dart';
import 'image_provider.dart' as image_provider;
import 'image_stream.dart';

/// The dart:io implementation of [image_provider.NetworkImage].
class NetworkImage extends image_provider.ImageProvider<image_provider.NetworkImage> implements image_provider.NetworkImage {
  /// Creates an object that fetches the image at the given URL.
  ///
  /// The arguments [url] and [scale] must not be null.
  const NetworkImage(this.url, { this.scale = 1.0, this.headers })
    : assert(url != null),
      assert(scale != null);

  @override
  final String url;

  @override
  final double scale;

  @override
  final Map<String, String> headers;

  @override
  Future<NetworkImage> obtainKey(image_provider.ImageConfiguration configuration) {
    return SynchronousFuture<NetworkImage>(this);
  }

  @override
  ImageStreamCompleter load(image_provider.NetworkImage key) {
    // Ownership of this controller is handed off to [_loadAsync];
    // it is that method's responsibility to close the controller's stream when
    // the image has been loaded or an error is thrown.
    final StreamController<ImageChunkEvent> chunkEvents = StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, chunkEvents),
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
      informationCollector: () {
        return <DiagnosticsNode>[
          DiagnosticsProperty<image_provider.ImageProvider>('Image provider', this),
          DiagnosticsProperty<image_provider.NetworkImage>('Image key', key),
        ];
      },
    );
  }

  // For [_pendingLoader] we don't need the value(worker isolate), just the future
  // itself that is used as an indicator that successive load requests should be
  // added to the list of pending load requests [_pendingLoadRequests].
  static Future<void> _pendingLoader;
  static RawReceivePort _loaderErrorHandler;
  static List<_DownloadRequest> _pendingLoadRequests;
  static SendPort _requestPort;

  Future<ui.Codec> _loadAsync(
    NetworkImage key,
    StreamController<ImageChunkEvent> chunkEvents,
  ) async {
    RawReceivePort downloadResponseHandler;
    try {
      assert(key == this);

      final Uri resolved = Uri.base.resolve(key.url);

      final Completer<TransferableTypedData> bytesCompleter = Completer<TransferableTypedData>();
      downloadResponseHandler = RawReceivePort((_DownloadResponse response) {
        if (response.bytes != null) {
          if (bytesCompleter.isCompleted) {
            // If an uncaught error occurred in the worker isolate, we'll have
            // already completed our bytes completer.
            return;
          }
          bytesCompleter.complete(response.bytes);
        } else if (response.chunkEvent != null) {
          chunkEvents.add(response.chunkEvent);
        } else if (response.error != null) {
          bytesCompleter.completeError(response.error);
        } else {
          assert(false);
        }
      });

      // This will keep references to [debugNetworkImageHttpClientProvider] tree-shaken
      // out of release builds.
      HttpClientProvider httpClientProvider;
      assert(() { httpClientProvider = debugNetworkImageHttpClientProvider; return true; }());

      final _DownloadRequest downloadRequest = _DownloadRequest(
        downloadResponseHandler.sendPort,
        resolved,
        headers,
        httpClientProvider,
      );
      if (_requestPort != null) {
        // If worker isolate is properly set up ([_requestPort] is holding
        // initialized [SendPort]), then just send download request down to it.
        _requestPort.send(downloadRequest);
      } else {
        if (_pendingLoader == null) {
          // If worker isolate creation was not started, start creation now.
          _spawnAndSetupIsolate();
        }
        // Record download request so it can either send a request when isolate is ready or handle errors.
        _pendingLoadRequests.add(downloadRequest);
      }

      final TransferableTypedData transferable = await bytesCompleter.future;

      final Uint8List bytes = transferable.materialize().asUint8List();
      if (bytes.isEmpty)
        throw Exception('NetworkImage is an empty file: $resolved');

      return PaintingBinding.instance.instantiateImageCodec(bytes);
    } finally {
      chunkEvents.close();
      downloadResponseHandler?.close();
    }
  }

  void _spawnAndSetupIsolate() {
    assert(_pendingLoadRequests == null);
    assert(_loaderErrorHandler == null);
    assert(_pendingLoader == null);
    _pendingLoadRequests = <_DownloadRequest>[];
    _pendingLoader = _spawnIsolate()..then((Isolate isolate) {
      _loaderErrorHandler = RawReceivePort((List<dynamic> errorAndStackTrace) {
        _cleanupDueToError(errorAndStackTrace[0]);
      });
      isolate.addErrorListener(_loaderErrorHandler.sendPort);
      isolate.resume(isolate.pauseCapability);
    }).catchError((dynamic error, StackTrace stackTrace) {
      _cleanupDueToError(error);
    });
  }

  void _cleanupDueToError(dynamic error) {
    for (_DownloadRequest request in _pendingLoadRequests) {
      request.handleError(error);
    }
    _pendingLoadRequests = null;
    _pendingLoader = null;
    _loaderErrorHandler.close();
    _loaderErrorHandler = null;
  }

  Future<Isolate> _spawnIsolate() {
    // Once worker isolate is up and running it sends it's [sendPort] over
    // [communicationBootstrapHandler] receive port.
    // If [sendPort] is [null], it indicates that worker isolate exited after
    // being idle.
    final RawReceivePort communicationBootstrapHandler = RawReceivePort((SendPort sendPort) {
      _requestPort = sendPort;
      if (sendPort == null) {
        assert(_pendingLoadRequests.isEmpty);
        _pendingLoader = null;
        _pendingLoadRequests = null;
        _loaderErrorHandler.close();
        _loaderErrorHandler = null;
        return;
      }

      // When we received [SendPort] for the worker isolate, we send all
      // pending requests that were accumulated before worker isolate provided
      // it's port (before [_requestPort] was populated).
      _pendingLoadRequests.forEach(sendPort.send);
      _pendingLoadRequests.clear();
    });

    return Isolate.spawn<SendPort>(_initializeWorkerIsolate,
      communicationBootstrapHandler.sendPort, paused: true);
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType)
      return false;
    final NetworkImage typedOther = other;
    return url == typedOther.url && scale == typedOther.scale;
  }

  @override
  int get hashCode => ui.hashValues(url, scale);

  @override
  String toString() => '$runtimeType("$url", scale: $scale)';
}

@immutable
class _DownloadResponse {
  const _DownloadResponse.bytes(this.bytes) : assert(bytes != null), chunkEvent = null, error = null;
  const _DownloadResponse.chunkEvent(this.chunkEvent) : assert(chunkEvent != null), bytes = null, error = null;
  const _DownloadResponse.error(this.error) : assert(error != null), bytes = null, chunkEvent = null;

  final TransferableTypedData bytes;
  final ImageChunkEvent chunkEvent;
  final dynamic error;
}

@immutable
class _DownloadRequest {
  const _DownloadRequest(this.sendPort, this.uri, this.headers, this.httpClientProvider) :
      assert(sendPort != null), assert(uri != null);

  final SendPort sendPort;
  final Uri uri;
  final Map<String, String> headers;
  final HttpClientProvider httpClientProvider;

  void handleError(dynamic error) { sendPort.send(_DownloadResponse.error(error)); }
}

// We set `autoUncompress` to false to ensure that we can trust the value of
// the `Content-Length` HTTP header. We automatically uncompress the content
// in our call to [getHttpClientResponseBytes].
final HttpClient _sharedHttpClient = HttpClient()..autoUncompress = false;
const Duration _idleDuration = Duration(seconds: 60);

/// Sets up the worker isolate to listen for incoming [_DownloadRequest]s from
/// the main isolate.
///
/// This method runs on a worker isolate.
///
/// The `handshakeSendPort` argument is this worker isolate's communications
/// link back to the main isolate. It is used to set-up the channel with which
/// the main isolate sends download requests to the worker isolate.
void _initializeWorkerIsolate(SendPort handshakeSendPort) {
  int ongoingRequests = 0;
  Timer idleTimer;
  RawReceivePort downloadRequestHandler;

  // Sets up a handler that processes download requests messages.
  downloadRequestHandler = RawReceivePort((_DownloadRequest downloadRequest) async {
    ongoingRequests++;
    idleTimer?.cancel();
    final HttpClient httpClient = downloadRequest.httpClientProvider != null
        ? downloadRequest.httpClientProvider()
        : _sharedHttpClient;

    try {
      final HttpClientRequest request = await httpClient.getUrl(downloadRequest.uri);
      downloadRequest.headers?.forEach((String name, String value) {
        request.headers.add(name, value);
      });
      final HttpClientResponse response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw image_provider.NetworkImageLoadException(
          statusCode: response?.statusCode,
          uri: downloadRequest.uri,
        );
      }
      final TransferableTypedData transferable = await getHttpClientResponseBytes(
        response,
        onBytesReceived: (int cumulative, int total) {
          downloadRequest.sendPort.send(_DownloadResponse.chunkEvent(
            ImageChunkEvent(
              cumulativeBytesLoaded: cumulative,
              expectedTotalBytes: total,
            ),
          ));
        },
      );
      downloadRequest.sendPort.send(_DownloadResponse.bytes(transferable));
    } catch (error) {
      downloadRequest.sendPort.send(_DownloadResponse.error(error));
    }
    ongoingRequests--;
    if (ongoingRequests == 0) {
      idleTimer = Timer(_idleDuration, () {
        assert(ongoingRequests == 0);
        // [null] indicates that worker is going down.
        handshakeSendPort.send(null);
        downloadRequestHandler.close();
      });
    }
  });

  handshakeSendPort.send(downloadRequestHandler.sendPort);
}
