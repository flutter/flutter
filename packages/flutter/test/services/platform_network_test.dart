// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  // This test ensures the zone variable used in Dart SDK does not change.
  //
  // If this symbol changes, then update [allowHttp] function as well.
  test('Zone variable can override HTTP behavior', () async {
    final httpClient = new HttpClient();
    expect(() => runZoned(
        () async => await httpClient.getUrl(Uri.parse('http://${Platform.localHostname}')),
        zoneValues: {#dart.library.io.allow_http: false}), throwsA(isA<StateError>()));
  });
}
