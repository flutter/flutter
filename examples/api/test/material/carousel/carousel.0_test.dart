// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/carousel/carousel.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Carousel Smoke Test', (WidgetTester tester) async {
    HttpOverrides.runZoned<Future<void>>(() async {
      await tester.pumpWidget(
        const example.CarouselExampleApp(),
      );

      expect(find.widgetWithText(example.HeroLayoutCard, 'Through the Pane'), findsOneWidget);
      final Finder firstCarousel = find.byType(CarouselView).first;
      await tester.drag(firstCarousel, const Offset(150, 0));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(example.HeroLayoutCard, 'The Flow'), findsOneWidget);

      await tester.drag(firstCarousel, const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(CarouselView, 'Cameras'), findsOneWidget);
      expect(find.widgetWithText(CarouselView, 'Lighting'), findsOneWidget);
      expect(find.widgetWithText(CarouselView, 'Climate'), findsOneWidget);
      expect(find.widgetWithText(CarouselView, 'Wifi'), findsOneWidget);

      await tester.drag(find.widgetWithText(CarouselView, 'Cameras'), const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(find.text('Uncontained layout'), findsOneWidget);
      expect(find.widgetWithText(CarouselView, 'Show 0'), findsOneWidget);
      expect(find.widgetWithText(CarouselView, 'Show 1'), findsOneWidget);
    }, createHttpClient: createMockImageHttpClient);
  });
}

// Returns a mock HTTP client that responds with an image to all requests.
FakeHttpClient createMockImageHttpClient(SecurityContext? _) {
  final FakeHttpClient client = FakeHttpClient();
  return client;
}

class FakeHttpClient extends Fake implements HttpClient {
  FakeHttpClient([this.context]);

  SecurityContext? context;

  @override
  bool autoUncompress = false;

  final FakeHttpClientRequest request = FakeHttpClientRequest();

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return request;
  }
}

class FakeHttpClientRequest extends Fake implements HttpClientRequest {
  final FakeHttpClientResponse response = FakeHttpClientResponse();

  @override
  Future<HttpClientResponse> close() async {
    return response;
  }
}

class FakeHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => kTransparentImage.length;

  @override
  final FakeHttpHeaders headers = FakeHttpHeaders();

  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int>)? onData, {
    void Function()? onDone,
    Function? onError,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable(<List<int>>[kTransparentImage])
      .listen(onData, onDone: onDone, onError: onError, cancelOnError: cancelOnError);
  }

  static const List<int> kTransparentImage = <int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
    0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
    0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x06, 0x62, 0x4B,
    0x47, 0x44, 0x00, 0xFF, 0x00, 0xFF, 0x00, 0xFF, 0xA0, 0xBD, 0xA7, 0x93, 0x00,
    0x00, 0x00, 0x09, 0x70, 0x48, 0x59, 0x73, 0x00, 0x00, 0x0B, 0x13, 0x00, 0x00,
    0x0B, 0x13, 0x01, 0x00, 0x9A, 0x9C, 0x18, 0x00, 0x00, 0x00, 0x07, 0x74, 0x49,
    0x4D, 0x45, 0x07, 0xE6, 0x03, 0x10, 0x17, 0x07, 0x1D, 0x2E, 0x5E, 0x30, 0x9B,
    0x00, 0x00, 0x00, 0x0B, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0x60, 0x00,
    0x02, 0x00, 0x00, 0x05, 0x00, 0x01, 0xE2, 0x26, 0x05, 0x9B, 0x00, 0x00, 0x00,
    0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ];
}

class FakeHttpHeaders extends Fake implements HttpHeaders { }
