// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'project.dart';

class ProjectWithImmediateExit extends Project {

  @override
  final String pubspec = '''
  name: test
  environment:
    sdk: ">=2.12.0-0 <3.0.0"

  dependencies:
    flutter:
      sdk: flutter
  ''';

  @override
  final String main = r'''
  import 'dart:async';
  import 'dart:io';

  Future<void> main() async {
    await Future.delayed(const Duration(milliseconds: 50));
    exit(0);
  }
  ''';

}
