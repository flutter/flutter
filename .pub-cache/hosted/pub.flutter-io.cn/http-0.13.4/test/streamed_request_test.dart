// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('contentLength', () {
    test('defaults to null', () {
      var request = http.StreamedRequest('POST', dummyUrl);
      expect(request.contentLength, isNull);
    });

    test('disallows negative values', () {
      var request = http.StreamedRequest('POST', dummyUrl);
      expect(() => request.contentLength = -1, throwsArgumentError);
    });

    test('is frozen by finalize()', () {
      var request = http.StreamedRequest('POST', dummyUrl)..finalize();
      expect(() => request.contentLength = 10, throwsStateError);
    });
  });
  group('#method', () {
    test('must be a token', () {
      expect(() => http.StreamedRequest('SUPER LLAMA', dummyUrl),
          throwsArgumentError);
    });
  });
}
