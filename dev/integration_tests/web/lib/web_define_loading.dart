// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;

Future<void> main() async {
  final StringBuffer output = StringBuffer();
  const String combined = String.fromEnvironment('test.valueA') +
    String.fromEnvironment('test.valueB');
  if (combined == 'ExampleValue') {
    output.write('--- TEST SUCCEEDED ---');
    print('--- TEST SUCCEEDED ---');
  } else {
    output.write('--- TEST FAILED ---');
    print('--- TEST FAILED ---');
  }

  html.HttpRequest.request(
    '/test-result',
    method: 'POST',
    sendData: '$output',
  );
}
