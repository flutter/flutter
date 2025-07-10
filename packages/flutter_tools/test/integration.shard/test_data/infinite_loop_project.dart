// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'project.dart';

// Reproduction case from
// https://github.com/flutter/flutter/issues/161466#issuecomment-2743309718.
class InfiniteLoopProject extends Project {
  @override
  final String pubspec = '''
  name: test
  environment:
    sdk: ^3.7.0-0

  dependencies:
    flutter:
      sdk: flutter
  ''';

  @override
  final String main = r'''
  import 'dart:async';
  import 'dart:developer';
  import 'dart:isolate';

  import 'package:flutter/material.dart';

  void main() {
    runApp(
      Builder(builder: (context) {
        while (true) {
          // Loop forever.
        }
      }),
    );
  }
  ''';
}
