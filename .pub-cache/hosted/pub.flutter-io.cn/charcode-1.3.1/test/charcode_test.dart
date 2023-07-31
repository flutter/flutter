// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import "package:test/test.dart";

import "../bin/charcode.dart" as bin;

void main() {
  testOutput([], (output) {
    expect(output, isEmpty);
  });

  testOutput(["a"], (output) {
    expect(count(output, r"$"), 1);
    expect(output, contains(r"int $a = 0x61"));
  });

  testOutput(["a-c"], (output) {
    expect(count(output, r"$"), 3);
    expect(output, contains(r"int $a = 0x61"));
    expect(output, contains(r"int $b = 0x62"));
    expect(output, contains(r"int $c = 0x63"));
  });

  testOutput(["b=bee:Explanation!", "a-c"], (output) {
    expect(count(output, r"$"), 3);
    expect(output, contains(r"int $a = 0x61"));
    expect(output, isNot(contains(r"int $b = 0x62")));
    expect(output, contains(r"int $bee = 0x62"));
    expect(output, contains(r"Explanation!"));
    expect(output, contains(r"int $c = 0x63"));
  });

  testOutput(["b", "b=bee:Explanation!", "b"], (output) {
    expect(count(output, r"$"), 2);
    expect(output, contains(r"int $b = 0x62"));
    expect(output, contains(r"int $bee = 0x62"));
    expect(output, contains(r"Explanation!"));
  });

  testOutput(["a-c"], (output) {
    expect(count(output, r"$"), 3);
    expect(output, contains(r"int $a = 0x61"));
    expect(output, contains(r"int $b = 0x62"));
    expect(output, contains(r"int $c = 0x63"));
  });

  // Escapes
  testOutput([r"\x61-\99\u000065"], (output) {
    expect(count(output, r"$"), 4);
    expect(output, contains(r"int $a = 0x61"));
    expect(output, contains(r"int $b = 0x62"));
    expect(output, contains(r"int $c = 0x63"));
    expect(output, contains(r"int $e = 0x65"));
  });

  testOutput([r"\0=nil", r"\0"], (output) {
    expect(output, contains(r"int $nil = 0x00;"));
  });

  testOutput([r"\d"], (output) {
    expect(count(output, r"$"), 10);
    checkRange(output, "0", "9");
  });

  testOutput([r"\w"], (output) {
    expect(count(output, r" $"), 64);
    checkRange(output, "0", "9");
    checkRange(output, "a", "z");
    checkRange(output, "A", "Z");
    expect(output, contains(r"int $$ = 0x24"));
    expect(output, contains(r"int $_ = 0x5f"));
  });

  testOutput([r"\s"], (output) {
    expect(count(output, r"$"), 4);
    expect(output, contains(r"int $tab = 0x09;"));
    expect(output, contains(r"int $lf = 0x0a;"));
    expect(output, contains(r"int $cr = 0x0d;"));
    expect(output, contains(r"int $space = 0x20;"));
  });

  testOutput([r"\t"], (output) {
    expect(count(output, r"$"), 1);
    expect(output, contains(r"int $tab = 0x09;"));
  });

  testOutput([r"\n"], (output) {
    expect(count(output, r"$"), 1);
    expect(output, contains(r"int $lf = 0x0a;"));
  });

  testOutput([r"\r"], (output) {
    expect(count(output, r"$"), 1);
    expect(output, contains(r"int $cr = 0x0d;"));
  });

  // Accept one digit for for \x.
  testOutput([r"\x0z"], (output) {
    expect(count(output, r"$"), 2);
    expect(output, contains(r"int $nul = 0x00;"));
    expect(output, contains(r"int $z = 0x7a;"));
  });

  // At most two digits for \x.
  testOutput([r"\x41F"], (output) {
    expect(count(output, r"$"), 2);
    expect(output, contains(r"int $A = 0x41;"));
    expect(output, contains(r"int $F = 0x46;"));
  });

  // At most six digits for \u.
  testOutput([r"\u10FFFF=last", r"\u10FFFFF"], (output) {
    expect(count(output, r"$"), 2);
    expect(output, contains(r"int $last = 0x10ffff;"));
    expect(output, contains(r"int $F = 0x46;"));
  });

  testOutput([r"\d-a"], (output) {
    expect(count(output, r"$"), 12);
    checkRange(output, "0", "9");
    expect(output, contains(r"int $minus = 0x2d;"));
    expect(output, contains(r"int $a = 0x61;"));
  });

  // Setting the prefix.
  testOutput(["-p_", "a-c"], (output) {
    expect(output, contains(r"int _a = 0x61;"));
    expect(output, contains(r"int _b = 0x62;"));
    expect(output, contains(r"int _c = 0x63;"));
  });

  // Optional prefix cannot be split into next argument.
  testOutput(["-p", "_", "a-c"], (output) {
    expect(output, contains(r"int a = 0x61;"));
    expect(output, contains(r"int b = 0x62;"));
    expect(output, contains(r"int c = 0x63;"));
    expect(output, contains(r"int _ = 0x5f;"));
  });

  testOutput(["--prefix=_", "a-c"], (output) {
    expect(output, contains(r"int _a = 0x61;"));
    expect(output, contains(r"int _b = 0x62;"));
    expect(output, contains(r"int _c = 0x63;"));
  });

  // Optional prefix cannot be split into next argument.
  testOutput(["--prefix", "_", "a-c"], (output) {
    expect(output, contains(r"int a = 0x61;"));
    expect(output, contains(r"int b = 0x62;"));
    expect(output, contains(r"int c = 0x63;"));
    expect(output, contains(r"int _ = 0x5f;"));
  });

  testOutput(["b", "-p_", "b", "-px", "b"], (output) {
    expect(output, contains(r"int $b = 0x62;"));
    expect(output, contains(r"int _b = 0x62;"));
    expect(output, contains(r"int xb = 0x62;"));
  });

  // Empty prefix uses previous non-empty prefix for
  // invalid identifiers
  testOutput(["-p", "a-c0"], (output) {
    expect(output, contains(r"int $0 = 0x30;"));
    expect(output, contains(r"int a = 0x61;"));
    expect(output, contains(r"int b = 0x62;"));
    expect(output, contains(r"int c = 0x63;"));
  });

  testOutput(["-p_", "-p", "a-c0"], (output) {
    expect(output, contains(r"int _0 = 0x30;"));
    expect(output, contains(r"int a = 0x61;"));
    expect(output, contains(r"int b = 0x62;"));
    expect(output, contains(r"int c = 0x63;"));
  });

  testOutput(["--help"], (output) {
    expect(output, startsWith("Usage:"));
  });

  void testReadFile(List<String> commands, void Function(String) check) {
    group("File-test", () {
      var tmpDir = Directory.systemTemp.createTempSync("test");
      var file = File("${tmpDir.path}${Platform.pathSeparator}file.txt");
      setUp(() {
        file.writeAsStringSync(commands.join("\n"));
      });
      tearDown(() {
        tmpDir.deleteSync(recursive: true);
      });
      testOutput(["-f${file.path}"], check);
    });
  }

  // Commands can be read from file,
  // both character ranges and declarations.
  testReadFile(["a", "b"], (output) {
    expect(count(output, r"$"), 2);
    expect(output, contains(r"int $a = 0x61"));
    expect(output, contains(r"int $b = 0x62"));
  });

  testReadFile(["b=bee", "b"], (output) {
    expect(count(output, r"$"), 1);
    expect(output, contains(r"int $bee = 0x62"));
  });

  // Flags are not recognized when reading from file.
  testReadFile(["-p_", "b"], (output) {
    expect(count(output, r"$"), 4);
    expect(output, contains(r"int $b = 0x62"));
    expect(output, contains(r"int $p = 0x70"));
    expect(output, contains(r"int $minus = 0x2d"));
    expect(output, contains(r"int $_ = 0x5f"));
  });
}

void testOutput(List<String> commands, void Function(String) outputTest) {
  test("charcode ${commands.join(" ")}", () {
    var buffer = StringBuffer();
    bin.main(commands, buffer);
    outputTest(buffer.toString());
  });
}

int count(String output, String part) {
  var count = 0;
  var pos = 0;
  while ((pos = output.indexOf(part, pos)) >= 0) {
    count++;
    pos += part.length;
  }
  return count;
}

void checkRange(String output, String start, String end, [String p = r"$"]) {
  var from = start.codeUnitAt(0);
  var to = end.codeUnitAt(0);
  for (var i = from; i <= to; i++) {
    expect(output,
        contains("$p${String.fromCharCode(i)} = 0x${i.toRadixString(16)};"));
  }
}
