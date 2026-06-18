// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:flutter_devicelab/framework/fs_safety.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart' as test_package show test;
import 'package:test/test.dart' hide test;

export 'package:test/test.dart' hide isInstanceOf, test;

/// A matcher that compares the type of the actual value to the type argument T.
TypeMatcher<T> isInstanceOf<T>() => isA<T>();

@isTest
void test(
  String description,
  FutureOr<void> Function() body, {
  String? testOn,
  Timeout? timeout,
  dynamic skip,
  List<String>? tags,
  Map<String, dynamic>? onPlatform,
  int? retry,
}) {
  test_package.test(
    description,
    () async {
      return io.IOOverrides.runWithIOOverrides(() => body(), FSGuardIOOverrides());
    },
    skip: skip,
    tags: tags,
    onPlatform: onPlatform,
    retry: retry,
    testOn: testOn,
    timeout: timeout,
  );
}
