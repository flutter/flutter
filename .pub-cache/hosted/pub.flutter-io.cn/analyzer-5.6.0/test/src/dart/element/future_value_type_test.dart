// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FutureValueTypeTest);
  });
}

@reflectiveTest
class FutureValueTypeTest extends AbstractTypeSystemTest {
  /// futureValueType(`dynamic`) = `dynamic`.
  test_dynamic() {
    _check(dynamicNone, 'dynamic');
  }

  /// futureValueType(Future<`S`>) = `S`, for all `S`.
  test_future() {
    void check(DartType S, String expected) {
      _check(futureNone(S), expected);
    }

    check(intNone, 'int');
    check(intQuestion, 'int?');
    check(intStar, 'int*');

    check(dynamicNone, 'dynamic');
    check(voidNone, 'void');

    check(neverNone, 'Never');
    check(neverQuestion, 'Never?');
    check(neverStar, 'Never*');

    check(objectNone, 'Object');
    check(objectQuestion, 'Object?');
    check(objectStar, 'Object*');
  }

  /// futureValueType(FutureOr<`S`>) = `S`, for all `S`.
  test_futureOr() {
    void check(DartType S, String expected) {
      _check(futureOrNone(S), expected);
    }

    check(intNone, 'int');
    check(intQuestion, 'int?');
    check(intStar, 'int*');

    check(dynamicNone, 'dynamic');
    check(voidNone, 'void');

    check(neverNone, 'Never');
    check(neverQuestion, 'Never?');
    check(neverStar, 'Never*');

    check(objectNone, 'Object');
    check(objectQuestion, 'Object?');
    check(objectStar, 'Object*');
  }

  /// Otherwise, for all `S`, futureValueType(`S`) = `Object?`.
  test_other() {
    _check(objectNone, 'Object?');
    _check(intNone, 'Object?');
  }

  /// futureValueType(`S?`) = futureValueType(`S`), for all `S`.
  test_suffix_question() {
    _check(intQuestion, 'Object?');

    _check(futureQuestion(intNone), 'int');
    _check(futureQuestion(intQuestion), 'int?');
    _check(futureQuestion(intStar), 'int*');

    _check(futureOrQuestion(intNone), 'int');
    _check(futureOrQuestion(intQuestion), 'int?');
    _check(futureOrQuestion(intStar), 'int*');

    _check(futureQuestion(objectNone), 'Object');
    _check(futureQuestion(objectQuestion), 'Object?');
    _check(futureQuestion(objectStar), 'Object*');

    _check(futureQuestion(dynamicNone), 'dynamic');
    _check(futureQuestion(voidNone), 'void');
  }

  /// futureValueType(`S*`) = futureValueType(`S`), for all `S`.
  test_suffix_star() {
    _check(intStar, 'Object?');

    _check(futureStar(intNone), 'int');
    _check(futureStar(intQuestion), 'int?');
    _check(futureStar(intStar), 'int*');

    _check(futureOrStar(intNone), 'int');
    _check(futureOrStar(intQuestion), 'int?');
    _check(futureOrStar(intStar), 'int*');

    _check(futureStar(objectNone), 'Object');
    _check(futureStar(objectQuestion), 'Object?');
    _check(futureStar(objectStar), 'Object*');

    _check(futureStar(dynamicNone), 'dynamic');
    _check(futureStar(voidNone), 'void');
  }

  /// futureValueType(`void`) = `void`.
  test_void() {
    _check(voidNone, 'void');
  }

  void _check(DartType T, String expected) {
    var result = typeSystem.futureValueType(T);
    expect(
      result.getDisplayString(withNullability: true),
      expected,
    );
  }
}
