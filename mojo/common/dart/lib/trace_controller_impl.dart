// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:mojo/application.dart';
import 'package:mojo/bindings.dart';
import 'package:mojo/core.dart';
import 'package:mojom/tracing/tracing.mojom.dart';

class TraceControllerImpl implements TraceController {
  TraceControllerStub _stub;
  TraceDataCollectorProxy _collector;
  // TODO(rudominer) We currently ignore _categories.
  String _categories;

  TraceControllerImpl.fromEndpoint(MojoMessagePipeEndpoint e) {
    _stub = TraceControllerStub.newFromEndpoint(e);
    _stub.impl = this;
  }

  @override
  void startTracing(String categories, TraceDataCollectorProxy collector) {
    assert(_collector == null);
    _collector = collector;
    _categories = categories;
  }

  @override
  void stopTracing() {
    assert(_collector != null);
    _collector.close();
    _collector = null;
  }

  bool isActive() {
    return _collector != null;
  }

  void sendTraceMessage(String message) {
    if (_collector != null) {
      _collector.ptr.dataCollected(message);
    }
  }
}
