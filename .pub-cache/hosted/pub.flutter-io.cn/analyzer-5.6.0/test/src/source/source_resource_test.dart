// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/java_engine_io.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/source/source_resource.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FileSourceTest);
  });
}

@reflectiveTest
class FileSourceTest with ResourceProviderMixin {
  void test_equals_false_differentFiles() {
    File file1 = getFile("/does/not/exist1.dart");
    File file2 = getFile("/does/not/exist2.dart");
    FileSource source1 = FileSource(file1);
    FileSource source2 = FileSource(file2);
    expect(source1 == source2, isFalse);
  }

  void test_equals_false_null() {
    File file = getFile("/does/not/exist1.dart");
    FileSource source1 = FileSource(file);
    expect(source1, isNotNull);
  }

  void test_equals_true() {
    File file1 = getFile("/does/not/exist.dart");
    File file2 = getFile("/does/not/exist.dart");
    FileSource source1 = FileSource(file1);
    FileSource source2 = FileSource(file2);
    expect(source1 == source2, isTrue);
  }

  void test_fileReadMode() {
    expect(FileSource.fileReadMode('a'), 'a');
    expect(FileSource.fileReadMode('a\n'), 'a\n');
    expect(FileSource.fileReadMode('ab'), 'ab');
    expect(FileSource.fileReadMode('abc'), 'abc');
    expect(FileSource.fileReadMode('a\nb'), 'a\nb');
    expect(FileSource.fileReadMode('a\rb'), 'a\rb');
    expect(FileSource.fileReadMode('a\r\nb'), 'a\r\nb');
  }

  void test_fileReadMode_changed() {
    FileSource.fileReadMode = (String s) => '${s}xyz';
    expect(FileSource.fileReadMode('a'), 'axyz');
    expect(FileSource.fileReadMode('a\n'), 'a\nxyz');
    expect(FileSource.fileReadMode('ab'), 'abxyz');
    expect(FileSource.fileReadMode('abc'), 'abcxyz');
    FileSource.fileReadMode = (String s) => s;
  }

  void test_getFullName() {
    File file = getFile("/does/not/exist.dart");
    FileSource source = FileSource(file);
    expect(source.fullName, file.path);
  }

  void test_getShortName() {
    File file = getFile("/does/not/exist.dart");
    FileSource source = FileSource(file);
    expect(source.shortName, "exist.dart");
  }

  void test_hashCode() {
    File file1 = getFile("/does/not/exist.dart");
    File file2 = getFile("/does/not/exist.dart");
    FileSource source1 = FileSource(file1);
    FileSource source2 = FileSource(file2);
    expect(source2.hashCode, source1.hashCode);
  }

  void test_issue14500() {
    // see https://code.google.com/p/dart/issues/detail?id=14500
    FileSource source = FileSource(getFile("/some/packages/foo:bar.dart"));
    expect(source, isNotNull);
    expect(source.exists(), isFalse);
  }

  void test_resolveRelative_file_fileName() {
    if (OSUtilities.isWindows()) {
      // On Windows, the URI that is produced includes a drive letter,
      // which I believe is not consistent across all machines that might run
      // this test.
      return;
    }
    File file = getFile("/a/b/test.dart");
    FileSource source = FileSource(file);
    expect(source, isNotNull);
    Uri relative = resolveRelativeUri(source.uri, Uri.parse("lib.dart"));
    expect(relative, isNotNull);
    expect(relative.toString(), "file:///a/b/lib.dart");
  }

  void test_resolveRelative_file_filePath() {
    if (OSUtilities.isWindows()) {
      // On Windows, the URI that is produced includes a drive letter,
      // which I believe is not consistent across all machines that might run
      // this test.
      return;
    }
    File file = getFile("/a/b/test.dart");
    FileSource source = FileSource(file);
    expect(source, isNotNull);
    Uri relative = resolveRelativeUri(source.uri, Uri.parse("c/lib.dart"));
    expect(relative, isNotNull);
    expect(relative.toString(), "file:///a/b/c/lib.dart");
  }

  void test_resolveRelative_file_filePathWithParent() {
    if (OSUtilities.isWindows()) {
      // On Windows, the URI that is produced includes a drive letter, which I
      // believe is not consistent across all machines that might run this test.
      return;
    }
    File file = getFile("/a/b/test.dart");
    FileSource source = FileSource(file);
    expect(source, isNotNull);
    Uri relative = resolveRelativeUri(source.uri, Uri.parse("../c/lib.dart"));
    expect(relative, isNotNull);
    expect(relative.toString(), "file:///a/c/lib.dart");
  }

  void test_system() {
    File file = getFile("/does/not/exist.dart");
    FileSource source = FileSource(file, Uri.parse("dart:core"));
    expect(source, isNotNull);
    expect(source.fullName, file.path);
    expect(source.uri.toString(), 'dart:core');
  }
}
