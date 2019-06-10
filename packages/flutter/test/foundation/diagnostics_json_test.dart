// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Element diagnostics json includes widgetRuntimeType', () async {
    final Element element = _TestElement();

    final Map<String, Object> json = element.toDiagnosticsNode().toJsonMap(DiagnosticsSerialisationDelegate());
    expect(json['widgetRuntimeType'], 'Placeholder');
    expect(json['stateful'], isFalse);
  });

  test('StatefulElement diganostics are stateful', () {
    final Element element = StatefulElement(const Tooltip(message: 'foo'));

    final Map<String, Object> json = element.toDiagnosticsNode().toJsonMap(DiagnosticsSerialisationDelegate());
    expect(json['widgetRuntimeType'], 'Tooltip');
    expect(json['stateful'], isTrue);
  });
}

class _TestElement extends Element {
  _TestElement() : super(const Placeholder());

  @override
  void forgetChild(Element child) {
    // Intentionally left empty.
  }

  @override
  void performRebuild() {
    // Intentionally left empty.
  }
}
