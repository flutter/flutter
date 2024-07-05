// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<void> main() async {
  final StringBuffer output = StringBuffer();
  const String combined = String.fromEnvironment('test.valueA') +
    String.fromEnvironment('test.valueB');
  if (combined == 'Example,AValue') {
    output.write('--- TEST SUCCEEDED ---');
    print('--- TEST SUCCEEDED ---');
  } else {
    output.write('--- TEST FAILED ---');
    print('--- TEST FAILED ---');
  }

  web.window.fetch(
    '/test-result'.toJS,
    web.RequestInit(
      method: 'POST',
      body: '$output'.toJS,
    )
  );
}
