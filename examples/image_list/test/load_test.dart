import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_list/main.dart';
import 'package:mockito/mockito.dart';

class MockHttpClient extends Mock implements HttpClient {}
class MockHttpClientRequest extends Mock implements HttpClientRequest {}
class MockHttpClientResponse extends Mock implements HttpClientResponse {}

Uint8List bytes;
HttpClient sampleHttpProvider() {
  final HttpClient httpClient = MockHttpClient();
  final List<Uint8List> chunks = <Uint8List> [bytes];
  final MockHttpClientRequest request = MockHttpClientRequest();
  final MockHttpClientResponse response = MockHttpClientResponse();
  when(httpClient.getUrl(any)).thenAnswer((_) => Future<HttpClientRequest>.value(request));
  when(request.close()).thenAnswer((_) => Future<HttpClientResponse>.value(response));
  when(response.statusCode).thenReturn(HttpStatus.ok);
  when(response.contentLength).thenReturn(bytes.length);
  when(response.listen(
    any,
    onDone: anyNamed('onDone'),
    onError: anyNamed('onError'),
    cancelOnError: anyNamed('cancelOnError'),
  )).thenAnswer((Invocation invocation) {
    final void Function(List<int>) onData = invocation.positionalArguments[0];
    final void Function(Object) onError = invocation.namedArguments[#onError];
    final void Function() onDone = invocation.namedArguments[#onDone];
    final bool cancelOnError = invocation.namedArguments[#cancelOnError];

    return Stream<Uint8List>.fromIterable(chunks).listen(
      onData,
      onDone: onDone,
      onError: onError,
      cancelOnError: cancelOnError,
    );
  });

  return httpClient;
}

void main() async {
  group(NetworkImage, ()
  {
    setUpAll(() async {
      final Uint8List byteData = (await rootBundle.load('images/coast.jpg')).buffer.asUint8List();
      bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
    });

    testWidgets('Ensure images are loaded', (WidgetTester tester) async {
      debugNetworkImageHttpClientProvider = sampleHttpProvider;

      await tester.pumpWidget(MyApp(0));

      final Finder allImages = find.byType(Image);
      expect(allImages, findsNWidgets(50));

      for (Element e in allImages.evaluate()) {
        await tester.runAsync(() async =>
            await precacheImage((e.widget as Image).image, e));
      }

      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MyHomePage),
        matchesGoldenFile(
          'load.widgets_loaded.done.png',
          version: 0,
        ),
      );

      debugNetworkImageHttpClientProvider = null;
    });
  });
}