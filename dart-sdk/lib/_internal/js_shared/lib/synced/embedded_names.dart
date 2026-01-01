// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: constant_identifier_names

/// A 'Universe' object used by 'dart:_rti'.
const RTI_UNIVERSE = 'typeUniverse';

/// An embedded global that contains the property used to store type information
/// on JavaScript Array instances. This is a Symbol (except for IE11, where is
/// is a String).
const ARRAY_RTI_PROPERTY = 'arrayRti';

/// A list of types used in the program e.g. for reflection or encoding of
/// function types.
///
/// Use [JsBuiltin.getType] instead of directly accessing this embedded global.
const TYPES = 'types';

/// Names that are supported by [JS_GET_NAME].
// TODO(herhut): Make entries lower case (as in fields) and find a better name.
enum JsGetName {
  GETTER_PREFIX,
  SETTER_PREFIX,
  CALL_PREFIX,
  CALL_PREFIX0,
  CALL_PREFIX1,
  CALL_PREFIX2,
  CALL_PREFIX3,
  CALL_PREFIX4,
  CALL_PREFIX5,
  CALL_CATCH_ALL,
  REQUIRED_PARAMETER_PROPERTY,
  DEFAULT_VALUES_PROPERTY,
  CALL_NAME_PROPERTY,
  DEFERRED_ACTION_PROPERTY,

  /// Prefix used for generated type test property on classes.
  OPERATOR_IS_PREFIX,

  /// Name used for generated function types on classes and methods.
  SIGNATURE_NAME,

  /// Name of JavaScript property used to store runtime-type information on
  /// instances of parameterized classes.
  RTI_NAME,

  /// String representation of the type of the Future class.
  FUTURE_CLASS_TYPE_NAME,

  /// Field name used for determining if an object or its interceptor has
  /// JavaScript indexing behavior.
  IS_INDEXABLE_FIELD_NAME,

  /// String representation of the type of the null class.
  NULL_CLASS_TYPE_NAME,

  /// String representation of the type of the object class.
  OBJECT_CLASS_TYPE_NAME,

  /// String representation of the type of the List class.
  LIST_CLASS_TYPE_NAME,

  /// Property name for Rti._as field.
  RTI_FIELD_AS,

  /// Property name for Rti._is field.
  RTI_FIELD_IS,

  /// Property name for shape tag property in record class prototype.
  RECORD_SHAPE_TAG_PROPERTY,

  /// Property name for shape recipe property in record class prototype.
  RECORD_SHAPE_TYPE_PROPERTY,
}

enum JsBuiltin {
  /// Returns the JavaScript constructor function for Dart's Object class.
  /// This can be used for type tests, as in
  ///
  ///     var constructor = JS_BUILTIN('', JsBuiltin.dartObjectConstructor);
  ///     if (JS('bool', '# instanceof #', obj, constructor))
  ///       ...
  dartObjectConstructor,

  /// Returns the JavaScript constructor function for the runtime's Closure
  /// class, the base class of all closure objects.  This can be used for type
  /// tests, as in
  ///
  ///     var constructor = JS_BUILTIN('', JsBuiltin.dartClosureConstructor);
  ///     if (JS('bool', '# instanceof #', obj, constructor))
  ///       ...
  dartClosureConstructor,

  /// Returns true if the given type is a type argument of a js-interop class
  /// or a supertype of a js-interop class.
  ///
  ///     JS_BUILTIN('bool', JsBuiltin.isJsInteropTypeArgument, o)
  isJsInteropTypeArgument,

  /// Returns the metadata of the given [index].
  ///
  ///     JS_BUILTIN('returns:var;effects:none;depends:none',
  ///                JsBuiltin.getMetadata, index);
  getMetadata,

  /// Returns the type of the given [index].
  ///
  ///     JS_BUILTIN('returns:var;effects:none;depends:none',
  ///                JsBuiltin.getType, index);
  getType,
}

/// Names of fields of the Rti Universe object.
class RtiUniverseFieldNames {
  static const String evalCache = 'eC';
  static const String typeRules = 'tR';
  static const String erasedTypes = 'eT';
  static const String typeParameterVariances = 'tPV';
  static const String sharedEmptyArray = 'sEA';
}
