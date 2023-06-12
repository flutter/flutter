// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/test_analysis_context.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DartObjectImplTest);
  });
}

const int LONG_MAX_VALUE = 0x7fffffffffffffff;

final Matcher throwsEvaluationException =
    throwsA(TypeMatcher<EvaluationException>());

@reflectiveTest
class DartObjectImplTest {
  late final TypeProvider _typeProvider;
  late final TypeSystemImpl _typeSystem;

  void setUp() {
    var analysisContext = TestAnalysisContext();
    _typeProvider = analysisContext.typeProviderLegacy;
    _typeSystem = analysisContext.typeSystemLegacy;
  }

  void test_add_knownDouble_knownDouble() {
    _assertAdd(_doubleValue(3.0), _doubleValue(1.0), _doubleValue(2.0));
  }

  void test_add_knownDouble_knownInt() {
    _assertAdd(_doubleValue(3.0), _doubleValue(1.0), _intValue(2));
  }

  void test_add_knownDouble_unknownDouble() {
    _assertAdd(_doubleValue(null), _doubleValue(1.0), _doubleValue(null));
  }

  void test_add_knownDouble_unknownInt() {
    _assertAdd(_doubleValue(null), _doubleValue(1.0), _intValue(null));
  }

  void test_add_knownInt_knownInt() {
    _assertAdd(_intValue(3), _intValue(1), _intValue(2));
  }

  void test_add_knownInt_knownString() {
    _assertAdd(null, _intValue(1), _stringValue("2"));
  }

  void test_add_knownInt_unknownDouble() {
    _assertAdd(_doubleValue(null), _intValue(1), _doubleValue(null));
  }

  void test_add_knownInt_unknownInt() {
    _assertAdd(_intValue(null), _intValue(1), _intValue(null));
  }

  void test_add_knownString_knownInt() {
    _assertAdd(null, _stringValue("1"), _intValue(2));
  }

  void test_add_knownString_knownString() {
    _assertAdd(_stringValue("ab"), _stringValue("a"), _stringValue("b"));
  }

  void test_add_knownString_unknownString() {
    _assertAdd(_stringValue(null), _stringValue("a"), _stringValue(null));
  }

  void test_add_unknownDouble_knownDouble() {
    _assertAdd(_doubleValue(null), _doubleValue(null), _doubleValue(2.0));
  }

  void test_add_unknownDouble_knownInt() {
    _assertAdd(_doubleValue(null), _doubleValue(null), _intValue(2));
  }

  void test_add_unknownInt_knownDouble() {
    _assertAdd(_doubleValue(null), _intValue(null), _doubleValue(2.0));
  }

  void test_add_unknownInt_knownInt() {
    _assertAdd(_intValue(null), _intValue(null), _intValue(2));
  }

  void test_add_unknownString_knownString() {
    _assertAdd(_stringValue(null), _stringValue(null), _stringValue("b"));
  }

  void test_add_unknownString_unknownString() {
    _assertAdd(_stringValue(null), _stringValue(null), _stringValue(null));
  }

  void test_bitAnd_knownInt_knownInt() {
    _assertEagerAnd(_intValue(2), _intValue(6), _intValue(3));
  }

  void test_bitAnd_knownInt_knownString() {
    _assertEagerAnd(null, _intValue(6), _stringValue("3"));
  }

  void test_bitAnd_knownInt_unknownInt() {
    _assertEagerAnd(_intValue(null), _intValue(6), _intValue(null));
  }

  void test_bitAnd_knownString_knownInt() {
    _assertEagerAnd(null, _stringValue("6"), _intValue(3));
  }

  void test_bitAnd_unknownInt_knownInt() {
    _assertEagerAnd(_intValue(null), _intValue(null), _intValue(3));
  }

  void test_bitAnd_unknownInt_unknownInt() {
    _assertEagerAnd(_intValue(null), _intValue(null), _intValue(null));
  }

  void test_bitNot_knownInt() {
    _assertBitNot(_intValue(-4), _intValue(3));
  }

  void test_bitNot_knownString() {
    _assertBitNot(null, _stringValue("6"));
  }

  void test_bitNot_unknownInt() {
    _assertBitNot(_intValue(null), _intValue(null));
  }

  void test_bitOr_knownInt_knownInt() {
    _assertEagerOr(_intValue(7), _intValue(6), _intValue(3));
  }

  void test_bitOr_knownInt_knownString() {
    _assertEagerOr(null, _intValue(6), _stringValue("3"));
  }

  void test_bitOr_knownInt_unknownInt() {
    _assertEagerOr(_intValue(null), _intValue(6), _intValue(null));
  }

  void test_bitOr_knownString_knownInt() {
    _assertEagerOr(null, _stringValue("6"), _intValue(3));
  }

  void test_bitOr_unknownInt_knownInt() {
    _assertEagerOr(_intValue(null), _intValue(null), _intValue(3));
  }

  void test_bitOr_unknownInt_unknownInt() {
    _assertEagerOr(_intValue(null), _intValue(null), _intValue(null));
  }

  void test_bitXor_knownInt_knownInt() {
    _assertEagerXor(_intValue(5), _intValue(6), _intValue(3));
  }

  void test_bitXor_knownInt_knownString() {
    _assertEagerXor(null, _intValue(6), _stringValue("3"));
  }

  void test_bitXor_knownInt_unknownInt() {
    _assertEagerXor(_intValue(null), _intValue(6), _intValue(null));
  }

  void test_bitXor_knownString_knownInt() {
    _assertEagerXor(null, _stringValue("6"), _intValue(3));
  }

  void test_bitXor_unknownInt_knownInt() {
    _assertEagerXor(_intValue(null), _intValue(null), _intValue(3));
  }

  void test_bitXor_unknownInt_unknownInt() {
    _assertEagerXor(_intValue(null), _intValue(null), _intValue(null));
  }

  void test_concatenate_knownInt_knownString() {
    _assertConcatenate(null, _intValue(2), _stringValue("def"));
  }

  void test_concatenate_knownString_knownInt() {
    _assertConcatenate(null, _stringValue("abc"), _intValue(3));
  }

  void test_concatenate_knownString_knownString() {
    _assertConcatenate(
        _stringValue("abcdef"), _stringValue("abc"), _stringValue("def"));
  }

  void test_concatenate_knownString_unknownString() {
    _assertConcatenate(
        _stringValue(null), _stringValue("abc"), _stringValue(null));
  }

  void test_concatenate_unknownString_knownString() {
    _assertConcatenate(
        _stringValue(null), _stringValue(null), _stringValue("def"));
  }

  void test_divide_knownDouble_knownDouble() {
    _assertDivide(_doubleValue(3.0), _doubleValue(6.0), _doubleValue(2.0));
  }

  void test_divide_knownDouble_knownInt() {
    _assertDivide(_doubleValue(3.0), _doubleValue(6.0), _intValue(2));
  }

  void test_divide_knownDouble_unknownDouble() {
    _assertDivide(_doubleValue(null), _doubleValue(6.0), _doubleValue(null));
  }

  void test_divide_knownDouble_unknownInt() {
    _assertDivide(_doubleValue(null), _doubleValue(6.0), _intValue(null));
  }

  void test_divide_knownInt_knownInt() {
    _assertDivide(_doubleValue(3.0), _intValue(6), _intValue(2));
  }

  void test_divide_knownInt_knownString() {
    _assertDivide(null, _intValue(6), _stringValue("2"));
  }

  void test_divide_knownInt_unknownDouble() {
    _assertDivide(_doubleValue(null), _intValue(6), _doubleValue(null));
  }

  void test_divide_knownInt_unknownInt() {
    _assertDivide(_doubleValue(null), _intValue(6), _intValue(null));
  }

  void test_divide_knownString_knownInt() {
    _assertDivide(null, _stringValue("6"), _intValue(2));
  }

  void test_divide_unknownDouble_knownDouble() {
    _assertDivide(_doubleValue(null), _doubleValue(null), _doubleValue(2.0));
  }

  void test_divide_unknownDouble_knownInt() {
    _assertDivide(_doubleValue(null), _doubleValue(null), _intValue(2));
  }

  void test_divide_unknownInt_knownDouble() {
    _assertDivide(_doubleValue(null), _intValue(null), _doubleValue(2.0));
  }

  void test_divide_unknownInt_knownInt() {
    _assertDivide(_doubleValue(null), _intValue(null), _intValue(2));
  }

  void test_eagerAnd_knownBool_knownBool() {
    void check(bool left, bool right, bool expected) {
      _assertEagerAnd(
        _boolValue(expected),
        _boolValue(left),
        _boolValue(right),
      );
    }

    check(false, false, false);
    check(true, false, false);
    check(false, true, false);
    check(true, true, true);
  }

  void test_eagerAnd_knownBool_knownInt() {
    _assertEagerAnd(null, _boolValue(true), _intValue(0));
  }

  void test_eagerAnd_knownBool_unknownBool() {
    _assertEagerAnd(_boolValue(null), _boolValue(true), _boolValue(null));
  }

  void test_eagerAnd_unknownBool_knownBool() {
    _assertEagerAnd(_boolValue(null), _boolValue(null), _boolValue(true));
  }

  void test_eagerOr_knownBool_knownBool() {
    void check(bool left, bool right, bool expected) {
      _assertEagerOr(
        _boolValue(expected),
        _boolValue(left),
        _boolValue(right),
      );
    }

    check(false, false, false);
    check(true, false, true);
    check(false, true, true);
    check(true, true, true);
  }

  void test_eagerOr_knownBool_knownInt() {
    _assertEagerOr(null, _boolValue(true), _intValue(0));
  }

  void test_eagerOr_knownBool_unknownBool() {
    _assertEagerOr(_boolValue(null), _boolValue(true), _boolValue(null));
  }

  void test_eagerOr_unknownBool_knownBool() {
    _assertEagerOr(_boolValue(null), _boolValue(null), _boolValue(true));
  }

  void test_eagerXor_knownBool_knownBool() {
    void check(bool left, bool right, bool expected) {
      _assertEagerXor(
        _boolValue(expected),
        _boolValue(left),
        _boolValue(right),
      );
    }

    check(false, false, false);
    check(true, false, true);
    check(false, true, true);
    check(true, true, false);
  }

  void test_eagerXor_knownBool_knownInt() {
    _assertEagerXor(null, _boolValue(true), _intValue(0));
  }

  void test_eagerXor_knownBool_unknownBool() {
    _assertEagerXor(_boolValue(null), _boolValue(true), _boolValue(null));
  }

  void test_eagerXor_unknownBool_knownBool() {
    _assertEagerXor(_boolValue(null), _boolValue(null), _boolValue(true));
  }

  void test_equalEqual_bool_false() {
    _assertEqualEqual(_boolValue(false), _boolValue(false), _boolValue(true));
  }

  void test_equalEqual_bool_true() {
    _assertEqualEqual(_boolValue(true), _boolValue(true), _boolValue(true));
  }

  void test_equalEqual_bool_unknown() {
    _assertEqualEqual(_boolValue(null), _boolValue(null), _boolValue(false));
  }

  void test_equalEqual_double_false() {
    _assertEqualEqual(_boolValue(false), _doubleValue(2.0), _doubleValue(4.0));
  }

  void test_equalEqual_double_true() {
    _assertEqualEqual(_boolValue(true), _doubleValue(2.0), _doubleValue(2.0));
  }

  void test_equalEqual_double_unknown() {
    _assertEqualEqual(_boolValue(null), _doubleValue(1.0), _doubleValue(null));
  }

  void test_equalEqual_int_false() {
    _assertEqualEqual(_boolValue(false), _intValue(-5), _intValue(5));
  }

  void test_equalEqual_int_true() {
    _assertEqualEqual(_boolValue(true), _intValue(5), _intValue(5));
  }

  void test_equalEqual_int_unknown() {
    _assertEqualEqual(_boolValue(null), _intValue(null), _intValue(3));
  }

  void test_equalEqual_list_empty() {
    _assertEqualEqual(
      null,
      _listValue(_typeProvider.intType, []),
      _listValue(_typeProvider.intType, []),
    );
  }

  void test_equalEqual_list_false() {
    _assertEqualEqual(
      null,
      _listValue(_typeProvider.intType, []),
      _listValue(_typeProvider.intType, []),
    );
  }

  void test_equalEqual_map_empty() {
    _assertEqualEqual(
      null,
      _mapValue(_typeProvider.intType, _typeProvider.stringType, []),
      _mapValue(_typeProvider.intType, _typeProvider.stringType, []),
    );
  }

  void test_equalEqual_map_false() {
    _assertEqualEqual(
      null,
      _mapValue(_typeProvider.intType, _typeProvider.stringType, []),
      _mapValue(_typeProvider.intType, _typeProvider.stringType, []),
    );
  }

  void test_equalEqual_null() {
    _assertEqualEqual(_boolValue(true), _nullValue(), _nullValue());
  }

  void test_equalEqual_string_false() {
    _assertEqualEqual(
        _boolValue(false), _stringValue("abc"), _stringValue("def"));
  }

  void test_equalEqual_string_true() {
    _assertEqualEqual(
        _boolValue(true), _stringValue("abc"), _stringValue("abc"));
  }

  void test_equalEqual_string_unknown() {
    _assertEqualEqual(
        _boolValue(null), _stringValue(null), _stringValue("def"));
  }

  void test_equals_list_false_differentSizes() {
    expect(
        _listValue(_typeProvider.boolType, [_boolValue(true)]) ==
            _listValue(
                _typeProvider.boolType, [_boolValue(true), _boolValue(false)]),
        isFalse);
  }

  void test_equals_list_false_sameSize() {
    expect(
        _listValue(_typeProvider.boolType, [_boolValue(true)]) ==
            _listValue(_typeProvider.boolType, [_boolValue(false)]),
        isFalse);
  }

  void test_equals_list_true_empty() {
    expect(
      _listValue(_typeProvider.intType, []),
      _listValue(_typeProvider.intType, []),
    );
  }

  void test_equals_list_true_nonEmpty() {
    expect(
      _listValue(_typeProvider.boolType, [_boolValue(true)]),
      _listValue(_typeProvider.boolType, [_boolValue(true)]),
    );
  }

  void test_equals_map_true_empty() {
    expect(
      _mapValue(_typeProvider.intType, _typeProvider.stringType, []),
      _mapValue(_typeProvider.intType, _typeProvider.stringType, []),
    );
  }

  void test_equals_symbol_false() {
    expect(_symbolValue("a") == _symbolValue("b"), isFalse);
  }

  void test_equals_symbol_true() {
    expect(_symbolValue("a"), _symbolValue("a"));
  }

  void test_getValue_bool_false() {
    expect(_boolValue(false).toBoolValue(), false);
  }

  void test_getValue_bool_true() {
    expect(_boolValue(true).toBoolValue(), true);
  }

  void test_getValue_bool_unknown() {
    expect(_boolValue(null).toBoolValue(), isNull);
  }

  void test_getValue_double_known() {
    double value = 2.3;
    expect(_doubleValue(value).toDoubleValue(), value);
  }

  void test_getValue_double_unknown() {
    expect(_doubleValue(null).toDoubleValue(), isNull);
  }

  void test_getValue_int_known() {
    int value = 23;
    expect(_intValue(value).toIntValue(), value);
  }

  void test_getValue_int_unknown() {
    expect(_intValue(null).toIntValue(), isNull);
  }

  void test_getValue_list_empty() {
    var result = _listValue(_typeProvider.intType, []).toListValue();
    _assertInstanceOfObjectArray(result);
    List<Object> array = result as List<Object>;
    expect(array, hasLength(0));
  }

  void test_getValue_list_valid() {
    var result =
        _listValue(_typeProvider.intType, [_intValue(23)]).toListValue();
    _assertInstanceOfObjectArray(result);
    List<Object> array = result as List<Object>;
    expect(array, hasLength(1));
  }

  void test_getValue_map_empty() {
    var result = _mapValue(_typeProvider.intType, _typeProvider.stringType, [])
        .toMapValue();
    expect(result, hasLength(0));
  }

  void test_getValue_map_valid() {
    var result = _mapValue(_typeProvider.stringType, _typeProvider.stringType,
        [_stringValue("key"), _stringValue("value")]).toMapValue();
    expect(result, hasLength(1));
  }

  void test_getValue_null() {
    expect(_nullValue().isNull, isTrue);
  }

  void test_getValue_set_empty() {
    DartObjectImpl object = _setValue(_typeProvider.intType, null);
    var set = object.toSetValue();
    expect(set, hasLength(0));
  }

  void test_getValue_set_valid() {
    DartObjectImpl object = _setValue(_typeProvider.intType, {_intValue(23)});
    var set = object.toSetValue();
    expect(set, hasLength(1));
  }

  void test_getValue_string_known() {
    String value = "twenty-three";
    expect(_stringValue(value).toStringValue(), value);
  }

  void test_getValue_string_unknown() {
    expect(_stringValue(null).toStringValue(), isNull);
  }

  void test_greaterThan_knownDouble_knownDouble_false() {
    _assertGreaterThan(_boolValue(false), _doubleValue(1.0), _doubleValue(2.0));
  }

  void test_greaterThan_knownDouble_knownDouble_true() {
    _assertGreaterThan(_boolValue(true), _doubleValue(2.0), _doubleValue(1.0));
  }

  void test_greaterThan_knownDouble_knownInt_false() {
    _assertGreaterThan(_boolValue(false), _doubleValue(1.0), _intValue(2));
  }

  void test_greaterThan_knownDouble_knownInt_true() {
    _assertGreaterThan(_boolValue(true), _doubleValue(2.0), _intValue(1));
  }

  void test_greaterThan_knownDouble_unknownDouble() {
    _assertGreaterThan(_boolValue(null), _doubleValue(1.0), _doubleValue(null));
  }

  void test_greaterThan_knownDouble_unknownInt() {
    _assertGreaterThan(_boolValue(null), _doubleValue(1.0), _intValue(null));
  }

  void test_greaterThan_knownInt_knownInt_false() {
    _assertGreaterThan(_boolValue(false), _intValue(1), _intValue(2));
  }

  void test_greaterThan_knownInt_knownInt_true() {
    _assertGreaterThan(_boolValue(true), _intValue(2), _intValue(1));
  }

  void test_greaterThan_knownInt_knownString() {
    _assertGreaterThan(null, _intValue(1), _stringValue("2"));
  }

  void test_greaterThan_knownInt_unknownDouble() {
    _assertGreaterThan(_boolValue(null), _intValue(1), _doubleValue(null));
  }

  void test_greaterThan_knownInt_unknownInt() {
    _assertGreaterThan(_boolValue(null), _intValue(1), _intValue(null));
  }

  void test_greaterThan_knownString_knownInt() {
    _assertGreaterThan(null, _stringValue("1"), _intValue(2));
  }

  void test_greaterThan_unknownDouble_knownDouble() {
    _assertGreaterThan(_boolValue(null), _doubleValue(null), _doubleValue(2.0));
  }

  void test_greaterThan_unknownDouble_knownInt() {
    _assertGreaterThan(_boolValue(null), _doubleValue(null), _intValue(2));
  }

  void test_greaterThan_unknownInt_knownDouble() {
    _assertGreaterThan(_boolValue(null), _intValue(null), _doubleValue(2.0));
  }

  void test_greaterThan_unknownInt_knownInt() {
    _assertGreaterThan(_boolValue(null), _intValue(null), _intValue(2));
  }

  void test_greaterThanOrEqual_knownDouble_knownDouble_false() {
    _assertGreaterThanOrEqual(
        _boolValue(false), _doubleValue(1.0), _doubleValue(2.0));
  }

  void test_greaterThanOrEqual_knownDouble_knownDouble_true() {
    _assertGreaterThanOrEqual(
        _boolValue(true), _doubleValue(2.0), _doubleValue(1.0));
  }

  void test_greaterThanOrEqual_knownDouble_knownInt_false() {
    _assertGreaterThanOrEqual(
        _boolValue(false), _doubleValue(1.0), _intValue(2));
  }

  void test_greaterThanOrEqual_knownDouble_knownInt_true() {
    _assertGreaterThanOrEqual(
        _boolValue(true), _doubleValue(2.0), _intValue(1));
  }

  void test_greaterThanOrEqual_knownDouble_unknownDouble() {
    _assertGreaterThanOrEqual(
        _boolValue(null), _doubleValue(1.0), _doubleValue(null));
  }

  void test_greaterThanOrEqual_knownDouble_unknownInt() {
    _assertGreaterThanOrEqual(
        _boolValue(null), _doubleValue(1.0), _intValue(null));
  }

  void test_greaterThanOrEqual_knownInt_knownInt_false() {
    _assertGreaterThanOrEqual(_boolValue(false), _intValue(1), _intValue(2));
  }

  void test_greaterThanOrEqual_knownInt_knownInt_true() {
    _assertGreaterThanOrEqual(_boolValue(true), _intValue(2), _intValue(2));
  }

  void test_greaterThanOrEqual_knownInt_knownString() {
    _assertGreaterThanOrEqual(null, _intValue(1), _stringValue("2"));
  }

  void test_greaterThanOrEqual_knownInt_unknownDouble() {
    _assertGreaterThanOrEqual(
        _boolValue(null), _intValue(1), _doubleValue(null));
  }

  void test_greaterThanOrEqual_knownInt_unknownInt() {
    _assertGreaterThanOrEqual(_boolValue(null), _intValue(1), _intValue(null));
  }

  void test_greaterThanOrEqual_knownString_knownInt() {
    _assertGreaterThanOrEqual(null, _stringValue("1"), _intValue(2));
  }

  void test_greaterThanOrEqual_unknownDouble_knownDouble() {
    _assertGreaterThanOrEqual(
        _boolValue(null), _doubleValue(null), _doubleValue(2.0));
  }

  void test_greaterThanOrEqual_unknownDouble_knownInt() {
    _assertGreaterThanOrEqual(
        _boolValue(null), _doubleValue(null), _intValue(2));
  }

  void test_greaterThanOrEqual_unknownInt_knownDouble() {
    _assertGreaterThanOrEqual(
        _boolValue(null), _intValue(null), _doubleValue(2.0));
  }

  void test_greaterThanOrEqual_unknownInt_knownInt() {
    _assertGreaterThanOrEqual(_boolValue(null), _intValue(null), _intValue(2));
  }

  void test_hasKnownValue_bool_false() {
    expect(_boolValue(false).hasKnownValue, isTrue);
  }

  void test_hasKnownValue_bool_true() {
    expect(_boolValue(true).hasKnownValue, isTrue);
  }

  void test_hasKnownValue_bool_unknown() {
    expect(_boolValue(null).hasKnownValue, isFalse);
  }

  void test_hasKnownValue_double_known() {
    expect(_doubleValue(2.3).hasKnownValue, isTrue);
  }

  void test_hasKnownValue_double_unknown() {
    expect(_doubleValue(null).hasKnownValue, isFalse);
  }

  void test_hasKnownValue_int_known() {
    expect(_intValue(23).hasKnownValue, isTrue);
  }

  void test_hasKnownValue_int_unknown() {
    expect(_intValue(null).hasKnownValue, isFalse);
  }

  void test_hasKnownValue_list_empty() {
    expect(_listValue(_typeProvider.intType, []).hasKnownValue, isTrue);
  }

  void test_hasKnownValue_list_valid() {
    expect(_listValue(_typeProvider.intType, [_intValue(23)]).hasKnownValue,
        isTrue);
  }

  void test_hasKnownValue_map_empty() {
    expect(
        _mapValue(_typeProvider.intType, _typeProvider.stringType, [])
            .hasKnownValue,
        isTrue);
  }

  void test_hasKnownValue_map_valid() {
    expect(
        _mapValue(_typeProvider.stringType, _typeProvider.stringType,
            [_stringValue("key"), _stringValue("value")]).hasKnownValue,
        isTrue);
  }

  void test_hasKnownValue_null() {
    expect(_nullValue().hasKnownValue, isTrue);
  }

  void test_hasKnownValue_string_known() {
    expect(_stringValue("twenty-three").hasKnownValue, isTrue);
  }

  void test_hasKnownValue_string_unknown() {
    expect(_stringValue(null).hasKnownValue, isFalse);
  }

  void test_identical_bool_false() {
    _assertIdentical(_boolValue(false), _boolValue(false), _boolValue(true));
  }

  void test_identical_bool_true() {
    _assertIdentical(_boolValue(true), _boolValue(true), _boolValue(true));
  }

  void test_identical_bool_unknown() {
    _assertIdentical(_boolValue(null), _boolValue(null), _boolValue(false));
  }

  void test_identical_double_false() {
    _assertIdentical(_boolValue(false), _doubleValue(2.0), _doubleValue(4.0));
  }

  void test_identical_double_true() {
    _assertIdentical(_boolValue(true), _doubleValue(2.0), _doubleValue(2.0));
  }

  void test_identical_double_unknown() {
    _assertIdentical(_boolValue(null), _doubleValue(1.0), _doubleValue(null));
  }

  void test_identical_int_false() {
    _assertIdentical(_boolValue(false), _intValue(-5), _intValue(5));
  }

  void test_identical_int_true() {
    _assertIdentical(_boolValue(true), _intValue(5), _intValue(5));
  }

  void test_identical_int_unknown() {
    _assertIdentical(_boolValue(null), _intValue(null), _intValue(3));
  }

  void test_identical_intZero_doubleZero() {
    // Used in Flutter:
    // const bool kIsWeb = identical(0, 0.0);
    _assertIdentical(_boolValue(null), _intValue(0), _doubleValue(0.0));
    _assertIdentical(_boolValue(null), _doubleValue(0.0), _intValue(0));
  }

  void test_identical_list_empty() {
    _assertIdentical(
      _boolValue(true),
      _listValue(_typeProvider.intType, []),
      _listValue(_typeProvider.intType, []),
    );
  }

  void test_identical_list_false_differentTypes() {
    _assertIdentical(
      _boolValue(false),
      _listValue(_typeProvider.intType, []),
      _listValue(_typeProvider.doubleType, []),
    );
  }

  void test_identical_list_false_differentValues() {
    _assertIdentical(_boolValue(false), _listValue(_typeProvider.intType, []),
        _listValue(_typeProvider.intType, [_intValue(3)]));
  }

  void test_identical_list_true_equalTypes() {
    _assertIdentical(
      _boolValue(true),
      _listValue(_typeProvider.intType, []),
      _listValue(_typeProvider.intType, []),
    );
  }

  void test_identical_list_true_equalTypesRuntime() {
    _assertIdentical(
      _boolValue(true),
      _listValue(
        _typeProvider.objectType,
        [],
      ),
      _listValue(
        _typeProvider.futureOrElement.instantiate(
          typeArguments: [_typeProvider.objectType],
          nullabilitySuffix: NullabilitySuffix.none,
        ),
        [],
      ),
    );
  }

  void test_identical_map_empty() {
    _assertIdentical(
      _boolValue(true),
      _mapValue(_typeProvider.intType, _typeProvider.stringType, []),
      _mapValue(_typeProvider.intType, _typeProvider.stringType, []),
    );
  }

  void test_identical_map_false_differentEntries() {
    _assertIdentical(
      _boolValue(false),
      _mapValue(_typeProvider.intType, _typeProvider.intType, []),
      _mapValue(
        _typeProvider.intType,
        _typeProvider.intType,
        [_intValue(1), _intValue(2)],
      ),
    );
  }

  void test_identical_map_false_differentTypes() {
    _assertIdentical(
      _boolValue(false),
      _mapValue(_typeProvider.boolType, _typeProvider.intType, []),
      _mapValue(_typeProvider.intType, _typeProvider.intType, []),
    );

    _assertIdentical(
      _boolValue(false),
      _mapValue(_typeProvider.intType, _typeProvider.boolType, []),
      _mapValue(_typeProvider.intType, _typeProvider.intType, []),
    );
  }

  void test_identical_map_true_equalTypesRuntime() {
    _assertIdentical(
      _boolValue(true),
      _mapValue(
        _typeProvider.intType,
        _typeProvider.objectType,
        [],
      ),
      _mapValue(
        _typeProvider.intType,
        _typeProvider.futureOrElement.instantiate(
          typeArguments: [_typeProvider.objectType],
          nullabilitySuffix: NullabilitySuffix.none,
        ),
        [],
      ),
    );
  }

  void test_identical_null() {
    _assertIdentical(_boolValue(true), _nullValue(), _nullValue());
  }

  void test_identical_string_false() {
    _assertIdentical(
        _boolValue(false), _stringValue("abc"), _stringValue("def"));
  }

  void test_identical_string_true() {
    _assertIdentical(
        _boolValue(true), _stringValue("abc"), _stringValue("abc"));
  }

  void test_identical_string_unknown() {
    _assertIdentical(_boolValue(null), _stringValue(null), _stringValue("def"));
  }

  void test_identical_Type_interfaceType() {
    _assertIdentical(
      _boolValue(true),
      _typeValue(_typeProvider.intType),
      _typeValue(_typeProvider.intType),
    );

    _assertIdentical(
      _boolValue(false),
      _typeValue(_typeProvider.intType),
      _typeValue(_typeProvider.numType),
    );

    _assertIdentical(
      _boolValue(true),
      _typeValue(_typeProvider.futureOrType(_typeProvider.objectType)),
      _typeValue(_typeProvider.objectType),
    );
  }

  void test_identical_Type_notType() {
    _assertIdentical(
      _boolValue(false),
      _typeValue(_typeProvider.intType),
      _intValue(0),
    );
  }

  void test_integerDivide_infinity_knownDouble() {
    _assertIntegerDivide(
      null,
      _doubleValue(double.infinity),
      _doubleValue(2.0),
    );
  }

  void test_integerDivide_infinity_knownInt() {
    _assertIntegerDivide(null, _doubleValue(double.infinity), _intValue(2));
  }

  void test_integerDivide_knownDouble_knownDouble() {
    _assertIntegerDivide(_intValue(3), _doubleValue(6.0), _doubleValue(2.0));
  }

  void test_integerDivide_knownDouble_knownInt() {
    _assertIntegerDivide(_intValue(3), _doubleValue(6.0), _intValue(2));
  }

  void test_integerDivide_knownDouble_unknownDouble() {
    _assertIntegerDivide(
        _intValue(null), _doubleValue(6.0), _doubleValue(null));
  }

  void test_integerDivide_knownDouble_unknownInt() {
    _assertIntegerDivide(_intValue(null), _doubleValue(6.0), _intValue(null));
  }

  void test_integerDivide_knownInt_knownDoubleZero() {
    _assertIntegerDivide(null, _intValue(6), _doubleValue(0.0));
  }

  void test_integerDivide_knownInt_knownInt() {
    _assertIntegerDivide(_intValue(3), _intValue(6), _intValue(2));
  }

  void test_integerDivide_knownInt_knownString() {
    _assertIntegerDivide(null, _intValue(6), _stringValue("2"));
  }

  void test_integerDivide_knownInt_unknownDouble() {
    _assertIntegerDivide(_intValue(null), _intValue(6), _doubleValue(null));
  }

  void test_integerDivide_knownInt_unknownInt() {
    _assertIntegerDivide(_intValue(null), _intValue(6), _intValue(null));
  }

  void test_integerDivide_knownInt_zero() {
    _assertIntegerDivide(null, _intValue(2), _intValue(0));
  }

  void test_integerDivide_knownString_knownInt() {
    _assertIntegerDivide(null, _stringValue("6"), _intValue(2));
  }

  void test_integerDivide_NaN_knownDouble() {
    _assertIntegerDivide(null, _doubleValue(double.nan), _doubleValue(2.0));
  }

  void test_integerDivide_NaN_knownInt() {
    _assertIntegerDivide(null, _doubleValue(double.nan), _intValue(2));
  }

  void test_integerDivide_negativeInfinity_knownDouble() {
    _assertIntegerDivide(
      null,
      _doubleValue(double.negativeInfinity),
      _doubleValue(2.0),
    );
  }

  void test_integerDivide_negativeInfinity_knownInt() {
    _assertIntegerDivide(
      null,
      _doubleValue(double.negativeInfinity),
      _intValue(2),
    );
  }

  void test_integerDivide_unknownDouble_knownDouble() {
    _assertIntegerDivide(
        _intValue(null), _doubleValue(null), _doubleValue(2.0));
  }

  void test_integerDivide_unknownDouble_knownInt() {
    _assertIntegerDivide(_intValue(null), _doubleValue(null), _intValue(2));
  }

  void test_integerDivide_unknownInt_knownDouble() {
    _assertIntegerDivide(_intValue(null), _intValue(null), _doubleValue(2.0));
  }

  void test_integerDivide_unknownInt_knownInt() {
    _assertIntegerDivide(_intValue(null), _intValue(null), _intValue(2));
  }

  void test_isBoolNumStringOrNull_bool_false() {
    expect(_boolValue(false).isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_bool_true() {
    expect(_boolValue(true).isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_bool_unknown() {
    expect(_boolValue(null).isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_double_known() {
    expect(_doubleValue(2.3).isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_double_unknown() {
    expect(_doubleValue(null).isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_int_known() {
    expect(_intValue(23).isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_int_unknown() {
    expect(_intValue(null).isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_list() {
    expect(
        _listValue(_typeProvider.intType, []).isBoolNumStringOrNull, isFalse);
  }

  void test_isBoolNumStringOrNull_null() {
    expect(_nullValue().isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_string_known() {
    expect(_stringValue("twenty-three").isBoolNumStringOrNull, isTrue);
  }

  void test_isBoolNumStringOrNull_string_unknown() {
    expect(_stringValue(null).isBoolNumStringOrNull, isTrue);
  }

  void test_lessThan_knownDouble_knownDouble_false() {
    _assertLessThan(_boolValue(false), _doubleValue(2.0), _doubleValue(1.0));
  }

  void test_lessThan_knownDouble_knownDouble_true() {
    _assertLessThan(_boolValue(true), _doubleValue(1.0), _doubleValue(2.0));
  }

  void test_lessThan_knownDouble_knownInt_false() {
    _assertLessThan(_boolValue(false), _doubleValue(2.0), _intValue(1));
  }

  void test_lessThan_knownDouble_knownInt_true() {
    _assertLessThan(_boolValue(true), _doubleValue(1.0), _intValue(2));
  }

  void test_lessThan_knownDouble_unknownDouble() {
    _assertLessThan(_boolValue(null), _doubleValue(1.0), _doubleValue(null));
  }

  void test_lessThan_knownDouble_unknownInt() {
    _assertLessThan(_boolValue(null), _doubleValue(1.0), _intValue(null));
  }

  void test_lessThan_knownInt_knownInt_false() {
    _assertLessThan(_boolValue(false), _intValue(2), _intValue(1));
  }

  void test_lessThan_knownInt_knownInt_true() {
    _assertLessThan(_boolValue(true), _intValue(1), _intValue(2));
  }

  void test_lessThan_knownInt_knownString() {
    _assertLessThan(null, _intValue(1), _stringValue("2"));
  }

  void test_lessThan_knownInt_unknownDouble() {
    _assertLessThan(_boolValue(null), _intValue(1), _doubleValue(null));
  }

  void test_lessThan_knownInt_unknownInt() {
    _assertLessThan(_boolValue(null), _intValue(1), _intValue(null));
  }

  void test_lessThan_knownString_knownInt() {
    _assertLessThan(null, _stringValue("1"), _intValue(2));
  }

  void test_lessThan_unknownDouble_knownDouble() {
    _assertLessThan(_boolValue(null), _doubleValue(null), _doubleValue(2.0));
  }

  void test_lessThan_unknownDouble_knownInt() {
    _assertLessThan(_boolValue(null), _doubleValue(null), _intValue(2));
  }

  void test_lessThan_unknownInt_knownDouble() {
    _assertLessThan(_boolValue(null), _intValue(null), _doubleValue(2.0));
  }

  void test_lessThan_unknownInt_knownInt() {
    _assertLessThan(_boolValue(null), _intValue(null), _intValue(2));
  }

  void test_lessThanOrEqual_knownDouble_knownDouble_false() {
    _assertLessThanOrEqual(
        _boolValue(false), _doubleValue(2.0), _doubleValue(1.0));
  }

  void test_lessThanOrEqual_knownDouble_knownDouble_true() {
    _assertLessThanOrEqual(
        _boolValue(true), _doubleValue(1.0), _doubleValue(2.0));
  }

  void test_lessThanOrEqual_knownDouble_knownInt_false() {
    _assertLessThanOrEqual(_boolValue(false), _doubleValue(2.0), _intValue(1));
  }

  void test_lessThanOrEqual_knownDouble_knownInt_true() {
    _assertLessThanOrEqual(_boolValue(true), _doubleValue(1.0), _intValue(2));
  }

  void test_lessThanOrEqual_knownDouble_unknownDouble() {
    _assertLessThanOrEqual(
        _boolValue(null), _doubleValue(1.0), _doubleValue(null));
  }

  void test_lessThanOrEqual_knownDouble_unknownInt() {
    _assertLessThanOrEqual(
        _boolValue(null), _doubleValue(1.0), _intValue(null));
  }

  void test_lessThanOrEqual_knownInt_knownInt_false() {
    _assertLessThanOrEqual(_boolValue(false), _intValue(2), _intValue(1));
  }

  void test_lessThanOrEqual_knownInt_knownInt_true() {
    _assertLessThanOrEqual(_boolValue(true), _intValue(1), _intValue(2));
  }

  void test_lessThanOrEqual_knownInt_knownString() {
    _assertLessThanOrEqual(null, _intValue(1), _stringValue("2"));
  }

  void test_lessThanOrEqual_knownInt_unknownDouble() {
    _assertLessThanOrEqual(_boolValue(null), _intValue(1), _doubleValue(null));
  }

  void test_lessThanOrEqual_knownInt_unknownInt() {
    _assertLessThanOrEqual(_boolValue(null), _intValue(1), _intValue(null));
  }

  void test_lessThanOrEqual_knownString_knownInt() {
    _assertLessThanOrEqual(null, _stringValue("1"), _intValue(2));
  }

  void test_lessThanOrEqual_unknownDouble_knownDouble() {
    _assertLessThanOrEqual(
        _boolValue(null), _doubleValue(null), _doubleValue(2.0));
  }

  void test_lessThanOrEqual_unknownDouble_knownInt() {
    _assertLessThanOrEqual(_boolValue(null), _doubleValue(null), _intValue(2));
  }

  void test_lessThanOrEqual_unknownInt_knownDouble() {
    _assertLessThanOrEqual(
        _boolValue(null), _intValue(null), _doubleValue(2.0));
  }

  void test_lessThanOrEqual_unknownInt_knownInt() {
    _assertLessThanOrEqual(_boolValue(null), _intValue(null), _intValue(2));
  }

  void test_logicalAnd_false_false() {
    _assertLazyAnd(_boolValue(false), _boolValue(false), _boolValue(false));
  }

  void test_logicalAnd_false_null() {
    _assertLazyAnd(_boolValue(false), _boolValue(false), _nullValue());
  }

  void test_logicalAnd_false_string() {
    _assertLazyAnd(_boolValue(false), _boolValue(false), _stringValue("false"));
  }

  void test_logicalAnd_false_true() {
    _assertLazyAnd(_boolValue(false), _boolValue(false), _boolValue(true));
  }

  void test_logicalAnd_null_false() {
    expect(() {
      _assertLazyAnd(_boolValue(false), _nullValue(), _boolValue(false));
    }, throwsEvaluationException);
  }

  void test_logicalAnd_null_true() {
    expect(() {
      _assertLazyAnd(_boolValue(false), _nullValue(), _boolValue(true));
    }, throwsEvaluationException);
  }

  void test_logicalAnd_string_false() {
    expect(() {
      _assertLazyAnd(
          _boolValue(false), _stringValue("true"), _boolValue(false));
    }, throwsEvaluationException);
  }

  void test_logicalAnd_string_true() {
    expect(() {
      _assertLazyAnd(
          _boolValue(false), _stringValue("false"), _boolValue(true));
    }, throwsEvaluationException);
  }

  void test_logicalAnd_true_false() {
    _assertLazyAnd(_boolValue(false), _boolValue(true), _boolValue(false));
  }

  void test_logicalAnd_true_null() {
    _assertLazyAnd(null, _boolValue(true), _nullValue());
  }

  void test_logicalAnd_true_string() {
    expect(() {
      _assertLazyAnd(_boolValue(false), _boolValue(true), _stringValue("true"));
    }, throwsEvaluationException);
  }

  void test_logicalAnd_true_true() {
    _assertLazyAnd(_boolValue(true), _boolValue(true), _boolValue(true));
  }

  void test_logicalNot_false() {
    _assertLogicalNot(_boolValue(true), _boolValue(false));
  }

  void test_logicalNot_null() {
    _assertLogicalNot(null, _nullValue());
  }

  void test_logicalNot_string() {
    expect(() {
      _assertLogicalNot(_boolValue(true), _stringValue(null));
    }, throwsEvaluationException);
  }

  void test_logicalNot_true() {
    _assertLogicalNot(_boolValue(false), _boolValue(true));
  }

  void test_logicalNot_unknown() {
    _assertLogicalNot(_boolValue(null), _boolValue(null));
  }

  void test_logicalOr_false_false() {
    _assertLazyOr(_boolValue(false), _boolValue(false), _boolValue(false));
  }

  void test_logicalOr_false_null() {
    _assertLazyOr(null, _boolValue(false), _nullValue());
  }

  void test_logicalOr_false_string() {
    expect(() {
      _assertLazyOr(
          _boolValue(false), _boolValue(false), _stringValue("false"));
    }, throwsEvaluationException);
  }

  void test_logicalOr_false_true() {
    _assertLazyOr(_boolValue(true), _boolValue(false), _boolValue(true));
  }

  void test_logicalOr_null_false() {
    expect(() {
      _assertLazyOr(_boolValue(false), _nullValue(), _boolValue(false));
    }, throwsEvaluationException);
  }

  void test_logicalOr_null_true() {
    expect(() {
      _assertLazyOr(_boolValue(true), _nullValue(), _boolValue(true));
    }, throwsEvaluationException);
  }

  void test_logicalOr_string_false() {
    expect(() {
      _assertLazyOr(_boolValue(false), _stringValue("true"), _boolValue(false));
    }, throwsEvaluationException);
  }

  void test_logicalOr_string_true() {
    expect(() {
      _assertLazyOr(_boolValue(true), _stringValue("false"), _boolValue(true));
    }, throwsEvaluationException);
  }

  void test_logicalOr_true_false() {
    _assertLazyOr(_boolValue(true), _boolValue(true), _boolValue(false));
  }

  void test_logicalOr_true_null() {
    _assertLazyOr(_boolValue(true), _boolValue(true), _nullValue());
  }

  void test_logicalOr_true_string() {
    _assertLazyOr(_boolValue(true), _boolValue(true), _stringValue("true"));
  }

  void test_logicalOr_true_true() {
    _assertLazyOr(_boolValue(true), _boolValue(true), _boolValue(true));
  }

  void test_logicalShiftRight_knownInt_knownInt() {
    _assertLogicalShiftRight(_intValue(16), _intValue(64), _intValue(2));
  }

  void test_logicalShiftRight_knownInt_unknownInt() {
    _assertLogicalShiftRight(_intValue(null), _intValue(64), _intValue(null));
  }

  void test_logicalShiftRight_unknownInt_knownInt() {
    _assertLogicalShiftRight(_intValue(null), _intValue(null), _intValue(2));
  }

  void test_logicalShiftRight_unknownInt_unknownInt() {
    _assertLogicalShiftRight(_intValue(null), _intValue(null), _intValue(null));
  }

  void test_minus_knownDouble_knownDouble() {
    _assertMinus(_doubleValue(1.0), _doubleValue(4.0), _doubleValue(3.0));
  }

  void test_minus_knownDouble_knownInt() {
    _assertMinus(_doubleValue(1.0), _doubleValue(4.0), _intValue(3));
  }

  void test_minus_knownDouble_unknownDouble() {
    _assertMinus(_doubleValue(null), _doubleValue(4.0), _doubleValue(null));
  }

  void test_minus_knownDouble_unknownInt() {
    _assertMinus(_doubleValue(null), _doubleValue(4.0), _intValue(null));
  }

  void test_minus_knownInt_knownInt() {
    _assertMinus(_intValue(1), _intValue(4), _intValue(3));
  }

  void test_minus_knownInt_knownString() {
    _assertMinus(null, _intValue(4), _stringValue("3"));
  }

  void test_minus_knownInt_unknownDouble() {
    _assertMinus(_doubleValue(null), _intValue(4), _doubleValue(null));
  }

  void test_minus_knownInt_unknownInt() {
    _assertMinus(_intValue(null), _intValue(4), _intValue(null));
  }

  void test_minus_knownString_knownInt() {
    _assertMinus(null, _stringValue("4"), _intValue(3));
  }

  void test_minus_unknownDouble_knownDouble() {
    _assertMinus(_doubleValue(null), _doubleValue(null), _doubleValue(3.0));
  }

  void test_minus_unknownDouble_knownInt() {
    _assertMinus(_doubleValue(null), _doubleValue(null), _intValue(3));
  }

  void test_minus_unknownInt_knownDouble() {
    _assertMinus(_doubleValue(null), _intValue(null), _doubleValue(3.0));
  }

  void test_minus_unknownInt_knownInt() {
    _assertMinus(_intValue(null), _intValue(null), _intValue(3));
  }

  void test_negated_double_known() {
    _assertNegated(_doubleValue(2.0), _doubleValue(-2.0));
  }

  void test_negated_double_unknown() {
    _assertNegated(_doubleValue(null), _doubleValue(null));
  }

  void test_negated_int_known() {
    _assertNegated(_intValue(-3), _intValue(3));
  }

  void test_negated_int_unknown() {
    _assertNegated(_intValue(null), _intValue(null));
  }

  void test_negated_string() {
    _assertNegated(null, _stringValue(null));
  }

  void test_notEqual_bool_false() {
    _assertNotEqual(_boolValue(false), _boolValue(true), _boolValue(true));
  }

  void test_notEqual_bool_true() {
    _assertNotEqual(_boolValue(true), _boolValue(false), _boolValue(true));
  }

  void test_notEqual_bool_unknown() {
    _assertNotEqual(_boolValue(null), _boolValue(null), _boolValue(false));
  }

  void test_notEqual_double_false() {
    _assertNotEqual(_boolValue(false), _doubleValue(2.0), _doubleValue(2.0));
  }

  void test_notEqual_double_true() {
    _assertNotEqual(_boolValue(true), _doubleValue(2.0), _doubleValue(4.0));
  }

  void test_notEqual_double_unknown() {
    _assertNotEqual(_boolValue(null), _doubleValue(1.0), _doubleValue(null));
  }

  void test_notEqual_int_false() {
    _assertNotEqual(_boolValue(false), _intValue(5), _intValue(5));
  }

  void test_notEqual_int_true() {
    _assertNotEqual(_boolValue(true), _intValue(-5), _intValue(5));
  }

  void test_notEqual_int_unknown() {
    _assertNotEqual(_boolValue(null), _intValue(null), _intValue(3));
  }

  void test_notEqual_null() {
    _assertNotEqual(_boolValue(false), _nullValue(), _nullValue());
  }

  void test_notEqual_string_false() {
    _assertNotEqual(
        _boolValue(false), _stringValue("abc"), _stringValue("abc"));
  }

  void test_notEqual_string_true() {
    _assertNotEqual(_boolValue(true), _stringValue("abc"), _stringValue("def"));
  }

  void test_notEqual_string_unknown() {
    _assertNotEqual(_boolValue(null), _stringValue(null), _stringValue("def"));
  }

  void test_performToString_bool_false() {
    _assertPerformToString(_stringValue("false"), _boolValue(false));
  }

  void test_performToString_bool_true() {
    _assertPerformToString(_stringValue("true"), _boolValue(true));
  }

  void test_performToString_bool_unknown() {
    _assertPerformToString(_stringValue(null), _boolValue(null));
  }

  void test_performToString_double_known() {
    _assertPerformToString(_stringValue("2.0"), _doubleValue(2.0));
  }

  void test_performToString_double_unknown() {
    _assertPerformToString(_stringValue(null), _doubleValue(null));
  }

  void test_performToString_int_known() {
    _assertPerformToString(_stringValue("5"), _intValue(5));
  }

  void test_performToString_int_unknown() {
    _assertPerformToString(_stringValue(null), _intValue(null));
  }

  void test_performToString_null() {
    _assertPerformToString(_stringValue("null"), _nullValue());
  }

  void test_performToString_string_known() {
    _assertPerformToString(_stringValue("abc"), _stringValue("abc"));
  }

  void test_performToString_string_unknown() {
    _assertPerformToString(_stringValue(null), _stringValue(null));
  }

  void test_remainder_knownDouble_knownDouble() {
    _assertRemainder(_doubleValue(1.0), _doubleValue(7.0), _doubleValue(2.0));
  }

  void test_remainder_knownDouble_knownInt() {
    _assertRemainder(_doubleValue(1.0), _doubleValue(7.0), _intValue(2));
  }

  void test_remainder_knownDouble_unknownDouble() {
    _assertRemainder(_doubleValue(null), _doubleValue(7.0), _doubleValue(null));
  }

  void test_remainder_knownDouble_unknownInt() {
    _assertRemainder(_doubleValue(null), _doubleValue(6.0), _intValue(null));
  }

  void test_remainder_knownInt_knownInt() {
    _assertRemainder(_intValue(1), _intValue(7), _intValue(2));
  }

  void test_remainder_knownInt_knownInt_zero() {
    _assertRemainder(null, _intValue(7), _intValue(0));
  }

  void test_remainder_knownInt_knownString() {
    _assertRemainder(null, _intValue(7), _stringValue("2"));
  }

  void test_remainder_knownInt_unknownDouble() {
    _assertRemainder(_doubleValue(null), _intValue(7), _doubleValue(null));
  }

  void test_remainder_knownInt_unknownInt() {
    _assertRemainder(_intValue(null), _intValue(7), _intValue(null));
  }

  void test_remainder_knownString_knownInt() {
    _assertRemainder(null, _stringValue("7"), _intValue(2));
  }

  void test_remainder_unknownDouble_knownDouble() {
    _assertRemainder(_doubleValue(null), _doubleValue(null), _doubleValue(2.0));
  }

  void test_remainder_unknownDouble_knownInt() {
    _assertRemainder(_doubleValue(null), _doubleValue(null), _intValue(2));
  }

  void test_remainder_unknownInt_knownDouble() {
    _assertRemainder(_doubleValue(null), _intValue(null), _doubleValue(2.0));
  }

  void test_remainder_unknownInt_knownInt() {
    _assertRemainder(_intValue(null), _intValue(null), _intValue(2));
  }

  void test_shiftLeft_knownInt_knownInt() {
    _assertShiftLeft(_intValue(48), _intValue(6), _intValue(3));
  }

  void test_shiftLeft_knownInt_knownInt_negative() {
    _assertShiftLeft(null, _intValue(1), _intValue(-1));
  }

  void test_shiftLeft_knownInt_knownString() {
    _assertShiftLeft(null, _intValue(6), _stringValue(null));
  }

  void test_shiftLeft_knownInt_tooLarge() {
    _assertShiftLeft(
      _intValue(null),
      _intValue(6),
      DartObjectImpl(
        _typeSystem,
        _typeProvider.intType,
        IntState(LONG_MAX_VALUE),
      ),
    );
  }

  void test_shiftLeft_knownInt_unknownInt() {
    _assertShiftLeft(_intValue(null), _intValue(6), _intValue(null));
  }

  void test_shiftLeft_knownString_knownInt() {
    _assertShiftLeft(null, _stringValue(null), _intValue(3));
  }

  void test_shiftLeft_unknownInt_knownInt() {
    _assertShiftLeft(_intValue(null), _intValue(null), _intValue(3));
  }

  void test_shiftLeft_unknownInt_unknownInt() {
    _assertShiftLeft(_intValue(null), _intValue(null), _intValue(null));
  }

  void test_shiftRight_knownInt_knownInt() {
    _assertShiftRight(_intValue(6), _intValue(48), _intValue(3));
  }

  void test_shiftRight_knownInt_knownInt_negative() {
    _assertShiftRight(null, _intValue(1), _intValue(-1));
  }

  void test_shiftRight_knownInt_knownString() {
    _assertShiftRight(null, _intValue(48), _stringValue(null));
  }

  void test_shiftRight_knownInt_tooLarge() {
    _assertShiftRight(
      _intValue(null),
      _intValue(48),
      DartObjectImpl(
        _typeSystem,
        _typeProvider.intType,
        IntState(LONG_MAX_VALUE),
      ),
    );
  }

  void test_shiftRight_knownInt_unknownInt() {
    _assertShiftRight(_intValue(null), _intValue(48), _intValue(null));
  }

  void test_shiftRight_knownString_knownInt() {
    _assertShiftRight(null, _stringValue(null), _intValue(3));
  }

  void test_shiftRight_unknownInt_knownInt() {
    _assertShiftRight(_intValue(null), _intValue(null), _intValue(3));
  }

  void test_shiftRight_unknownInt_unknownInt() {
    _assertShiftRight(_intValue(null), _intValue(null), _intValue(null));
  }

  void test_stringLength_int() {
    expect(() {
      _assertStringLength(_intValue(null), _intValue(0));
    }, throwsEvaluationException);
  }

  void test_stringLength_knownString() {
    _assertStringLength(_intValue(3), _stringValue("abc"));
  }

  void test_stringLength_unknownString() {
    _assertStringLength(_intValue(null), _stringValue(null));
  }

  void test_times_knownDouble_knownDouble() {
    _assertTimes(_doubleValue(6.0), _doubleValue(2.0), _doubleValue(3.0));
  }

  void test_times_knownDouble_knownInt() {
    _assertTimes(_doubleValue(6.0), _doubleValue(2.0), _intValue(3));
  }

  void test_times_knownDouble_unknownDouble() {
    _assertTimes(_doubleValue(null), _doubleValue(2.0), _doubleValue(null));
  }

  void test_times_knownDouble_unknownInt() {
    _assertTimes(_doubleValue(null), _doubleValue(2.0), _intValue(null));
  }

  void test_times_knownInt_knownInt() {
    _assertTimes(_intValue(6), _intValue(2), _intValue(3));
  }

  void test_times_knownInt_knownString() {
    _assertTimes(null, _intValue(2), _stringValue("3"));
  }

  void test_times_knownInt_unknownDouble() {
    _assertTimes(_doubleValue(null), _intValue(2), _doubleValue(null));
  }

  void test_times_knownInt_unknownInt() {
    _assertTimes(_intValue(null), _intValue(2), _intValue(null));
  }

  void test_times_knownString_knownInt() {
    _assertTimes(null, _stringValue("2"), _intValue(3));
  }

  void test_times_unknownDouble_knownDouble() {
    _assertTimes(_doubleValue(null), _doubleValue(null), _doubleValue(3.0));
  }

  void test_times_unknownDouble_knownInt() {
    _assertTimes(_doubleValue(null), _doubleValue(null), _intValue(3));
  }

  void test_times_unknownInt_knownDouble() {
    _assertTimes(_doubleValue(null), _intValue(null), _doubleValue(3.0));
  }

  void test_times_unknownInt_knownInt() {
    _assertTimes(_intValue(null), _intValue(null), _intValue(3));
  }

  /// Assert that the result of executing [fn] is the [expected] value, or, if
  /// [expected] is `null`, that the operation throws an exception .
  void _assert(DartObjectImpl? expected, DartObjectImpl? Function() fn) {
    if (expected == null) {
      expect(() {
        fn();
      }, throwsEvaluationException);
    } else {
      var result = fn();
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /// Assert that the result of adding the [left] and [right] operands is the
  /// [expected] value, or that the operation throws an exception if the
  /// expected value is `null`.
  void _assertAdd(
      DartObjectImpl? expected, DartObjectImpl left, DartObjectImpl right) {
    if (expected == null) {
      expect(() {
        left.add(_typeSystem, right);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = left.add(_typeSystem, right);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /// Assert that the bit-not of the [operand] is the [expected] value, or that
  /// the operation throws an exception if the expected value is `null`.
  void _assertBitNot(DartObjectImpl? expected, DartObjectImpl operand) {
    if (expected == null) {
      expect(() {
        operand.bitNot(_typeSystem);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = operand.bitNot(_typeSystem);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /// Assert that the result of concatenating the [left] and [right] operands is
  /// the [expected] value, or that the operation throws an exception if the
  /// expected value is `null`.
  void _assertConcatenate(
      DartObjectImpl? expected, DartObjectImpl left, DartObjectImpl right) {
    if (expected == null) {
      expect(() {
        left.concatenate(_typeSystem, right);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = left.concatenate(_typeSystem, right);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /// Assert that the result of dividing the [left] and [right] operands is the
  /// [expected] value, or that the operation throws an exception if the
  /// expected value is `null`.
  void _assertDivide(
      DartObjectImpl? expected, DartObjectImpl left, DartObjectImpl right) {
    if (expected == null) {
      expect(() {
        left.divide(_typeSystem, right);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = left.divide(_typeSystem, right);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /// Assert that the result of bit-anding the [left] and [right] operands is
  /// the [expected] value, or that the operation throws an exception if the
  /// expected value is `null`.
  void _assertEagerAnd(
      DartObjectImpl? expected, DartObjectImpl left, DartObjectImpl right) {
    if (expected == null) {
      expect(() {
        left.eagerAnd(_typeSystem, right);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = left.eagerAnd(_typeSystem, right);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /// Assert that the result of bit-oring the [left] and [right] operands is the
  /// [expected] value, or that the operation throws an exception if the
  /// expected value is `null`.
  void _assertEagerOr(
      DartObjectImpl? expected, DartObjectImpl left, DartObjectImpl right) {
    if (expected == null) {
      expect(() {
        left.eagerOr(_typeSystem, right);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = left.eagerOr(_typeSystem, right);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /// Assert that the result of bit-xoring the [left] and [right] operands is
  /// the [expected] value, or that the operation throws an exception if the
  /// expected value is `null`.
  void _assertEagerXor(
      DartObjectImpl? expected, DartObjectImpl left, DartObjectImpl right) {
    if (expected == null) {
      expect(() {
        left.eagerXor(_typeSystem, right);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = left.eagerXor(_typeSystem, right);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /// Assert that the result of comparing the [left] and [right] operands for
  /// equality is the [expected] value, or that the operation throws an
  /// exception if the expected value is `null`.
  void _assertEqualEqual(
      DartObjectImpl? expected, DartObjectImpl left, DartObjectImpl right) {
    if (expected == null) {
      expect(() {
        left.equalEqual(_typeSystem, right);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = left.equalEqual(_typeSystem, right);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /// Assert that the result of comparing the [left] and [right] operands is the
  /// [expected] value, or that the operation throws an exception if the
  /// expected value is `null`.
  void _assertGreaterThan(
      DartObjectImpl? expected, DartObjectImpl left, DartObjectImpl right) {
    if (expected == null) {
      expect(() {
        left.greaterThan(_typeSystem, right);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = left.greaterThan(_typeSystem, right);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /// Assert that the result of comparing the [left] and [right] operands is the
  /// [expected] value, or that the operation throws an exception if the
  /// expected value is `null`.
  void _assertGreaterThanOrEqual(
      DartObjectImpl? expected, DartObjectImpl left, DartObjectImpl right) {
    if (expected == null) {
      expect(() {
        left.greaterThanOrEqual(_typeSystem, right);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = left.greaterThanOrEqual(_typeSystem, right);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /// Assert that the result of comparing the [left] and [right] operands using
  /// identical() is the expected value.
  void _assertIdentical(
      DartObjectImpl expected, DartObjectImpl left, DartObjectImpl right) {
    DartObjectImpl result = left.isIdentical2(_typeSystem, right);
    expect(result, isNotNull);
    expect(result, expected);
  }

  void _assertInstanceOfObjectArray(Object? result) {
    // TODO(scheglov) implement
  }

  /// Assert that the result of dividing the [left] and [right] operands as
  /// integers is the [expected] value, or that the operation throws an
  /// exception if the expected value is `null`.
  void _assertIntegerDivide(
      DartObjectImpl? expected, DartObjectImpl left, DartObjectImpl right) {
    if (expected == null) {
      expect(() {
        left.integerDivide(_typeSystem, right);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = left.integerDivide(_typeSystem, right);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /// Assert that the result of logical-anding the [left] and [right] operands
  /// is the [expected] value, or that the operation throws an exception if the
  /// expected value is `null`.
  void _assertLazyAnd(
      DartObjectImpl? expected, DartObjectImpl left, DartObjectImpl right) {
    if (expected == null) {
      expect(() {
        left.lazyAnd(_typeSystem, () => right);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = left.lazyAnd(_typeSystem, () => right);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /// Assert that the result of logical-oring the [left] and [right] operands is
  /// the [expected] value, or that the operation throws an exception if the
  /// expected value is `null`.
  void _assertLazyOr(
      DartObjectImpl? expected, DartObjectImpl left, DartObjectImpl right) {
    if (expected == null) {
      expect(() {
        left.lazyOr(_typeSystem, () => right);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = left.lazyOr(_typeSystem, () => right);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /// Assert that the result of comparing the [left] and [right] operands is the
  /// [expected] value, or that the operation throws an exception if the
  /// expected value is `null`.
  void _assertLessThan(
      DartObjectImpl? expected, DartObjectImpl left, DartObjectImpl right) {
    if (expected == null) {
      expect(() {
        left.lessThan(_typeSystem, right);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = left.lessThan(_typeSystem, right);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /// Assert that the result of comparing the [left] and [right] operands is the
  /// [expected] value, or that the operation throws an exception if the
  /// expected value is `null`.
  void _assertLessThanOrEqual(
      DartObjectImpl? expected, DartObjectImpl left, DartObjectImpl right) {
    if (expected == null) {
      expect(() {
        left.lessThanOrEqual(_typeSystem, right);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = left.lessThanOrEqual(_typeSystem, right);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /// Assert that the logical-not of the [operand] is the [expected] value, or
  /// that the operation throws an exception if the expected value is `null`.
  void _assertLogicalNot(DartObjectImpl? expected, DartObjectImpl operand) {
    if (expected == null) {
      expect(() {
        operand.logicalNot(_typeSystem);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = operand.logicalNot(_typeSystem);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /// Assert that the result of bit-shifting the [left] operand by the [right]
  /// operand number of bits is the [expected] value, or that the operation
  /// throws an exception if the expected value is `null`.
  void _assertLogicalShiftRight(
      DartObjectImpl? expected, DartObjectImpl left, DartObjectImpl right) {
    _assert(expected, () => left.logicalShiftRight(_typeSystem, right));
  }

  /// Assert that the result of subtracting the [left] and [right] operands is
  /// the [expected] value, or that the operation throws an exception if the
  /// expected value is `null`.
  void _assertMinus(
      DartObjectImpl? expected, DartObjectImpl left, DartObjectImpl right) {
    if (expected == null) {
      expect(() {
        left.minus(_typeSystem, right);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = left.minus(_typeSystem, right);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /// Assert that the negation of the [operand] is the [expected] value, or that
  /// the operation throws an exception if the expected value is `null`.
  void _assertNegated(DartObjectImpl? expected, DartObjectImpl operand) {
    if (expected == null) {
      expect(() {
        operand.negated(_typeSystem);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = operand.negated(_typeSystem);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /// Assert that the result of comparing the [left] and [right] operands for
  /// inequality is the [expected] value, or that the operation throws an
  /// exception if the expected value is `null`.
  void _assertNotEqual(
      DartObjectImpl? expected, DartObjectImpl left, DartObjectImpl right) {
    if (expected == null) {
      expect(() {
        left.notEqual(_typeSystem, right);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = left.notEqual(_typeSystem, right);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /// Assert that converting the [operand] to a string is the [expected] value,
  /// or that the operation throws an exception if the expected value is `null`.
  void _assertPerformToString(
      DartObjectImpl? expected, DartObjectImpl operand) {
    if (expected == null) {
      expect(() {
        operand.performToString(_typeSystem);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = operand.performToString(_typeSystem);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /// Assert that the result of taking the remainder of the [left] and [right]
  /// operands is the [expected] value, or that the operation throws an
  /// exception if the expected value is `null`.
  void _assertRemainder(
      DartObjectImpl? expected, DartObjectImpl left, DartObjectImpl right) {
    _assert(expected, () => left.remainder(_typeSystem, right));
  }

  /// Assert that the result of multiplying the [left] and [right] operands is
  /// the [expected] value, or that the operation throws an exception if the
  /// expected value is `null`.
  void _assertShiftLeft(
      DartObjectImpl? expected, DartObjectImpl left, DartObjectImpl right) {
    _assert(expected, () => left.shiftLeft(_typeSystem, right));
  }

  /// Assert that the result of multiplying the [left] and [right] operands is
  /// the [expected] value, or that the operation throws an exception if the
  /// expected value is `null`.
  void _assertShiftRight(
      DartObjectImpl? expected, DartObjectImpl left, DartObjectImpl right) {
    _assert(expected, () => left.shiftRight(_typeSystem, right));
  }

  /// Assert that the length of the [operand] is the [expected] value, or that
  /// the operation throws an exception if the expected value is `null`.
  void _assertStringLength(DartObjectImpl? expected, DartObjectImpl operand) {
    if (expected == null) {
      expect(() {
        operand.stringLength(_typeSystem);
      }, throwsEvaluationException);
    } else {
      DartObjectImpl result = operand.stringLength(_typeSystem);
      expect(result, isNotNull);
      expect(result, expected);
    }
  }

  /// Assert that the result of multiplying the [left] and [right] operands is
  /// the [expected] value, or that the operation throws an exception if the
  /// expected value is `null`.
  void _assertTimes(
      DartObjectImpl? expected, DartObjectImpl left, DartObjectImpl right) {
    _assert(expected, () => left.times(_typeSystem, right));
  }

  DartObjectImpl _boolValue(bool? value) {
    if (value == null) {
      return DartObjectImpl(
        _typeSystem,
        _typeProvider.boolType,
        BoolState.UNKNOWN_VALUE,
      );
    } else if (identical(value, false)) {
      return DartObjectImpl(
        _typeSystem,
        _typeProvider.boolType,
        BoolState.FALSE_STATE,
      );
    } else if (identical(value, true)) {
      return DartObjectImpl(
        _typeSystem,
        _typeProvider.boolType,
        BoolState.TRUE_STATE,
      );
    }
    fail("Invalid boolean value used in test");
  }

  DartObjectImpl _doubleValue(double? value) {
    if (value == null) {
      return DartObjectImpl(
        _typeSystem,
        _typeProvider.doubleType,
        DoubleState.UNKNOWN_VALUE,
      );
    } else {
      return DartObjectImpl(
        _typeSystem,
        _typeProvider.doubleType,
        DoubleState(value),
      );
    }
  }

  DartObjectImpl _intValue(int? value) {
    if (value == null) {
      return DartObjectImpl(
        _typeSystem,
        _typeProvider.intType,
        IntState.UNKNOWN_VALUE,
      );
    } else {
      return DartObjectImpl(
        _typeSystem,
        _typeProvider.intType,
        IntState(value),
      );
    }
  }

  DartObjectImpl _listValue(
    DartType elementType,
    List<DartObjectImpl> elements,
  ) {
    return DartObjectImpl(
      _typeSystem,
      _typeProvider.listType(elementType),
      ListState(elements),
    );
  }

  DartObjectImpl _mapValue(DartType keyType, DartType valueType,
      List<DartObjectImpl> keyValuePairs) {
    Map<DartObjectImpl, DartObjectImpl> map =
        <DartObjectImpl, DartObjectImpl>{};
    int count = keyValuePairs.length;
    for (int i = 0; i < count;) {
      map[keyValuePairs[i++]] = keyValuePairs[i++];
    }
    return DartObjectImpl(
      _typeSystem,
      _typeProvider.mapType(keyType, valueType),
      MapState(map),
    );
  }

  DartObjectImpl _nullValue() {
    return DartObjectImpl(
      _typeSystem,
      _typeProvider.nullType,
      NullState.NULL_STATE,
    );
  }

  DartObjectImpl _setValue(
      ParameterizedType type, Set<DartObjectImpl>? elements) {
    return DartObjectImpl(
      _typeSystem,
      type,
      SetState(elements ?? <DartObjectImpl>{}),
    );
  }

  DartObjectImpl _stringValue(String? value) {
    if (value == null) {
      return DartObjectImpl(
        _typeSystem,
        _typeProvider.stringType,
        StringState.UNKNOWN_VALUE,
      );
    } else {
      return DartObjectImpl(
        _typeSystem,
        _typeProvider.stringType,
        StringState(value),
      );
    }
  }

  DartObjectImpl _symbolValue(String value) {
    return DartObjectImpl(
      _typeSystem,
      _typeProvider.symbolType,
      SymbolState(value),
    );
  }

  DartObjectImpl _typeValue(DartType value) {
    return DartObjectImpl(
      _typeSystem,
      _typeProvider.typeType,
      TypeState(value),
    );
  }
}
