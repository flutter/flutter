import 'dart:async';
import 'package:flutter/foundation.dart' show ValueGetter;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http;

import '../../../packages/flutter/test/painting/image_data.dart';

// Returns a mock HTTP client that responds with an image to all requests.
ValueGetter<http.Client> createMockImageHttpClient = () {
  return new http.MockClient((http.BaseRequest request) {
    return new Future<http.Response>.value(
      new http.Response.bytes(kTransparentImage, 200, request: request)
    );
  });
};
