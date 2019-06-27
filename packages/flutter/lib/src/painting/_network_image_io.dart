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
    // Ownership of this controller is handed off to [_loadAsyncOnDesignatedIsolate];
    // it is that method's responsibility to close the controller's stream when
    // the image has been loaded or an error is thrown.
    final StreamController<ImageChunkEvent> chunkEvents = StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleter(
      codec: _loadAsyncOnDesignatedIsolate(key, chunkEvents),
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

  static Future<Isolate> _pendingLoader;
  static List<_PendingLoadRequest> _pendingLoadRequests;
  static SendPort _requestPort;

  Future<ui.Codec> _loadAsyncOnDesignatedIsolate(
    NetworkImage key,
    StreamController<ImageChunkEvent> chunkEvents,
  ) async {
    try {
      assert(key == this);

      final Uri resolved = Uri.base.resolve(key.url);

      final Completer<TransferableTypedData> completer = Completer<TransferableTypedData>();
      final RawReceivePort port = RawReceivePort((dynamic message) {
        if (message is TransferableTypedData) {
          completer.complete(message);
        } else if (message is ImageChunkEvent) {
          chunkEvents.add(message);
        } else {
          completer.completeError(message);
        }
      });

      // This will keep reference to [debugNetworkImageHttpClientProvider] tree-shaken
      // out of release build.
      HttpClientProvider httpClientProvider;
      assert(() { httpClientProvider = debugNetworkImageHttpClientProvider; return true; }());

      final _DownloadRequest downloadRequest = _DownloadRequest(port.sendPort,
          resolved, headers, httpClientProvider);
      if (_requestPort != null) {
        // If worker isolate is properly set up([_requestPort] is holding
        // initialized [SendPort], then just send download request down to it.
        _requestPort.send(downloadRequest);
      } else {
        if (_pendingLoader == null) {
          // If worker isolate creation was not started, start creation now.
          _pendingLoadRequests = <_PendingLoadRequest>[];

          _pendingLoader = _setupIsolate()..then((Isolate isolate) {
              isolate.addErrorListener(RawReceivePort(
                  (List<dynamic> errorAndStacktrace) {
                    _cleanupDueToError(errorAndStacktrace[0]);
                  }).sendPort);
              isolate.resume(isolate.pauseCapability);
            }).catchError((dynamic error, StackTrace stackTrace) {
              _cleanupDueToError(error);
            });
        }
        // Record donwload request so it can either send a request when isolate is ready or handle errors.
        _pendingLoadRequests.add(_PendingLoadRequest(
            (SendPort sendPort) { sendPort.send(downloadRequest); },
            (dynamic error) { downloadRequest.sendPort.send(error); }
        ));
      }

      final TransferableTypedData transferable = await completer.future;
      port.close();

      final Uint8List bytes = transferable.materialize().asUint8List();
      if (bytes.isEmpty)
        throw Exception('NetworkImage is an empty file: $resolved');

      return await PaintingBinding.instance.instantiateImageCodec(bytes);
    } finally {
      chunkEvents.close();
    }
  }

  void _cleanupDueToError(dynamic error) {
    for (_PendingLoadRequest request in _pendingLoadRequests) {
      request.handleError(error);
    }
    _pendingLoadRequests = null;
    _pendingLoader = null;
  }


  Future<Isolate> _setupIsolate() {
    // This is used to get _requestPort [SendPort] that can be used to
    // communicate with worker isolate: when isolate is spawned it will send
    // it's [SendPort] over via this [RawReceivePort].
    // Received [sendPort] can also be [null], which indicates that worker
    // isolate exited after being idle.
    final RawReceivePort receivePort = RawReceivePort((SendPort sendPort) {
      _requestPort = sendPort;
      if (sendPort == null) {
        _pendingLoader = null;
      }

      // When we received [SendPort] for the worker isolate, we send all
      // pending requests that were accumulated before worker isolate provided
      // it's port (before [_requestPort] was populated).
      for (_PendingLoadRequest pendingRequest in _pendingLoadRequests) {
        // [sendPort] being null indicates that worker has been idle and exited.
        // That should not happen if there are pending download requests.
        assert(sendPort != null);
        pendingRequest.sendRequest(sendPort);
      }
      _pendingLoadRequests.clear();
    });

    return Isolate.spawn<_HttpClientIsolateParameters>(
        _handleHttpClientGet,
        _HttpClientIsolateParameters(receivePort.sendPort),
        paused: true);
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

class _PendingLoadRequest {
  _PendingLoadRequest(this.sendRequest, this.handleError);

  Function sendRequest;
  Function handleError;
}


class _DownloadRequest {
  _DownloadRequest(this.sendPort, this.uri, this.headers, this.debugNetworkImageHttpClientProvider);

  final SendPort sendPort;
  final Uri uri;
  final Map<String, String> headers;
  final HttpClientProvider debugNetworkImageHttpClientProvider;
}

class _HttpClientIsolateParameters {
  _HttpClientIsolateParameters(this.sendPort);

  final SendPort sendPort;
}

// We set `autoUncompress` to false to ensure that we can trust the value of
// the `Content-Length` HTTP header. We automatically uncompress the content
// in our call to [consolidateHttpClientResponseBytes].
final HttpClient _sharedHttpClient = HttpClient()..autoUncompress = false;
const Duration _idleDuration = Duration(seconds: 60);

void _handleHttpClientGet(_HttpClientIsolateParameters params) {
  int ongoingRequests = 0;
  Timer idleTimer;
  RawReceivePort receivePort;

  // Sets up a handler that processes download requests messages.
  receivePort = RawReceivePort((_DownloadRequest downloadRequest) async {
    ongoingRequests++;
    idleTimer?.cancel();
    final HttpClient httpClient =
      downloadRequest.debugNetworkImageHttpClientProvider != null
          ? downloadRequest.debugNetworkImageHttpClientProvider()
          : _sharedHttpClient;

    try {
      final HttpClientRequest request = await httpClient.getUrl(downloadRequest.uri);
      downloadRequest.headers?.forEach((String name, String value) {
        request.headers.add(name, value);
      });
      final HttpClientResponse response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw Exception(
            'HTTP request failed, statusCode: ${response?.statusCode}, ${downloadRequest.uri}');
      }
      final TransferableTypedData transferable = await consolidateHttpClientResponseBytes(
          response,
          onBytesReceived: (int cumulative, int total) {
             downloadRequest.sendPort.send(ImageChunkEvent(
               cumulativeBytesLoaded: cumulative,
               expectedTotalBytes: total,
             ));
          });
      downloadRequest.sendPort.send(transferable);
    } catch (error) {
      downloadRequest.sendPort.send(error.toString());
    }
    ongoingRequests--;
    if (ongoingRequests == 0) {
      idleTimer = Timer(_idleDuration, () {
        // [null] indicates that worker is going down.
        params.sendPort.send(null);
        receivePort?.close();
      });
    }
  });

  params.sendPort.send(receivePort.sendPort);
}
