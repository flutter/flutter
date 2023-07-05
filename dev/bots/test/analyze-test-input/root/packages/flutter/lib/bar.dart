// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'debug_only.dart';

//class _DebugOnly {
//  const _DebugOnly();
//}
//
//const _DebugOnly _debugOnly = _DebugOnly();
//const bool kDebugMode = bool.fromEnvironment('test-only');
const String _debugAssert = '';
//
//class Foo {
//  @_debugOnly
//  final Map<String, String>? foo = kDebugMode ? <String, String>{} : null;
//
//  @_debugOnly
//  final Map<String, String>? bar = kDebugMode ? null : <String, String>{};
//}

/// Simply avoid this
/// and simply do that.

// A class extends a debug class is also a debug class (because of the default
// constructor).
class ProductionClass11 extends ClassFromDebugLibWithNamedConstructor {
  ProductionClass11() : super.constructor(); // bad: debug only constructor
}

class ProductionClass21 extends ClassFromDebugLibWithImplicitDefaultConstructor {
  ProductionClass21();
}

class ProductionClass22 extends ClassFromDebugLibWithImplicitDefaultConstructor { }

class ProductionClass31 extends ClassFromDebugLibWithExplicitDefaultConstructor {
  ProductionClass31();
}

class ProductionClass32 extends ClassFromDebugLibWithExplicitDefaultConstructor { }

class ProductionClass33 implements ClassFromDebugLibWithExplicitDefaultConstructor { }

class _DebugOnlyClass1 implements ProductionClassWithFactoryConstructors { }
@_debugAssert
class _DebugOnlyClass2 implements ProductionClassWithFactoryConstructors {
  _DebugOnlyClass2();
}
class _DebugOnlyClass3 implements ProductionClassWithFactoryConstructors {
  @_debugAssert
  const _DebugOnlyClass3.named();
}

class ProductionClassWithFactoryConstructors {
  // good.
  factory ProductionClassWithFactoryConstructors.named1() = _DebugOnlyClass1;
  // bad.
  factory ProductionClassWithFactoryConstructors.named2() = _DebugOnlyClass2;
  // bad.
  factory ProductionClassWithFactoryConstructors.named3() = _DebugOnlyClass3.named;
}

void takeAnything(Object? input) { }

void testConstructors() {
  // With named constructor.
  ProductionClass11();
  // With synthesized default constructor.
  ProductionClass21(); // good: the constructor isn't defined by the super class.
  ProductionClass22(); // good: the constructor isn't defined by the super class.
  // With explicit default constructor.
  ProductionClass31(); // bad: the constructor is defined by the super class thus marked as debug-only.
  takeAnything(ProductionClass31.new); // Also bad for the same reason.
  ProductionClass32(); // bad: the constructor is defined by the super class thus marked as debug-only.
  ProductionClass33(); // good: the debug-only constructor is not inherited.

}

final ProductionClass x = ProductionClass();
ProductionClass? xx = null;
ProductionClass y = ProductionClass();

void badDebugAssertAccess() {
  globalVaraibleFromDebugLib += 'test';
  globalFunctionFromDebugLib();
  void Function() f = globalFunctionFromDebugLib;
  f = globalFunctionFromDebugLib.call;
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

  final ProductionClass x = ProductionClass()
    ..run();
}

@_debugAssert
class _DebugOnlyClass extends BaseClass {
  void debugOnlyMemberMethod() {}
}

class BaseClass {
  void run() { }
}

class ProductionClass extends _DebugOnlyClass with MixinFromDebugLib {
  @override
  ProductionClass operator +(ProductionClass rhs) {
    return ProductionClass()
      ..debugGetSet = debugGetSet + rhs.debugGetSet
      ..fieldFromDebugLib = fieldFromDebugLib + rhs.fieldFromDebugLib;
  }
}
