// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../flutter_test_alternative.dart' show Fake;
import '../image_data.dart';

void main() {
  late MockHttpClient client;

  setUp(() {
    client = MockHttpClient();
    MockHttpHeaders.headers.clear();
  });

  testWidgets('Headers', (WidgetTester tester) async {
    HttpOverrides.runZoned<Future<void>>(() async {
      await tester.pumpWidget(Image.network(
        'https://www.example.com/images/frame.png',
        headers: const <String, String>{'flutter': 'flutter'},
      ));

      expect(MockHttpHeaders.headers['flutter'], <String>['flutter']);

    }, createHttpClient: (SecurityContext? _) {
      return client;
    });
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/57187

  testWidgets('Header Resolver', (WidgetTester tester) async {
    HttpOverrides.runZoned<Future<void>>(() async {
      await tester.pumpWidget(Image.network(
        'https://www.example.com/images/frame2.png',
        headers: const <String, String>{
          'flutter': 'flutter',
          'Accept-Language': 'en-US',
        },
        headerResolver: () async => const <String, String>{
          'flutter': 'async flutter',
          'Accept-Language': 'de-DE',
        },
      ));

      expect(MockHttpHeaders.headers['flutter'], <String>['flutter', 'async flutter']);
      expect(MockHttpHeaders.headers['Accept-Language'], <String>['en-US', 'de-DE']);

    }, createHttpClient: (SecurityContext? _) {
      return client;
    });
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/57187

  testWidgets('Throwing Header Resolver', (WidgetTester tester) async {
    HttpOverrides.runZoned<Future<void>>(() async {
      Object? imageError;
      await tester.pumpWidget(Image.network(
        'https://www.example.com/images/frame3.png',
        headerResolver: () async => throw StateError('Something went wrong'),
        errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
          imageError = error;
          return const SizedBox();
        },
      ));

      await tester.pump();

      expect(imageError, isStateError
        .having((StateError error) => error.message, 'message', 'Something went wrong'));

    }, createHttpClient: (SecurityContext? _) {
      return client;
    });
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/57187
}

class MockHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return MockHttpClientRequest();
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
  static final Map<String, List<String>> headers = <String, List<String>>{};

  @override
  void add(String key, Object value, { bool preserveHeaderCase = false }) {
    headers[key] ??= <String>[];
    headers[key]!.add(value.toString());
  }
}
