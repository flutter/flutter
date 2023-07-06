// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'debug_only.dart';

const Null _debugAssert = null;

final ProductionClassWithDebugOnlyMixin x = ProductionClassWithDebugOnlyMixin();
ProductionClassWithDebugOnlyMixin? xx = null;
ProductionClassWithDebugOnlyMixin y = ProductionClassWithDebugOnlyMixin();
void takeAnything(Object? input) { }

void badDebugAssertAccess() {
  globalVaraibleFromDebugLib += 'test';
  globalFunctionFromDebugLib();
  void Function() f = globalFunctionFromDebugLib;
  f = globalFunctionFromDebugLib.call;
  MixinFromDebugLib.staticMethodFromDebugLib();
  f = MixinFromDebugLib.staticMethodFromDebugLib;
  x.fieldFromDebugLib;
  xx?.fieldFromDebugLib;
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

  // Overridden Operators
  x + x;
  xx! + xx!;
  y += x;
  y += xx!;
  ~x;
  ~xx!;
  x[x.debugGetSet];
  xx?[x.debugGetSet];
}

void goodDebugAssertAccess() {
  assert(() {
    final _DebugOnlyClass debugObject = _DebugOnlyClass();
    debugObject
      ..debugOnlyMemberMethod();
    void Function() f = debugObject.debugOnlyMemberMethod;
    f();
    return true;
  }());

  final ProductionClassWithDebugOnlyMixin x = ProductionClassWithDebugOnlyMixin()
    ..run();
}

class BaseClass {
  void run() { }
  void stop() { }

  int get value => 0;

  int operator ~() => ~value;
}

@_debugAssert
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

  @_debugAssert
  @override
  int get value => -1; // bad.

  @_debugAssert
  @override
  int operator ~() => ~value;
}

class ClassWithBadAnnotation1 extends BaseClass with MixinOnBaseClass {
  @_debugAssert
  @override
  void run() {  }

  void run1() {  }
}

class ClassWithBadAnnotation2 with MixinOnBaseClass {
  @_debugAssert
  @override
  void run() {  }

  @override
  void stop() {  }

  @override
  int get value => -1;
}

@_debugAssert
extension DebugOnly on ProductionClassWithDebugOnlyMixin {
  void debugOnlyExtensionMethod() {  }
}
