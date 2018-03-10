import 'dart:async';
import 'dart:io';
import 'package:mockito/mockito.dart';

import '../../../packages/flutter/test/painting/image_data.dart';

// Returns a mock HTTP client that responds with an image to all requests.
HttpClient createMockImageHttpClient(SecurityContext context) {
  final MockHttpClient client = new MockHttpClient();
  final MockHttpClientRequest request = new MockHttpClientRequest();
  final MockHttpClientResponse response = new MockHttpClientResponse(kTransparentImage);
  final MockHttpHeaders headers = new MockHttpHeaders();

  when(request.headers).thenReturn(headers);
  when(request.close()).thenReturn(new Future<HttpClientResponse>.value(response));
  when(response.statusCode).thenReturn(200);
  when(response.contentLength).thenReturn(kTransparentImage.length);
  when(client.getUrl(typed(any))).thenReturn(request);

  return client;
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
