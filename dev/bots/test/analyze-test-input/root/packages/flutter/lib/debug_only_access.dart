// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'debug_only_lib.dart';

const Null debugAssert = null;

final ProductionClassWithDebugOnlyMixin x = ProductionClassWithDebugOnlyMixin();
ProductionClassWithDebugOnlyMixin? xx;
ProductionClassWithDebugOnlyMixin y = ProductionClassWithDebugOnlyMixin();
void takeAnything(Object? input) { }

void badDebugAssertAccess() {
  globalVaraibleFromDebugLib += 'test';
  globalFunctionFromDebugLib();
  void Function() f = globalFunctionFromDebugLib; // ignore: unused_local_variable
  f = globalFunctionFromDebugLib.call;
  MixinFromDebugLib.staticMethodFromDebugLib();
  f = MixinFromDebugLib.staticMethodFromDebugLib;
  x.fieldFromDebugLib; // ignore: unnecessary_statements
  xx?.fieldFromDebugLib; // ignore: unnecessary_statements
  x.debugGetSet;
  xx?.debugGetSet;
  x.debugGetSet = 2;
  xx?.debugGetSet = 2;
  x..fieldFromDebugLib += x.debugGetSet
   ..debugGetSet += x.debugGetSet;
  xx?..fieldFromDebugLib += x.debugGetSet
   ..debugGetSet += x.debugGetSet;
  takeAnything(xx?.methodFromDebugLib);
  x.debugOnlyExtensionMethod();
  takeAnything(xx?.debugOnlyExtensionMethod);
  DebugOnlyEnum.foo; // ignore: unnecessary_statements
  DebugOnlyEnum.values; // ignore: unnecessary_statements
  RegularEnum.foo.debugOnlyMethod();

  // Overridden Operators
  x + x; // ignore: unnecessary_statements
  xx! + xx!; // ignore: unnecessary_statements
  y += x;
  y += xx!;
  ~x; // ignore: unnecessary_statements
  ~xx!; // ignore: unnecessary_statements
  x[x.debugGetSet]; // ignore: unnecessary_statements
  xx?[x.debugGetSet]; // ignore: unnecessary_statements
}

/// Yours truly [globalVaraibleFromDebugLib] from the comment section with love.
void goodDebugAssertAccess() {
  assert(() {
    final _DebugOnlyClass debugObject = _DebugOnlyClass();
    debugObject
      .debugOnlyMemberMethod();
    final void Function() f = debugObject.debugOnlyMemberMethod;
    f();
    return true;
  }());

  final ProductionClassWithDebugOnlyMixin x = ProductionClassWithDebugOnlyMixin() // ignore: unused_local_variable
    ..run();
    RegularEnum.foo; // ignore: unnecessary_statements
}

mixin class BaseClass {
  void run() { }
  void stop() { }

  int get value => 0;

  int operator ~() => ~value;
}

@debugAssert
class _DebugOnlyClass extends BaseClass {
  void debugOnlyMemberMethod() {}
}

class ProductionClassWithDebugOnlyMixin extends _DebugOnlyClass with MixinFromDebugLib {
  @override
  ProductionClassWithDebugOnlyMixin operator +(ProductionClassWithDebugOnlyMixin rhs) {
    return ProductionClassWithDebugOnlyMixin()
      ..debugGetSet = debugGetSet + rhs.debugGetSet
      ..fieldFromDebugLib = fieldFromDebugLib + rhs.fieldFromDebugLib;
  }
}

mixin MixinOnBaseClass implements BaseClass {
  void runAndStop() {
    run();
    stop();
  }

  @debugAssert
  @override
  int get value => -1;         // bad annotation.

  @debugAssert
  @override
  int operator ~() => ~value;  // bad annotation.
}

class ClassWithBadAnnotation1 extends BaseClass with MixinOnBaseClass {
  @debugAssert
  @override
  void run() {  }             // bad annotation.

  void run1() {  }
}

class ClassWithBadAnnotation2 with MixinOnBaseClass {
  @debugAssert
  @override
  void run() {  }             // bad annotation.

  @override
  void stop() {  }

  @override
  int get value => -1;
}

@debugAssert
extension DebugOnly on ProductionClassWithDebugOnlyMixin {
  void debugOnlyExtensionMethod() {  }
}

@debugAssert
enum DebugOnlyEnum with BaseClass {
  foo
}

@debugAssert
mixin DebugOnlyMixinOnRegularEnum {
  void debugOnlyMethod() {}
}

enum RegularEnum with DebugOnlyMixinOnRegularEnum {
  foo
}
