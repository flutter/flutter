// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:file/file.dart';
import 'package:stream_channel/stream_channel.dart';

import 'base/process.dart';

const String _kManifest = 'MANIFEST.txt';
const String _kSend = 'send';
const String _kReceive = 'receive';
const String _kId = 'id';
const String _kType = 'type';
const String _kData = 'data';

File _getManifest(Directory location) {
  String path = location.fileSystem.path.join(location.path, _kManifest);
  return location.fileSystem.file(path);
}

class RecordingVMServiceChannel extends DelegatingStreamChannel<String> {
  final List<_Event> _events = <_Event>[];

  _StreamRecorder _streamRecorder;
  _RecordingSink _sinkRecorder;

  RecordingVMServiceChannel(StreamChannel<String> delegate, Directory location)
      : super(delegate) {
    addShutdownHook(() async {
      _events.sort((_Event event1, _Event event2) {
        int id1 = event1.id;
        int id2 = event2.id;
        int result = id1.compareTo(id2);
        if (result != 0) {
          return result;
        } else if (event1.type == _kSend) {
          return -1;
        } else {
          return 1;
        }
      });

      File file = _getManifest(location);
      String json = new JsonEncoder.withIndent('  ').convert(_events);
      await file.writeAsString(json, flush: true);
    });
  }

  @override
  Stream<String> get stream {
    if (_streamRecorder == null) {
      _streamRecorder = new _StreamRecorder(super.stream, _events);
    }
    return _streamRecorder.stream;
  }

  @override
  StreamSink<String> get sink {
    if (_sinkRecorder == null) {
      _sinkRecorder = new _RecordingSink(super.sink, _events);
    }
    return _sinkRecorder;
  }
}

abstract class _Event {
  final String type;
  final Map<String, dynamic> data;

  _Event(this.type, this.data);

  int get id => data[_kId];

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      _kType: type,
      _kData: data,
    };
  }
}

class _SendEvent extends _Event {
  _SendEvent(Map<String, dynamic> data) : super(_kSend, data);
  _SendEvent.fromString(String data) : this(JSON.decoder.convert(data));
}

class _ReceiveEvent extends _Event {
  _ReceiveEvent(Map<String, dynamic> data) : super(_kReceive, data);
  _ReceiveEvent.fromString(String data) : this(JSON.decoder.convert(data));
}

class _Transaction {
  _SendEvent sendEvent;
  _ReceiveEvent receiveEvent;
}

class _StreamRecorder {
  final Stream<String> _delegate;
  final StreamController<String> _controller;
  final List<_Event> _recording;
  StreamSubscription<String> _subscription;

  _StreamRecorder(Stream<String> stream, this._recording)
      : _delegate = stream,
        _controller = stream.isBroadcast
            ? new StreamController<String>.broadcast()
            : new StreamController<String>() {
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

  StreamSubscription<String> _listenToStream() {
    return _delegate.listen(
      (String element) {
        _recording.add(new _ReceiveEvent.fromString(element));
        _controller.add(element);
      },
      onError: (dynamic error, StackTrace stackTrace) {
        // TODO(tvolkert): Record errors
        _controller.addError(error, stackTrace);
      },
      onDone: () {
        _controller.close();
      },
    );
  }

  Stream<String> get stream => _controller.stream;
}

class _RecordingSink implements StreamSink<String> {
  final StreamSink<String> _delegate;
  final List<_Event> _recording;

  _RecordingSink(this._delegate, this._recording);

  @override
  Future<dynamic> close() => _delegate.close();

  @override
  Future<dynamic> get done => _delegate.done;

  @override
  void add(String data) {
    _delegate.add(data);
    _recording.add(new _SendEvent.fromString(data));
  }

  @override
  void addError(dynamic errorEvent, [StackTrace stackTrace]) {
    throw new UnimplementedError('TODO(tvokert): add support if ever need to');
  }

  @override
  Future<dynamic> addStream(Stream<String> stream) {
    throw new UnimplementedError('TODO(tvokert): add support if ever need to');
  }
}

class ReplayVMServiceChannel extends StreamChannelMixin<String> {
  final Map<int, _Transaction> _transactions;
  final StreamController<String> _controller = new StreamController<String>();
  _ReplaySink _replaySink;

  ReplayVMServiceChannel(Directory location)
      : _transactions = _loadTransactions(location);

  static Map<int, _Transaction> _loadTransactions(Directory location) {
    File file = _getManifest(location);
    String json = file.readAsStringSync();
    Iterable<_Event> events = JSON.decoder.convert(json).map<_Event>(_toEvent);
    Map<int, _Transaction> transactions = <int, _Transaction>{};
    for (_Event event in events) {
      _Transaction transaction =
          transactions.putIfAbsent(event.id, () => new _Transaction());
      if (event.type == _kSend) {
        assert(transaction.sendEvent == null);
        transaction.sendEvent = event;
      } else {
        assert(transaction.receiveEvent == null);
        transaction.receiveEvent = event;
      }
    }
    return transactions;
  }

  static _Event _toEvent(Map<String, dynamic> jsonData) {
    return jsonData[_kType] == _kSend
        ? new _SendEvent(jsonData[_kData])
        : new _ReceiveEvent(jsonData[_kData]);
  }

  void send(_SendEvent event) {
    if (!_transactions.containsKey(event.id))
      throw new ArgumentError('No matching invocation found');
    _Transaction transaction = _transactions.remove(event.id);
    // TODO(tvolkert): validate `transaction.sendEvent` matches `event`
    print('Sending event ${event.id}');
    if (transaction.receiveEvent == null) {
      _controller.addError(new ArgumentError('Dangling event...'));
      _controller.close();
    } else {
      _controller.add(JSON.encoder.convert(transaction.receiveEvent.data));
      if (_transactions.isEmpty)
        _controller.close();
    }
  }

  @override
  StreamSink<String> get sink {
    if (_replaySink == null)
      _replaySink = new _ReplaySink(this);
    return _replaySink;
  }

  @override
  Stream<String> get stream => _controller.stream;
}

class _ReplaySink implements StreamSink<String> {
  final ReplayVMServiceChannel channel;
  final Completer<Null> _completer = new Completer<Null>();

  _ReplaySink(this.channel);

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
      throw new StateError('Sink already closed');
    channel.send(new _SendEvent.fromString(data));
  }

  @override
  void addError(dynamic errorEvent, [StackTrace stackTrace]) {
    throw new UnimplementedError('TODO(tvokert): add support if ever need to');
  }

  @override
  Future<dynamic> addStream(Stream<String> stream) {
    throw new UnimplementedError('TODO(tvokert): add support if ever need to');
  }
}
