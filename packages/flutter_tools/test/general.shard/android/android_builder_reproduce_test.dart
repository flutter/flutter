// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/android/gradle.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:test/test.dart';

import '../../src/context.dart';

void main() {
  testUsingContext('AndroidGradleBuilder is registered in AppContext', () {
    expect(context.get<AndroidGradleBuilder>(), isNotNull);
  });
}
