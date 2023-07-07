// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
library usage.web_test;

import 'dart:async';
import 'dart:html';

import 'package:test/test.dart';
import 'package:usage/src/usage_impl_html.dart';

import 'hit_types_test.dart' as hit_types_test;
import 'usage_impl_test.dart' as usage_impl_test;
import 'usage_test.dart' as usage_test;
import 'uuid_test.dart' as uuid_test;

void main() {
  // Define the tests.
  hit_types_test.defineTests();
  usage_test.defineTests();
  usage_impl_test.defineTests();
  uuid_test.defineTests();

  // Define some web specific tests.
  defineWebTests();
}

void defineWebTests() {
  group('HtmlPostHandler', () {
    test('sendPost', () async {
      var client = MockRequestor();
      var postHandler = HtmlPostHandler(mockRequestor: client.request);
      var args = [
        <String, String>{'utv': 'varName', 'utt': '123'},
      ];

      await postHandler.sendPost(
          'http://www.google.com', args.map(postHandler.encodeHit).toList());
      expect(client.sendCount, 1);
    });
  });

  group('HtmlPersistentProperties', () {
    test('add', () {
      var props = HtmlPersistentProperties('foo_props');
      props['foo'] = 'bar';
      expect(props['foo'], 'bar');
    });

    test('remove', () {
      var props = HtmlPersistentProperties('foo_props');
      props['foo'] = 'bar';
      expect(props['foo'], 'bar');
      props['foo'] = null;
      expect(props['foo'], null);
    });
  });
}

class MockRequestor {
  int sendCount = 0;

  Future<HttpRequest> request(String url, {String? method, sendData}) {
    expect(url, isNotEmpty);
    expect(method, isNotEmpty);
    expect(sendData, isNotEmpty);

    sendCount++;
    return Future.value(HttpRequest());
  }
}
