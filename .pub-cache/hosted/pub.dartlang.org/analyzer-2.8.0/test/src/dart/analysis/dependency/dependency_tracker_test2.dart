// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NodeTransitiveSignatureTest);
  });
}

@reflectiveTest
class NodeTransitiveSignatureTest extends BaseDependencyTest {
  test_experiment_1() async {
//    await buildLibrary(a, r'''
//final a = 1;
//''');
//
//    await buildLibrary(b, r'''
//import 'a.dart';
//
//final b = 2 + a;
//final c = 4;
//int d = b;
//''');
//
//    tracker.computeSignatures();
//
//    newFile(a, content: r'''
//final a = -1;
//final a2 = 2;
//''');
//    driver.changeFile(a);
//    var newParseResult = driver.parseFileSync(a);
//    tracker.changeFile(aUri, [newParseResult.unit]);
  }

  test_experiment_2() async {
//    await buildLibrary(a, r'''
//import 'b.dart';
//
//final a = 1;
//final c = b;
//final e = 5;
//''');
//
//    await buildLibrary(b, r'''
//import 'a.dart';
//
//final b = a;
//final d = 4;
//''');
//
//    tracker.computeSignatures();
//
//    newFile(a, content: r'''
//import 'b.dart';
//
//final a = -1;
//final c = b;
//final e = 5;
//''');
//    driver.changeFile(a);
//    var newParseResult = driver.parseFileSync(a);
//    tracker.changeFile(aUri, aUri, [newParseResult.unit]);
  }

  test_experiment_3() async {
//    await buildLibrary(a, r'''
//final int a = 1;
//final b = 2;
//final c = a;
//final d = c;
//final e = a + b;
//final f = 10;
//''');
//
//    tracker.computeSignatures();
//
//    newFile(a, content: r'''
//final int a = -1;
//final b = 2;
//final c = a;
//final d = c;
//final e = a + b;
//final f = 10;
//''');
//    driver.changeFile(a);
//    var newParseResult = driver.parseFileSync(a);
//    tracker.changeFile(aUri, aUri, [newParseResult.unit]);
  }
}
