// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:mojo/core.dart';
import 'package:mojo_services/tracing/tracing.mojom.dart';

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

  TraceProviderImpl() {
    _message_queue = [];
    _enqueuing = true;
    new Future(() {
      new Future.delayed(const Duration(seconds: 1), () {
      _enqueuing = false;
      _message_queue.clear();
      });
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

    for (String message in _message_queue) {
      _recorder.ptr.record(message);
    }
    _enqueuing = false;
    _message_queue.clear();
  }

  @override
  void stopTracing() {
    assert(_recorder != null);
    _recorder.close();
    _recorder = null;
  }

  bool isActive() {
    return _enqueuing || _recorder != null;
  }

  void sendTraceMessage(String message) {
    if (_recorder != null) {
      _recorder.ptr.record(message);
    } else if (_enqueuing) {
      _message_queue.add(message);
    }
  }
}
