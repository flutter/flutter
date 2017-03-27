// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:test/test.dart';

void main() {
  test('Path provider control test', () async {
    final List<MethodCall> log = <MethodCall>[];
    String response;

    SystemChannels.platform.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);
      return response;
    });

    Directory directory = await PathProvider.getTemporaryDirectory();

    expect(log, equals(<MethodCall>[new MethodCall('PathProvider.getTemporaryDirectory')]));
    expect(directory, isNull);
    log.clear();

    directory = await PathProvider.getApplicationDocumentsDirectory();

    expect(log, equals(<MethodCall>[new MethodCall('PathProvider.getApplicationDocumentsDirectory')]));
    expect(directory, isNull);

    final String fakePath = "/foo/bar/baz";
    response = fakePath;

    directory = await PathProvider.getTemporaryDirectory();
    expect(directory.path, equals(fakePath));

    directory = await PathProvider.getApplicationDocumentsDirectory();
    expect(directory.path, equals(fakePath));
  });
}
