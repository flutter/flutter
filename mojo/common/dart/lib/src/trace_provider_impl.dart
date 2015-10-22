// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:mojo/core.dart';
import 'package:mojo_services/tracing/tracing.mojom.dart';

enum TraceSendTiming {
  IMMEDIATE,
  // TODO: Add BATCHED?
  AT_END,
}

class TraceProviderImpl implements TraceProvider {
  // Any messages sent before the tracing service connects to us will be
  // recorded and kept until one second after construction of the trace
  // provider. If the tracing service connects before that time, we will replay
  // the recorded trace events.
  //
  // This allows the client to record trace events early during initialization
  // of the app.
  List<String> _message_queue;
  bool _enqueuing;

  TraceProviderStub _stub;
  TraceRecorderProxy _recorder;
  // TODO(rudominer) We currently ignore _categories.
  String _categories;

  TraceSendTiming _timing;

  TraceProviderImpl([TraceSendTiming timing = TraceSendTiming.IMMEDIATE]) {
    _message_queue = [];
    _enqueuing = true;
    _timing = timing;
    new Future.delayed(const Duration(seconds: 1), () {
      if (_enqueuing) {
        _enqueuing = false;
        _message_queue.clear();
      }
    });
  }

  void connect(MojoMessagePipeEndpoint e) {
    _stub = TraceProviderStub.newFromEndpoint(e);
    _stub.impl = this;
  }

  @override
  void startTracing(String categories, TraceRecorderProxy recorder) {
    assert(_recorder == null);
    _recorder = recorder;
    _categories = categories;
    _enqueuing = false;
    if (_timing == TraceSendTiming.IMMEDIATE) {
      for (String message in _message_queue) {
        _recorder.ptr.record(message);
      }
      _message_queue.clear();
    }
  }

  @override
  void stopTracing() {
    assert(_recorder != null);
    if (_timing == TraceSendTiming.AT_END) {
      for (String message in _message_queue) {
        _recorder.ptr.record(message);
      }
      _message_queue.clear();
    }
    _recorder.close();
    _recorder = null;
  }

  bool isActive() {
    return _enqueuing || _recorder != null;
  }

  void sendTraceMessage(String message) {
    switch (_timing) {
      case TraceSendTiming.IMMEDIATE:
        if (_recorder != null) {
          _recorder.ptr.record(message);
        } else if (_enqueuing) {
          _message_queue.add(message);
        }
        break;
      case TraceSendTiming.AT_END:
        if (isActive()) {
          _message_queue.add(message);
        }
        break;
    }
  }
}
