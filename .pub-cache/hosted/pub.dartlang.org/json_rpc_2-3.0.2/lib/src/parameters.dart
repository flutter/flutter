// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'exception.dart';

/// A wrapper for the parameters to a server method.
///
/// JSON-RPC 2.0 allows parameters that are either a list or a map. This class
/// provides functions that not only assert that the parameters object is the
/// correct type, but also that the expected arguments exist and are themselves
/// the correct type.
///
/// Example usage:
///
///     server.registerMethod("subtract", (params) {
///       return params["minuend"].asNum - params["subtrahend"].asNum;
///     });
class Parameters {
  /// The name of the method that this request called.
  final String method;

  /// The underlying value of the parameters object.
  ///
  /// If this is accessed for a [Parameter] that was not passed, the request
  /// will be automatically rejected. To avoid this, use [Parameter.valueOr].
  dynamic get value => _value;
  final dynamic _value;

  Parameters(this.method, this._value);

  /// Returns a single parameter.
  ///
  /// If [key] is a [String], the request is expected to provide named
  /// parameters. If it's an [int], the request is expected to provide
  /// positional parameters. Requests that don't do so will be rejected
  /// automatically.
  ///
  /// Whether or not the given parameter exists, this returns a [Parameter]
  /// object. If a parameter's value is accessed through a getter like [value]
  /// or [Parameter.asNum], the request will be rejected if that parameter
  /// doesn't exist. On the other hand, if it's accessed through a method with a
  /// default value like [Parameter.valueOr] or [Parameter.asNumOr], the default
  /// value will be returned.
  Parameter operator [](key) {
    if (key is int) {
      _assertPositional();
      if (key < value.length) {
        return Parameter._(method, value[key], this, key);
      } else {
        return _MissingParameter(method, this, key);
      }
    } else if (key is String) {
      _assertNamed();
      if (value.containsKey(key)) {
        return Parameter._(method, value[key], this, key);
      } else {
        return _MissingParameter(method, this, key);
      }
    } else {
      throw ArgumentError('Parameters[] only takes an int or a string, was '
          '"$key".');
    }
  }

  /// Asserts that [value] exists and is a [List] and returns it.
  List get asList {
    _assertPositional();
    return value;
  }

  /// Asserts that [value] exists and is a [Map] and returns it.
  Map get asMap {
    _assertNamed();
    return value;
  }

  /// Asserts that [value] is a positional argument list.
  void _assertPositional() {
    if (value is List) return;
    throw RpcException.invalidParams('Parameters for method "$method" '
        'must be passed by position.');
  }

  /// Asserts that [value] is a named argument map.
  void _assertNamed() {
    if (value is Map) return;
    throw RpcException.invalidParams('Parameters for method "$method" '
        'must be passed by name.');
  }
}

/// A wrapper for a single parameter to a server method.
///
/// This provides numerous functions for asserting the type of the parameter in
/// question. These functions each have a version that asserts that the
/// parameter exists (for example, [asNum] and [asString]) and a version that
/// returns a default value if the parameter doesn't exist (for example,
/// [asNumOr] and [asStringOr]). If an assertion fails, the request is
/// automatically rejected.
///
/// This extends [Parameters] to make it easy to access nested parameters. For
/// example:
///
///     // "params.value" is "{'scores': {'home': [5, 10, 17]}}"
///     params['scores']['home'][2].asInt // => 17
class Parameter extends Parameters {
  // The parent parameters, used to construct [_path].
  final Parameters _parent;

  /// The key used to access [this], used to construct [_path].
  final dynamic _key;

  /// A human-readable representation of the path of getters used to get this.
  ///
  /// Named parameters are represented as `.name`, whereas positional parameters
  /// are represented as `[index]`. For example: `"foo[0].bar.baz"`. Named
  /// parameters that contain characters that are neither alphanumeric,
  /// underscores, or hyphens will be JSON-encoded. For example: `"foo
  /// bar"."baz.bang"`. If quotes are used for an individual component, they
  /// won't be used for the entire string.
  ///
  /// An exception is made for single-level parameters. A single-level
  /// positional parameter is just represented by the index plus one, because
  /// "parameter 1" is clearer than "parameter [0]". A single-level named
  /// parameter is represented by that name in quotes.
  String get _path {
    if (_parent is! Parameter) {
      return _key is int ? (_key + 1).toString() : jsonEncode(_key);
    }

    String quoteKey(key) {
      if (key.contains(RegExp(r'[^a-zA-Z0-9_-]'))) return jsonEncode(key);
      return key;
    }

    String computePath(params) {
      if (params._parent is! Parameter) {
        return params._key is int ? '[${params._key}]' : quoteKey(params._key);
      }

      var path = computePath(params._parent);
      return params._key is int
          ? '$path[${params._key}]'
          : '$path.${quoteKey(params._key)}';
    }

    return computePath(this);
  }

  /// Whether this parameter exists.
  bool get exists => true;

  Parameter._(String method, value, this._parent, this._key)
      : super(method, value);

  /// Returns [value], or [defaultValue] if this parameter wasn't passed.
  dynamic valueOr(defaultValue) => value;

  /// Asserts that [value] exists and is a number and returns it.
  ///
  /// [asNumOr] may be used to provide a default value instead of rejecting the
  /// request if [value] doesn't exist.
  num get asNum => _getTyped('a number', (value) => value is num);

  /// Asserts that [value] is a number and returns it.
  ///
  /// If [value] doesn't exist, this returns [defaultValue].
  num asNumOr(num defaultValue) => asNum;

  /// Asserts that [value] exists and is an integer and returns it.
  ///
  /// [asIntOr] may be used to provide a default value instead of rejecting the
  /// request if [value] doesn't exist.
  ///
  /// Note that which values count as integers varies between the Dart VM and
  /// dart2js. The value `1.0` will be considered an integer under dart2js but
  /// not under the VM.
  int get asInt => _getTyped('an integer', (value) => value is int);

  /// Asserts that [value] is an integer and returns it.
  ///
  /// If [value] doesn't exist, this returns [defaultValue].
  ///
  /// Note that which values count as integers varies between the Dart VM and
  /// dart2js. The value `1.0` will be considered an integer under dart2js but
  /// not under the VM.
  int asIntOr(int defaultValue) => asInt;

  /// Asserts that [value] exists and is a boolean and returns it.
  ///
  /// [asBoolOr] may be used to provide a default value instead of rejecting the
  /// request if [value] doesn't exist.
  bool get asBool => _getTyped('a boolean', (value) => value is bool);

  /// Asserts that [value] is a boolean and returns it.
  ///
  /// If [value] doesn't exist, this returns [defaultValue].
  bool asBoolOr(bool defaultValue) => asBool;

  /// Asserts that [value] exists and is a string and returns it.
  ///
  /// [asStringOr] may be used to provide a default value instead of rejecting
  /// the request if [value] doesn't exist.
  String get asString => _getTyped('a string', (value) => value is String);

  /// Asserts that [value] is a string and returns it.
  ///
  /// If [value] doesn't exist, this returns [defaultValue].
  String asStringOr(String defaultValue) => asString;

  /// Asserts that [value] exists and is a [List] and returns it.
  ///
  /// [asListOr] may be used to provide a default value instead of rejecting the
  /// request if [value] doesn't exist.
  @override
  List get asList => _getTyped('an Array', (value) => value is List);

  /// Asserts that [value] is a [List] and returns it.
  ///
  /// If [value] doesn't exist, this returns [defaultValue].
  List asListOr(List defaultValue) => asList;

  /// Asserts that [value] exists and is a [Map] and returns it.
  ///
  /// [asMapOr] may be used to provide a default value instead of rejecting the
  /// request if [value] doesn't exist.
  @override
  Map get asMap => _getTyped('an Object', (value) => value is Map);

  /// Asserts that [value] is a [Map] and returns it.
  ///
  /// If [value] doesn't exist, this returns [defaultValue].
  Map asMapOr(Map defaultValue) => asMap;

  /// Asserts that [value] exists, is a string, and can be parsed as a
  /// [DateTime] and returns it.
  ///
  /// [asDateTimeOr] may be used to provide a default value instead of rejecting
  /// the request if [value] doesn't exist.
  DateTime get asDateTime => _getParsed('date/time', DateTime.parse);

  /// Asserts that [value] exists, is a string, and can be parsed as a
  /// [DateTime] and returns it.
  ///
  /// If [value] doesn't exist, this returns [defaultValue].
  DateTime asDateTimeOr(DateTime defaultValue) => asDateTime;

  /// Asserts that [value] exists, is a string, and can be parsed as a
  /// [Uri] and returns it.
  ///
  /// [asUriOr] may be used to provide a default value instead of rejecting the
  /// request if [value] doesn't exist.
  Uri get asUri => _getParsed('URI', Uri.parse);

  /// Asserts that [value] exists, is a string, and can be parsed as a
  /// [Uri] and returns it.
  ///
  /// If [value] doesn't exist, this returns [defaultValue].
  Uri asUriOr(Uri defaultValue) => asUri;

  /// Get a parameter named [named] that matches [test], or the value of calling
  /// [orElse].
  ///
  /// [type] is used for the error message. It should begin with an indefinite
  /// article.
  dynamic _getTyped(String type, bool Function(dynamic) test) {
    if (test(value)) return value;
    throw RpcException.invalidParams('Parameter $_path for method '
        '"$method" must be $type, but was ${jsonEncode(value)}.');
  }

  dynamic _getParsed(String description, Function(String) parse) {
    var string = asString;
    try {
      return parse(string);
    } on FormatException catch (error) {
      // DateTime.parse doesn't actually include any useful information in the
      // FormatException, just the string that was being parsed. There's no use
      // in including that in the RPC exception. See issue 17753.
      var message = error.message;
      if (message == string) {
        message = '';
      } else {
        message = '\n$message';
      }

      throw RpcException.invalidParams('Parameter $_path for method '
          '"$method" must be a valid $description, but was '
          '${jsonEncode(string)}.$message');
    }
  }

  @override
  void _assertPositional() {
    // Throw the standard exception for a mis-typed list.
    asList;
  }

  @override
  void _assertNamed() {
    // Throw the standard exception for a mis-typed map.
    asMap;
  }
}

/// A subclass of [Parameter] representing a missing parameter.
class _MissingParameter extends Parameter {
  @override
  dynamic get value {
    throw RpcException.invalidParams('Request for method "$method" is '
        'missing required parameter $_path.');
  }

  @override
  bool get exists => false;

  _MissingParameter(String method, Parameters parent, key)
      : super._(method, null, parent, key);

  @override
  dynamic valueOr(defaultValue) => defaultValue;

  @override
  num asNumOr(num defaultValue) => defaultValue;

  @override
  int asIntOr(int defaultValue) => defaultValue;

  @override
  bool asBoolOr(bool defaultValue) => defaultValue;

  @override
  String asStringOr(String defaultValue) => defaultValue;

  @override
  List asListOr(List defaultValue) => defaultValue;

  @override
  Map asMapOr(Map defaultValue) => defaultValue;

  @override
  DateTime asDateTimeOr(DateTime defaultValue) => defaultValue;

  @override
  Uri asUriOr(Uri defaultValue) => defaultValue;
}
