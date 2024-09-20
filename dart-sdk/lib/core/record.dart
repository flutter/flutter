// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/// A record value.
///
/// The `Record` class is a supertype of all *record types*,
/// but is not itself the runtime type of any object instances
/// _(it's an abstract class)_.
/// All objects that implement `Record` has a record type as their runtime type.
///
/// A record value, described by a record type, consists of a number of fields,
/// which are each either positional or named.
///
/// Record values and record types are written similarly to
/// argument lists and simplified function type parameter lists (no `required`
/// modifier allowed, or needed, since record fields are never optional).
/// Example:
/// ```dart
/// (int, String, {bool isValid}) triple = (1, "one", isValid: true);
/// ```
/// is syntactically similar to
/// ```dart
/// typedef F = void Function(int, String, {bool isValid});
/// void callIt(F f) => f(1, "one", isValid: true);
/// ```
///
/// Every record and record type has a *shape*,
/// given by the number of positional fields and the names of named fields.
/// For example:
/// ```dart continued
/// (double value, String name, {String isValid}) another = (
///      3.14, "Pi", isValid: "real");
/// ```
/// is another record declaration with the same *shape* (two positional fields,
/// one named field named `isValid`), but with a different type.
/// The names written on the positional fields are entirely for documentation
/// purposes, they have no effect on the program _(same as names on positional
/// parameters in function types, like `typedef F = int Function(int value);`,
/// where the identifier `value` has no effect)_.
///
/// Record values are mainly destructured using patterns, like:
/// ```dart continued
/// switch (triple) {
///   case (int value, String name, isValid: bool ok): // ....
/// }
/// ```
/// The individual fields can also be accessed using named getters,
/// using `$1`, `$2`, etc. for positional fields, and the names themselves
/// for named fields.
/// ```dart continued
/// int value = triple.$1;
/// String name = triple.$2;
/// bool ok = triple.isValid;
/// ```
/// Because of that, some identifiers cannot be used as names of named fields:
/// * The names of `Object` members: `hashCode`, `runtimeType`, `toString` and
///   `noSuchMethod`.
/// * The name of a positional getter in the same record, so `(0, $1: 0)` is
///   invalid, but `(0, $2: 0)` is valid, since there is no positional field
///   with getter `$2` in *that* record shape. _(It'll still be confusing,
///   and should be avoided in practice.)_
/// * Also, no name starting with an underscore, `_`, is allowed. Field names
///   cannot be library private.
///
/// The run-time type of a record object is a record type, and as such, a
/// subtype of [Record], and transitively of [Object] and its supertypes.
///
/// Record values do not have a persistent [identical] behavior.
/// A reference to a record object can change *at any time* to a reference
/// to another record object with the same shape and field values.
///
/// Other than that, a record type can only be a subtype of another record
/// type with the same shape, and only if the former record type's field types
/// are subtypes of the other record type's corresponding field types.
/// That is, `(int, String, {bool isValid})` is a subtype of
/// `(num, String, {Object isValid})`, because they have the same shape,
/// and the field types are pointwise subtypes.
/// Record types with different shapes are unrelated to each other.
abstract final class Record {
  /// A `Type` object representing the runtime type of a record.
  ///
  /// The runtime type of a record is defined by the record's *shape*,
  /// the number of positional fields and names of named fields,
  /// and the runtime type of each of those fields.
  /// (The runtime type of the record does not depend on
  /// the `runtimeType` getter of its fields' values,
  /// which may have overridden [Object.runtimeType].)
  ///
  /// The `Type` object of a record type is only equal to another `Type` object
  /// for a record type, and only if the other record type has the same shape,
  /// and if the corresponding fields have the same types.
  Type get runtimeType;

  /// A hash-code compatible with `==`.
  ///
  /// Since [operator==] is defined in terms of the `==` operators of
  /// the record's field values, the hash code is also computed based on the
  /// [Object.hashCode] of the field values.
  ///
  /// There is no guaranteed order in which the `hashCode` of field values
  /// is accessed.
  /// It's unspecified how those values are combined,
  /// other than it being consistent throughout a single program execution.
  int get hashCode;

  /// Checks whether [other] has the same shape and equal fields to this record.
  ///
  /// A record is only equal to another record with the same *shape*,
  /// and then only when the value of every field is equal,
  /// occording to its `==`, to the corresponding field value of [other].
  ///
  /// There is no guaranteed order in which field value equality is checked,
  /// and it's unspecified whether further fields are checked after finding
  /// corresponding fields which are not equal.
  /// It's not even guaranteed that the order is consistent within a single
  /// program execution.
  ///
  /// As usual, be very careful around objects which break the equality
  /// contract, like [double.nan] which is not equal to itself.
  /// For example
  /// ```dart
  /// var pair = ("a", double.nan);
  /// if (pair != pair) print("Oops");
  /// ```
  /// will print the "Oops", because `pair == pair` is defined to be equal to
  /// `"a" == "a" & double.nan == double.nan`, which is false.
  bool operator ==(Object other);

  /// Creates a string-representation of the record.
  ///
  /// The string representation is only intended for debugging,
  /// and may differ between development and production.
  /// There is no guaranteed format in production mode.
  ///
  /// In development mode, the string will strive to be a parenthesized
  /// comma separated list of field representations, where the field
  /// representation is the `toString` of the value for positional fields,
  /// and `someName:` followed by that for a named field named `someName`.
  String toString();
}
