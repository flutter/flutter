// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library src_gen_common;

import 'package:markdown/markdown.dart';

const int RUNE_SPACE = 32;
const int RUNE_EOL = 10;
const int RUNE_LEFT_CURLY = 123;
const int RUNE_RIGHT_CURLY = 125;

final RegExp _wsRegexp = RegExp(r'\s+');

String collapseWhitespace(String str) => str.replaceAll(_wsRegexp, ' ');

bool isEmphasis(Node node) => node is Element && node.tag == 'em';
bool isPara(Node node) => node is Element && node.tag == 'p';
bool isBlockquote(Node node) => node is Element && node.tag == 'blockquote';
bool isPre(Node node) => node is Element && node.tag == 'pre';
bool isList(Node node) => node is Element && node.tag == 'ul';
bool isH1(Node node) => node is Element && node.tag == 'h1';
bool isH3(Node node) => node is Element && node.tag == 'h3';
bool isHeader(Node node) => node is Element && node.tag.startsWith('h');
String textForElement(Node node) =>
    (((node as Element).children!.first) as Text).text;
String textForCode(Node node) =>
    textForElement((node as Element).children!.first);

/// foo ==> Foo
String titleCase(String str) =>
    str.substring(0, 1).toUpperCase() + str.substring(1);

/// FooBar ==> fooBar
String lowerTitleCase(String str) =>
    str.substring(0, 1).toLowerCase() + str.substring(1);

String joinLast(Iterable<String> strs, String join, [String? last]) {
  if (strs.isEmpty) return '';
  List list = strs.toList();
  if (list.length == 1) return list.first;
  StringBuffer buf = StringBuffer();
  for (int i = 0; i < list.length; i++) {
    if (i > 0) {
      if (i + 1 == list.length && last != null) {
        buf.write(last);
      } else {
        buf.write(join);
      }
    }
    buf.write(list[i]);
  }
  return buf.toString();
}

/// Wrap a string on column boundaries.
String wrap(String str, [int col = 80]) {
  // The given string could contain newlines.
  List<String> lines = str.split('\n');
  return lines.map((l) => _simpleWrap(l, col)).join('\n');
}

/// Wrap a string ignoring newlines.
String _simpleWrap(String str, [int col = 80]) {
  List<String> lines = [];

  while (str.length > col) {
    int index = col;

    while (index > 0 && str.codeUnitAt(index) != RUNE_SPACE) {
      index--;
    }

    if (index == 0) {
      index = str.indexOf(' ');

      if (index == -1) {
        lines.add(str);
        str = '';
      } else {
        lines.add(str.substring(0, index).trim());
        str = str.substring(index).trim();
      }
    } else {
      lines.add(str.substring(0, index).trim());
      str = str.substring(index).trim();
    }
  }

  if (str.isNotEmpty) lines.add(str);

  return lines.join('\n');
}
