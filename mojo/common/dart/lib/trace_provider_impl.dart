// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:mojo/application.dart';
import 'package:mojo/bindings.dart';
import 'package:mojo/core.dart';
import 'package:mojo_services/tracing/tracing.mojom.dart';

class TraceProviderImpl implements TraceProvider {
  TraceProviderStub _stub;
  TraceRecorderProxy _recorder;
  // TODO(rudominer) We currently ignore _categories.
  String _categories;

  TraceProviderImpl.fromEndpoint(MojoMessagePipeEndpoint e) {
    _stub = TraceProviderStub.newFromEndpoint(e);
    _stub.impl = this;
  }

  @override
  void startTracing(String categories, TraceRecorderProxy recorder) {
    assert(_recorder == null);
    _recorder = recorder;
    _categories = categories;
  }

  @override
  void stopTracing() {
    assert(_recorder != null);
    _recorder.close();
    _recorder = null;
  }

  bool isActive() {
    return _recorder != null;
  }

  void sendTraceMessage(String message) {
    if (_recorder != null) {
      _recorder.ptr.record(message);
    }
  }
}
