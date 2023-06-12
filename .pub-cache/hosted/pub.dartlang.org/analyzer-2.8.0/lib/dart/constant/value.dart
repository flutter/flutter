// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The interface used to access the result of constant evaluation.
///
/// Because the analyzer does not have any of the code under analysis loaded, it
/// does not do real evaluation. Instead it performs a symbolic computation and
/// presents those results through this interface.
///
/// Instances of these constant values are accessed through the
/// [element model](../element/element.dart).
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

/// A representation of the value of a compile-time constant expression.
///
/// Note that, unlike the mirrors system, the object being represented does *not*
/// exist. This interface allows static analysis tools to determine something
/// about the state of the object that would exist if the code that creates the
/// object were executed, but none of the code being analyzed is actually
/// executed.
///
/// Clients may not extend, implement or mix-in this class.
abstract class DartObject {
  /// Return `true` if the value of the object being represented is known.
  ///
  /// This method will return `false` if
  /// * the value being represented is the value of a declared variable (a
  ///   variable whose value is provided at run-time using a `-D` command-line
  ///   option), or
  /// * the value is a function.
  ///
  /// The result of this method does not imply anything about the state of
  /// object representations returned by the method [getField], those that are
  /// elements of the list returned by [toListValue], or the keys or values in
  /// the map returned by [toMapValue]. For example, a representation of a list
  /// can return `true` even if one or more of the elements of that list would
  /// return `false`.
  bool get hasKnownValue;

  /// Return `true` if the object being represented represents the value 'null'.
  bool get isNull;

  /// Return a representation of the type of the object being represented.
  ///
  /// For values resulting from the invocation of a 'const' constructor, this
  /// will be a representation of the run-time type of the object.
  ///
  /// For values resulting from a literal expression, this will be a
  /// representation of the static type of the value -- `int` for integer
  /// literals, `List` for list literals, etc. -- even when the static type is an
  /// abstract type (such as `List`) and hence will never be the run-time type of
  /// the represented object.
  ///
  /// For values resulting from any other kind of expression, this will be a
  /// representation of the result of evaluating the expression.
  ///
  /// Return `null` if the expression cannot be evaluated, either because it is
  /// not a valid constant expression or because one or more of the values used
  /// in the expression does not have a known value.
  ///
  /// This method can return a representation of the type, even if this object
  /// would return `false` from [hasKnownValue].
  DartType? get type;

  /// Return a representation of the value of the field with the given [name].
  ///
  /// Return `null` if either the object being represented does not have a field
  /// with the given name or if the implementation of the class of the object is
  /// invalid, making it impossible to determine that value of the field.
  ///
  /// Note that, unlike the mirrors API, this method does *not* invoke a getter;
  /// it simply returns a representation of the known state of a field.
  DartObject? getField(String name);

  /// Return a boolean corresponding to the value of the object being
  /// represented, or `null` if
  /// * this object is not of type 'bool',
  /// * the value of the object being represented is not known, or
  /// * the value of the object being represented is `null`.
  bool? toBoolValue();

  /// Return a double corresponding to the value of the object being represented,
  /// or `null`
  /// if
  /// * this object is not of type 'double',
  /// * the value of the object being represented is not known, or
  /// * the value of the object being represented is `null`.
  double? toDoubleValue();

  /// Return an element corresponding to the value of the object being
  /// represented, or `null`
  /// if
  /// * this object is not of a function type,
  /// * the value of the object being represented is not known, or
  /// * the value of the object being represented is `null`.
  ExecutableElement? toFunctionValue();

  /// Return an integer corresponding to the value of the object being
  /// represented, or `null` if
  /// * this object is not of type 'int',
  /// * the value of the object being represented is not known, or
  /// * the value of the object being represented is `null`.
  int? toIntValue();

  /// Return a list corresponding to the value of the object being represented,
  /// or `null` if
  /// * this object is not of type 'List', or
  /// * the value of the object being represented is `null`.
  List<DartObject>? toListValue();

  /// Return a map corresponding to the value of the object being represented, or
  /// `null` if
  /// * this object is not of type 'Map', or
  /// * the value of the object being represented is `null`.
  Map<DartObject?, DartObject?>? toMapValue();

  /// Return a set corresponding to the value of the object being represented,
  /// or `null` if
  /// * this object is not of type 'Set', or
  /// * the value of the object being represented is `null`.
  Set<DartObject>? toSetValue();

  /// Return a string corresponding to the value of the object being represented,
  /// or `null` if
  /// * this object is not of type 'String',
  /// * the value of the object being represented is not known, or
  /// * the value of the object being represented is `null`.
  String? toStringValue();

  /// Return a string corresponding to the value of the object being represented,
  /// or `null` if
  /// * this object is not of type 'Symbol', or
  /// * the value of the object being represented is `null`.
  /// (We return the string
  String? toSymbolValue();

  /// Return the representation of the type corresponding to the value of the
  /// object being represented, or `null` if
  /// * this object is not of type 'Type', or
  /// * the value of the object being represented is `null`.
  DartType? toTypeValue();
}
