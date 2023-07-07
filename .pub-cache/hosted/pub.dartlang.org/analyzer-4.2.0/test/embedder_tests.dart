// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';

import 'resource_utils.dart';

abstract class EmbedderRelatedTest {
  final String emptyPath = '/home/.pub-cache/empty';
  final String foxPath = '/home/.pub-cache/fox';
  final String foxLib = '/home/.pub-cache/fox/lib';

  late final TestPathTranslator pathTranslator;
  late final ResourceProvider resourceProvider;

  buildResourceProvider() {
    MemoryResourceProvider rawProvider = MemoryResourceProvider();
    resourceProvider = TestResourceProvider(rawProvider);
    pathTranslator = TestPathTranslator(rawProvider)
      ..newFolder('/home/.pub-cache/empty')
      ..newFolder('/home/.pub-cache/fox/lib')
      ..newFile('/home/.pub-cache/fox/lib/_embedder.yaml', r'''
embedded_libs:
  "dart:deep": "deep/directory/file.dart"
  "dart:core" : "core/core.dart"
  "dart:fox": "slippy.dart"
  "dart:bear": "grizzly.dart"
  "dart:relative": "../relative.dart"
  "fart:loudly": "nomatter.dart"
''');
  }

  void setUp() {
    buildResourceProvider();
  }
}
