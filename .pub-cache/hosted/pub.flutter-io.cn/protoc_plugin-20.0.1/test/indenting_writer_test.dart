#!/usr/bin/env dart
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:protoc_plugin/indenting_writer.dart';
import 'package:protoc_plugin/src/generated/descriptor.pb.dart';
import 'package:test/test.dart';

void main() {
  test('IndentingWriter can indent a block', () {
    var out = IndentingWriter(filename: '');
    out.addBlock('class test {', '}', () {
      out.println('first;');
      out.println();
      out.println('second;');
    });

    expect(out.toString(), '''
class test {
  first;

  second;
}
''');
  });

  test('IndentingWriter annotation tracks previous output', () {
    var out = IndentingWriter(filename: 'sample.proto');
    out.print('13 characters');
    out.printAnnotated('sample text', [
      NamedLocation(name: 'text', fieldPathSegment: [1, 2, 3], start: 7)
    ]);
    var expected = GeneratedCodeInfo_Annotation()
      ..path.addAll([1, 2, 3])
      ..sourceFile = 'sample.proto'
      ..begin = 20
      ..end = 24;
    var annotation = out.sourceLocationInfo.annotation[0];
    expect(annotation, equals(expected));
  });

  test('IndentingWriter annotation counts indents correctly', () {
    var out = IndentingWriter(filename: '');
    out.addBlock('34 characters including newline {', '}', () {
      out.printlnAnnotated('sample text',
          [NamedLocation(name: 'sample', fieldPathSegment: [], start: 0)]);
    });
    var annotation = out.sourceLocationInfo.annotation[0];
    // The indent is 2 characters, so these should be shifted by 2.
    expect(annotation.begin, equals(36));
    expect(annotation.end, equals(42));
  });

  test('IndentingWriter annotations counts multiline output correctly', () {
    var out = IndentingWriter(filename: '');
    out.print('20 characters\ntotal\n');
    out.printlnAnnotated('20 characters before this',
        [NamedLocation(name: 'ch', fieldPathSegment: [], start: 3)]);
    var annotation = out.sourceLocationInfo.annotation[0];
    expect(annotation.begin, equals(23));
    expect(annotation.end, equals(25));
  });
}
