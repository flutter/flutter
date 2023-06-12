// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ResourceUriResolverTest);
  });
}

@reflectiveTest
class ResourceUriResolverTest with ResourceProviderMixin {
  late final ResourceUriResolver resolver;

  void setUp() {
    resolver = ResourceUriResolver(resourceProvider);
    newFile('/test.dart', '');
    newFolder('/folder');
  }

  void test_creation() {
    expect(resourceProvider, isNotNull);
    expect(resolver, isNotNull);
  }

  void test_pathToUri() {
    var path = convertPath('/test.dart');
    var uri = toUri(path);
    expect(resolver.pathToUri(path), uri);
  }

  void test_resolveAbsolute_file() {
    var uri = toUri('/test.dart');

    var source = resolver.resolveAbsolute(uri)!;
    expect(source.exists(), isTrue);
    expect(source.fullName, convertPath('/test.dart'));
  }

  void test_resolveAbsolute_folder() {
    var uri = toUri('/folder');

    var source = resolver.resolveAbsolute(uri)!;
    expect(source.exists(), isFalse);
    expect(source.fullName, convertPath('/folder'));
  }

  void test_resolveAbsolute_notFile_dartUri() {
    var uri = Uri(scheme: 'dart', path: 'core');

    var source = resolver.resolveAbsolute(uri);
    expect(source, isNull);
  }

  void test_resolveAbsolute_notFile_httpsUri() {
    var uri = Uri(scheme: 'https', path: '127.0.0.1/test.dart');

    var source = resolver.resolveAbsolute(uri);
    expect(source, isNull);
  }
}
