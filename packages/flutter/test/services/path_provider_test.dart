// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:test/test.dart';

void main() {
  test('Path provider control test', () async {
    List<String> log = <String>[];
    String response;

    PlatformMessages.setMockStringMessageHandler('flutter/platform', (String message) async {
      log.add(message);
      return response;
    });

    Directory directory = await PathProvider.getTemporaryDirectory();

    expect(log, equals(<String>['{"method":"PathProvider.getTemporaryDirectory","args":[]}']));
    expect(directory, isNull);
    log.clear();

    directory = await PathProvider.getApplicationDocumentsDirectory();

    expect(log, equals(<String>['{"method":"PathProvider.getApplicationDocumentsDirectory","args":[]}']));
    expect(directory, isNull);

    String fakePath = "/foo/bar/baz";
    response = '{"path":"$fakePath"}';

    directory = await PathProvider.getTemporaryDirectory();
    expect(directory.path, equals(fakePath));

    directory = await PathProvider.getApplicationDocumentsDirectory();
    expect(directory.path, equals(fakePath));
  });
}
