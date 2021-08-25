import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/src/painting/_network_image_web.dart';
import 'package:flutter_test/flutter_test.dart';

void runTests() {
  tearDown(() {
    debugRestoreHttpRequestFactory();
  });

  test('loads an image from the network', () async {
    // TODO: Mock HttpRequest
    // httpRequestFactory = () {};
  });
}
