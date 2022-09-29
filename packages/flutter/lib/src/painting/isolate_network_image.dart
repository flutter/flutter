// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

@immutable
class IsolateNetworkImage extends ImageProvider<IsolateNetworkImage> {

  /// Creates an object that fetches the image at the given URL.
  ///
  /// The arguments [url] and [scale] must not be null.
  const IsolateNetworkImage(this.url, { this.scale = 1.0, this.headers })
    : assert(url != null),
      assert(scale != null);

  final String url;
  final double scale;
  final Map<String, String>? headers;

  static NetworkIsolate? _networkIsolate;
  static final Future<NetworkIsolate> _pendingNetworkIsolate = NetworkIsolate.create().then((NetworkIsolate value) {
    return _networkIsolate = value;
  });

  @override
  Future<IsolateNetworkImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<IsolateNetworkImage>(this);
  }

  @override
  ImageStreamCompleter load(IsolateNetworkImage key, DecoderCallback decode) {
    // Ownership of this controller is handed off to [_loadAsync]; it is that
    // method's responsibility to close the controller's stream when the image
    // has been loaded or an error is thrown.
    final StreamController<ImageChunkEvent> chunkEvents = StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, chunkEvents, null, decode),
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
      debugLabel: key.url,
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<IsolateNetworkImage>('Image provider', this),
        DiagnosticsProperty<IsolateNetworkImage>('Image key', key),
      ],
    );
  }

  @override
  ImageStreamCompleter loadBuffer(IsolateNetworkImage key, DecoderBufferCallback decode) {
    // Ownership of this controller is handed off to [_loadAsync]; it is that
    // method's responsibility to close the controller's stream when the image
    // has been loaded or an error is thrown.
    final StreamController<ImageChunkEvent> chunkEvents = StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, chunkEvents, decode, null),
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
      debugLabel: key.url,
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<IsolateNetworkImage>('Image provider', this),
        DiagnosticsProperty<IsolateNetworkImage>('Image key', key),
      ],
    );
  }


  Future<ui.Codec> _loadAsync(
    IsolateNetworkImage key,
    StreamController<ImageChunkEvent> chunkEvents,
    DecoderBufferCallback? decode,
    DecoderCallback? decodeDepreacted,
  ) async {
    try {
      assert(key == this);
      if (_networkIsolate == null) {
        await _pendingNetworkIsolate;
      }
      final Uri uri = Uri.base.resolve(key.url);
      final Uint8List bytes = await _networkIsolate!.getUrl(uri, key.headers, (int cumulativeBytes, int? totalBytes) {
        chunkEvents.add(ImageChunkEvent(cumulativeBytesLoaded: cumulativeBytes, expectedTotalBytes: totalBytes));
      });
      if (decode != null) {
        final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
        return decode(buffer);
      } else {
        assert(decodeDepreacted != null);
        return decodeDepreacted!(bytes);
      }
    } catch (e) {
      // Depending on where the exception was thrown, the image cache may not
      // have had a chance to track the key in the cache at all.
      // Schedule a microtask to give the cache a chance to add the key.
      scheduleMicrotask(() {
        PaintingBinding.instance.imageCache.evict(key);
      });
      rethrow;
    } finally {
      chunkEvents.close();
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is IsolateNetworkImage
        && other.url == url
        && other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(url, scale);

  @override
  String toString() => '${objectRuntimeType(this, 'NetworkImage')}("$url", scale: $scale)';
}

class NetworkIsolate {
  NetworkIsolate._();

  late final Isolate _isolate;
  late final SendPort _sendPort;
  final Completer<void> _ready = Completer<void>();

  int _nextId = 0;
  final Map<int, _PendingNetworkRequest> _pending = <int, _PendingNetworkRequest>{};

  static Future<NetworkIsolate> create() async {
    final NetworkIsolate networkIsolate = NetworkIsolate._();
    final RawReceivePort port = RawReceivePort();
    port.handler = networkIsolate._onResponse;

    final Isolate isolate = await Isolate.spawn(
      _networkIsolateMain,
      _SpawnArgs(port.sendPort),
    );
    await networkIsolate._ready.future;
    // Do not access this field directly; use [_httpClient] instead.
    // We set `autoUncompress` to false to ensure that we can trust the value of
    // the `Content-Length` HTTP header. We automatically uncompress the content
    // in our call to [consolidateHttpClientResponseBytes].
    final HttpClient httpClient = HttpClient()..autoUncompress = false;
    networkIsolate._sendPort.send(httpClient);
    return networkIsolate.._isolate = isolate;
  }

  void dispose() {
    _isolate.kill();
  }

  Future<Uint8List> getUrl(
    Uri uri,
    Map<String, String>? headers,
    void Function(int cumulativeBytes, int? totalBytes)? onChunkEvent,
  ) async {
    final int id = _nextId;
    _nextId += 1;

    final _PendingNetworkRequest request = _PendingNetworkRequest();
    _pending[id] = request;

    try {
      if (onChunkEvent != null) {
        request.controller.stream.listen((_ChunkEvent event) {
          onChunkEvent.call(event.cumulativeBytes, event.totalBytes);
        });
      }
      _sendPort.send(_GetUrl(uri, headers, id));
      return request.completer.future;
    } finally {
      _pending.remove(id);
      request.controller.close();
    }
  }

  void _onResponse(Object? data) {
    if (data is SendPort) {
      _sendPort = data;
      _ready.complete();
    } else if (data is _ChunkEvent) {
      _pending[data.id]!.controller.add(data);
    } else if (data is _ExceptionEvent) {
      _pending[data.id]!.completer.completeError(data.exception);
    } else if (data is _ResponseEvent) {
      _pending[data.id]!.completer.complete(data.data.materialize().asUint8List());
    } else {
      assert(false, 'Unexpected NetworkIsolate response: $data');
    }
  }

  static late HttpClient _httpClient;

  static void _networkIsolateMain(_SpawnArgs args) {
    final RawReceivePort port = RawReceivePort();
    port.handler = (Object? request) {
      if (request is HttpClient) {
        _httpClient = request;
      } else if (request is _GetUrl) {
        _getUrl(_httpClient, request.uri, request.id, request.headers, args.sendPort);
      } else {
        assert(false, 'Unexpected NetworkIsolate request: $request');
      }
    };
    args.sendPort.send(port.sendPort);
  }

  static Future<void> _getUrl(HttpClient client, Uri uri, int id, Map<String, String>? headers, SendPort sendPort) async {
    try {
      final HttpClientRequest request = await client.getUrl(uri);
      headers?.forEach(request.headers.add);
      final HttpClientResponse response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        // The network may be only temporarily unavailable, or the file will be
        // added on the server later. Avoid having future calls to resolve
        // fail to check the network again.
        sendPort.send(_ExceptionEvent(Exception(), id));
        await response.drain<List<int>>(<int>[]);
        return;
      }
      final TransferableTypedData bytes = await _transferableConsolidateHttpClientResponseBytes(
        response,
        onBytesReceived: (int cumulative, int? total) {
          sendPort.send(_ChunkEvent(cumulative, total, id));
        },
      );
      sendPort.send(_ResponseEvent(bytes, id));
    } catch (err) {
      sendPort.send(_ExceptionEvent(err, id));
    }
  }
}

class _PendingNetworkRequest {
  final Completer<Uint8List> completer = Completer<Uint8List>();
  final StreamController<_ChunkEvent> controller = StreamController<_ChunkEvent>();
  StackTrace? stackTrace;
}

class _ChunkEvent {
  const _ChunkEvent(this.cumulativeBytes, this.totalBytes, this.id);

  final int id;
  final int cumulativeBytes;
  final int? totalBytes;
}

class _ResponseEvent {
  const _ResponseEvent(this.data, this.id);

  final int id;
  final TransferableTypedData data;
}

class _ExceptionEvent {
  _ExceptionEvent(this.exception, this.id);

  final int id;
  final Object exception;
}

class _SpawnArgs {
  _SpawnArgs(this.sendPort);

  final SendPort sendPort;
}

class _GetUrl {
  const _GetUrl(this.uri, this.headers, this.id);

  final Uri uri;
  final Map<String, String>? headers;
  final int id;
}


Future<TransferableTypedData> _transferableConsolidateHttpClientResponseBytes(
  HttpClientResponse response, {
  bool autoUncompress = true,
  BytesReceivedCallback? onBytesReceived,
}) {
  assert(autoUncompress != null);
  final Completer<TransferableTypedData> completer = Completer<TransferableTypedData>.sync();
  final _OutputBuffer output = _OutputBuffer();
  ByteConversionSink sink = output;
  int? expectedContentLength = response.contentLength;
  if (expectedContentLength == -1) {
    expectedContentLength = null;
  }
  switch (response.compressionState) {
    case HttpClientResponseCompressionState.compressed:
      if (autoUncompress) {
        // We need to un-compress the bytes as they come in.
        sink = gzip.decoder.startChunkedConversion(output);
      }
      break;
    case HttpClientResponseCompressionState.decompressed:
      // response.contentLength will not match our bytes stream, so we declare
      // that we don't know the expected content length.
      expectedContentLength = null;
      break;
    case HttpClientResponseCompressionState.notCompressed:
      // Fall-through.
      break;
  }

  int bytesReceived = 0;
  late final StreamSubscription<List<int>> subscription;
  subscription = response.listen((List<int> chunk) {
    sink.add(chunk);
    if (onBytesReceived != null) {
      bytesReceived += chunk.length;
      try {
        onBytesReceived(bytesReceived, expectedContentLength);
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
        subscription.cancel();
        return;
      }
    }
  }, onDone: () {
    sink.close();
    completer.complete(output.bytes);
  }, onError: completer.completeError, cancelOnError: true);

  return completer.future;
}

class _OutputBuffer extends ByteConversionSinkBase {
  List<Uint8List>? _chunks = <Uint8List>[];
  TransferableTypedData? _bytes;

  @override
  void add(List<int> chunk) {
    assert(_bytes == null);
    _chunks!.add(chunk as Uint8List);
  }

  @override
  void close() {
    if (_bytes != null) {
      // We've already been closed; this is a no-op
      return;
    }
    _bytes = TransferableTypedData.fromList(_chunks!);
    _chunks = null;
  }

  TransferableTypedData get bytes {
    assert(_bytes != null);
    return _bytes!;
  }
}
