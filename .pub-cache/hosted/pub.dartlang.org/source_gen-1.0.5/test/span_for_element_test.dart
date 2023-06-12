// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

void main() {
  late LibraryElement library;

  setUpAll(() async {
    library = await resolveSource(
      r'''
library test_lib;

abstract class Example implements List {
  List<A> get getter => null;
  set setter(int value) {}
  int field;
  int get fieldProp => field;
  set fieldProp(int value) {
    field = value;
  }
}
''',
      (resolver) async => (await resolver.findLibraryByName('test_lib'))!,
      inputId: AssetId('test_lib', 'lib/test_lib.dart'),
    );
  });

  test('should highlight the use of "class Example"', () async {
    expect(
        spanForElement(library.getType('Example')!).message('Here it is'), r'''
line 3, column 16 of package:test_lib/test_lib.dart: Here it is
  ╷
3 │ abstract class Example implements List {
  │                ^^^^^^^
  ╵''');
  });

  test('should correctly highlight getter', () async {
    expect(
        spanForElement(library.getType('Example')!.getField('getter')!)
            .message('Here it is'),
        r'''
line 4, column 15 of package:test_lib/test_lib.dart: Here it is
  ╷
4 │   List<A> get getter => null;
  │               ^^^^^^
  ╵''');
  });

  test('should correctly highlight setter', () async {
    expect(
        spanForElement(library.getType('Example')!.getField('setter')!)
            .message('Here it is'),
        r'''
line 5, column 7 of package:test_lib/test_lib.dart: Here it is
  ╷
5 │   set setter(int value) {}
  │       ^^^^^^
  ╵''');
  });

  test('should correctly highlight field', () async {
    expect(
        spanForElement(library.getType('Example')!.getField('field')!)
            .message('Here it is'),
        r'''
line 6, column 7 of package:test_lib/test_lib.dart: Here it is
  ╷
6 │   int field;
  │       ^^^^^
  ╵''');
  });

  test('highlight getter with getter/setter property', () async {
    expect(
        spanForElement(library.getType('Example')!.getField('fieldProp')!)
            .message('Here it is'),
        r'''
line 7, column 11 of package:test_lib/test_lib.dart: Here it is
  ╷
7 │   int get fieldProp => field;
  │           ^^^^^^^^^
  ╵''');
  });
}
