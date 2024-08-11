// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._runtime;

/// Describes the shape of a record value.
final class Shape {
  /// The number of positional elements in the record.
  final int positionals;

  /// The names of the named elements in the record in alphabetical order.
  final List<String>? named;

  Shape(this.positionals, this.named);

  @override
  String toString() {
    return 'Shape($positionals, [${named?.join(", ")}])';
  }
}

/// Used to store a [Shape] on an instance of a record object.
final shapeProperty = JS('', 'Symbol("shape")');

/// Used to store a [JSArray] on an instance of a record object containing all
/// the elements in the record in order.
final valuesProperty = JS('', 'Symbol("values")');

/// Internal base class for all concrete records.
final class RecordImpl implements Record {
  /// Cache for faster access after the first call of [hashCode].
  int? _hashCode;

  /// Cache for faster access after the first call of [toString].
  ///
  /// NOTE: Does not contain the cached result of the "safe" [_toString] call.
  String? _printed;

  RecordImpl(Shape shape, JSArray values) {
    // Coerce all undefined values to null because dynamic gets of record
    // elements rely on the getter returning undefined to signal that the getter
    // does not exist.
    for (int i = 0; i < values.length; i++) {
      if (JS<bool>('!', '#[#] === void 0', values, i)) {
        JS('', '#[#] = null', values, i);
      }
    }
    JS('!', '#[#] = #', this, shapeProperty, shape);
    JS('!', '#[#] = #', this, valuesProperty, values);
  }

  @override
  bool operator ==(Object? other) {
    if (!(other is RecordImpl)) return false;
    // Shapes are canonicalized and stored in a map so there will only ever be
    // one instance of the same shape.
    if (JS<bool>(
        '!', '#[#] !== #[#]', this, shapeProperty, other, shapeProperty))
      return false;
    // If the shapes are identical then the two records have the same number of
    // positional elements and the same named elements.
    // This implies: `values.length == other.values.length`.
    var values = JS<JSArray>('!', '#[#]', this, valuesProperty);
    var otherValues = JS<JSArray>('!', '#[#]', other, valuesProperty);
    for (var i = 0; i < values.length; i++) {
      if (values[i] != otherValues[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode {
    final cachedValue = _hashCode;
    if (cachedValue != null) return cachedValue;
    var shape = JS<Shape>('!', '#[#]', this, shapeProperty);
    var values = JS<JSArray>('!', '#[#]', this, valuesProperty);
    return _hashCode = Object.hashAll([shape, ...values]);
  }

  @override
  String toString() => _toString(false);

  /// Returns the string representation of this record.
  ///
  /// Will recursively call [toString] on the elements when [safe] is `false`
  /// or [Primitives.safeToString] when [safe] is `true`.
  String _toString(bool safe) {
    final cachedValue = _printed;
    if (!safe && cachedValue != null) return cachedValue;
    var buffer = StringBuffer();
    var shape = JS<Shape>('!', '#[#]', this, shapeProperty);
    var values = JS<JSArray>('!', '#[#]', this, valuesProperty);
    var posCount = shape.positionals;
    var count = values.length;

    if (safe) buffer.write('Record ');
    buffer.write('(');
    for (var i = 0; i < count; i++) {
      if (i >= posCount) {
        buffer.write('${shape.named![i - posCount]}');
        buffer.write(': ');
      }
      var value = values[i];
      buffer.write(safe ? Primitives.safeToString(value) : '${value}');
      if (i < count - 1) buffer.write(', ');
    }
    buffer.write(')');
    var result = buffer.toString();
    if (!safe) _printed = result;
    return result;
  }
}

/// Cache used to canonicalize all Record shapes in the program.
///
/// [Shape]s are keyed by a distinct shape key [String], that consists of the
/// total number of elements followed by semicolon and then a comma-separated
/// list of the named element names in sorted order.
///
/// Shape key examples:
///
///   | Record                              | Shape Key     |
///   -------------------------------------------------------
///   | (false, "hello")                    | "2;"          |
///   | (name: "Fosse", legs: 4)            | "2;legs,name" |
///   | ("hello", name: "Cello", legs: 4)   | "3;legs,name" |
final shapes = JS('!', 'new Map()');

/// Cache used to canonicalize all Record representation classes in the program.
///
/// These are keyed by a distinct shape recipe String, which consists of an
/// integer followed by space-separated named labels.
final _records = JS('!', 'new Map()');

/// Returns a canonicalized shape for the provided number of [positionals] and
/// [named] elements.
///
/// The [shapeKey] must agree with the number of [positionals] and the [named]
/// elements list. See [shapes] for a description of the shape key format.
Shape registerShape(
    @notNull String shapeKey, @notNull int positionals, List<String>? named) {
  var cached = JS<Shape?>('', '#.get(#)', shapes, shapeKey);
  if (cached != null) {
    return cached;
  }

  var shape = Shape(positionals, named);
  JS('', '#.set(#, #)', shapes, shapeKey, shape);
  return shape;
}

/// Returns a canonicalized Record class with the provided number of
/// [positionals] and [named] elements.
///
/// The [shapeKey] must agree with the number of [positionals] and the [named]
/// elements list. See [shapes] for a description of the shape key format.
Object registerRecord(
    @notNull String shapeKey, @notNull int positionals, List<String>? named) {
  var cached = JS('', '#.get(#)', _records, shapeKey);
  if (cached != null) {
    return cached;
  }

  Object recordClass =
      JS('!', 'class _Record extends # {}', JS_CLASS_REF(RecordImpl));
  // Add a 'new' function to be used instead of a constructor
  // (which is disallowed on dart objects).
  Object newRecord = JS(
      '!',
      '''
    #.new = function (shape, values) {
      Object.getPrototypeOf(#).new.call(this, shape, values);
    }
  ''',
      recordClass,
      recordClass);

  JS('!', '#.prototype = #.prototype', newRecord, recordClass);
  var recordPrototype = JS('', '#.prototype', recordClass);

  _recordGet(@notNull int index) => JS(
      '!', 'function recordGet() {return this[#][#];}', valuesProperty, index);

  // Add convenience getters for accessing the record's field values.
  var count = 0;
  while (count < positionals) {
    var name = '\$${count + 1}';
    defineAccessor(recordPrototype, name,
        get: _recordGet(count), enumerable: true);
    count++;
  }
  if (named != null) {
    for (var name in named) {
      if (name == 'constructor' || name == 'prototype') {
        // This renaming is directly coupled to the renaming logic at compile
        // time in js_names.dart `.memberNameForDartMember()`.
        name = '_$name';
      }
      defineAccessor(recordPrototype, name,
          get: _recordGet(count), enumerable: true);
      count++;
    }
  }

  JS('', '#.set(#, #)', _records, shapeKey, newRecord);
  return newRecord;
}

/// Creates a record consisting of [values] with the shape described by the
/// number of [positionals] and [named] elements.
///
/// The [shapeKey] must agree with the number of [positionals] and the [named]
/// elements list. See [shapes] for a description of the shape key format.
Object recordLiteral(@notNull String shapeKey, @notNull int positionals,
    List<String>? named, @notNull List values) {
  var shape = registerShape(shapeKey, positionals, named);
  var record = registerRecord(shapeKey, positionals, named);
  return JS('!', 'new #(#, #)', record, shape, values);
}

String recordSafeToString(RecordImpl rec) => rec._toString(true);
