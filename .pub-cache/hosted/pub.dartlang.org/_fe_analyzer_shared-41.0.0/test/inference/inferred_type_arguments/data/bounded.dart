// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Bound {}

class BoundedGenericClass<A extends Bound?, B extends Bound> {}

A boundedGenericA<A extends Bound?>() => throw '';
B boundedGenericB<B extends Bound>() => throw '';

class GenericClass<X extends Bound?, Y extends Bound> {
  method() {
    new BoundedGenericClass/*<Bound?,Bound>*/();
    BoundedGenericClass<X, Y> class1a = new BoundedGenericClass/*<Never,Y>*/();
    BoundedGenericClass<Y, Y> class1b = new BoundedGenericClass/*<Y,Y>*/();
    BoundedGenericClass<Bound?, Bound> class1c =
        new BoundedGenericClass/*<Bound?,Bound>*/();
    BoundedGenericClass<Bound, Bound> class1d =
        new BoundedGenericClass/*<Bound,Bound>*/();

    boundedGenericA/*<Bound?>*/();
    X x1 = boundedGenericA/*<Never>*/();
    Y y1 = boundedGenericA/*<Y>*/();
    Bound b1 = boundedGenericA/*<Bound>*/();
    Bound? b2 = boundedGenericA/*<Bound?>*/();

    boundedGenericB/*<Bound>*/();
    Y y2 = boundedGenericB/*<Y>*/();
    Bound b3 = boundedGenericB/*<Bound>*/();
  }
}

genericMethod<X extends Bound?, Y extends Bound>() {
  new BoundedGenericClass/*<Bound?,Bound>*/();
  BoundedGenericClass<X, Y> class1a = new BoundedGenericClass/*<Never,Y>*/();
  BoundedGenericClass<Y, Y> class1b = new BoundedGenericClass/*<Y,Y>*/();
  BoundedGenericClass<Bound?, Bound> class1c =
      new BoundedGenericClass/*<Bound?,Bound>*/();
  BoundedGenericClass<Bound, Bound> class1d =
      new BoundedGenericClass/*<Bound,Bound>*/();

  boundedGenericA/*<Bound?>*/();
  X x1 = boundedGenericA/*<Never>*/();
  Y y1 = boundedGenericA/*<Y>*/();
  Bound b1 = boundedGenericA/*<Bound>*/();
  Bound? b2 = boundedGenericA/*<Bound?>*/();

  boundedGenericB/*<Bound>*/();
  Y y2 = boundedGenericB/*<Y>*/();
  Bound b3 = boundedGenericB/*<Bound>*/();
}
