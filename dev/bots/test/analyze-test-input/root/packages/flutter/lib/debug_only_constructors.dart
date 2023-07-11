// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'debug_only_lib.dart';

const Object debugAssert = Object();

class ProductionClass11 extends ClassFromDebugLibWithNamedConstructor {
  ProductionClass11() : super.constructor(); // bad: debug-only constructor invoked
}

class ProductionClass21 extends ClassFromDebugLibWithImplicitDefaultConstructor {
  ProductionClass21(); // Good: super() is synthesized thus not considered debug-only.
}

class ProductionClass22 extends ClassFromDebugLibWithImplicitDefaultConstructor { }

class ProductionClass31 extends ClassFromDebugLibWithExplicitDefaultConstructor {
  ProductionClass31();       // Bad: super() is not synthesized.
  ProductionClass31.named(); // Bad: super() is not synthesized.
}

class ProductionClass32 extends ClassFromDebugLibWithExplicitDefaultConstructor { }

class ProductionClass41 extends ClassFromDebugLibWithExplicitConstructorAndFormalParameters {
  ProductionClass41.named(super.value); // Bad: super(int value) is not synthesized.
}

class ProductionClass5 {
  ProductionClass5(this.debugOnlyField);                      // Bad: accessing debug-only field.
  ProductionClass5.named(int value) : debugOnlyField = value; // Bad: accessing debug-only field.

  @debugAssert
  final int debugOnlyField;
}

class ProductionClass33 implements ClassFromDebugLibWithExplicitDefaultConstructor { }

class _DebugOnlyClass1 implements ProductionClassWithFactoryConstructors { }
@debugAssert
class _DebugOnlyClass2 implements ProductionClassWithFactoryConstructors {
  _DebugOnlyClass2();
}
class _DebugOnlyClass3 implements ProductionClassWithFactoryConstructors {
  @debugAssert
  const _DebugOnlyClass3.named();
  // ignore: unused_element
  const _DebugOnlyClass3.nonDebug() : this.named(); // Bad: named is a debug-only constructor.
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
  ProductionClass32(); // bad: the constructor is defined by the super class thus marked as debug-only.
  takeAnything(ProductionClass32.new); // Also bad for the same reason.
  ProductionClass33(); // good: the debug-only constructor is not inherited.
}
