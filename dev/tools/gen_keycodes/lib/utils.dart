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
///
/// 'TVFoo' should be convert to 'tvFoo'.
/// 'KeyX' should be convert to 'keyX'.
String upperCamelToLowerCamel(String upperCamel) {
  final RegExp initialGroup = RegExp(r'^([A-Z]([A-Z]*|[^A-Z]*))([A-Z]([^A-Z]|$)|$)');
  return upperCamel.replaceFirstMapped(initialGroup, (Match match) {
    return match.group(1).toLowerCase() + (match.group(3) ?? '');
  });
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

/// Given an [input] string, wraps the text at 80 characters and prepends each
/// line with the [prefix] string. Use for generated comments.
String wrapString(String input, {String prefix}) {
  final int wrapWidth = 80 - prefix.length;
  final StringBuffer result = StringBuffer();
  final List<String> words = input.split(RegExp(r'\s+'));
  String currentLine = words.removeAt(0);
  for (final String word in words) {
    if ((currentLine.length + word.length) < wrapWidth) {
      currentLine += ' $word';
    } else {
      result.writeln('$prefix$currentLine');
      currentLine = word;
    }
  }
  if (currentLine.isNotEmpty) {
    result.writeln('$prefix$currentLine');
  }
  return result.toString();
}
