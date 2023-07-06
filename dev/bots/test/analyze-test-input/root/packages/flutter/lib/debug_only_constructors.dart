// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'debug_only.dart';

const Object _debugAssert = Object();

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
