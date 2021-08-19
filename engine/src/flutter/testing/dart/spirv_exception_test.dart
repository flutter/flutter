// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:litetest/litetest.dart';
import 'package:path/path.dart' as path;
import 'package:spirv/spirv.dart' as spirv;

const List<spirv.TargetLanguage> targets = <spirv.TargetLanguage>[
  spirv.TargetLanguage.sksl,
  spirv.TargetLanguage.glslES,
  spirv.TargetLanguage.glslES300,
];

void main() {
  test('spirv transpiler throws exceptions', () async {
    int count = 0;
    await for (final Uint8List shader in exceptionShaders()) {
      for (final spirv.TargetLanguage target in targets) {
        expect(() => spirv.transpile(shader.buffer, target), throwsException);
      }
      count++;
    }
    // If the SPIR-V assembly step silently fails, make sure this test fails
    // too.
    expect(count, greaterThan(0));
  });
}

Stream<Uint8List> exceptionShaders() async* {
  final Directory dir = Directory(path.joinAll(<String>[
    'out',
    'host_debug_unopt',
    'gen',
    'flutter',
    'lib',
    'spirv',
    'test',
    'exception_shaders',
  ]));
  await for (final FileSystemEntity entry in dir.list()) {
    if (entry is! File) {
      continue;
    }
    final File file = entry;
    if (path.extension(file.path) != '.spv') {
      continue;
    }
    yield file.readAsBytesSync();
  }
}
