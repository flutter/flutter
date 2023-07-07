// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library visitor_test;

import 'package:csslib/src/messages.dart';
import 'package:csslib/visitor.dart';
import 'package:test/test.dart';

import 'testing.dart';

class ClassVisitor extends Visitor {
  final List expectedClasses;
  final foundClasses = <String>{};

  ClassVisitor(this.expectedClasses);

  @override
  void visitClassSelector(ClassSelector node) {
    foundClasses.add(node.name);
  }

  bool get matches {
    var match = true;
    foundClasses.forEach((value) {
      match = match && expectedClasses.contains(value);
    });
    expectedClasses.forEach((value) {
      match = match && foundClasses.contains(value);
    });

    return match;
  }
}

void testClassVisitors() {
  var errors = <Message>[];
  var in1 = '.foobar { }';

  var s = parseCss(in1, errors: errors);

  expect(errors.isEmpty, true, reason: errors.toString());

  var clsVisits = ClassVisitor(['foobar'])..visitTree(s);
  expect(clsVisits.matches, true);

  in1 = '''
      .foobar1 { }
      .xyzzy .foo #my-div { color: red; }
      div.hello { font: arial; }
    ''';

  s = parseCss(in1, errors: errors..clear(), opts: simpleOptions);

  expect(errors.isEmpty, true, reason: errors.toString());

  clsVisits = ClassVisitor(['foobar1', 'xyzzy', 'foo', 'hello'])..visitTree(s);
  expect(clsVisits.matches, true);

  expect(prettyPrint(s), r'''
.foobar1 {
}
.xyzzy .foo #my-div {
  color: #f00;
}
div.hello {
  font: arial;
}''');
}

class PolyfillEmitter extends CssPrinter {
  final String _prefix;

  PolyfillEmitter(this._prefix);

  @override
  void visitClassSelector(ClassSelector node) {
    emit('.${_prefix}_${node.name}');
  }
}

String polyfillPrint(String prefix, StyleSheet ss) =>
    (PolyfillEmitter(prefix)..visitTree(ss, pretty: true)).toString();

void testPolyFill() {
  var errors = <Message>[];
  final input = r'''
.foobar { }
div.xyzzy { }
#foo .foo .bar .foobar { }
''';

  final generated = r'''
.myComponent_foobar {
}
div.myComponent_xyzzy {
}
#foo .myComponent_foo .myComponent_bar .myComponent_foobar {
}''';

  var s = parseCss(input, errors: errors);
  expect(errors.isEmpty, true, reason: errors.toString());

  final emitted = polyfillPrint('myComponent', s);
  expect(emitted, generated);
}

void main() {
  test('Class Visitors', testClassVisitors);
  test('Polyfill', testPolyFill);
}
