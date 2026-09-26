// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart';
import 'package:flutter_analyzer_plugin/src/rules/access_debug_members_only_in_asserts.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

@reflectiveTest
class AccessDebugMembersOnlyInAssertsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    Registry.ruleRegistry.registerLintRule(AccessDebugMembersOnlyInAsserts());
    super.setUp();
  }

  @override
  String get analysisRule => AccessDebugMembersOnlyInAsserts.code.name;

  static const String debugOnlyAccessSource = '''
// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

String debugGlobalVariable = '';

void debugGlobalFunction() { }

mixin DebugMixin {
  static int debugStaticVar = 0;

  static void debugStaticMethod() { }

  int debugField = 0;

  int get debugGetSet => _debugGetSet;
  int _debugGetSet = 0;
  set debugGetSet(int value) => _debugGetSet = value;

  void debugMethod() { }
}

final ProductionClass x = ProductionClass();
ProductionClass? xx;
void takeAnything(Object? input) { }

void badDebugAssertAccess() {
  debugGlobalVariable += 'test';
  debugGlobalFunction();
  void Function() f = debugGlobalFunction; // ignore: unused_local_variable
  f = debugGlobalFunction.call;
  DebugMixin.debugStaticMethod();
  f = DebugMixin.debugStaticMethod;
  x.debugField; // ignore: unnecessary_statements
  xx?.debugField; // ignore: unnecessary_statements
  x.debugGetSet;
  xx?.debugGetSet;
  x.debugGetSet = 2;
  xx?.debugGetSet = 2;
  x..debugField += x.debugGetSet
   ..debugGetSet += x.debugGetSet;
  xx?..debugField += x.debugGetSet
   ..debugGetSet += x.debugGetSet;
  takeAnything(xx?.debugMethod);
  x.debugOnlyExtensionMethod();
  takeAnything(xx?.debugOnlyExtensionMethod);
  DebugOnlyEnum.foo; // ignore: unnecessary_statements
  DebugOnlyEnum.values; // ignore: unnecessary_statements
  RegularEnum.foo.debugOnlyMethod();
}

/// Yours truly [debugGlobalVariable] from the comment section with love.
void goodDebugAssertAccess() {
  assert(() {
    final _DebugOnlyClass debugObject = _DebugOnlyClass();
    debugObject
      .debugOnlyMemberMethod();
    final void Function() f = debugObject.debugOnlyMemberMethod;
    f();
    return true;
  }());

  final ProductionClass x = ProductionClass() // ignore: unused_local_variable
    ..run();
  RegularEnum.foo; // ignore: unnecessary_statements
}

mixin class BaseClass {
  void run() { }
  void stop() { }

  int get value => 0;
}

class _DebugOnlyClass extends BaseClass {
  void debugOnlyMemberMethod() {}
}

class ProductionClass extends BaseClass {
  int debugField = 0;

  int get debugGetSet => _debugGetSet;
  int _debugGetSet = 0;
  set debugGetSet(int value) => _debugGetSet = value;

  void debugMethod() {
    debugField = debugGetSet + 1;
  }

  @override
  String toString() => debugGetSet.toString();

  _DebugOnlyClass debugField1 = _DebugOnlyClass(), debugField2 = _DebugOnlyClass();
  _DebugOnlyClass debugField3 = _DebugOnlyClass(), nonDebugField = _DebugOnlyClass();
}

extension DebugOnly on ProductionClass {
  void debugOnlyExtensionMethod() { }
}

enum DebugOnlyEnum with BaseClass {
  foo
}

enum RegularEnum {
  foo;

  void debugOnlyMethod() {}
}
''';

  static const String debugOnlyConstructorsSource = '''
// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class BaseWithDebugConstructor {
  BaseWithDebugConstructor.debugConstructor();
}

class ProductionClass11 extends BaseWithDebugConstructor {
  ProductionClass11() : super.debugConstructor(); // bad: debug-only constructor invoked
}

class ProductionClass5 {
  ProductionClass5(this.debugOnlyField);                      // Good: formal parameters can start with debug.
  ProductionClass5.named(int value) : debugOnlyField = value; // Bad: accessing debug-only field in initializer.
  ProductionClass5.debugNamed(this.debugOnlyField);           // Good: inside debug-only constructor.

  final int debugOnlyField;
}

class _ProductionClass1 implements ProductionClassWithFactoryConstructors { }
class _DebugOnlyClass2 implements ProductionClassWithFactoryConstructors {
  _DebugOnlyClass2();
}
class _ProductionClass3 implements ProductionClassWithFactoryConstructors {
  const _ProductionClass3.debugNamed();
  // ignore: unused_element
  const _ProductionClass3.nonDebug() : this.debugNamed(); // Bad: debugNamed is a debug-only constructor.
}

class ProductionClassWithFactoryConstructors {
  // good.
  factory ProductionClassWithFactoryConstructors.named1() = _ProductionClass1;
  // bad.
  factory ProductionClassWithFactoryConstructors.named2() = _DebugOnlyClass2;
  // bad.
  factory ProductionClassWithFactoryConstructors.named3() = _ProductionClass3.debugNamed;
}

void testConstructors() {
  _DebugOnlyClass2();
  const _ProductionClass3.debugNamed();
}
''';

  // ignore: non_constant_identifier_names
  Future<void> test_debug_only_access() async {
    await assertDiagnostics(debugOnlyAccessSource, <ExpectedDiagnostic>[
      lint(628, 19, messageContains: 'debugGlobalVariable accessed outside of an assert.'),
      lint(661, 19, messageContains: 'debugGlobalFunction accessed outside of an assert.'),
      lint(706, 19, messageContains: 'debugGlobalFunction accessed outside of an assert.'),
      lint(766, 19, messageContains: 'debugGlobalFunction accessed outside of an assert.'),
      lint(794, 10, messageContains: 'DebugMixin accessed outside of an assert.'),
      lint(805, 17, messageContains: 'debugStaticMethod accessed outside of an assert.'),
      lint(832, 10, messageContains: 'DebugMixin accessed outside of an assert.'),
      lint(843, 17, messageContains: 'debugStaticMethod accessed outside of an assert.'),
      lint(866, 10, messageContains: 'debugField accessed outside of an assert.'),
      lint(918, 10, messageContains: 'debugField accessed outside of an assert.'),
      lint(968, 11, messageContains: 'debugGetSet accessed outside of an assert.'),
      lint(987, 11, messageContains: 'debugGetSet accessed outside of an assert.'),
      lint(1004, 11, messageContains: 'debugGetSet accessed outside of an assert.'),
      lint(1027, 11, messageContains: 'debugGetSet accessed outside of an assert.'),
      lint(1049, 10, messageContains: 'debugField accessed outside of an assert.'),
      lint(1065, 11, messageContains: 'debugGetSet accessed outside of an assert.'),
      lint(1082, 11, messageContains: 'debugGetSet accessed outside of an assert.'),
      lint(1099, 11, messageContains: 'debugGetSet accessed outside of an assert.'),
      lint(1119, 10, messageContains: 'debugField accessed outside of an assert.'),
      lint(1135, 11, messageContains: 'debugGetSet accessed outside of an assert.'),
      lint(1152, 11, messageContains: 'debugGetSet accessed outside of an assert.'),
      lint(1169, 11, messageContains: 'debugGetSet accessed outside of an assert.'),
      lint(1201, 11, messageContains: 'debugMethod accessed outside of an assert.'),
      lint(1219, 24, messageContains: 'debugOnlyExtensionMethod accessed outside of an assert.'),
      lint(1266, 24, messageContains: 'debugOnlyExtensionMethod accessed outside of an assert.'),
      lint(1295, 13, messageContains: 'DebugOnlyEnum accessed outside of an assert.'),
      lint(1350, 13, messageContains: 'DebugOnlyEnum accessed outside of an assert.'),
      lint(1424, 15, messageContains: 'debugOnlyMethod accessed outside of an assert.'),
      lint(2364, 11, messageContains: 'debugGetSet accessed outside of an assert.'),
      lint(2475, 15, messageContains: '_DebugOnlyClass accessed outside of an assert.'),
      lint(2540, 15, messageContains: '_DebugOnlyClass accessed outside of an assert.'),
    ]);
  }

  // ignore: non_constant_identifier_names
  Future<void> test_debug_only_constructors() async {
    await assertDiagnostics(debugOnlyConstructorsSource, <ExpectedDiagnostic>[
      lint(337, 16, messageContains: 'debugConstructor accessed outside of an assert.'),
      lint(573, 14, messageContains: 'debugOnlyField accessed outside of an assert.'),
      lint(1147, 10, messageContains: 'debugNamed accessed outside of an assert.'),
      lint(1419, 16, messageContains: '_DebugOnlyClass2 accessed outside of an assert.'),
      lint(1525, 10, messageContains: 'debugNamed accessed outside of an assert.'),
      lint(1568, 16, messageContains: '_DebugOnlyClass2 accessed outside of an assert.'),
      lint(1614, 10, messageContains: 'debugNamed accessed outside of an assert.'),
    ]);
  }
}

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AccessDebugMembersOnlyInAssertsTest);
  });
}
