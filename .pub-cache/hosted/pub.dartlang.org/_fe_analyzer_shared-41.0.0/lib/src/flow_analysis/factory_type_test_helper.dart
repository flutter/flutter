// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class FactorTypeTestMixin<Type> {
  Type futureNone(Type type);
  Type futureOrNone(Type type);

  Type get dynamicType;
  Type get intNone;
  Type get intQuestion;
  Type get intStar;
  Type get numNone;
  Type get numQuestion;
  Type get numStar;
  Type get objectNone;
  Type get objectQuestion;
  Type get objectStar;
  Type get stringNone;
  Type get stringQuestion;
  Type get stringStar;
  Type get nullNone;
  Type get voidType;

  void test_dynamic() {
    check(dynamicType, intNone, 'dynamic');
  }

  void test_futureOr() {
    check(futureOrNone(intNone), intNone, 'Future<int>');
    check(futureOrNone(intNone), futureNone(intNone), 'int');

    check(futureOrNone(intQuestion), intNone, 'FutureOr<int?>');
    check(futureOrNone(intQuestion), futureNone(intNone), 'FutureOr<int?>');
    check(futureOrNone(intQuestion), intQuestion, 'Future<int?>');
    check(futureOrNone(intQuestion), futureNone(intQuestion), 'int?');
    check(futureOrNone(intQuestion), intStar, 'Future<int?>');
    check(futureOrNone(intQuestion), futureNone(intStar), 'int?');

    check(futureOrNone(intNone), numNone, 'Future<int>');
    check(futureOrNone(intNone), futureNone(numNone), 'int');
  }

  void test_object() {
    check(objectNone, objectNone, 'Never');
    check(objectNone, objectQuestion, 'Never');
    check(objectNone, objectStar, 'Never');

    check(objectNone, intNone, 'Object');
    check(objectNone, intQuestion, 'Object');
    check(objectNone, intStar, 'Object');

    check(objectQuestion, objectNone, 'Never?');
    check(objectQuestion, objectQuestion, 'Never');
    check(objectQuestion, objectStar, 'Never');

    check(objectQuestion, intNone, 'Object?');
    check(objectQuestion, intQuestion, 'Object');
    check(objectQuestion, intStar, 'Object');
  }

  test_subtype() {
    check(intNone, intNone, 'Never');
    check(intNone, intQuestion, 'Never');
    check(intNone, intStar, 'Never');

    check(intQuestion, intNone, 'Never?');
    check(intQuestion, intQuestion, 'Never');
    check(intQuestion, intStar, 'Never');

    check(intStar, intNone, 'Never');
    check(intStar, intQuestion, 'Never');
    check(intStar, intStar, 'Never');

    check(intNone, numNone, 'Never');
    check(intNone, numQuestion, 'Never');
    check(intNone, numStar, 'Never');

    check(intQuestion, numNone, 'Never?');
    check(intQuestion, numQuestion, 'Never');
    check(intQuestion, numStar, 'Never');

    check(intStar, numNone, 'Never');
    check(intStar, numQuestion, 'Never');
    check(intStar, numStar, 'Never');

    check(intNone, nullNone, 'int');
    check(intQuestion, nullNone, 'int');
    check(intStar, nullNone, 'int');

    check(intNone, stringNone, 'int');
    check(intQuestion, stringNone, 'int?');
    check(intStar, stringNone, 'int*');

    check(intNone, stringQuestion, 'int');
    check(intQuestion, stringQuestion, 'int');
    check(intStar, stringQuestion, 'int');

    check(intNone, stringStar, 'int');
    check(intQuestion, stringStar, 'int');
    check(intStar, stringStar, 'int');
  }

  void test_void() {
    check(voidType, intNone, 'void');
  }

  Type factor(Type T, Type S);

  void expect(Type T, Type S, String actualResult, String expectedResult);

  void check(Type T, Type S, String expectedStr) {
    Type result = factor(T, S);
    String resultStr = typeString(result);

    expect(T, S, resultStr, expectedStr);
  }

  String typeString(Type type);
}
