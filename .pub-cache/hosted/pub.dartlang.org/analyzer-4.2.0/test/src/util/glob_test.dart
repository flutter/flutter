// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/util/glob.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GlobPosixTest);
    defineReflectiveTests(GlobWindowsTest);
  });
}

@reflectiveTest
class GlobPosixTest {
  void test_case() {
    Glob glob = Glob(r'\', r'**.DaRt');
    expect(glob.matches(r'aaa.dart'), isTrue);
    expect(glob.matches(r'bbb.DART'), isTrue);
    expect(glob.matches(r'ccc.dArT'), isTrue);
    expect(glob.matches(r'ddd.DaRt'), isTrue);
  }

  void test_question() {
    Glob glob = Glob(r'/', r'?.dart');
    expect(glob.matches(r'a.dart'), isTrue);
    expect(glob.matches(r'b.dart'), isTrue);
    expect(glob.matches(r'cc.dart'), isFalse);
  }

  void test_specialChars() {
    Glob glob = Glob(r'/', r'*.dart');
    expect(glob.matches(r'a.dart'), isTrue);
    expect(glob.matches('_-a.dart'), isTrue);
    expect(glob.matches(r'^$*?.dart'), isTrue);
    expect(glob.matches(r'()[]{}.dart'), isTrue);
    expect(glob.matches('\u2665.dart'), isTrue);
  }

  void test_specialChars2() {
    Glob glob = Glob(r'/', r'a[]b.dart');
    expect(glob.matches(r'a[]b.dart'), isTrue);
    expect(glob.matches(r'aNb.dart'), isFalse);
  }

  void test_star() {
    Glob glob = Glob(r'/', r'web/*.dart');
    expect(glob.matches(r'web/foo.dart'), isTrue);
    expect(glob.matches(r'web/barbaz.dart'), isTrue);
    // does not end with 'dart'
    expect(glob.matches(r'web/foo.html'), isFalse);
    // not in 'web'
    expect(glob.matches(r'lib/foo.dart'), isFalse);
    expect(glob.matches(r'/web/foo.dart'), isFalse);
    // in sub-folder
    expect(glob.matches(r'web/sub/foo.dart'), isFalse);
  }

  void test_starStar() {
    Glob glob = Glob(r'/', r'**.dart');
    expect(glob.matches(r'foo/bar.dart'), isTrue);
    expect(glob.matches(r'foo/bar/baz.dart'), isTrue);
    expect(glob.matches(r'/foo/bar.dart'), isTrue);
    expect(glob.matches(r'/foo/bar/baz.dart'), isTrue);
    // does not end with 'dart'
    expect(glob.matches(r'/web/foo.html'), isFalse);
  }

  void test_starStar_star() {
    Glob glob = Glob(r'/', r'**/*.dart');
    expect(glob.matches(r'foo/bar.dart'), isTrue);
    expect(glob.matches(r'foo/bar/baz.dart'), isTrue);
    expect(glob.matches(r'/foo/bar.dart'), isTrue);
    expect(glob.matches(r'/foo/bar/baz.dart'), isTrue);
    // does not end with 'dart'
    expect(glob.matches(r'/web/foo.html'), isFalse);
  }
}

@reflectiveTest
class GlobWindowsTest {
  void test_case() {
    Glob glob = Glob(r'\', r'**.dart');
    expect(glob.matches(r'aaa.dart'), isTrue);
    expect(glob.matches(r'bbb.DART'), isTrue);
    expect(glob.matches(r'ccc.dArT'), isTrue);
    expect(glob.matches(r'ddd.DaRt'), isTrue);
  }

  void test_question() {
    Glob glob = Glob(r'\', r'?.dart');
    expect(glob.matches(r'a.dart'), isTrue);
    expect(glob.matches(r'b.dart'), isTrue);
    expect(glob.matches(r'cc.dart'), isFalse);
  }

  void test_specialChars() {
    Glob glob = Glob(r'\', r'*.dart');
    expect(glob.matches(r'a.dart'), isTrue);
    expect(glob.matches('_-a.dart'), isTrue);
    expect(glob.matches(r'^$*?.dart'), isTrue);
    expect(glob.matches(r'()[]{}.dart'), isTrue);
    expect(glob.matches('\u2665.dart'), isTrue);
  }

  void test_star() {
    Glob glob = Glob(r'\', r'web/*.dart');
    expect(glob.matches(r'web\foo.dart'), isTrue);
    expect(glob.matches(r'web\barbaz.dart'), isTrue);
    // does not end with 'dart'
    expect(glob.matches(r'web\foo.html'), isFalse);
    // not in 'web'
    expect(glob.matches(r'lib\foo.dart'), isFalse);
    expect(glob.matches(r'\web\foo.dart'), isFalse);
    // in sub-folder
    expect(glob.matches(r'web\sub\foo.dart'), isFalse);
  }

  void test_starStar() {
    Glob glob = Glob(r'\', r'**.dart');
    expect(glob.matches(r'foo\bar.dart'), isTrue);
    expect(glob.matches(r'foo\bar\baz.dart'), isTrue);
    expect(glob.matches(r'C:\foo\bar.dart'), isTrue);
    expect(glob.matches(r'C:\foo\bar\baz.dart'), isTrue);
    // does not end with 'dart'
    expect(glob.matches(r'C:\web\foo.html'), isFalse);
  }
}
