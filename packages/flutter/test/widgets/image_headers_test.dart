// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../image_data.dart';

void main() {
  testWidgets('Headers', (WidgetTester tester) async {
    final MockHttpClient client = MockHttpClient();
    debugNetworkImageHttpClientProvider = () {
      return client;
    };

    await tester.runAsync(() async {
      const NetworkImage image = NetworkImage(
        'https://www.example.com/images/frame.png',
        headers: <String, String>{'flutter': 'flutter'},
      );
      final Completer<bool> completer = Completer<bool>();
      image.resolve(ImageConfiguration.empty).addListener(ImageStreamListener((ImageInfo image, bool synchronousCall) {
        completer.complete(true);
      }));
      await completer.future;
    });

    final MockHttpClient lastClient = debugLastHttpClientUsed! as MockHttpClient;
    expect(lastClient.request.headers.headers['flutter'], <String>['flutter']);
    debugNetworkImageHttpClientProvider = null;
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/57187
}

class MockHttpClient extends Fake implements HttpClient {
  final MockHttpClientRequest request = MockHttpClientRequest();

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return request;
  }

  @override
  bool autoUncompress = false;
}

class MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final MockHttpHeaders headers = MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async {
    return MockHttpClientResponse();
  }
}

class MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get contentLength => kTransparentImage.length;

  @override
  int get statusCode => HttpStatus.ok;

  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.decompressed;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData, {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream<List<int>>.fromIterable(<List<int>>[kTransparentImage]).listen(
      onData,
      onDone: onDone,
      onError: onError,
      cancelOnError: cancelOnError,
    );
  }
}

class MockHttpHeaders extends Fake implements HttpHeaders {
  final Map<String, List<String>> headers = <String, List<String>>{};

  @override
  void add(String key, Object value, { bool preserveHeaderCase = false }) {
    headers[key] ??= <String>[];
    headers[key]!.add(value.toString());
  }
}
