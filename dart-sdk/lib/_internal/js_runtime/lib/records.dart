// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of _js_helper;

/// Base class for all records.
abstract final class _Record implements Record {
  const _Record();

  int get _shapeTag => JS('JSUInt31', '#[#]', this,
      JS_GET_NAME(JsGetName.RECORD_SHAPE_TAG_PROPERTY));

  bool _sameShape(_Record other) => _shapeTag == other._shapeTag;

  /// Field values in canonical order.
  // TODO(50081): Replace with a Map view.
  List<Object?> _getFieldValues();

  Type get runtimeType {
    // TODO(51040): Consider caching.
    return newRti.getRuntimeTypeOfRecord(this);
  }

  newRti.Rti _getRti() {
    String recipe =
        JS('', '#[#]', this, JS_GET_NAME(JsGetName.RECORD_SHAPE_TYPE_PROPERTY));
    return newRti.evaluateRtiForRecord(recipe, _getFieldValues());
  }

  @override
  String toString() => _toString(false);

  String _toString(bool safe) {
    final keys = _fieldKeys();
    final values = _getFieldValues();
    assert(keys.length == values.length);
    final sb = StringBuffer();
    String separator = '';
    if (safe) sb.write('Record ');
    sb.write('(');
    for (int i = 0; i < keys.length; i++) {
      sb.write(separator);
      Object key = keys[i];
      if (key is String) {
        sb.write(key);
        sb.write(': ');
      }
      final value = values[i];
      if (safe) {
        sb.write(Primitives.safeToString(value));
      } else {
        sb.write(value);
      }
      separator = ', ';
    }
    sb.write(')');
    return sb.toString();
  }

  /// Returns a list of integers and strings corresponding to the indexed and
  /// named fields of this record.
  List<Object> _fieldKeys() {
    int shapeTag = _shapeTag;
    while (_computedFieldKeys.length <= shapeTag) _computedFieldKeys.add(null);
    return _computedFieldKeys[shapeTag] ??= _computeFieldKeys();
  }

  List<Object> _computeFieldKeys() {
    String recipe =
        JS('', '#[#]', this, JS_GET_NAME(JsGetName.RECORD_SHAPE_TYPE_PROPERTY));

    // TODO(50081): The Rti recipe format is agnostic to what the record shape
    // key is. We happen to use a comma-separated list of the names for the
    // named arguments. `"+a,b(1,2,3,4)"` is the 4-record with two named fields
    // `a` and `b`. We should refactor the code so that rti.dart returns the
    // arity and the Rti's shape key which are interpreted here.
    int position = JS('', '#.indexOf(#)', recipe, '(');
    String joinedNames = JS('', '#.substring(1, #)', recipe, position);
    String fields = JS('', '#.substring(#)', recipe, position);
    int arity;
    if (fields == '()') {
      arity = 0;
    } else {
      String commas = JS('', '#.replace(/[^,]/g, "")', fields);
      arity = commas.length + 1;
    }

    List<Object> result = List.generate(arity, (i) => i);
    if (joinedNames != '') {
      List<String> names = joinedNames.split(',');
      int last = arity;
      int i = names.length;
      while (i > 0) result[--last] = names[--i];
    }

    return List.unmodifiable(result);
  }

  static final List<List<Object>?> _computedFieldKeys = [];
}

/// Entrypoint for rti library. Calls rti.evaluateRtiForRecord with components
/// of the record.
@pragma('dart2js:as:trust')
newRti.Rti getRtiForRecord(Object? record) {
  return (record as _Record)._getRti();
}

/// The empty record.
final class _EmptyRecord extends _Record {
  const _EmptyRecord();

  @override
  List<Object?> _getFieldValues() => const [];

  @override
  String toString() => '()';

  @override
  bool operator ==(Object other) => identical(other, ());

  @override
  int get hashCode => 43 * 67;
}

/// Base class for all records with two fields.
// TODO(49718): Generate this class.
final class _Record2 extends _Record {
  final Object? _0;
  final Object? _1;

  _Record2(this._0, this._1);

  @override
  List<Object?> _getFieldValues() => [_0, _1];

  bool _equalFields(_Record2 other) {
    return _0 == other._0 && _1 == other._1;
  }

  @override
  // TODO(49718): Add specializations in shape class that combines is-check with
  // shape check.
  //
  // TODO(49718): Add specializations in type specialization that combines
  // is-check with shape check and inlines and specializes `_equalFields`.
  bool operator ==(Object other) {
    return other is _Record2 && _sameShape(other) && _equalFields(other);
  }

  @override
  int get hashCode => Object.hash(_shapeTag, _0, _1);
}

final class _Record1 extends _Record {
  final Object? _0;

  _Record1(this._0);

  @override
  List<Object?> _getFieldValues() => [_0];

  bool _equalFields(_Record1 other) {
    return _0 == other._0;
  }

  @override
  // TODO(49718): Same as _Record2.
  bool operator ==(Object other) {
    return other is _Record1 && _sameShape(other) && _equalFields(other);
  }

  @override
  int get hashCode => Object.hash(_shapeTag, _0);
}

final class _Record3 extends _Record {
  final Object? _0;
  final Object? _1;
  final Object? _2;

  _Record3(this._0, this._1, this._2);

  @override
  List<Object?> _getFieldValues() => [_0, _1, _2];

  bool _equalFields(_Record3 other) {
    return _0 == other._0 && _1 == other._1 && _2 == other._2;
  }

  @override
  // TODO(49718): Same as _Record2.
  bool operator ==(Object other) {
    return other is _Record3 && _sameShape(other) && _equalFields(other);
  }

  @override
  // TODO(49718): Incorporate shape in `hashCode`.
  int get hashCode => Object.hash(_shapeTag, _0, _1, _2);
}

final class _RecordN extends _Record {
  final JSArray _values;

  _RecordN(this._values);

  @override
  List<Object?> _getFieldValues() => _values;

  bool _equalFields(_RecordN other) => _equalValues(_values, other._values);

  static bool _equalValues(JSArray a, JSArray b) {
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) {
    return other is _RecordN && _sameShape(other) && _equalFields(other);
  }

  @override
  int get hashCode => Object.hash(_shapeTag, Object.hashAll(_values));
}

/// This function models the use of `_Record` and its subclasses. In the
/// resolution phase this function is assumed to be called in order to add
/// impacts for all the uses in code injected in lowering from K-world to
/// J-world.
///
/// Codegen impacts are finer-grained, based on the record representation
/// classes and impacts returned by [RecordCodegen].
void _recordImpactModel() {
  // Record classes are instantiated.
  Object? anything() => _inscrutable(0);
  final r0 = const _EmptyRecord();
  final r1 = _Record1(anything());
  final r2 = _Record2(anything(), anything());
  final r3 = _Record3(anything(), anything(), anything());
  final rN = _RecordN(anything() as JSArray);

  // Assume the `==` methods are called.
  r0 == anything();
  r1 == anything();
  r2 == anything();
  r3 == anything();
  rN == anything();

  newRti.pairwiseIsTest(anything() as JSArray, anything() as JSArray);
}

// TODO(50081): Can this be `external`?
@pragma('dart2js:assumeDynamic')
Object? _inscrutable(Object? x) => x;

/// Returns a JavaScript predicate that tests if the argument is a record with
/// the given shape and fields types. The shape is determined by the number of
/// fields and the partial shape tag [shape]. [fieldRtis] is a JSArray of Rti
/// type objects for each field.
///
/// Returns `null` if test will always fail.
@pragma('dart2js:never-inline')
@pragma('dart2js:index-bounds:trust')
@pragma('dart2js:as:trust')
Object? createRecordTypePredicate(Object? shape, Object? fieldRtis) {
  String partialShapeTag = shape as String;
  JSArray array = fieldRtis as JSArray;
  final length = array.length;

  final table = JS_EMBEDDED_GLOBAL('', RECORD_TYPE_TEST_COMBINATORS_PROPERTY);

  final combinedTag = '$length;$partialShapeTag';
  final function = JS('', '#[#]', table, combinedTag);

  if (function == null) {
    // If the shape is missing from the table it means that no records are
    // instantiated at that shape, so the result is always false.
    return null;
  }

  if (length == 0) {
    return function;
  }

  // If the JavaScript combinator has one argument per field, 'spread' the Rtis
  // into the function.  (This logic requires that 1-element records are handled
  // specially. We have chosen the arity class [_Record1] above, which is
  // usually tree-shaken. If we used [_RecordN], then we would either have to
  // special-case `length == 1` here or generate a combinator that returned a
  // function that indexed into the single-element `_values` array.)

  int argumentCount = JS('', '#.length', function);
  if (length == argumentCount) {
    return JS('', '#.apply(null, #)', function, array);
  }

  // Otherwise the combinator takes the list of field Rtis.
  assert(argumentCount == 1);
  return JS('', '#(#)', function, fieldRtis);
}
