// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:litetest/litetest.dart';
import 'package:path/path.dart' as path;
import 'package:process_runner/process_runner.dart';

import '../bin/format.dart' as target;

final io.File script = io.File.fromUri(io.Platform.script).absolute;
final io.Directory repoDir = script.parent.parent.parent;
final ProcessPool pool = ProcessPool(
  numWorkers: 1,
  processRunner: ProcessRunner(defaultWorkingDirectory: repoDir),
);

class FileContentPair {
  FileContentPair(this.original, this.formatted, this.fileExtension);

  final String original;
  final String formatted;
  final String fileExtension;
}

final FileContentPair ccContentPair = FileContentPair(
    'int main(){return 0;}\n', 'int main() {\n  return 0;\n}\n', '.cc');
final FileContentPair hContentPair =
    FileContentPair('int\nmain\n()\n;\n', 'int main();\n', '.h');
final FileContentPair gnContentPair = FileContentPair(
    'test\n(){testvar=true}\n', 'test() {\n  testvar = true\n}\n', '.gn');
final FileContentPair javaContentPair = FileContentPair(
    'class Test{public static void main(String args[]){System.out.println("Test");}}\n',
    'class Test {\n  public static void main(String args[]) {\n    System.out.println("Test");\n  }\n}\n',
    '.java');
final FileContentPair pythonContentPair = FileContentPair(
    "if __name__=='__main__':\n  sys.exit(\nMain(sys.argv)\n)\n",
    "if __name__ == '__main__':\n  sys.exit(Main(sys.argv))\n",
    '.py');
final FileContentPair whitespaceContentPair = FileContentPair(
    'int main() {\n  return 0;       \n}\n',
    'int main() {\n  return 0;\n}\n',
    '.c');

class TestFileFixture {
  TestFileFixture(this.type) {
    switch (type) {
      case target.FormatCheck.clang:
        final io.File ccFile = io.File('${repoDir.path}/format_test.cc');
        ccFile.writeAsStringSync(ccContentPair.original);
        files.add(ccFile);

        final io.File hFile = io.File('${repoDir.path}/format_test.h');
        hFile.writeAsStringSync(hContentPair.original);
        files.add(hFile);
      case target.FormatCheck.gn:
        final io.File gnFile = io.File('${repoDir.path}/format_test.gn');
        gnFile.writeAsStringSync(gnContentPair.original);
        files.add(gnFile);
      case target.FormatCheck.java:
        final io.File javaFile = io.File('${repoDir.path}/format_test.java');
        javaFile.writeAsStringSync(javaContentPair.original);
        files.add(javaFile);
      case target.FormatCheck.python:
        final io.File pyFile = io.File('${repoDir.path}/format_test.py');
        pyFile.writeAsStringSync(pythonContentPair.original);
        files.add(pyFile);
      case target.FormatCheck.whitespace:
        final io.File whitespaceFile = io.File('${repoDir.path}/format_test.c');
        whitespaceFile.writeAsStringSync(whitespaceContentPair.original);
        files.add(whitespaceFile);
    }
  }

  final target.FormatCheck type;
  final List<io.File> files = <io.File>[];

  void gitAdd() {
    final List<String> args = <String>['add'];
    for (final io.File file in files) {
      args.add(file.path);
    }

    io.Process.runSync('git', args);
  }

  void gitRemove() {
    final List<String> args = <String>['rm', '-f'];
    for (final io.File file in files) {
      args.add(file.path);
    }
    io.Process.runSync('git', args);
  }

  Iterable<FileContentPair> getFileContents() {
    return files.map((io.File file) {
      String content = file.readAsStringSync();
      // Avoid clang-tidy formatting CRLF EOL on Windows
      content = content.replaceAll('\r\n', '\n');
      switch (type) {
        case target.FormatCheck.clang:
          return FileContentPair(
            content,
            path.extension(file.path) == '.cc'
                ? ccContentPair.formatted
                : hContentPair.formatted,
            path.extension(file.path),
          );
        case target.FormatCheck.gn:
          return FileContentPair(
            content,
            gnContentPair.formatted,
            path.extension(file.path),
          );
        case target.FormatCheck.java:
          return FileContentPair(
            content,
            javaContentPair.formatted,
            path.extension(file.path),
          );
        case target.FormatCheck.python:
          return FileContentPair(
            content,
            pythonContentPair.formatted,
            path.extension(file.path),
          );
        case target.FormatCheck.whitespace:
          return FileContentPair(
            content,
            whitespaceContentPair.formatted,
            path.extension(file.path),
          );
      }
    });
  }
}

void main() {
  final String formatterPath =
      '${repoDir.path}/ci/format.${io.Platform.isWindows ? 'bat' : 'sh'}';

  test('Can fix C++ formatting errors', () {
    final TestFileFixture fixture = TestFileFixture(target.FormatCheck.clang);
    try {
      fixture.gitAdd();
      io.Process.runSync(formatterPath, <String>['--check', 'clang', '--fix'],
          workingDirectory: repoDir.path);

      final Iterable<FileContentPair> files = fixture.getFileContents();
      for (final FileContentPair pair in files) {
        expect(pair.original, equals(pair.formatted));
      }
    } finally {
      fixture.gitRemove();
    }
  });

  test('Can fix GN formatting errors', () {
    final TestFileFixture fixture = TestFileFixture(target.FormatCheck.gn);
    try {
      fixture.gitAdd();
      io.Process.runSync(formatterPath, <String>['--check', 'gn', '--fix'],
          workingDirectory: repoDir.path);

      final Iterable<FileContentPair> files = fixture.getFileContents();
      for (final FileContentPair pair in files) {
        expect(pair.original, equals(pair.formatted));
      }
    } finally {
      fixture.gitRemove();
    }
  });

  test('Can fix Java formatting errors', () {
    final TestFileFixture fixture = TestFileFixture(target.FormatCheck.java);
    try {
      fixture.gitAdd();
      io.Process.runSync(formatterPath, <String>['--check', 'java', '--fix'],
          workingDirectory: repoDir.path);

      final Iterable<FileContentPair> files = fixture.getFileContents();
      for (final FileContentPair pair in files) {
        expect(pair.original, equals(pair.formatted));
      }
    } finally {
      fixture.gitRemove();
    }
    // TODO(mtolmacs): Fails if Java dependency is unavailable,
    // https://github.com/flutter/flutter/issues/129221
  }, skip: true);

  test('Can fix Python formatting errors', () {
    final TestFileFixture fixture = TestFileFixture(target.FormatCheck.python);
    try {
      fixture.gitAdd();
      io.Process.runSync(formatterPath, <String>['--check', 'python', '--fix'],
          workingDirectory: repoDir.path);

      final Iterable<FileContentPair> files = fixture.getFileContents();
      for (final FileContentPair pair in files) {
        expect(pair.original, equals(pair.formatted));
      }
    } finally {
      fixture.gitRemove();
    }
  });

  test('Can fix whitespace formatting errors', () {
    final TestFileFixture fixture =
        TestFileFixture(target.FormatCheck.whitespace);
    try {
      fixture.gitAdd();
      io.Process.runSync(
          formatterPath, <String>['--check', 'whitespace', '--fix'],
          workingDirectory: repoDir.path);

      final Iterable<FileContentPair> files = fixture.getFileContents();
      for (final FileContentPair pair in files) {
        expect(pair.original, equals(pair.formatted));
      }
    } finally {
      fixture.gitRemove();
    }
  });
}
