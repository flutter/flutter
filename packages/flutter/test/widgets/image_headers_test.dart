// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import '../painting/image_data.dart';

void main() {
  testWidgets('Headers', (WidgetTester tester) async {
    HttpOverrides.runZoned(() async {
      await tester.pumpWidget(new Image.network(
        'https://www.example.com/images/frame.png',
        headers: const <String, String>{'flutter': 'flutter'},
      ));

    }, createHttpClient: (SecurityContext _) {
      final MockHttpClient client = new MockHttpClient();
      final MockHttpClientRequest request = new MockHttpClientRequest();
      final MockHttpClientResponse response = new MockHttpClientResponse(kTransparentImage);
      final MockHttpHeaders headers = new MockHttpHeaders();

      when(request.headers).thenReturn(headers);
      when(request.close()).thenReturn(new Future<HttpClientResponse>.value(response));
      when(response.statusCode).thenReturn(200);
      when(response.contentLength).thenReturn(kTransparentImage.length);
      when(client.getUrl(Uri.parse('https://www.example.com/images/frame.png'))).thenReturn(new Future<HttpClientRequest>.value(request));

      return client;
    });
  });
}

class MockHttpClient extends Mock implements HttpClient {}

class MockHttpClientRequest extends Mock implements HttpClientRequest {}

class MockHttpHeaders extends Mock implements HttpHeaders {}

class MockHttpClientResponse extends Mock implements HttpClientResponse {
  MockHttpClientResponse(this.bytes);

  final List<int> bytes;

  @override
  StreamSubscription<List<int>> listen(void onData(List<int> event),
      {Function onError, void onDone(), bool cancelOnError}) {
    return new Stream<List<int>>.fromIterable(<List<int>>[bytes]).listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}