// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ResolveRelativeUriTest);
  });
}

@reflectiveTest
class ResolveRelativeUriTest {
  void test_absolute() {
    _validate('dart:core', 'dart:async', 'dart:async');
    _validate('package:foo/foo.dart', 'dart:async', 'dart:async');
    _validate('package:a/a.dart', 'package:b/b.dart', 'package:b/b.dart');
    _validate('foo.dart', 'dart:async', 'dart:async');
  }

  void test_absoluteDart_relative() {
    _validate('dart:core', 'int.dart', 'dart:core/int.dart');
  }

  void test_absolutePackage_relative() {
    _validate('package:a/b.dart', 'c.dart', 'package:a/c.dart');
    _validate('package:a/b/c.dart', 'd.dart', 'package:a/b/d.dart');
    _validate('package:a/b/c.dart', '../d.dart', 'package:a/d.dart');
  }

  void test_relative_relative() {
    _validate('a/b.dart', 'c.dart', 'a/c.dart');
    _validate('a/b.dart', '../c.dart', 'c.dart');
    _validate('a.dart', '../b.dart', '../b.dart');
    _validate('a.dart', '../../b.dart', '../../b.dart');
    _validate('a/b.dart', '../../c.dart', '../c.dart');
  }

  void _validate(String base, String contained, String expected) {
    Uri actual = resolveRelativeUri(Uri.parse(base), Uri.parse(contained));
    expect(actual.toString(), expected);
  }
}
