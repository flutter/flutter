// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:file/file.dart';
import 'package:stream_channel/stream_channel.dart';

import 'base/io.dart';
import 'base/process.dart';
import 'globals.dart';

const String _kManifest = 'MANIFEST.txt';
const String _kRequest = 'request';
const String _kResponse = 'response';
const String _kId = 'id';
const String _kType = 'type';
const String _kData = 'data';

/// A [StreamChannel] that expects VM service (JSON-rpc) protocol messages and
/// serializes all such messages to the file system for later playback.
class RecordingVMServiceChannel extends DelegatingStreamChannel<String> {
  RecordingVMServiceChannel(StreamChannel<String> delegate, Directory location)
      : super(delegate) {
    addShutdownHook(() async {
      // Sort the messages such that they are ordered
      // `[request1, response1, request2, response2, ...]`. This serves no
      // purpose other than to make the serialized format more human-readable.
      _messages.sort();

      final File file = _getManifest(location);
      final String json = const JsonEncoder.withIndent('  ').convert(_messages);
      await file.writeAsString(json, flush: true);
    }, ShutdownStage.SERIALIZE_RECORDING);
  }

  final List<_Message> _messages = <_Message>[];

  _RecordingStream _streamRecorder;
  _RecordingSink _sinkRecorder;

  @override
  Stream<String> get stream {
    _streamRecorder ??= _RecordingStream(super.stream, _messages);
    return _streamRecorder.stream;
  }

  @override
  StreamSink<String> get sink => _sinkRecorder ??= _RecordingSink(super.sink, _messages);
}

/// Base class for request and response JSON-rpc messages.
abstract class _Message implements Comparable<_Message> {
  _Message(this.type, this.data);

  factory _Message.fromRecording(Map<String, dynamic> recordingData) {
    return recordingData[_kType] == _kRequest
        ? _Request(recordingData[_kData])
        : _Response(recordingData[_kData]);
  }

  final String type;
  final Map<String, dynamic> data;

  int get id => data[_kId];

  /// Allows [JsonEncoder] to properly encode objects of this type.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      _kType: type,
      _kData: data,
    };
  }

  @override
  int compareTo(_Message other) {
    if (id == null) {
      printError('Invalid VMService message data detected: $data');
      return -1;
    }
    final int result = id.compareTo(other.id);
    if (result != 0) {
      return result;
    } else if (type == _kRequest) {
      return -1;
    } else {
      return 1;
    }
  }
}

/// A VM service JSON-rpc request (sent to the VM).
class _Request extends _Message {
  _Request(Map<String, dynamic> data) : super(_kRequest, data);
  _Request.fromString(String data) : this(json.decoder.convert(data));
}

/// A VM service JSON-rpc response (from the VM).
class _Response extends _Message {
  _Response(Map<String, dynamic> data) : super(_kResponse, data);
  _Response.fromString(String data) : this(json.decoder.convert(data));
}

/// A matching request/response pair.
///
/// A request and response match by virtue of having matching
/// [IDs](_Message.id).
class _Transaction {
  _Request request;
  _Response response;
}

/// A helper class that monitors a [Stream] of VM service JSON-rpc responses
/// and saves the responses to a recording.
class _RecordingStream {
  _RecordingStream(Stream<String> stream, this._recording)
      : _delegate = stream,
        _controller = stream.isBroadcast
            ? StreamController<String>.broadcast()
            : StreamController<String>() {
    _controller.onListen = () {
      assert(_subscription == null);
      _subscription = _listenToStream();
    };
    _controller.onCancel = () async {
      assert(_subscription != null);
      await _subscription.cancel();
      _subscription = null;
    };
    _controller.onPause = () {
      assert(_subscription != null && !_subscription.isPaused);
      _subscription.pause();
    };
    _controller.onResume = () {
      assert(_subscription != null && _subscription.isPaused);
      _subscription.resume();
    };
  }

  final Stream<String> _delegate;
  final StreamController<String> _controller;
  final List<_Message> _recording;
  StreamSubscription<String> _subscription;

  StreamSubscription<String> _listenToStream() {
    return _delegate.listen(
      (String element) {
        _recording.add(_Response.fromString(element));
        _controller.add(element);
      },
      onError: _controller.addError, // We currently don't support recording of errors.
      onDone: _controller.close,
    );
  }

  /// The wrapped [Stream] to expose to callers.
  Stream<String> get stream => _controller.stream;
}

/// A [StreamSink] that monitors VM service JSON-rpc requests and saves the
/// requests to a recording.
class _RecordingSink implements StreamSink<String> {
  _RecordingSink(this._delegate, this._recording);

  final StreamSink<String> _delegate;
  final List<_Message> _recording;

  @override
  Future<dynamic> close() => _delegate.close();

  @override
  Future<dynamic> get done => _delegate.done;

  @override
  void add(String data) {
    _delegate.add(data);
    _recording.add(_Request.fromString(data));
  }

  @override
  void addError(dynamic errorEvent, [StackTrace stackTrace]) {
    throw UnimplementedError('Add support for this if the need ever arises');
  }

  @override
  Future<dynamic> addStream(Stream<String> stream) {
    throw UnimplementedError('Add support for this if the need ever arises');
  }
}

/// A [StreamChannel] that expects VM service (JSON-rpc) requests to be written
/// to its [StreamChannel.sink], looks up those requests in a recording, and
/// replays the corresponding responses back from the recording.
class ReplayVMServiceChannel extends StreamChannelMixin<String> {
  ReplayVMServiceChannel(Directory location)
      : _transactions = _loadTransactions(location);

  final Map<int, _Transaction> _transactions;
  final StreamController<String> _controller = StreamController<String>();
  _ReplaySink _replaySink;

  static Map<int, _Transaction> _loadTransactions(Directory location) {
    final File file = _getManifest(location);
    final String jsonData = file.readAsStringSync();
    final Iterable<_Message> messages = json.decoder.convert(jsonData).map<_Message>(_toMessage);
    final Map<int, _Transaction> transactions = <int, _Transaction>{};
    for (_Message message in messages) {
      final _Transaction transaction =
          transactions.putIfAbsent(message.id, () => _Transaction());
      if (message.type == _kRequest) {
        assert(transaction.request == null);
        transaction.request = message;
      } else {
        assert(transaction.response == null);
        transaction.response = message;
      }
    }
    return transactions;
  }

  static _Message _toMessage(Map<String, dynamic> jsonData) {
    return _Message.fromRecording(jsonData);
  }

  void send(_Request request) {
    if (!_transactions.containsKey(request.id))
      throw ArgumentError('No matching invocation found');
    final _Transaction transaction = _transactions.remove(request.id);
    // TODO(tvolkert): validate that `transaction.request` matches `request`
    if (transaction.response == null) {
      // This signals that when we were recording, the VM shut down before
      // we received the response. This is typically due to the user quitting
      // the app runner. We follow suit here and exit.
      printStatus('Exiting due to dangling request');
      exit(0);
    } else {
      _controller.add(json.encoder.convert(transaction.response.data));
      if (_transactions.isEmpty)
        _controller.close();
    }
  }

  @override
  StreamSink<String> get sink => _replaySink ??= _ReplaySink(this);

  @override
  Stream<String> get stream => _controller.stream;
}

class _ReplaySink implements StreamSink<String> {
  _ReplaySink(this.channel);

  final ReplayVMServiceChannel channel;
  final Completer<void> _completer = Completer<void>();

  @override
  Future<dynamic> close() {
    _completer.complete();
    return _completer.future;
  }

  @override
  Future<dynamic> get done => _completer.future;

  @override
  void add(String data) {
    if (_completer.isCompleted)
      throw StateError('Sink already closed');
    channel.send(_Request.fromString(data));
  }

  @override
  void addError(dynamic errorEvent, [StackTrace stackTrace]) {
    throw UnimplementedError('Add support for this if the need ever arises');
  }

  @override
  Future<dynamic> addStream(Stream<String> stream) {
    throw UnimplementedError('Add support for this if the need ever arises');
  }
}

File _getManifest(Directory location) {
  final String path = location.fileSystem.path.join(location.path, _kManifest);
  return location.fileSystem.file(path);
}
