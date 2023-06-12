// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_visitor.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/element/type_visitor.dart';
import 'package:analyzer/src/dart/resolver/variance.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BoundsHelperPredicatesTest);
    defineReflectiveTests(LowerBoundTest);
    defineReflectiveTests(UpperBound_FunctionTypes_Test);
    defineReflectiveTests(UpperBound_InterfaceTypes_Test);
    defineReflectiveTests(UpperBoundTest);
  });
}

@reflectiveTest
class BoundsHelperPredicatesTest extends _BoundsTestBase {
  static final Map<String, StackTrace> _isMoreBottomChecked = {};
  static final Map<String, StackTrace> _isMoreTopChecked = {};

  void isBottom(DartType type) {
    expect(typeSystem.isBottom(type), isTrue, reason: _typeString(type));
  }

  void isMoreBottom(DartType T, DartType S) {
    _assertIsBottomOrNull(T);
    _assertIsBottomOrNull(S);

    var str = _typeString(T) + ' vs ' + _typeString(S);
    _checkUniqueTypeStr(_isMoreBottomChecked, str);

    expect(typeSystem.isMoreBottom(T, S), isTrue, reason: str);
  }

  void isMoreTop(DartType T, DartType S) {
    _assertIsTopOrObject(T);
    _assertIsTopOrObject(S);

    var str = _typeString(T) + ' vs ' + _typeString(S);
    _checkUniqueTypeStr(_isMoreTopChecked, str);

    expect(typeSystem.isMoreTop(T, S), isTrue, reason: str);
  }

  void isNotBottom(DartType type) {
    expect(typeSystem.isBottom(type), isFalse, reason: _typeString(type));
  }

  void isNotMoreBottom(DartType T, DartType S) {
    _assertIsBottomOrNull(T);
    _assertIsBottomOrNull(S);

    var str = _typeString(T) + ' vs ' + _typeString(S);
    _checkUniqueTypeStr(_isMoreBottomChecked, str);

    expect(typeSystem.isMoreBottom(T, S), isFalse, reason: str);
  }

  void isNotMoreTop(DartType T, DartType S) {
    _assertIsTopOrObject(T);
    _assertIsTopOrObject(S);

    var str = _typeString(T) + ' vs ' + _typeString(S);
    _checkUniqueTypeStr(_isMoreTopChecked, str);

    expect(typeSystem.isMoreTop(T, S), isFalse, reason: str);
  }

  void isNotNull(DartType type) {
    expect(typeSystem.isNull(type), isFalse, reason: _typeString(type));
  }

  void isNotObject(DartType type) {
    expect(typeSystem.isObject(type), isFalse, reason: _typeString(type));
  }

  void isNotTop(DartType type) {
    expect(typeSystem.isTop(type), isFalse, reason: _typeString(type));
  }

  void isNull(DartType type) {
    expect(typeSystem.isNull(type), isTrue, reason: _typeString(type));
  }

  void isObject(DartType type) {
    expect(typeSystem.isObject(type), isTrue, reason: _typeString(type));
  }

  void isTop(DartType type) {
    expect(typeSystem.isTop(type), isTrue, reason: _typeString(type));
  }

  test_isBottom() {
    TypeParameterElement T;

    // BOTTOM(Never) is true
    isBottom(neverNone);
    isNotBottom(neverQuestion);
    isBottom(neverStar);

    // BOTTOM(X&T) is true iff BOTTOM(T)
    T = typeParameter('T', bound: objectQuestion);

    isBottom(promotedTypeParameterTypeNone(T, neverNone));
    isBottom(promotedTypeParameterTypeQuestion(T, neverNone));
    isBottom(promotedTypeParameterTypeStar(T, neverNone));

    isNotBottom(promotedTypeParameterTypeNone(T, neverQuestion));
    isNotBottom(promotedTypeParameterTypeQuestion(T, neverQuestion));
    isNotBottom(promotedTypeParameterTypeStar(T, neverQuestion));

    // BOTTOM(X extends T) is true iff BOTTOM(T)
    T = typeParameter('T', bound: neverNone);
    isBottom(typeParameterTypeNone(T));
    isBottom(typeParameterTypeQuestion(T));
    isBottom(typeParameterTypeStar(T));

    T = typeParameter('T', bound: neverQuestion);
    isNotBottom(typeParameterTypeNone(T));
    isNotBottom(typeParameterTypeQuestion(T));
    isNotBottom(typeParameterTypeStar(T));

    // BOTTOM(T) is false otherwise
    isNotBottom(dynamicNone);
    isNotBottom(voidNone);

    isNotBottom(objectNone);
    isNotBottom(objectQuestion);
    isNotBottom(objectStar);

    isNotBottom(intNone);
    isNotBottom(intQuestion);
    isNotBottom(intStar);

    T = typeParameter('T', bound: numNone);
    isNotBottom(typeParameterTypeNone(T));
    isNotBottom(typeParameterTypeQuestion(T));
    isNotBottom(typeParameterTypeStar(T));

    T = typeParameter('T', bound: numStar);
    isNotBottom(typeParameterTypeNone(T));
    isNotBottom(typeParameterTypeQuestion(T));
    isNotBottom(typeParameterTypeStar(T));

    isNotBottom(promotedTypeParameterTypeNone(T, intNone));
    isNotBottom(promotedTypeParameterTypeQuestion(T, intNone));
    isNotBottom(promotedTypeParameterTypeStar(T, intNone));
  }

  test_isMoreBottom() {
    // MOREBOTTOM(Never, T) = true
    isMoreBottom(neverNone, neverNone);
    isMoreBottom(neverNone, neverQuestion);
    isMoreBottom(neverNone, neverStar);

    isMoreBottom(neverNone, nullNone);
    isMoreBottom(neverNone, nullQuestion);
    isMoreBottom(neverNone, nullStar);

    // MOREBOTTOM(T, Never) = false
    isNotMoreBottom(neverQuestion, neverNone);
    isNotMoreBottom(neverStar, neverNone);

    isNotMoreBottom(nullNone, neverNone);
    isNotMoreBottom(nullQuestion, neverNone);
    isNotMoreBottom(nullStar, neverNone);

    // MOREBOTTOM(Null, T) = true
    isMoreBottom(nullNone, neverQuestion);
    isMoreBottom(nullNone, neverStar);

    isMoreBottom(nullNone, nullNone);
    isMoreBottom(nullNone, nullQuestion);
    isMoreBottom(nullNone, nullStar);

    // MOREBOTTOM(T, Null) = false
    isNotMoreBottom(neverQuestion, nullNone);
    isNotMoreBottom(neverStar, nullNone);

    isNotMoreBottom(nullQuestion, nullNone);
    isNotMoreBottom(nullStar, nullNone);

    // MOREBOTTOM(T?, S?) = MOREBOTTOM(T, S)
    isMoreBottom(neverQuestion, nullQuestion);
    isNotMoreBottom(nullQuestion, neverQuestion);

    // MOREBOTTOM(T, S?) = true
    isMoreBottom(neverStar, nullQuestion);
    isMoreBottom(nullStar, neverQuestion);

    // MOREBOTTOM(T?, S) = false
    isNotMoreBottom(neverQuestion, nullStar);
    isNotMoreBottom(nullQuestion, neverStar);

    // MOREBOTTOM(T*, S*) = MOREBOTTOM(T, S)
    isMoreBottom(neverStar, nullStar);
    isNotMoreBottom(nullStar, neverStar);

    // MOREBOTTOM(T, S*) = true
    isMoreBottom(
      typeParameterTypeNone(
        typeParameter('S', bound: neverNone),
      ),
      nullStar,
    );

    // MOREBOTTOM(T*, S) = false
    isNotMoreBottom(
      nullStar,
      typeParameterTypeNone(
        typeParameter('S', bound: neverNone),
      ),
    );

    // MOREBOTTOM(X&T, Y&S) = MOREBOTTOM(T, S)
    isMoreBottom(
      promotedTypeParameterTypeNone(
        typeParameter('T', bound: objectQuestion),
        neverNone,
      ),
      promotedTypeParameterTypeQuestion(
        typeParameter('S', bound: objectQuestion),
        neverNone,
      ),
    );

    // MOREBOTTOM(X&T, S) = true
    isMoreBottom(
      promotedTypeParameterTypeNone(
        typeParameter('T', bound: objectQuestion),
        neverNone,
      ),
      typeParameterTypeNone(
        typeParameter('S', bound: neverNone),
      ),
    );

    // MOREBOTTOM(T, X&S) = false
    isNotMoreBottom(
      typeParameterTypeNone(
        typeParameter('T', bound: neverNone),
      ),
      promotedTypeParameterTypeNone(
        typeParameter('S', bound: objectQuestion),
        neverNone,
      ),
    );

    // MOREBOTTOM(X extends T, Y extends S) = MOREBOTTOM(T, S)
    isMoreBottom(
      typeParameterTypeNone(
        typeParameter('T', bound: neverNone),
      ),
      typeParameterTypeQuestion(
        typeParameter('S', bound: neverNone),
      ),
    );
  }

  test_isMoreTop() {
    // MORETOP(void, T) = true
    isMoreTop(voidNone, voidNone);
    isMoreTop(voidNone, dynamicNone);
    isMoreTop(voidNone, objectNone);
    isMoreTop(voidNone, objectQuestion);
    isMoreTop(voidNone, objectStar);
    isMoreTop(voidNone, futureOrNone(objectNone));
    isMoreTop(voidNone, futureOrNone(objectQuestion));
    isMoreTop(voidNone, futureOrNone(objectStar));

    // MORETOP(T, void) = false
    isNotMoreTop(dynamicNone, voidNone);
    isNotMoreTop(objectNone, voidNone);
    isNotMoreTop(objectQuestion, voidNone);
    isNotMoreTop(objectStar, voidNone);
    isNotMoreTop(futureOrNone(objectNone), voidNone);
    isNotMoreTop(futureOrNone(objectQuestion), voidNone);
    isNotMoreTop(futureOrNone(objectStar), voidNone);

    // MORETOP(dynamic, T) = true
    isMoreTop(dynamicNone, dynamicNone);
    isMoreTop(dynamicNone, objectNone);
    isMoreTop(dynamicNone, objectQuestion);
    isMoreTop(dynamicNone, objectStar);
    isMoreTop(dynamicNone, futureOrNone(objectNone));
    isMoreTop(dynamicNone, futureOrNone(objectQuestion));
    isMoreTop(dynamicNone, futureOrNone(objectStar));

    // MORETOP(T, dynamic) = false
    isNotMoreTop(objectNone, dynamicNone);
    isNotMoreTop(objectQuestion, dynamicNone);
    isNotMoreTop(objectStar, dynamicNone);
    isNotMoreTop(futureOrNone(objectNone), dynamicNone);
    isNotMoreTop(futureOrNone(objectQuestion), dynamicNone);
    isNotMoreTop(futureOrNone(objectStar), dynamicNone);

    // MORETOP(Object, T) = true
    isMoreTop(objectNone, objectNone);
    isMoreTop(objectNone, objectQuestion);
    isMoreTop(objectNone, objectStar);
    isMoreTop(objectNone, futureOrNone(objectNone));
    isMoreTop(objectNone, futureOrQuestion(objectNone));
    isMoreTop(objectNone, futureOrStar(objectNone));

    // MORETOP(T, Object) = false
    isNotMoreTop(objectQuestion, objectNone);
    isNotMoreTop(objectStar, objectNone);
    isNotMoreTop(futureOrNone(objectNone), objectNone);
    isNotMoreTop(futureOrQuestion(objectNone), objectNone);
    isNotMoreTop(futureOrStar(objectNone), objectNone);

    // MORETOP(T*, S*) = MORETOP(T, S)
    isMoreTop(objectStar, objectStar);
    isMoreTop(objectStar, futureOrStar(objectNone));
    isMoreTop(objectStar, futureOrStar(objectQuestion));
    isMoreTop(objectStar, futureOrStar(objectStar));
    isMoreTop(futureOrStar(objectNone), futureOrStar(objectNone));

    // MORETOP(T, S*) = true
    isMoreTop(futureOrNone(objectNone), futureOrStar(voidNone));
    isMoreTop(futureOrNone(objectNone), futureOrStar(dynamicNone));
    isMoreTop(futureOrNone(objectNone), futureOrStar(objectNone));
    isMoreTop(futureOrQuestion(objectNone), futureOrStar(voidNone));
    isMoreTop(futureOrQuestion(objectNone), futureOrStar(dynamicNone));
    isMoreTop(futureOrQuestion(objectNone), futureOrStar(objectNone));

    // MORETOP(T*, S) = false
    isNotMoreTop(futureOrStar(voidNone), futureOrNone(objectNone));
    isNotMoreTop(futureOrStar(dynamicNone), futureOrNone(objectNone));
    isNotMoreTop(futureOrStar(objectNone), futureOrNone(objectNone));
    isNotMoreTop(futureOrStar(voidNone), futureOrQuestion(objectNone));
    isNotMoreTop(futureOrStar(dynamicNone), futureOrQuestion(objectNone));
    isNotMoreTop(futureOrStar(objectNone), futureOrQuestion(objectNone));

    // MORETOP(T?, S?) = MORETOP(T, S)
    isMoreTop(objectQuestion, objectQuestion);
    isMoreTop(futureOrQuestion(voidNone), futureOrQuestion(voidNone));
    isMoreTop(futureOrQuestion(voidNone), futureOrQuestion(dynamicNone));
    isMoreTop(futureOrQuestion(voidNone), futureOrQuestion(objectNone));

    // MORETOP(T, S?) = true
    isMoreTop(futureOrNone(objectNone), futureOrQuestion(voidNone));
    isMoreTop(futureOrNone(objectNone), futureOrQuestion(dynamicNone));
    isMoreTop(futureOrNone(objectNone), futureOrQuestion(objectNone));

    // MORETOP(T?, S) = false
    isNotMoreTop(futureOrQuestion(voidNone), futureOrNone(objectNone));
    isNotMoreTop(futureOrQuestion(dynamicNone), futureOrNone(objectNone));
    isNotMoreTop(futureOrQuestion(objectNone), futureOrNone(objectNone));

    // MORETOP(FutureOr<T>, FutureOr<S>) = MORETOP(T, S)
    isMoreTop(futureOrNone(voidNone), futureOrNone(voidNone));
    isMoreTop(futureOrNone(voidNone), futureOrNone(dynamicNone));
    isMoreTop(futureOrNone(voidNone), futureOrNone(objectNone));
    isNotMoreTop(futureOrNone(dynamicNone), futureOrNone(voidNone));
    isNotMoreTop(futureOrNone(objectNone), futureOrNone(voidNone));
  }

  test_isNull() {
    // NULL(Null) is true
    isNull(nullNone);

    // NULL(T?) is true iff NULL(T) or BOTTOM(T)
    isNull(nullQuestion);
    isNull(neverQuestion);
    isNull(
      typeParameterTypeQuestion(
        typeParameter('T', bound: neverNone),
      ),
    );

    // NULL(T*) is true iff NULL(T) or BOTTOM(T)
    isNull(nullStar);
    isNull(neverStar);
    isNull(
      typeParameterTypeStar(
        typeParameter('T', bound: neverNone),
      ),
    );

    // NULL(T) is false otherwise
    isNotNull(dynamicNone);
    isNotNull(voidNone);

    isNotNull(objectNone);
    isNotNull(objectQuestion);
    isNotNull(objectStar);

    isNotNull(intNone);
    isNotNull(intQuestion);
    isNotNull(intStar);

    isNotNull(futureOrNone(nullNone));
    isNotNull(futureOrNone(nullQuestion));
    isNotNull(futureOrNone(nullStar));

    isNotNull(futureOrQuestion(nullNone));
    isNotNull(futureOrQuestion(nullQuestion));
    isNotNull(futureOrQuestion(nullStar));

    isNotNull(futureOrStar(nullNone));
    isNotNull(futureOrStar(nullQuestion));
    isNotNull(futureOrStar(nullStar));
  }

  test_isObject() {
    // OBJECT(Object) is true
    isObject(objectNone);
    isNotObject(objectQuestion);
    isNotObject(objectStar);

    // OBJECT(FutureOr<T>) is OBJECT(T)
    isObject(futureOrNone(objectNone));
    isNotObject(futureOrNone(objectQuestion));
    isNotObject(futureOrNone(objectStar));

    isNotObject(futureOrQuestion(objectNone));
    isNotObject(futureOrQuestion(objectQuestion));
    isNotObject(futureOrQuestion(objectStar));

    isNotObject(futureOrStar(objectNone));
    isNotObject(futureOrStar(objectQuestion));
    isNotObject(futureOrStar(objectStar));

    // OBJECT(T) is false otherwise
    isNotObject(dynamicNone);
    isNotObject(voidNone);
    isNotObject(intNone);
  }

  test_isTop() {
    // TOP(T?) is true iff TOP(T) or OBJECT(T)
    isTop(objectQuestion);
    isTop(futureOrQuestion(dynamicNone));
    isTop(futureOrQuestion(voidNone));

    isTop(futureOrQuestion(objectNone));
    isTop(futureOrQuestion(objectQuestion));
    isTop(futureOrQuestion(objectStar));

    isNotTop(futureOrQuestion(intNone));
    isNotTop(futureOrQuestion(intQuestion));
    isNotTop(futureOrQuestion(intStar));

    // TOP(T*) is true iff TOP(T) or OBJECT(T)
    isTop(objectStar);
    isTop(futureOrStar(dynamicNone));
    isTop(futureOrStar(voidNone));

    isTop(futureOrStar(objectNone));
    isTop(futureOrStar(objectQuestion));
    isTop(futureOrStar(objectStar));

    isNotTop(futureOrStar(intNone));
    isNotTop(futureOrStar(intQuestion));
    isNotTop(futureOrStar(intStar));

    // TOP(dynamic) is true
    isTop(dynamicNone);
    isTop(UnknownInferredType.instance);

    // TOP(void) is true
    isTop(voidNone);

    // TOP(FutureOr<T>) is TOP(T)
    isTop(futureOrNone(dynamicNone));
    isTop(futureOrNone(voidNone));

    isNotTop(futureOrNone(objectNone));
    isTop(futureOrNone(objectQuestion));
    isTop(futureOrNone(objectStar));

    // TOP(T) is false otherwise
    isNotTop(objectNone);

    isNotTop(intNone);
    isNotTop(intQuestion);
    isNotTop(intStar);

    isNotTop(neverNone);
    isNotTop(neverQuestion);
    isNotTop(neverStar);
  }

  /// [TypeSystemImpl.isMoreBottom] can be used only for `BOTTOM` or `NULL`
  /// types. No need to check other types.
  void _assertIsBottomOrNull(DartType type) {
    expect(typeSystem.isBottom(type) || typeSystem.isNull(type), isTrue,
        reason: _typeString(type));
  }

  /// [TypeSystemImpl.isMoreTop] can be used only for `TOP` or `OBJECT`
  /// types. No need to check other types.
  void _assertIsTopOrObject(DartType type) {
    expect(typeSystem.isTop(type) || typeSystem.isObject(type), isTrue,
        reason: _typeString(type));
  }

  void _checkUniqueTypeStr(Map<String, StackTrace> map, String str) {
    var previousStack = map[str];
    if (previousStack != null) {
      fail('Not unique: $str\n$previousStack');
    } else {
      map[str] = StackTrace.current;
    }
  }
}

@reflectiveTest
class LowerBoundTest extends _BoundsTestBase {
  test_bottom_any() {
    void check(DartType T1, DartType T2) {
      _assertBottom(T1);
      _assertNotBottom(T2);
      _checkGreatestLowerBound(T1, T2, T1);
    }

    check(neverNone, objectNone);
    check(neverNone, objectStar);
    check(neverNone, objectQuestion);

    check(neverNone, intNone);
    check(neverNone, intQuestion);
    check(neverNone, intStar);

    check(neverNone, listNone(intNone));
    check(neverNone, listQuestion(intNone));
    check(neverNone, listStar(intNone));

    check(neverNone, futureOrNone(intNone));
    check(neverNone, futureOrQuestion(intNone));
    check(neverNone, futureOrStar(intNone));

    {
      var T = typeParameterTypeNone(
        typeParameter('T', bound: neverNone),
      );
      check(T, intNone);
      check(T, intQuestion);
      check(T, intStar);
    }

    {
      var T = promotedTypeParameterTypeNone(
        typeParameter('T', bound: objectQuestion),
        neverNone,
      );
      check(T, intNone);
      check(T, intQuestion);
      check(T, intStar);
    }
  }

  test_bottom_bottom() {
    void check(DartType T1, DartType T2) {
      _assertBottom(T1);
      _assertBottom(T2);
      _checkGreatestLowerBound(T1, T2, T1);
    }

    check(
      neverNone,
      typeParameterTypeNone(
        typeParameter('T', bound: neverNone),
      ),
    );

    check(
      neverNone,
      promotedTypeParameterTypeNone(
        typeParameter('T', bound: objectQuestion),
        neverNone,
      ),
    );
  }

  test_functionType2_parameters_conflicts() {
    _checkGreatestLowerBound(
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          requiredParameter(name: 'a', type: intNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedParameter(name: 'a', type: intNone),
        ],
      ),
      neverNone,
    );

    _checkGreatestLowerBound(
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          positionalParameter(name: 'a', type: intNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedParameter(name: 'a', type: intNone),
        ],
      ),
      neverNone,
    );
  }

  test_functionType2_parameters_named() {
    FunctionType build(
      List<DartType> requiredTypes,
      Map<String, DartType> namedMap,
      Map<String, DartType> namedRequiredMap,
    ) {
      var parameters = <ParameterElement>[];

      for (var requiredType in requiredTypes) {
        parameters.add(
          requiredParameter(type: requiredType),
        );
      }

      for (var entry in namedMap.entries) {
        parameters.add(
          namedParameter(name: entry.key, type: entry.value),
        );
      }

      for (var entry in namedRequiredMap.entries) {
        parameters.add(
          namedRequiredParameter(name: entry.key, type: entry.value),
        );
      }

      return functionTypeNone(
        returnType: voidNone,
        parameters: parameters,
      );
    }

    void check(FunctionType T1, FunctionType T2, DartType expected) {
      _checkGreatestLowerBound(T1, T2, expected);
    }

    check(
      build([], {}, {}),
      build([], {}, {}),
      build([], {}, {}),
    );

    {
      check(
        build([], {'a': intNone}, {}),
        build([], {'a': intNone}, {}),
        build([], {'a': intNone}, {}),
      );

      check(
        build([], {'a': intNone}, {}),
        build([], {}, {'a': intNone}),
        build([], {'a': intNone}, {}),
      );

      check(
        build([], {}, {'a': intNone}),
        build([], {}, {'a': intNone}),
        build([], {}, {'a': intNone}),
      );
    }

    {
      check(
        build([], {'a': intNone, 'b': intNone}, {}),
        build([], {'a': intNone, 'c': intNone}, {}),
        build([], {'a': intNone, 'b': intNone, 'c': intNone}, {}),
      );

      check(
        build([], {'a': intNone}, {'b': intNone}),
        build([], {'a': intNone}, {'c': intNone}),
        build([], {'a': intNone, 'b': intNone, 'c': intNone}, {}),
      );
    }

    {
      check(
        build([], {'a': intNone}, {}),
        build([], {'a': numNone}, {}),
        build([], {'a': numNone}, {}),
      );

      check(
        build([], {'a': intNone}, {}),
        build([], {'a': doubleNone}, {}),
        build([], {'a': numNone}, {}),
      );

      check(
        build([], {'a': intNone}, {}),
        build([], {'a': doubleQuestion}, {}),
        build([], {'a': numQuestion}, {}),
      );

      check(
        build([], {'a': intNone}, {}),
        build([], {'a': doubleStar}, {}),
        build([], {'a': numStar}, {}),
      );
    }
  }

  test_functionType2_parameters_positional() {
    FunctionType build(
      List<DartType> requiredTypes,
      List<DartType> positionalTypes,
    ) {
      var parameters = <ParameterElement>[];

      for (var requiredType in requiredTypes) {
        parameters.add(
          requiredParameter(type: requiredType),
        );
      }

      for (var positionalType in positionalTypes) {
        parameters.add(
          positionalParameter(type: positionalType),
        );
      }

      return functionTypeNone(
        returnType: voidNone,
        parameters: parameters,
      );
    }

    void check(FunctionType T1, FunctionType T2, DartType expected) {
      _checkGreatestLowerBound(T1, T2, expected);
    }

    check(
      build([], []),
      build([], []),
      build([], []),
    );

    check(
      build([intNone], []),
      build([intNone], []),
      build([intNone], []),
    );

    check(
      build([intNone], []),
      build([numNone], []),
      build([numNone], []),
    );

    check(
      build([intNone], []),
      build([doubleNone], []),
      build([numNone], []),
    );

    check(
      build([intNone], []),
      build([doubleQuestion], []),
      build([numQuestion], []),
    );

    check(
      build([intNone], []),
      build([doubleStar], []),
      build([numStar], []),
    );

    {
      check(
        build([intNone], []),
        build([], [intNone]),
        build([], [intNone]),
      );

      check(
        build([intNone], []),
        build([], []),
        build([], [intNone]),
      );

      check(
        build([], [intNone]),
        build([], [intNone]),
        build([], [intNone]),
      );

      check(
        build([], [intNone]),
        build([], []),
        build([], [intNone]),
      );
    }
  }

  test_functionType2_returnType() {
    void check(DartType T1_ret, DartType T2_ret, DartType expected_ret) {
      _checkGreatestLowerBound(
        functionTypeNone(returnType: T1_ret),
        functionTypeNone(returnType: T2_ret),
        functionTypeNone(returnType: expected_ret),
      );
    }

    check(intNone, intNone, intNone);
    check(intNone, numNone, intNone);

    check(intNone, voidNone, intNone);
    check(intNone, neverNone, neverNone);
  }

  test_functionType2_typeParameters() {
    void check(FunctionType T1, FunctionType T2, DartType expected) {
      _assertNullabilityNone(T1);
      _assertNullabilityNone(T2);

      _checkGreatestLowerBound(T1, T2, expected, checkSubtype: false);
    }

    check(
      functionTypeNone(
        returnType: voidNone,
        typeFormals: [
          typeParameter('T'),
        ],
      ),
      functionTypeNone(returnType: voidNone),
      neverNone,
    );

    check(
      functionTypeNone(
        returnType: voidNone,
        typeFormals: [
          typeParameter('T', bound: intNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        typeFormals: [
          typeParameter('T', bound: numNone),
        ],
      ),
      neverNone,
    );

    {
      var T = typeParameter('T', bound: numNone);
      var U = typeParameter('U', bound: numNone);
      var R = typeParameter('R', bound: numNone);
      check(
        functionTypeNone(
          returnType: typeParameterTypeNone(T),
          typeFormals: [T],
        ),
        functionTypeNone(
          returnType: typeParameterTypeNone(U),
          typeFormals: [U],
        ),
        functionTypeNone(
          returnType: typeParameterTypeNone(R),
          typeFormals: [R],
        ),
      );
    }
  }

  test_functionType_interfaceType() {
    void check(FunctionType T1, InterfaceType T2, DartType expected) {
      _checkGreatestLowerBound(T1, T2, expected);
    }

    check(
      functionTypeNone(returnType: voidNone),
      intNone,
      neverNone,
    );
  }

  test_functionType_interfaceType_Function() {
    void check(FunctionType T1) {
      _assertNullabilityNone(T1);
      _checkGreatestLowerBound(T1, functionNone, T1);
    }

    check(functionTypeNone(returnType: voidNone));

    check(
      functionTypeNone(
        returnType: intNone,
        parameters: [
          requiredParameter(type: numQuestion),
        ],
      ),
    );
  }

  test_futureOr() {
    InterfaceType futureOrFunction(DartType T, String str) {
      var result = futureOrNone(
        functionTypeNone(returnType: voidNone, parameters: [
          requiredParameter(type: T),
        ]),
      );
      expect(result.getDisplayString(withNullability: true), str);
      return result;
    }

    // DOWN(FutureOr<T1>, FutureOr<T2>) = FutureOr<S>, S = DOWN(T1, T2)
    _checkGreatestLowerBound(
      futureOrNone(intNone),
      futureOrNone(numNone),
      futureOrNone(intNone),
    );
    _checkGreatestLowerBound(
      futureOrFunction(intNone, 'FutureOr<void Function(int)>'),
      futureOrFunction(doubleNone, 'FutureOr<void Function(double)>'),
      futureOrFunction(numNone, 'FutureOr<void Function(num)>'),
    );

    // DOWN(FutureOr<T1>, Future<T2>) = Future<S>, S = DOWN(T1, T2)
    // DOWN(Future<T1>, FutureOr<T2>) = Future<S>, S = DOWN(T1, T2)
    _checkGreatestLowerBound(
      futureOrNone(numNone),
      futureNone(intNone),
      futureNone(intNone),
    );
    _checkGreatestLowerBound(
      futureOrNone(intNone),
      futureNone(numNone),
      futureNone(intNone),
    );

    // DOWN(FutureOr<T1>, T2) = S, S = DOWN(T1, T2)
    // DOWN(T1, FutureOr<T2>) = S, S = DOWN(T1, T2)
    _checkGreatestLowerBound(
      futureOrNone(numNone),
      intNone,
      intNone,
    );
    _checkGreatestLowerBound(
      futureOrNone(intNone),
      numNone,
      intNone,
    );
  }

  test_identical() {
    void check(DartType type) {
      _checkGreatestLowerBound(type, type, type);
    }

    check(intNone);
    check(intQuestion);
    check(intStar);
    check(listNone(intNone));
  }

  test_interfaceType2() {
    void check(InterfaceType T1, InterfaceType T2, DartType expected) {
      _assertNullabilityNone(T1);
      _assertNullabilityNone(T2);

      _checkGreatestLowerBound(T1, T2, expected);
    }

    check(intNone, intNone, intNone);
    check(numNone, intNone, intNone);
    check(doubleNone, intNone, neverNone);

    check(listNone(intNone), listNone(intNone), listNone(intNone));
    check(listNone(numNone), listNone(intNone), listNone(intNone));
    check(listNone(doubleNone), listNone(intNone), neverNone);
  }

  void test_interfaceType2_interfaces() {
    // class A
    // class B implements A
    // class C implements B
    var A = class_(name: 'A');
    var B = class_(name: 'B', interfaces: [interfaceTypeNone(A)]);
    var C = class_(name: 'C', interfaces: [interfaceTypeNone(B)]);
    _checkGreatestLowerBound(
      interfaceTypeNone(A),
      interfaceTypeNone(C),
      interfaceTypeNone(C),
    );
  }

  void test_interfaceType2_mixins() {
    // class A
    // class B
    // class C
    // class D extends A with B, C
    var A = class_(name: 'A');
    var typeA = interfaceTypeNone(A);

    var B = class_(name: 'B');
    var typeB = interfaceTypeNone(B);

    var C = class_(name: 'C');
    var typeC = interfaceTypeNone(C);

    var D = class_(
      name: 'D',
      superType: interfaceTypeNone(A),
      mixins: [typeB, typeC],
    );
    var typeD = interfaceTypeNone(D);

    _checkGreatestLowerBound(typeA, typeD, typeD);
    _checkGreatestLowerBound(typeB, typeD, typeD);
    _checkGreatestLowerBound(typeC, typeD, typeD);
  }

  void test_interfaceType2_superType() {
    // class A
    // class B extends A
    // class C extends B
    var A = class_(name: 'A');
    var B = class_(name: 'B', superType: interfaceTypeNone(A));
    var C = class_(name: 'C', superType: interfaceTypeNone(B));
    _checkGreatestLowerBound(
      interfaceTypeNone(A),
      interfaceTypeNone(C),
      interfaceTypeNone(C),
    );
  }

  test_none_question() {
    void check(DartType T1, DartType T2, DartType expected) {
      _assertNullabilityNone(T1);
      _assertNullabilityQuestion(T2);

      _assertNotSpecial(T1);
      _assertNotSpecial(T2);

      _checkGreatestLowerBound(T1, T2, expected);
    }

    check(intNone, intQuestion, intNone);

    check(numNone, intQuestion, intNone);
    check(intNone, numQuestion, intNone);

    check(doubleNone, intQuestion, neverNone);
    check(intNone, doubleQuestion, neverNone);
  }

  test_none_star() {
    void check(DartType T1, DartType T2, DartType expected) {
      _assertNullabilityNone(T1);
      _assertNullabilityStar(T2);

      _assertNotSpecial(T1);
      _assertNotSpecial(T2);

      _checkGreatestLowerBound(T1, T2, expected);
    }

    check(intNone, intStar, intNone);

    check(numNone, intStar, intNone);
    check(intNone, numStar, intNone);

    check(doubleNone, intStar, neverNone);
    check(intNone, doubleStar, neverNone);
  }

  test_null_any() {
    void check(DartType T2, DartType expected) {
      _assertNotBottom(T2);
      _assertNotNull(T2);
      _assertNotTop(T2);

      _checkGreatestLowerBound(nullNone, T2, expected);
    }

    void checkNull(DartType T2) {
      check(T2, nullNone);
    }

    void checkNever(DartType T2) {
      check(T2, neverNone);
    }

    checkNull(futureOrNone(nullNone));
    checkNull(futureOrNone(nullQuestion));
    checkNull(futureOrNone(nullStar));

    checkNull(futureOrQuestion(nullNone));
    checkNull(futureOrQuestion(nullQuestion));
    checkNull(futureOrQuestion(nullStar));

    checkNull(futureOrStar(nullNone));
    checkNull(futureOrStar(nullQuestion));
    checkNull(futureOrStar(nullStar));

    checkNever(objectNone);

    checkNever(intNone);
    checkNull(intQuestion);
    checkNull(intStar);

    checkNever(listNone(intNone));
    checkNull(listQuestion(intNone));
    checkNull(listStar(intNone));

    checkNever(listNone(intQuestion));
    checkNull(listQuestion(intQuestion));
    checkNull(listStar(intQuestion));
  }

  test_null_null() {
    void check(DartType T1, DartType T2) {
      _assertNull(T1);
      _assertNull(T2);

      _assertNotBottom(T1);
      _assertNotBottom(T2);

      _checkGreatestLowerBound(T1, T2, T1);
    }

    check(nullNone, nullQuestion);
    check(nullNone, nullStar);
  }

  test_object_any() {
    void check(DartType T2, DartType expected) {
      _assertNotObject(T2);

      _checkGreatestLowerBound(objectNone, T2, expected);
    }

    void checkNever(DartType T2) {
      check(T2, neverNone);
    }

    check(intNone, intNone);
    check(intQuestion, intNone);
    check(intStar, intStar);

    check(futureOrNone(intNone), futureOrNone(intNone));
    check(futureOrQuestion(intNone), futureOrNone(intNone));
    check(futureOrNone(intNone), futureOrNone(intNone));

    checkNever(futureOrNone(intQuestion));
    checkNever(futureOrQuestion(intQuestion));
    checkNever(futureOrNone(intQuestion));

    {
      var T = typeParameter('T', bound: objectNone);
      check(typeParameterTypeNone(T), typeParameterTypeNone(T));
      check(typeParameterTypeQuestion(T), typeParameterTypeNone(T));
      check(typeParameterTypeStar(T), typeParameterTypeStar(T));
    }

    {
      var T = typeParameter('T', bound: objectQuestion);
      check(
        typeParameterTypeNone(T),
        promotedTypeParameterTypeNone(T, objectNone),
      );
      check(
        typeParameterTypeQuestion(T),
        promotedTypeParameterTypeNone(T, objectNone),
      );
      check(
        typeParameterTypeStar(T),
        promotedTypeParameterTypeNone(T, objectNone),
      );
    }

    {
      var T = typeParameter('T', bound: futureOrNone(objectQuestion));
      checkNever(typeParameterTypeNone(T));
      checkNever(typeParameterTypeQuestion(T));
      checkNever(typeParameterTypeStar(T));
    }
  }

  test_object_object() {
    void check(DartType T1, DartType T2) {
      _assertObject(T1);
      _assertObject(T2);

      _checkGreatestLowerBound(T1, T2, T1);
    }

    check(futureOrNone(objectNone), objectNone);

    check(
      futureOrNone(
        futureOrNone(objectNone),
      ),
      futureOrNone(objectNone),
    );
  }

  test_question_question() {
    void check(DartType T1, DartType T2, DartType expected) {
      _assertNullabilityQuestion(T1);
      _assertNullabilityQuestion(T2);

      _assertNotSpecial(T1);
      _assertNotSpecial(T2);

      _checkGreatestLowerBound(T1, T2, expected);
    }

    check(intQuestion, intQuestion, intQuestion);

    check(numQuestion, intQuestion, intQuestion);
    check(intQuestion, numQuestion, intQuestion);

    check(doubleQuestion, intQuestion, neverQuestion);
    check(intQuestion, doubleQuestion, neverQuestion);
  }

  test_self() {
    var T = typeParameter('T');

    List<DartType> types = [
      dynamicType,
      voidNone,
      neverNone,
      typeParameterTypeStar(T),
      intNone,
      functionTypeNone(returnType: voidNone),
    ];

    for (var type in types) {
      _checkGreatestLowerBound(type, type, type);
    }
  }

  test_star_question() {
    void check(DartType T1, DartType T2, DartType expected) {
      _assertNullabilityQuestion(T1);
      _assertNullabilityStar(T2);

      _assertNotSpecial(T1);
      _assertNotSpecial(T2);

      _checkGreatestLowerBound(T1, T2, expected);
    }

    check(intQuestion, intStar, intStar);

    check(numQuestion, intStar, intStar);
    check(intQuestion, numStar, intStar);

    check(doubleQuestion, intStar, neverStar);
    check(intQuestion, doubleStar, neverStar);
  }

  test_star_star() {
    void check(DartType T1, DartType T2, DartType expected) {
      _assertNullabilityStar(T1);
      _assertNullabilityStar(T2);

      _assertNotSpecial(T1);
      _assertNotSpecial(T2);

      _checkGreatestLowerBound(T1, T2, expected);
    }

    check(intStar, numStar, intStar);
    check(intStar, doubleStar, neverStar);
  }

  test_top_any() {
    void check(DartType T1, DartType T2) {
      _assertTop(T1);
      _assertNotTop(T2);
      _checkGreatestLowerBound(T1, T2, T2);
    }

    check(voidNone, objectNone);
    check(voidNone, intNone);
    check(voidNone, intQuestion);
    check(voidNone, intStar);
    check(voidNone, listNone(intNone));
    check(voidNone, futureOrNone(intNone));
    check(voidNone, neverNone);
    check(voidNone, functionTypeNone(returnType: voidNone));

    check(dynamicNone, objectNone);
    check(dynamicNone, intNone);
    check(dynamicNone, intQuestion);
    check(dynamicNone, intStar);
    check(dynamicNone, listNone(intNone));
    check(dynamicNone, futureOrNone(intNone));
    check(dynamicNone, neverNone);
    check(dynamicNone, functionTypeNone(returnType: voidNone));

    check(objectQuestion, objectNone);
    check(objectQuestion, intNone);
    check(objectQuestion, intQuestion);
    check(objectQuestion, intStar);
    check(objectQuestion, listNone(intNone));
    check(objectQuestion, futureOrNone(intNone));
    check(objectQuestion, neverNone);
    check(objectQuestion, functionTypeNone(returnType: voidNone));

    check(objectStar, objectNone);
    check(objectStar, intNone);
    check(objectStar, intQuestion);
    check(objectStar, intStar);
    check(objectStar, listNone(intNone));
    check(objectStar, futureOrNone(intNone));
    check(objectStar, neverNone);
    check(objectStar, functionTypeNone(returnType: voidNone));

    check(futureOrNone(voidNone), intNone);
    check(futureOrQuestion(voidNone), intNone);
    check(futureOrStar(voidNone), intNone);
  }

  test_top_top() {
    void check(DartType T1, DartType T2) {
      _assertTop(T1);
      _assertTop(T2);
      _checkGreatestLowerBound(T1, T2, T2);
    }

    check(voidNone, dynamicNone);
    check(voidNone, objectStar);
    check(voidNone, objectQuestion);
    check(voidNone, futureOrNone(voidNone));
    check(voidNone, futureOrNone(dynamicNone));
    check(voidNone, futureOrNone(objectQuestion));
    check(voidNone, futureOrNone(objectStar));

    check(dynamicNone, objectStar);
    check(dynamicNone, objectQuestion);
    check(dynamicNone, futureOrNone(voidNone));
    check(dynamicNone, futureOrNone(dynamicNone));
    check(dynamicNone, futureOrNone(objectQuestion));
    check(dynamicNone, futureOrNone(objectStar));
    check(
      dynamicNone,
      futureOrStar(objectStar),
    );

    check(objectQuestion, futureOrQuestion(voidNone));
    check(objectQuestion, futureOrQuestion(dynamicNone));
    check(objectQuestion, futureOrQuestion(objectNone));
    check(objectQuestion, futureOrQuestion(objectQuestion));
    check(objectQuestion, futureOrQuestion(objectStar));

    check(objectQuestion, futureOrStar(voidNone));
    check(objectQuestion, futureOrStar(dynamicNone));
    check(objectQuestion, futureOrStar(objectNone));
    check(objectQuestion, futureOrStar(objectQuestion));
    check(objectQuestion, futureOrStar(objectStar));

    check(objectStar, futureOrStar(voidNone));
    check(objectStar, futureOrStar(dynamicNone));
    check(objectStar, futureOrStar(objectNone));
    check(objectStar, futureOrStar(objectQuestion));
    check(objectStar, futureOrStar(objectStar));

    check(futureOrNone(voidNone), objectQuestion);
    check(futureOrNone(dynamicNone), objectQuestion);
    check(futureOrNone(objectQuestion), objectQuestion);
    check(futureOrNone(objectStar), objectQuestion);

    check(futureOrNone(voidNone), futureOrNone(dynamicNone));
    check(futureOrNone(voidNone), futureOrNone(objectQuestion));
    check(futureOrNone(voidNone), futureOrNone(objectStar));
    check(futureOrNone(dynamicNone), futureOrNone(objectQuestion));
    check(futureOrNone(dynamicNone), futureOrNone(objectStar));
  }

  test_typeParameter() {
    void check({DartType? bound, required DartType T2}) {
      var T1 = typeParameterTypeNone(
        typeParameter('T', bound: bound),
      );
      _checkGreatestLowerBound(T1, T2, neverNone);
    }

    check(
      bound: null,
      T2: functionTypeNone(returnType: voidNone),
    );
    check(bound: null, T2: intNone);
    check(bound: numNone, T2: intNone);
  }

  void _checkGreatestLowerBound(DartType T1, DartType T2, DartType expected,
      {bool checkSubtype = true}) {
    var expectedStr = _typeString(expected);

    var result = typeSystem.getGreatestLowerBound(T1, T2);
    var resultStr = _typeString(result);
    expect(result, expected, reason: '''
expected: $expectedStr
actual: $resultStr
''');

    // Check that the result is a lower bound.
    if (checkSubtype) {
      expect(typeSystem.isSubtypeOf(result, T1), true);
      expect(typeSystem.isSubtypeOf(result, T2), true);
    }

    // Check for symmetry.
    result = typeSystem.getGreatestLowerBound(T2, T1);
    resultStr = _typeString(result);
    expect(result, expected, reason: '''
expected: $expectedStr
actual: $resultStr
''');
  }
}

@reflectiveTest
class UpperBound_FunctionTypes_Test extends _BoundsTestBase {
  void test_nested2_upParameterType() {
    var T1 = functionTypeNone(
      parameters: [
        requiredParameter(
          type: functionTypeNone(
            parameters: [
              requiredParameter(type: stringNone),
              requiredParameter(type: intNone),
              requiredParameter(type: intNone),
            ],
            returnType: voidNone,
          ),
        ),
      ],
      returnType: voidNone,
    );
    expect(
      _typeString(T1),
      'void Function(void Function(String, int, int))',
    );

    var T2 = functionTypeNone(
      parameters: [
        requiredParameter(
          type: functionTypeNone(
            parameters: [
              requiredParameter(type: intNone),
              requiredParameter(type: doubleNone),
              requiredParameter(type: numNone),
            ],
            returnType: voidNone,
          ),
        ),
      ],
      returnType: voidNone,
    );
    expect(
      _typeString(T2),
      'void Function(void Function(int, double, num))',
    );

    var expected = functionTypeNone(
      parameters: [
        requiredParameter(
          type: functionTypeNone(
            parameters: [
              requiredParameter(type: objectNone),
              requiredParameter(type: numNone),
              requiredParameter(type: numNone),
            ],
            returnType: voidNone,
          ),
        ),
      ],
      returnType: voidNone,
    );
    expect(
      _typeString(expected),
      'void Function(void Function(Object, num, num))',
    );

    _checkLeastUpperBound(T1, T2, expected);
  }

  void test_nested3_downParameterTypes() {
    var T1 = functionTypeNone(
      parameters: [
        requiredParameter(
          type: functionTypeNone(
            parameters: [
              requiredParameter(
                type: functionTypeNone(
                  parameters: [
                    requiredParameter(type: stringNone),
                    requiredParameter(type: intNone),
                    requiredParameter(type: intNone)
                  ],
                  returnType: voidNone,
                ),
              ),
            ],
            returnType: voidNone,
          ),
        ),
      ],
      returnType: voidNone,
    );
    expect(
      _typeString(T1),
      'void Function(void Function(void Function(String, int, int)))',
    );

    var T2 = functionTypeNone(
      parameters: [
        requiredParameter(
          type: functionTypeNone(
            parameters: [
              requiredParameter(
                type: functionTypeNone(
                  parameters: [
                    requiredParameter(type: intNone),
                    requiredParameter(type: doubleNone),
                    requiredParameter(type: numNone)
                  ],
                  returnType: voidNone,
                ),
              ),
            ],
            returnType: voidNone,
          ),
        ),
      ],
      returnType: voidNone,
    );
    expect(
      _typeString(T2),
      'void Function(void Function(void Function(int, double, num)))',
    );

    var expected = functionTypeNone(
      parameters: [
        requiredParameter(
          type: functionTypeNone(
            parameters: [
              requiredParameter(
                type: functionTypeNone(
                  parameters: [
                    requiredParameter(type: neverNone),
                    requiredParameter(type: neverNone),
                    requiredParameter(type: intNone)
                  ],
                  returnType: voidNone,
                ),
              ),
            ],
            returnType: voidNone,
          ),
        ),
      ],
      returnType: voidNone,
    );
    expect(
      _typeString(expected),
      'void Function(void Function(void Function(Never, Never, int)))',
    );

    _checkLeastUpperBound(T1, T2, expected);
  }

  void test_parameters_fuzzyArrows() {
    var T1 = functionTypeNone(
      parameters: [
        requiredParameter(type: dynamicType),
      ],
      returnType: voidNone,
    );

    var T2 = functionTypeNone(
      parameters: [
        requiredParameter(type: intNone),
      ],
      returnType: voidNone,
    );

    var expected = functionTypeNone(
      parameters: [
        requiredParameter(type: intNone),
      ],
      returnType: voidNone,
    );

    _checkLeastUpperBound(T1, T2, expected);
  }

  test_parameters_optionalNamed() {
    FunctionType build(Map<String, DartType> namedTypes) {
      return functionTypeNone(
        returnType: voidNone,
        parameters: namedTypes.entries.map((entry) {
          return namedParameter(name: entry.key, type: entry.value);
        }).toList(),
      );
    }

    void check(Map<String, DartType> T1_named, Map<String, DartType> T2_named,
        Map<String, DartType> expected_named) {
      var T1 = build(T1_named);
      var T2 = build(T2_named);
      var expected = build(expected_named);
      _checkLeastUpperBound(T1, T2, expected);
    }

    check({'a': intNone}, {}, {});
    check({'a': intNone}, {'b': intNone}, {});

    check({'a': intNone}, {'a': intNone}, {'a': intNone});
    check({'a': intNone}, {'a': intQuestion}, {'a': intNone});

    check({'a': intNone, 'b': doubleNone}, {'a': intNone}, {'a': intNone});
  }

  test_parameters_optionalPositional() {
    FunctionType build(List<DartType> positionalTypes) {
      return functionTypeNone(
        returnType: voidNone,
        parameters: positionalTypes.map((type) {
          return positionalParameter(type: type);
        }).toList(),
      );
    }

    void check(List<DartType> T1_positional, List<DartType> T2_positional,
        DartType expected) {
      var T1 = build(T1_positional);
      var T2 = build(T2_positional);
      _checkLeastUpperBound(T1, T2, expected);
    }

    check([intNone], [], build([]));
    check([intNone, doubleNone], [intNone], build([intNone]));

    check([intNone], [intNone], build([intNone]));
    check([intNone], [intQuestion], build([intNone]));

    check([intNone], [intStar], build([intNone]));
    check([intNone], [doubleNone], build([neverNone]));

    check([intNone], [numNone], build([intNone]));

    check(
      [doubleNone, numNone],
      [numNone, intNone],
      build([doubleNone, intNone]),
    );
  }

  test_parameters_requiredNamed() {
    _checkLeastUpperBound(
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          requiredParameter(name: 'a', type: intNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedRequiredParameter(name: 'a', type: intNone),
        ],
      ),
      functionNone,
    );

    _checkLeastUpperBound(
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          positionalParameter(name: 'a', type: intNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedRequiredParameter(name: 'a', type: intNone),
        ],
      ),
      functionNone,
    );

    _checkLeastUpperBound(
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedParameter(name: 'b', type: intNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedRequiredParameter(name: 'a', type: intNone),
        ],
      ),
      functionNone,
    );

    _checkLeastUpperBound(
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedParameter(name: 'a', type: intNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedRequiredParameter(name: 'a', type: intNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedRequiredParameter(name: 'a', type: intNone),
        ],
      ),
    );

    _checkLeastUpperBound(
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedParameter(name: 'a', type: intNone),
          namedRequiredParameter(name: 'b', type: intNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedRequiredParameter(name: 'b', type: intNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedRequiredParameter(name: 'b', type: intNone),
        ],
      ),
    );

    _checkLeastUpperBound(
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedRequiredParameter(name: 'a', type: intNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedRequiredParameter(name: 'a', type: numNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          namedRequiredParameter(name: 'a', type: intNone),
        ],
      ),
    );
  }

  test_parameters_requiredPositional() {
    FunctionType build(List<DartType> requiredTypes) {
      return functionTypeNone(
        returnType: voidNone,
        parameters: requiredTypes.map((type) {
          return requiredParameter(type: type);
        }).toList(),
      );
    }

    void check(List<DartType> T1_required, List<DartType> T2_required,
        DartType expected) {
      var T1 = build(T1_required);
      var T2 = build(T2_required);
      _checkLeastUpperBound(T1, T2, expected);
    }

    check([intNone], [], functionNone);

    check([intNone], [intNone], build([intNone]));
    check([intNone], [intQuestion], build([intNone]));

    check([intNone], [intStar], build([intNone]));
    check([intNone], [doubleNone], build([neverNone]));

    check([intNone], [numNone], build([intNone]));

    check(
      [doubleNone, numNone],
      [numNone, intNone],
      build([doubleNone, intNone]),
    );
  }

  void test_parameters_requiredPositional_differentArity() {
    var T1 = functionTypeNone(
      parameters: [
        requiredParameter(type: intNone),
        requiredParameter(type: intNone),
      ],
      returnType: voidNone,
    );

    var T2 = functionTypeNone(
      parameters: [
        requiredParameter(type: intNone),
        requiredParameter(type: intNone),
        requiredParameter(type: intNone),
      ],
      returnType: voidNone,
    );

    _checkLeastUpperBound(T1, T2, typeProvider.functionType);
  }

  test_returnType() {
    void check(DartType T1_ret, DartType T2_ret, DartType expected_ret) {
      _checkLeastUpperBound(
        functionTypeNone(returnType: T1_ret),
        functionTypeNone(returnType: T2_ret),
        functionTypeNone(returnType: expected_ret),
      );
    }

    check(intNone, intNone, intNone);
    check(intNone, intQuestion, intQuestion);
    check(intNone, intStar, intStar);

    check(intNone, numNone, numNone);
    check(intQuestion, numNone, numQuestion);
    check(intStar, numNone, numStar);

    check(intNone, dynamicNone, dynamicNone);
    check(intNone, neverNone, intNone);
  }

  void test_sameType_withNamed() {
    var T1 = functionTypeNone(
      parameters: [
        requiredParameter(type: stringNone),
        requiredParameter(type: intNone),
        requiredParameter(type: numNone),
        namedParameter(name: 'n', type: numNone),
      ],
      returnType: intNone,
    );

    var T2 = functionTypeNone(
      parameters: [
        requiredParameter(type: stringNone),
        requiredParameter(type: intNone),
        requiredParameter(type: numNone),
        namedParameter(name: 'n', type: numNone),
      ],
      returnType: intNone,
    );

    var expected = functionTypeNone(
      parameters: [
        requiredParameter(type: stringNone),
        requiredParameter(type: intNone),
        requiredParameter(type: numNone),
        namedParameter(name: 'n', type: numNone),
      ],
      returnType: intNone,
    );

    _checkLeastUpperBound(T1, T2, expected);
  }

  void test_sameType_withOptional() {
    var T1 = functionTypeNone(
      parameters: [
        requiredParameter(type: stringNone),
        requiredParameter(type: intNone),
        requiredParameter(type: numNone),
        positionalParameter(type: doubleNone),
      ],
      returnType: intNone,
    );

    var T2 = functionTypeNone(
      parameters: [
        requiredParameter(type: stringNone),
        requiredParameter(type: intNone),
        requiredParameter(type: numNone),
        positionalParameter(type: doubleNone),
      ],
      returnType: intNone,
    );

    var expected = functionTypeNone(
      parameters: [
        requiredParameter(type: stringNone),
        requiredParameter(type: intNone),
        requiredParameter(type: numNone),
        positionalParameter(type: doubleNone),
      ],
      returnType: intNone,
    );

    _checkLeastUpperBound(T1, T2, expected);
  }

  test_typeParameters() {
    void check(FunctionType T1, FunctionType T2, DartType expected) {
      _assertNullabilityNone(T1);
      _assertNullabilityNone(T2);

      _checkLeastUpperBound(T1, T2, expected);
    }

    check(
      functionTypeNone(
        returnType: voidNone,
        typeFormals: [
          typeParameter('T'),
        ],
      ),
      functionTypeNone(returnType: voidNone),
      functionNone,
    );

    check(
      functionTypeNone(
        returnType: voidNone,
        typeFormals: [
          typeParameter('T', bound: intNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        typeFormals: [
          typeParameter('T', bound: numNone),
        ],
      ),
      functionNone,
    );

    {
      var T = typeParameter('T', bound: numNone);
      var U = typeParameter('U', bound: numNone);
      var R = typeParameter('R', bound: numNone);
      check(
        functionTypeNone(
          returnType: typeParameterTypeNone(T),
          typeFormals: [T],
        ),
        functionTypeNone(
          returnType: typeParameterTypeNone(U),
          typeFormals: [U],
        ),
        functionTypeNone(
          returnType: typeParameterTypeNone(R),
          typeFormals: [R],
        ),
      );
    }
  }

  test_unrelated() {
    var T1 = functionTypeNone(returnType: intNone);

    _checkLeastUpperBound(T1, intNone, objectNone);
    _checkLeastUpperBound(T1, intQuestion, objectQuestion);
    _checkLeastUpperBound(T1, intStar, objectStar);

    _checkLeastUpperBound(
      T1,
      futureOrNone(functionQuestion),
      objectQuestion,
    );
  }
}

@reflectiveTest
class UpperBound_InterfaceTypes_Test extends _BoundsTestBase {
  test_directInterface() {
    // class A
    // class B implements A
    // class C implements B

    var A = class_(name: 'A');
    var typeA = interfaceTypeNone(A);

    var B = class_(name: 'B', interfaces: [typeA]);
    var typeB = interfaceTypeNone(B);

    var C = class_(name: 'C', interfaces: [typeB]);
    var typeC = interfaceTypeNone(C);

    _checkLeastUpperBound(typeB, typeC, typeB);
  }

  test_directInterface_legacy() {
    typeSystem = analysisContext.typeSystemLegacy;

    // (null safe) class A<T> {}
    // (legacy)    class B implements A<int> {}
    // (null safe) class C implements A<int> {}

    var A = class_(
      name: 'A',
      typeParameters: [typeParameter('T')],
    );

    var B = class_(
      name: 'B',
      interfaces: [
        interfaceTypeStar(A, typeArguments: [intStar])
      ],
    );

    var C = class_(
      name: 'C',
      interfaces: [
        interfaceTypeNone(A, typeArguments: [intNone])
      ],
    );

    _checkLeastUpperBound(
      interfaceTypeNone(B),
      interfaceTypeNone(C),
      interfaceTypeNone(A, typeArguments: [intStar]),
    );
  }

  test_directSuperclass() {
    // class A
    // class B extends A
    // class C extends B

    var A = class_(name: 'A');
    var typeA = interfaceTypeNone(A);

    var B = class_(name: 'B', superType: typeA);
    var typeB = interfaceTypeNone(B);

    var C = class_(name: 'C', superType: typeB);
    var typeC = interfaceTypeNone(C);

    _checkLeastUpperBound(typeB, typeC, typeB);
  }

  void test_directSuperclass_nullability() {
    var aElement = class_(name: 'A');
    var aQuestion = interfaceTypeQuestion(aElement);
    var aStar = interfaceTypeStar(aElement);
    var aNone = interfaceTypeNone(aElement);

    var bElementStar = class_(name: 'B', superType: aStar);
    var bElementNone = class_(name: 'B', superType: aNone);

    InterfaceType _bTypeStarElement(NullabilitySuffix nullability) {
      return interfaceType(
        bElementStar,
        nullabilitySuffix: nullability,
      );
    }

    InterfaceType _bTypeNoneElement(NullabilitySuffix nullability) {
      return interfaceType(
        bElementNone,
        nullabilitySuffix: nullability,
      );
    }

    var bStarQuestion = _bTypeStarElement(NullabilitySuffix.question);
    var bStarStar = _bTypeStarElement(NullabilitySuffix.star);
    var bStarNone = _bTypeStarElement(NullabilitySuffix.none);

    var bNoneQuestion = _bTypeNoneElement(NullabilitySuffix.question);
    var bNoneStar = _bTypeNoneElement(NullabilitySuffix.star);
    var bNoneNone = _bTypeNoneElement(NullabilitySuffix.none);

    void assertLUB(DartType type1, DartType type2, DartType expected) {
      expect(typeSystem.getLeastUpperBound(type1, type2), expected);
      expect(typeSystem.getLeastUpperBound(type2, type1), expected);
    }

    assertLUB(bStarQuestion, aQuestion, aQuestion);
    assertLUB(bStarQuestion, aStar, aQuestion);
    assertLUB(bStarQuestion, aNone, aQuestion);

    assertLUB(bStarStar, aQuestion, aQuestion);
    assertLUB(bStarStar, aStar, aStar);
    assertLUB(bStarStar, aNone, aStar);

    assertLUB(bStarNone, aQuestion, aQuestion);
    assertLUB(bStarNone, aStar, aStar);
    assertLUB(bStarNone, aNone, aNone);

    assertLUB(bNoneQuestion, aQuestion, aQuestion);
    assertLUB(bNoneQuestion, aStar, aQuestion);
    assertLUB(bNoneQuestion, aNone, aQuestion);

    assertLUB(bNoneStar, aQuestion, aQuestion);
    assertLUB(bNoneStar, aStar, aStar);
    assertLUB(bNoneStar, aNone, aStar);

    assertLUB(bNoneNone, aQuestion, aQuestion);
    assertLUB(bNoneNone, aStar, aStar);
    assertLUB(bNoneNone, aNone, aNone);
  }

  void test_implementationsOfComparable() {
    _checkLeastUpperBound(stringNone, numNone, objectNone);
  }

  void test_mixinAndClass_constraintAndInterface() {
    var A = class_(name: 'A');
    var A_none = interfaceTypeNone(A);

    var B = class_(name: 'B', interfaces: [A_none]);
    var M = mixin_(name: 'M', constraints: [A_none]);

    _checkLeastUpperBound(
      interfaceTypeNone(B),
      interfaceTypeNone(M),
      A_none,
    );
  }

  void test_mixinAndClass_object() {
    var A = class_(name: 'A');
    var M = mixin_(name: 'M');

    _checkLeastUpperBound(
      interfaceTypeNone(A),
      interfaceTypeNone(M),
      objectNone,
    );
  }

  void test_mixinAndClass_sharedInterface() {
    var A = class_(name: 'A');
    var A_none = interfaceTypeNone(A);

    var B = class_(name: 'B', interfaces: [A_none]);
    var M = mixin_(name: 'M', interfaces: [A_none]);

    _checkLeastUpperBound(
      interfaceTypeNone(B),
      interfaceTypeNone(M),
      A_none,
    );
  }

  void test_sameElement_nullability() {
    var aElement = class_(name: 'A');

    var aQuestion = interfaceTypeQuestion(aElement);
    var aStar = interfaceTypeStar(aElement);
    var aNone = interfaceTypeNone(aElement);

    void assertLUB(DartType type1, DartType type2, DartType expected) {
      expect(typeSystem.getLeastUpperBound(type1, type2), expected);
      expect(typeSystem.getLeastUpperBound(type2, type1), expected);
    }

    assertLUB(aQuestion, aQuestion, aQuestion);
    assertLUB(aQuestion, aStar, aQuestion);
    assertLUB(aQuestion, aNone, aQuestion);

    assertLUB(aStar, aQuestion, aQuestion);
    assertLUB(aStar, aStar, aStar);
    assertLUB(aStar, aNone, aStar);

    assertLUB(aNone, aQuestion, aQuestion);
    assertLUB(aNone, aStar, aStar);
    assertLUB(aNone, aNone, aNone);
  }

  void test_sharedMixin1() {
    // mixin M {}
    // class B with M {}
    // class C with M {}

    var M = mixin_(name: 'M');
    var M_none = interfaceTypeNone(M);

    var B = class_(name: 'B', mixins: [M_none]);
    var B_none = interfaceTypeNone(B);

    var C = class_(name: 'C', mixins: [M_none]);
    var C_none = interfaceTypeNone(C);

    _checkLeastUpperBound(B_none, C_none, M_none);
  }

  void test_sharedMixin2() {
    // mixin M1 {}
    // mixin M2 {}
    // mixin M3 {}
    // class A with M1, M2 {}
    // class B with M1, M3 {}

    var M1 = mixin_(name: 'M1');
    var M1_none = interfaceTypeNone(M1);

    var M2 = mixin_(name: 'M2');
    var M2_none = interfaceTypeNone(M2);

    var M3 = mixin_(name: 'M3');
    var M3_none = interfaceTypeNone(M3);

    var A = class_(name: 'A', mixins: [M1_none, M2_none]);
    var A_none = interfaceTypeNone(A);

    var B = class_(name: 'B', mixins: [M1_none, M3_none]);
    var B_none = interfaceTypeNone(B);

    _checkLeastUpperBound(A_none, B_none, M1_none);
  }

  void test_sharedMixin3() {
    // mixin M1 {}
    // mixin M2 {}
    // mixin M3 {}
    // class A with M2, M1 {}
    // class B with M3, M1 {}

    var M1 = mixin_(name: 'M1');
    var M1_none = interfaceTypeNone(M1);

    var M2 = mixin_(name: 'M2');
    var M2_none = interfaceTypeNone(M2);

    var M3 = mixin_(name: 'M3');
    var M3_none = interfaceTypeNone(M3);

    var A = class_(name: 'A', mixins: [M2_none, M1_none]);
    var A_none = interfaceTypeNone(A);

    var B = class_(name: 'B', mixins: [M3_none, M1_none]);
    var B_none = interfaceTypeNone(B);

    _checkLeastUpperBound(A_none, B_none, M1_none);
  }

  void test_sharedSuperclass1() {
    // class A {}
    // class B extends A {}
    // class C extends A {}

    var A = class_(name: 'A');
    var A_none = interfaceTypeNone(A);

    var B = class_(name: 'B', superType: A_none);
    var B_none = interfaceTypeNone(B);

    var C = class_(name: 'C', superType: A_none);
    var C_none = interfaceTypeNone(C);

    _checkLeastUpperBound(B_none, C_none, A_none);
  }

  void test_sharedSuperclass1_nullability() {
    var aElement = class_(name: 'A');
    var aQuestion = interfaceTypeQuestion(aElement);
    var aStar = interfaceTypeStar(aElement);
    var aNone = interfaceTypeNone(aElement);

    var bElementNone = class_(name: 'B', superType: aNone);
    var bElementStar = class_(name: 'B', superType: aStar);

    var cElementNone = class_(name: 'C', superType: aNone);
    var cElementStar = class_(name: 'C', superType: aStar);

    InterfaceType bTypeElementNone(NullabilitySuffix nullability) {
      return interfaceType(
        bElementNone,
        nullabilitySuffix: nullability,
      );
    }

    InterfaceType bTypeElementStar(NullabilitySuffix nullability) {
      return interfaceType(
        bElementStar,
        nullabilitySuffix: nullability,
      );
    }

    var bNoneQuestion = bTypeElementNone(NullabilitySuffix.question);
    var bNoneStar = bTypeElementNone(NullabilitySuffix.star);
    var bNoneNone = bTypeElementNone(NullabilitySuffix.none);

    var bStarQuestion = bTypeElementStar(NullabilitySuffix.question);
    var bStarStar = bTypeElementStar(NullabilitySuffix.star);
    var bStarNone = bTypeElementStar(NullabilitySuffix.none);

    InterfaceType cTypeElementNone(NullabilitySuffix nullability) {
      return interfaceType(
        cElementNone,
        nullabilitySuffix: nullability,
      );
    }

    InterfaceType cTypeElementStar(NullabilitySuffix nullability) {
      return interfaceType(
        cElementStar,
        nullabilitySuffix: nullability,
      );
    }

    var cNoneQuestion = cTypeElementNone(NullabilitySuffix.question);
    var cNoneStar = cTypeElementNone(NullabilitySuffix.star);
    var cNoneNone = cTypeElementNone(NullabilitySuffix.none);

    var cStarQuestion = cTypeElementStar(NullabilitySuffix.question);
    var cStarStar = cTypeElementStar(NullabilitySuffix.star);
    var cStarNone = cTypeElementStar(NullabilitySuffix.none);

    void assertLUB(DartType type1, DartType type2, DartType expected) {
      expect(typeSystem.getLeastUpperBound(type1, type2), expected);
      expect(typeSystem.getLeastUpperBound(type2, type1), expected);
    }

    assertLUB(bNoneQuestion, cNoneQuestion, aQuestion);
    assertLUB(bNoneQuestion, cNoneStar, aQuestion);
    assertLUB(bNoneQuestion, cNoneNone, aQuestion);
    assertLUB(bNoneQuestion, cStarQuestion, aQuestion);
    assertLUB(bNoneQuestion, cStarStar, aQuestion);
    assertLUB(bNoneQuestion, cStarNone, aQuestion);

    assertLUB(bNoneStar, cNoneQuestion, aQuestion);
    assertLUB(bNoneStar, cNoneStar, aStar);
    assertLUB(bNoneStar, cNoneNone, aStar);
    assertLUB(bNoneStar, cStarQuestion, aQuestion);
    assertLUB(bNoneStar, cStarStar, aStar);
    assertLUB(bNoneStar, cStarNone, aStar);

    assertLUB(bNoneNone, cNoneQuestion, aQuestion);
    assertLUB(bNoneNone, cNoneStar, aStar);
    assertLUB(bNoneNone, cNoneNone, aNone);
    assertLUB(bNoneNone, cStarQuestion, aQuestion);
    assertLUB(bNoneNone, cStarStar, aStar);
    assertLUB(bNoneNone, cStarNone, aNone);

    assertLUB(bStarQuestion, cNoneQuestion, aQuestion);
    assertLUB(bStarQuestion, cNoneStar, aQuestion);
    assertLUB(bStarQuestion, cNoneNone, aQuestion);
    assertLUB(bStarQuestion, cStarQuestion, aQuestion);
    assertLUB(bStarQuestion, cStarStar, aQuestion);
    assertLUB(bStarQuestion, cStarNone, aQuestion);

    assertLUB(bStarStar, cNoneQuestion, aQuestion);
    assertLUB(bStarStar, cNoneStar, aStar);
    assertLUB(bStarStar, cNoneNone, aStar);
    assertLUB(bStarStar, cStarQuestion, aQuestion);
    assertLUB(bStarStar, cStarStar, aStar);
    assertLUB(bStarStar, cStarNone, aStar);

    assertLUB(bStarNone, cNoneQuestion, aQuestion);
    assertLUB(bStarNone, cNoneStar, aStar);
    assertLUB(bStarNone, cNoneNone, aNone);
    assertLUB(bStarNone, cStarQuestion, aQuestion);
    assertLUB(bStarNone, cStarStar, aStar);
    assertLUB(bStarNone, cStarNone, aNone);
  }

  void test_sharedSuperclass2() {
    // class A {}
    // class B extends A {}
    // class C extends A {}
    // class D extends C {}

    var A = class_(name: 'A');
    var A_none = interfaceTypeNone(A);

    var B = class_(name: 'B', superType: A_none);
    var B_none = interfaceTypeNone(B);

    var C = class_(name: 'C', superType: A_none);
    var C_none = interfaceTypeNone(C);

    var D = class_(name: 'D', superType: C_none);
    var D_none = interfaceTypeNone(D);

    _checkLeastUpperBound(B_none, D_none, A_none);
  }

  void test_sharedSuperclass3() {
    // class A {}
    // class B extends A {}
    // class C extends B {}
    // class D extends B {}

    var A = class_(name: 'A');
    var A_none = interfaceTypeNone(A);

    var B = class_(name: 'B', superType: A_none);
    var B_none = interfaceTypeNone(B);

    var C = class_(name: 'C', superType: B_none);
    var C_none = interfaceTypeNone(C);

    var D = class_(name: 'D', superType: B_none);
    var D_none = interfaceTypeNone(D);

    _checkLeastUpperBound(C_none, D_none, B_none);
  }

  void test_sharedSuperclass4() {
    // class A {}
    // class A2 {}
    // class A3 {}
    // class B extends A implements A2 {}
    // class C extends A implement A3 {}

    var A = class_(name: 'A');
    var A_none = interfaceTypeNone(A);

    var A2 = class_(name: 'A2');
    var A2_none = interfaceTypeNone(A2);

    var A3 = class_(name: 'A3');
    var A3_none = interfaceTypeNone(A3);

    var B = class_(name: 'B', superType: A_none, interfaces: [A2_none]);
    var B_none = interfaceTypeNone(B);

    var C = class_(name: 'C', superType: A_none, interfaces: [A3_none]);
    var C_none = interfaceTypeNone(C);

    _checkLeastUpperBound(B_none, C_none, A_none);
  }

  void test_sharedSuperinterface1() {
    // class A {}
    // class B implements A {}
    // class C implements A {}

    var A = class_(name: 'A');
    var A_none = interfaceTypeNone(A);

    var B = class_(name: 'B', interfaces: [A_none]);
    var B_none = interfaceTypeNone(B);

    var C = class_(name: 'C', interfaces: [A_none]);
    var C_none = interfaceTypeNone(C);

    _checkLeastUpperBound(B_none, C_none, A_none);
  }

  void test_sharedSuperinterface2() {
    // class A {}
    // class B implements A {}
    // class C implements A {}
    // class D implements C {}

    var A = class_(name: 'A');
    var A_none = interfaceTypeNone(A);

    var B = class_(name: 'B', interfaces: [A_none]);
    var B_none = interfaceTypeNone(B);

    var C = class_(name: 'C', interfaces: [A_none]);
    var C_none = interfaceTypeNone(C);

    var D = class_(name: 'D', interfaces: [C_none]);
    var D_none = interfaceTypeNone(D);

    _checkLeastUpperBound(B_none, D_none, A_none);
  }

  void test_sharedSuperinterface3() {
    // class A {}
    // class B implements A {}
    // class C implements B {}
    // class D implements B {}

    var A = class_(name: 'A');
    var A_none = interfaceTypeNone(A);

    var B = class_(name: 'B', interfaces: [A_none]);
    var B_none = interfaceTypeNone(B);

    var C = class_(name: 'C', interfaces: [B_none]);
    var C_none = interfaceTypeNone(C);

    var D = class_(name: 'D', interfaces: [B_none]);
    var D_none = interfaceTypeNone(D);

    _checkLeastUpperBound(C_none, D_none, B_none);
  }

  void test_sharedSuperinterface4() {
    // class A {}
    // class A2 {}
    // class A3 {}
    // class B implements A, A2 {}
    // class C implements A, A3 {}

    var A = class_(name: 'A');
    var A_none = interfaceTypeNone(A);

    var A2 = class_(name: 'A2');
    var A2_none = interfaceTypeNone(A2);

    var A3 = class_(name: 'A3');
    var A3_none = interfaceTypeNone(A3);

    var B = class_(name: 'B', interfaces: [A_none, A2_none]);
    var B_none = interfaceTypeNone(B);

    var C = class_(name: 'C', interfaces: [A_none, A3_none]);
    var C_none = interfaceTypeNone(C);

    _checkLeastUpperBound(B_none, C_none, A_none);
  }
}

@reflectiveTest
class UpperBoundTest extends _BoundsTestBase {
  test_bottom_any() {
    void check(DartType T1, DartType T2) {
      _assertBottom(T1);
      _assertNotBottom(T2);
      _checkLeastUpperBound(T1, T2, T2);
    }

    check(neverNone, dynamicNone);

    check(neverNone, objectNone);
    check(neverNone, objectStar);
    check(neverNone, objectQuestion);

    check(neverNone, intNone);
    check(neverNone, intQuestion);
    check(neverNone, intStar);

    check(neverNone, listNone(intNone));
    check(neverNone, listQuestion(intNone));
    check(neverNone, listStar(intNone));

    check(neverNone, futureOrNone(intNone));
    check(neverNone, futureOrQuestion(intNone));
    check(neverNone, futureOrStar(intNone));

    check(neverNone, functionTypeNone(returnType: voidNone));
    check(neverNone, functionTypeQuestion(returnType: voidNone));
    check(neverNone, functionTypeStar(returnType: voidNone));

    {
      var T = typeParameter('T');
      check(neverNone, typeParameterTypeNone(T));
      check(neverNone, typeParameterTypeQuestion(T));
      check(neverNone, typeParameterTypeStar(T));
    }

    {
      var T = typeParameterTypeNone(
        typeParameter('T', bound: neverNone),
      );
      check(T, intNone);
      check(T, intQuestion);
      check(T, intStar);
    }

    {
      var T = promotedTypeParameterTypeNone(
        typeParameter('T', bound: objectQuestion),
        neverNone,
      );
      check(T, intNone);
      check(T, intQuestion);
      check(T, intStar);
    }
  }

  test_bottom_bottom() {
    void check(DartType T1, DartType T2) {
      _assertBottom(T1);
      _assertBottom(T2);
      _checkLeastUpperBound(T1, T2, T2);
    }

    check(
      neverNone,
      typeParameterTypeNone(
        typeParameter('T', bound: neverNone),
      ),
    );

    check(
      neverNone,
      promotedTypeParameterTypeNone(
        typeParameter('T', bound: objectQuestion),
        neverNone,
      ),
    );
  }

  test_functionType_interfaceType() {
    void check(FunctionType T1, InterfaceType T2, InterfaceType expected) {
      _checkLeastUpperBound(T1, T2, expected);
    }

    check(
      functionTypeNone(returnType: voidNone),
      intNone,
      objectNone,
    );
  }

  test_functionType_interfaceType_Function() {
    void check(FunctionType T1, InterfaceType T2, InterfaceType expected) {
      _checkLeastUpperBound(T1, T2, expected);
    }

    void checkNone(FunctionType T1) {
      _assertNullabilityNone(T1);
      check(T1, functionNone, functionNone);
    }

    checkNone(functionTypeNone(returnType: voidNone));

    checkNone(
      functionTypeNone(
        returnType: intNone,
        parameters: [
          requiredParameter(type: numQuestion),
        ],
      ),
    );

    check(
      functionTypeQuestion(returnType: voidNone),
      functionNone,
      functionQuestion,
    );
  }

  /// UP(Future<T1>, FutureOr<T2>) = FutureOr<T3> where T3 = UP(T1, T2)
  /// UP(FutureOr<T1>, Future<T2>) = FutureOr<T3> where T3 = UP(T1, T2)
  test_futureOr_future() {
    void check(DartType T1, DartType T2, DartType expected) {
      _checkLeastUpperBound(
        futureNone(T1),
        futureOrNone(T2),
        futureOrNone(expected),
      );
    }

    check(intNone, doubleNone, numNone);
    check(intNone, stringNone, objectNone);
  }

  /// UP(FutureOr<T1>, FutureOr<T2>) = FutureOr<T3> where T3 = UP(T1, T2)
  test_futureOr_futureOr() {
    void check(DartType T1, DartType T2, DartType expected) {
      _checkLeastUpperBound(
        futureOrNone(T1),
        futureOrNone(T2),
        futureOrNone(expected),
      );
    }

    check(intNone, doubleNone, numNone);
    check(intNone, stringNone, objectNone);
  }

  /// UP(T1, FutureOr<T2>) = FutureOr<T3> where T3 = UP(T1, T2)
  /// UP(FutureOr<T1>, T2) = FutureOr<T3> where T3 = UP(T1, T2)
  test_futureOr_other() {
    void check(DartType T1, DartType T2, DartType expected) {
      _checkLeastUpperBound(
        futureOrNone(T1),
        T2,
        futureOrNone(expected),
      );
    }

    check(intNone, doubleNone, numNone);
    check(intNone, stringNone, objectNone);
  }

  test_identical() {
    void check(DartType type) {
      _checkLeastUpperBound(type, type, type);
    }

    check(intNone);
    check(intQuestion);
    check(intStar);
    check(listNone(intNone));
  }

  void test_interfaceType_functionType() {
    var A = class_(name: 'A');

    _checkLeastUpperBound(
      interfaceTypeNone(A),
      functionTypeNone(returnType: voidNone),
      objectNone,
    );
  }

  test_none_question() {
    void check(DartType T1, DartType T2, DartType expected) {
      _assertNullabilityNone(T1);
      _assertNullabilityQuestion(T2);

      _assertNotSpecial(T1);
      _assertNotSpecial(T2);

      _checkLeastUpperBound(T1, T2, expected);
    }

    check(doubleNone, intQuestion, numQuestion);
    check(numNone, doubleQuestion, numQuestion);
    check(numNone, intQuestion, numQuestion);
  }

  test_none_star() {
    void check(DartType T1, DartType T2, DartType expected) {
      _assertNullabilityNone(T1);
      _assertNullabilityStar(T2);

      _assertNotSpecial(T1);
      _assertNotSpecial(T2);

      _checkLeastUpperBound(T1, T2, expected);
    }

    check(doubleNone, intStar, numStar);
    check(numNone, doubleStar, numStar);
    check(numNone, intStar, numStar);
  }

  test_null_any() {
    void check(DartType T1, DartType T2, DartType expected) {
      _assertNull(T1);
      _assertNotNull(T2);

      _assertNotTop(T1);
      _assertNotTop(T2);

      _assertNotBottom(T1);
      _assertNotBottom(T2);

      _checkLeastUpperBound(T1, T2, expected);
    }

    check(nullNone, objectNone, objectQuestion);

    check(nullNone, intNone, intQuestion);
    check(nullNone, intQuestion, intQuestion);
    check(nullNone, intStar, intStar);

    check(nullQuestion, intNone, intQuestion);
    check(nullQuestion, intQuestion, intQuestion);
    check(nullQuestion, intStar, intStar);

    check(nullStar, intNone, intStar);
    check(nullStar, intQuestion, intQuestion);
    check(nullStar, intStar, intStar);

    check(nullNone, listNone(intNone), listQuestion(intNone));
    check(nullNone, listQuestion(intNone), listQuestion(intNone));
    check(nullNone, listStar(intNone), listStar(intNone));

    check(nullNone, futureOrNone(intNone), futureOrQuestion(intNone));
    check(nullNone, futureOrQuestion(intNone), futureOrQuestion(intNone));
    check(nullNone, futureOrStar(intNone), futureOrStar(intNone));

    check(nullNone, futureOrNone(intQuestion), futureOrNone(intQuestion));
    check(nullNone, futureOrStar(intQuestion), futureOrStar(intQuestion));

    check(
      nullNone,
      functionTypeNone(returnType: intNone),
      functionTypeQuestion(returnType: intNone),
    );
  }

  test_null_null() {
    void check(DartType T1, DartType T2) {
      _assertNull(T1);
      _assertNull(T2);

      _assertNotBottom(T1);
      _assertNotBottom(T2);

      _checkLeastUpperBound(T1, T2, T2);
    }

    check(nullNone, nullQuestion);
    check(nullNone, nullStar);
  }

  test_object_any() {
    void check(DartType T1, DartType T2, DartType expected) {
      _assertObject(T1);
      _assertNotObject(T2);

      _checkLeastUpperBound(T1, T2, expected);
    }

    check(objectNone, intNone, objectNone);
    check(objectNone, intQuestion, objectQuestion);
    check(objectNone, intStar, objectNone);

    check(objectNone, futureOrNone(intQuestion), objectQuestion);

    check(futureOrNone(objectNone), intNone, futureOrNone(objectNone));
    check(futureOrNone(objectNone), intQuestion, futureOrQuestion(objectNone));
    check(futureOrNone(objectNone), intStar, futureOrNone(objectNone));
  }

  test_object_object() {
    void check(DartType T1, DartType T2) {
      _assertObject(T1);
      _assertObject(T2);

      _checkLeastUpperBound(T1, T2, T2);
    }

    check(futureOrNone(objectNone), objectNone);

    check(
      futureOrNone(
        futureOrNone(objectNone),
      ),
      futureOrNone(objectNone),
    );
  }

  test_question_question() {
    void check(DartType T1, DartType T2, DartType expected) {
      _assertNullabilityQuestion(T1);
      _assertNullabilityQuestion(T2);

      _assertNotSpecial(T1);
      _assertNotSpecial(T2);

      _checkLeastUpperBound(T1, T2, expected);
    }

    check(doubleQuestion, intQuestion, numQuestion);
    check(numQuestion, doubleQuestion, numQuestion);
    check(numQuestion, intQuestion, numQuestion);
  }

  test_question_star() {
    void check(DartType T1, DartType T2, DartType expected) {
      _assertNullabilityQuestion(T1);
      _assertNullabilityStar(T2);

      _assertNotSpecial(T1);
      _assertNotSpecial(T2);

      _checkLeastUpperBound(T1, T2, expected);
    }

    check(doubleQuestion, intStar, numQuestion);
    check(numQuestion, doubleStar, numQuestion);
    check(numQuestion, intStar, numQuestion);
  }

  test_star_star() {
    void check(DartType T1, DartType T2, DartType expected) {
      _assertNullabilityStar(T1);
      _assertNullabilityStar(T2);

      _assertNotSpecial(T1);
      _assertNotSpecial(T2);

      _checkLeastUpperBound(T1, T2, expected);
    }

    check(doubleStar, intStar, numStar);
    check(numStar, doubleStar, numStar);
    check(numStar, intStar, numStar);
  }

  test_top_any() {
    void check(DartType T1, DartType T2) {
      _assertTop(T1);
      _assertNotTop(T2);
      _checkLeastUpperBound(T1, T2, T1);
    }

    void check2(DartType T1) {
      check(T1, objectNone);
      check(T1, intNone);
      check(T1, intQuestion);
      check(T1, intStar);
      check(T1, listNone(intNone));
      check(T1, futureOrNone(intNone));
      check(T1, functionTypeNone(returnType: voidNone));

      {
        var T = typeParameter('T');
        check(T1, typeParameterTypeNone(T));
        check(T1, typeParameterTypeQuestion(T));
        check(T1, typeParameterTypeStar(T));
      }
    }

    check2(voidNone);
    check2(dynamicNone);
    check2(objectQuestion);
    check2(objectStar);

    check2(futureOrNone(voidNone));
    check2(futureOrQuestion(voidNone));
    check2(futureOrStar(voidNone));
  }

  test_top_top() {
    void check(DartType T1, DartType T2) {
      _assertTop(T1);
      _assertTop(T2);
      _checkLeastUpperBound(T1, T2, T1);
    }

    check(voidNone, dynamicNone);
    check(voidNone, objectStar);
    check(voidNone, objectQuestion);
    check(voidNone, futureOrNone(voidNone));
    check(voidNone, futureOrNone(dynamicNone));
    check(voidNone, futureOrNone(objectQuestion));
    check(voidNone, futureOrNone(objectStar));

    check(dynamicNone, objectStar);
    check(dynamicNone, objectQuestion);
    check(dynamicNone, futureOrNone(voidNone));
    check(dynamicNone, futureOrNone(dynamicNone));
    check(dynamicNone, futureOrNone(objectQuestion));
    check(dynamicNone, futureOrNone(objectStar));
    check(
      dynamicNone,
      futureOrStar(objectStar),
    );

    check(objectQuestion, futureOrQuestion(voidNone));
    check(objectQuestion, futureOrQuestion(dynamicNone));
    check(objectQuestion, futureOrQuestion(objectNone));
    check(objectQuestion, futureOrQuestion(objectQuestion));
    check(objectQuestion, futureOrQuestion(objectStar));

    check(objectQuestion, futureOrStar(voidNone));
    check(objectQuestion, futureOrStar(dynamicNone));
    check(objectQuestion, futureOrStar(objectNone));
    check(objectQuestion, futureOrStar(objectQuestion));
    check(objectQuestion, futureOrStar(objectStar));

    check(objectStar, futureOrStar(voidNone));
    check(objectStar, futureOrStar(dynamicNone));
    check(objectStar, futureOrStar(objectNone));
    check(objectStar, futureOrStar(objectQuestion));
    check(objectStar, futureOrStar(objectStar));

    check(futureOrNone(voidNone), objectQuestion);
    check(futureOrNone(dynamicNone), objectQuestion);
    check(futureOrNone(objectQuestion), objectQuestion);
    check(futureOrNone(objectStar), objectQuestion);

    check(futureOrNone(voidNone), futureOrNone(dynamicNone));
    check(futureOrNone(voidNone), futureOrNone(objectQuestion));
    check(futureOrNone(voidNone), futureOrNone(objectStar));
    check(futureOrNone(dynamicNone), futureOrNone(objectQuestion));
    check(futureOrNone(dynamicNone), futureOrNone(objectStar));
  }

  test_typeParameter_bound() {
    void check(TypeParameterType T1, DartType T2, DartType expected) {
      _assertNullabilityNone(T1);
      _assertNullabilityNone(T2);

      _assertNotSpecial(T1);
      _assertNotSpecial(T2);

      _checkLeastUpperBound(T1, T2, expected);
    }

    {
      var T = typeParameter('T', bound: intNone);
      check(typeParameterTypeNone(T), numNone, numNone);
    }

    {
      var T = typeParameter('T', bound: intNone);
      var U = typeParameter('U', bound: numNone);
      check(typeParameterTypeNone(T), typeParameterTypeNone(U), numNone);
    }

    {
      var T = typeParameter('T', bound: intNone);
      var U = typeParameter('U', bound: numQuestion);
      check(typeParameterTypeNone(T), typeParameterTypeNone(U), numQuestion);
    }

    {
      var T = typeParameter('T', bound: intQuestion);
      var U = typeParameter('U', bound: numNone);
      check(typeParameterTypeNone(T), typeParameterTypeNone(U), numQuestion);
    }

    {
      var T = typeParameter('T', bound: numNone);
      var T_none = typeParameterTypeNone(T);
      var U = typeParameter('U', bound: T_none);
      check(T_none, typeParameterTypeNone(U), T_none);
    }
  }

  void test_typeParameter_fBounded() {
    // class A<T> {}
    var T = typeParameter('T');
    var A = class_(name: 'A', typeParameters: [T]);

    // <S extends A<S>>
    var S = typeParameter('S');
    var S_none = typeParameterTypeNone(S);
    S.bound = interfaceTypeNone(A, typeArguments: [S_none]);

    // <U extends A<U>>
    var U = typeParameter('U');
    var U_none = typeParameterTypeNone(U);
    U.bound = interfaceTypeNone(A, typeArguments: [U_none]);

    _checkLeastUpperBound(
      S_none,
      typeParameterTypeNone(U),
      interfaceTypeNone(A, typeArguments: [objectQuestion]),
    );
  }

  void test_typeParameter_function_bounded() {
    var T = typeParameter('T', bound: typeProvider.functionType);

    _checkLeastUpperBound(
      typeParameterTypeNone(T),
      functionTypeNone(returnType: voidNone),
      typeProvider.functionType,
    );
  }

  void test_typeParameter_function_noBound() {
    var T = typeParameter('T', bound: objectQuestion);

    _checkLeastUpperBound(
      typeParameterTypeNone(T),
      functionTypeNone(returnType: voidNone),
      objectQuestion,
    );
  }

  void test_typeParameter_greatestClosure_functionBounded() {
    var T = typeParameter('T');
    var T_none = typeParameterTypeNone(T);
    T.bound = functionTypeNone(
      returnType: voidNone,
      parameters: [
        requiredParameter(type: T_none),
      ],
    );

    _checkLeastUpperBound(
      T_none,
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          requiredParameter(type: nullNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          requiredParameter(type: neverNone),
        ],
      ),
    );
  }

  void test_typeParameter_greatestClosure_functionPromoted() {
    var T = typeParameter('T');
    var T_none = typeParameterTypeNone(T);
    var T_none_promoted = typeParameterTypeNone(
      T,
      promotedBound: functionTypeNone(
        returnType: voidNone,
        parameters: [
          requiredParameter(type: T_none),
        ],
      ),
    );

    _checkLeastUpperBound(
      T_none_promoted,
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          requiredParameter(type: nullNone),
        ],
      ),
      functionTypeNone(
        returnType: voidNone,
        parameters: [
          requiredParameter(type: neverNone),
        ],
      ),
    );
  }

  void test_typeParameter_interface_bounded() {
    var A = class_(name: 'A');
    var A_none = interfaceTypeNone(A);

    var B = class_(name: 'B', superType: A_none);
    var B_none = interfaceTypeNone(B);

    var C = class_(name: 'C', superType: A_none);
    var C_none = interfaceTypeNone(C);

    var T = typeParameter('T', bound: B_none);
    var typeT = typeParameterTypeNone(T);

    _checkLeastUpperBound(typeT, C_none, A_none);
  }

  void test_typeParameter_interface_bounded_objectQuestion() {
    var T = typeParameter('T', bound: objectQuestion);

    _checkLeastUpperBound(
      typeParameterTypeNone(T),
      intNone,
      objectQuestion,
    );
  }

  void test_typeParameter_interface_noBound() {
    var T = typeParameter('T');

    _checkLeastUpperBound(
      typeParameterTypeNone(T),
      intNone,
      objectQuestion,
    );
  }

  void test_typeParameters_contravariant_different() {
    // class A<in T>
    var T = typeParameter('T', variance: Variance.contravariant);
    var A = class_(name: 'A', typeParameters: [T]);

    // A<num>
    // A<int>
    var A_num = interfaceTypeNone(A, typeArguments: [numNone]);
    var A_int = interfaceTypeNone(A, typeArguments: [intNone]);

    _checkLeastUpperBound(A_int, A_num, A_int);
  }

  void test_typeParameters_contravariant_same() {
    // class A<in T>
    var T = typeParameter('T', variance: Variance.contravariant);
    var A = class_(name: 'A', typeParameters: [T]);

    // A<num>
    var A_num = interfaceTypeNone(A, typeArguments: [numNone]);

    _checkLeastUpperBound(A_num, A_num, A_num);
  }

  void test_typeParameters_covariant_different() {
    // class A<out T>
    var T = typeParameter('T', variance: Variance.covariant);
    var A = class_(name: 'A', typeParameters: [T]);

    // A<num>
    // A<int>
    var A_num = interfaceTypeNone(A, typeArguments: [numNone]);
    var A_int = interfaceTypeNone(A, typeArguments: [intNone]);

    _checkLeastUpperBound(A_int, A_num, A_num);
  }

  void test_typeParameters_covariant_same() {
    // class A<out T>
    var T = typeParameter('T', variance: Variance.covariant);
    var A = class_(name: 'A', typeParameters: [T]);

    // A<num>
    var A_num = interfaceTypeStar(A, typeArguments: [numNone]);

    _checkLeastUpperBound(A_num, A_num, A_num);
  }

  void test_typeParameters_invariant_object() {
    // class A<inout T>
    var T = typeParameter('T', variance: Variance.invariant);
    var A = class_(name: 'A', typeParameters: [T]);

    // A<num>
    // A<int>
    var A_num = interfaceTypeNone(A, typeArguments: [numNone]);
    var A_int = interfaceTypeNone(A, typeArguments: [intNone]);

    _checkLeastUpperBound(A_num, A_int, objectNone);
  }

  void test_typeParameters_invariant_same() {
    // class A<inout T>
    var T = typeParameter('T', variance: Variance.invariant);
    var A = class_(name: 'A', typeParameters: [T]);

    // A<num>
    var A_num = interfaceTypeNone(A, typeArguments: [numNone]);

    _checkLeastUpperBound(A_num, A_num, A_num);
  }

  void test_typeParameters_multi_basic() {
    // class A<out T, inout U, in V>
    var T = typeParameter('T', variance: Variance.covariant);
    var U = typeParameter('U', variance: Variance.invariant);
    var V = typeParameter('V', variance: Variance.contravariant);
    var A = class_(name: 'A', typeParameters: [T, U, V]);

    // A<num, num, num>
    // A<int, num, int>
    var A_num_num_num = interfaceTypeNone(
      A,
      typeArguments: [numNone, numNone, numNone],
    );
    var A_int_num_int = interfaceTypeNone(
      A,
      typeArguments: [intNone, numNone, intNone],
    );

    // We expect A<num, num, int>
    var A_num_num_int = interfaceTypeNone(
      A,
      typeArguments: [numNone, numNone, intNone],
    );

    _checkLeastUpperBound(A_num_num_num, A_int_num_int, A_num_num_int);
  }

  void test_typeParameters_multi_objectInterface() {
    // class A<out T, inout U, in V>
    var T = typeParameter('T', variance: Variance.covariant);
    var U = typeParameter('T', variance: Variance.invariant);
    var V = typeParameter('T', variance: Variance.contravariant);
    var A = class_(name: 'A', typeParameters: [T, U, V]);

    // A<num, String, num>
    // A<int, num, int>
    var A_num_String_num = interfaceTypeNone(
      A,
      typeArguments: [numNone, stringNone, numNone],
    );
    var A_int_num_int = interfaceTypeNone(
      A,
      typeArguments: [intNone, numNone, intNone],
    );

    _checkLeastUpperBound(A_num_String_num, A_int_num_int, objectNone);
  }

  void test_typeParameters_multi_objectType() {
    // class A<out T, inout U, in V>
    var T = typeParameter('T', variance: Variance.covariant);
    var U = typeParameter('T', variance: Variance.invariant);
    var V = typeParameter('T', variance: Variance.contravariant);
    var A = class_(name: 'A', typeParameters: [T, U, V]);

    // A<String, num, num>
    // A<int, num, int>
    var A_String_num_num = interfaceTypeNone(
      A,
      typeArguments: [stringNone, numNone, numNone],
    );
    var A_int_num_int = interfaceTypeNone(
      A,
      typeArguments: [intNone, numNone, intNone],
    );

    // We expect A<Object, num, int>
    var A_Object_num_int = interfaceTypeNone(
      A,
      typeArguments: [objectNone, numNone, intNone],
    );

    _checkLeastUpperBound(A_String_num_num, A_int_num_int, A_Object_num_int);
  }

  /// Check least upper bound of the same class with different type parameters.
  void test_typeParameters_noVariance_different() {
    _checkLeastUpperBound(
      listNone(intNone),
      listNone(doubleNone),
      listNone(numNone),
    );
  }

  void test_typeParameters_noVariance_same() {
    var listOfInt = listNone(intNone);
    _checkLeastUpperBound(listOfInt, listOfInt, listOfInt);
  }
}

@reflectiveTest
class _BoundsTestBase extends AbstractTypeSystemTest {
  void _assertBottom(DartType type) {
    if (!typeSystem.isBottom(type)) {
      fail('isBottom must be true: ' + _typeString(type));
    }
  }

  void _assertNotBottom(DartType type) {
    if (typeSystem.isBottom(type)) {
      fail('isBottom must be false: ' + _typeString(type));
    }
  }

  void _assertNotNull(DartType type) {
    if (typeSystem.isNull(type)) {
      fail('isNull must be false: ' + _typeString(type));
    }
  }

  void _assertNotObject(DartType type) {
    if (typeSystem.isObject(type)) {
      fail('isObject must be false: ' + _typeString(type));
    }
  }

  void _assertNotSpecial(DartType type) {
    _assertNotBottom(type);
    _assertNotNull(type);
    _assertNotObject(type);
    _assertNotTop(type);
  }

  void _assertNotTop(DartType type) {
    if (typeSystem.isTop(type)) {
      fail('isTop must be false: ' + _typeString(type));
    }
  }

  void _assertNull(DartType type) {
    if (!typeSystem.isNull(type)) {
      fail('isNull must be true: ' + _typeString(type));
    }
  }

  void _assertNullability(DartType type, NullabilitySuffix expected) {
    if (type.nullabilitySuffix != expected) {
      fail('Expected $expected in ' + _typeString(type));
    }
  }

  void _assertNullabilityNone(DartType type) {
    _assertNullability(type, NullabilitySuffix.none);
  }

  void _assertNullabilityQuestion(DartType type) {
    _assertNullability(type, NullabilitySuffix.question);
  }

  void _assertNullabilityStar(DartType type) {
    _assertNullability(type, NullabilitySuffix.star);
  }

  void _assertObject(DartType type) {
    if (!typeSystem.isObject(type)) {
      fail('isObject must be true: ' + _typeString(type));
    }
  }

  void _assertTop(DartType type) {
    if (!typeSystem.isTop(type)) {
      fail('isTop must be true: ' + _typeString(type));
    }
  }

  void _checkLeastUpperBound(DartType T1, DartType T2, DartType expected) {
    var expectedStr = _typeString(expected);

    var result = typeSystem.getLeastUpperBound(T1, T2);
    var resultStr = _typeString(result);
    expect(result, expected, reason: '''
expected: $expectedStr
actual: $resultStr
''');

    // Check that the result is an upper bound.
    expect(typeSystem.isSubtypeOf(T1, result), true);
    expect(typeSystem.isSubtypeOf(T2, result), true);

    // Check for symmetry.
    result = typeSystem.getLeastUpperBound(T2, T1);
    resultStr = _typeString(result);
    expect(result, expected, reason: '''
expected: $expectedStr
actual: $resultStr
''');
  }

  String _typeParametersStr(DartType type) {
    var typeStr = '';

    var typeParameterCollector = _TypeParameterCollector();
    type.accept(typeParameterCollector);
    for (var typeParameter in typeParameterCollector.typeParameters) {
      typeStr += ', $typeParameter';
    }
    return typeStr;
  }

  String _typeString(DartType type) {
    return type.getDisplayString(withNullability: true) +
        _typeParametersStr(type);
  }
}

class _TypeParameterCollector
    implements TypeVisitor<void>, InferenceTypeVisitor<void> {
  final Set<String> typeParameters = {};

  /// We don't need to print bounds for these type parameters, because
  /// they are already included into the function type itself, and cannot
  /// be promoted.
  final Set<TypeParameterElement> functionTypeParameters = {};

  @override
  void visitDynamicType(DynamicType type) {}

  @override
  void visitFunctionType(FunctionType type) {
    functionTypeParameters.addAll(type.typeFormals);
    for (var typeParameter in type.typeFormals) {
      var bound = typeParameter.bound;
      if (bound != null) {
        bound.accept(this);
      }
    }
    for (var parameter in type.parameters) {
      parameter.type.accept(this);
    }
    type.returnType.accept(this);
  }

  @override
  void visitInterfaceType(InterfaceType type) {
    for (var typeArgument in type.typeArguments) {
      typeArgument.accept(this);
    }
  }

  @override
  void visitNeverType(NeverType type) {}

  @override
  void visitTypeParameterType(TypeParameterType type) {
    if (!functionTypeParameters.contains(type.element)) {
      var bound = type.element.bound;
      var promotedBound = (type as TypeParameterTypeImpl).promotedBound;

      if (bound == null && promotedBound == null) {
        return;
      }

      var str = '';

      if (bound != null) {
        var boundStr = bound.getDisplayString(withNullability: true);
        str += '${type.element.name} extends ' + boundStr;
      }

      if (promotedBound != null) {
        var promotedBoundStr = promotedBound.getDisplayString(
          withNullability: true,
        );
        if (str.isNotEmpty) {
          str += ', ';
        }
        str += '${type.element.name} & ' + promotedBoundStr;
      }

      typeParameters.add(str);
    }
  }

  @override
  void visitUnknownInferredType(UnknownInferredType type) {}

  @override
  void visitVoidType(VoidType type) {}
}
