// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http;
import 'package:flutter/services.dart' show createHttpClient;

import '../painting/image_data.dart';

void main() {
  testWidgets('Headers', (WidgetTester tester) async {
    createHttpClient = () => new http.MockClient((http.BaseRequest request) {
          expect(request.headers, <String, String>{'flutter': 'flutter'});
          return new Future<http.Response>.value(new http.Response.bytes(
              kTransparentImage, 200,
              request: request));
        });
    await tester.pumpWidget(new Image.network(
      'https://www.example.com/images/frame.png',
      headers: const <String, String>{'flutter': 'flutter'},
    ));
  });
}
