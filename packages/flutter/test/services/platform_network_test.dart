// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const Symbol _symbol = #dart.library.io.allow_http;

  test('AllowHTTP sets the correct zone variable', () async {
    expect(Zone.current[_symbol], isNull);
    allowHttp(() {
      expect(Zone.current[_symbol], isTrue);
    });
  });

  // This test ensures the zone variable used in Dart SDK does not change.
  //
  // If this symbol changes, then update [allowHttp] function as well.
  test('Zone variable can override HTTP behavior', () async {
    final HttpClient httpClient = HttpClient();
    try {
      await runZoned(
        () async => await httpClient.getUrl(Uri.parse('http://${Platform.localHostname}')),
        zoneValues: <Symbol, bool>{_symbol: false},
      );
      fail('This should have thrown a StateError. '
           'Check if the symbol for setting allow_http behavior has changed');
    } on StateError catch(e) {
      expect(e.message, contains('Insecure HTTP is not allowed by the current platform'));
    }
  });
}
