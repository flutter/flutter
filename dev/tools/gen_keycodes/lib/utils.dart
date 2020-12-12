// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

/// The location of the Flutter root directory, based on the known location of
/// this script.
final Directory flutterRoot = Directory(path.dirname(Platform.script.toFilePath())).parent.parent.parent.parent;

/// Converts `FOO_BAR` to `fooBar`.
String shoutingToLowerCamel(String shouting) {
  final RegExp initialLetter = RegExp(r'_([^_])([^_]*)');
  final String snake = shouting.toLowerCase();
  final String result = snake.replaceAllMapped(initialLetter, (Match match) {
    return match.group(1).toUpperCase() + match.group(2).toLowerCase();
  });
  return result;
}

/// Converts 'FooBar' to 'fooBar'.
String upperCamelToLowerCamel(String upperCamel) {
  return upperCamel.substring(0, 1).toLowerCase() + upperCamel.substring(1);
}

/// Converts 'fooBar' to 'FooBar'.
String lowerCamelToUpperCamel(String lowerCamel) {
  return lowerCamel.substring(0, 1).toUpperCase() + lowerCamel.substring(1);
}

/// A list of Dart reserved words.
///
/// Since these are Dart reserved words, we can't use them as-is for enum names.
const List<String> kDartReservedWords = <String>[
  'abstract',
  'as',
  'assert',
  'async',
  'await',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'covariant',
  'default',
  'deferred',
  'do',
  'dynamic',
  'else',
  'enum',
  'export',
  'extends',
  'external',
  'factory',
  'false',
  'final',
  'finally',
  'for',
  'Function',
  'get',
  'hide',
  'if',
  'implements',
  'import',
  'in',
  'interface',
  'is',
  'library',
  'mixin',
  'new',
  'null',
  'on',
  'operator',
  'part',
  'rethrow',
  'return',
  'set',
  'show',
  'static',
  'super',
  'switch',
  'sync',
  'this',
  'throw',
  'true',
  'try',
  'typedef',
  'var',
  'void',
  'while',
  'with',
  'yield',
];

/// Converts an integer into a hex string with the given number of digits.
String toHex(int value, {int digits = 8}) {
  if (value == null) {
    return 'null';
  }
  return '0x${value.toRadixString(16).padLeft(digits, '0')}';
}

/// Parses an integer from a hex string.
int getHex(String input) {
  return int.parse(input, radix: 16);
}
