// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('IconDataDiagnosticsProperty includes valueProperties in JSON', () {
    IconDataDiagnosticsProperty property = IconDataDiagnosticsProperty('foo', const IconData(101010));
    final Map<String, Object> valueProperties = property.toJsonMap(const DiagnosticsSerialisationDelegate())['valueProperties'];
    print(valueProperties);
    expect(valueProperties['codePoint'], 101010);

    property = IconDataDiagnosticsProperty('foo', null);
    final Map<String, Object> json = property.toJsonMap(const DiagnosticsSerialisationDelegate());
    expect(json.containsKey('valueProperties'), isFalse);
  });
}
