// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: missing_whitespace_between_adjacent_strings

import 'package:test/test.dart';

void main() {
  group('escaping should work with', () {
    _testEscaping('no escaped chars', 'Hello, world!', 'Hello, world!');
    _testEscaping('newline', '\n', r'\n');
    _testEscaping('carriage return', '\r', r'\r');
    _testEscaping('form feed', '\f', r'\f');
    _testEscaping('backspace', '\b', r'\b');
    _testEscaping('tab', '\t', r'\t');
    _testEscaping('vertical tab', '\v', r'\v');
    _testEscaping('null byte', '\x00', r'\x00');
    _testEscaping('ASCII control character', '\x11', r'\x11');
    _testEscaping('delete', '\x7F', r'\x7F');
    _testEscaping('escape combos', r'\n', r'\\n');
    _testEscaping(
        'All characters',
        'A new line\nA charriage return\rA form feed\fA backspace\b'
            'A tab\tA vertical tab\vA slash\\A null byte\x00A control char\x1D'
            'A delete\x7F',
        r'A new line\nA charriage return\rA form feed\fA backspace\b'
            r'A tab\tA vertical tab\vA slash\\A null byte\x00A control char\x1D'
            r'A delete\x7F');
  });

  group('unequal strings remain unequal when escaped', () {
    _testUnequalStrings('with a newline', '\n', r'\n');
    _testUnequalStrings('with slash literals', '\\', r'\\');
  });
}

/// Creates a [test] with name [name] that verifies [source] escapes to value
/// [target].
void _testEscaping(String name, String source, String target) {
  test(name, () {
    var escaped = escape(source);
    expect(escaped == target, isTrue,
        reason: 'Expected escaped value: $target\n'
            '  Actual escaped value: $escaped');
  });
}

/// Creates a [test] with name [name] that ensures two different [String] values
/// [s1] and [s2] remain unequal when escaped.
void _testUnequalStrings(String name, String s1, String s2) {
  test(name, () {
    // Explicitly not using the equals matcher
    expect(s1 != s2, isTrue, reason: 'The source values should be unequal');

    var escapedS1 = escape(s1);
    var escapedS2 = escape(s2);

    // Explicitly not using the equals matcher
    expect(escapedS1 != escapedS2, isTrue,
        reason: 'Unequal strings, when escaped, should remain unequal.');
  });
}
