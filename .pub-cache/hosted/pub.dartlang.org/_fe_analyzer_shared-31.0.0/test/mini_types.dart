// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file implements a "mini type system" that's similar to full Dart types,
// but light weight enough to be suitable for unit testing of code in the
// `_fe_analyzer_shared` package.

import 'package:test/test.dart';

/// Representation of a function type suitable for unit testing of code in the
/// `_fe_analyzer_shared` package.
///
/// Optional and named parameters are not (yet) supported.
class FunctionType extends Type {
  /// The return type.
  final Type returnType;

  /// A list of the types of positional parameters.
  final List<Type> positionalParameters;

  FunctionType(this.returnType, this.positionalParameters) : super._();

  @override
  String get type => '$returnType Function(${positionalParameters.join(', ')})';
}

/// Representation of a "simple" type suitable for unit testing of code in the
/// `_fe_analyzer_shared` package.  A "simple" type is either an interface type
/// with zero or more type parameters (e.g. `double`, or `Map<int, String>`), a
/// reference to a type parameter, or one of the special types whose name is a
/// single word (e.g. `dynamic`).
class NonFunctionType extends Type {
  /// The name of the type.
  final String name;

  /// The type arguments, or `const []` if there are no type arguments.
  final List<Type> args;

  NonFunctionType(this.name, {this.args = const []}) : super._();

  @override
  String get type {
    if (args.isEmpty) {
      return name;
    } else {
      return '$name<${args.join(', ')}>';
    }
  }
}

/// Representation of a promoted type parameter type suitable for unit testing
/// of code in the `_fe_analyzer_shared` package.  A promoted type parameter is
/// often written using the syntax `a&b`, where `a` is the type parameter and
/// `b` is what it's promoted to.  For example, `T&int` represents the type
/// parameter `T`, promoted to `int`.
class PromotedTypeVariableType extends Type {
  final Type innerType;

  final Type promotion;

  PromotedTypeVariableType(this.innerType, this.promotion) : super._();

  @override
  String get type => '$innerType&$promotion';
}

/// Representation of a nullable type suitable for unit testing of code in the
/// `_fe_analyzer_shared` package.  This class is used only for nullable types
/// that are spelled with an explicit trailing `?`, e.g. `double?`; it is not
/// used for e.g. `dynamic` or `FutureOr<int?>`, even though those types are
/// nullable as well.
class QuestionType extends Type {
  final Type innerType;

  QuestionType(this.innerType) : super._();

  @override
  String get type => '$innerType?';
}

/// Representation of a "star" type suitable for unit testing of code in the
/// `_fe_analyzer_shared` package.
class StarType extends Type {
  final Type innerType;

  StarType(this.innerType) : super._();

  @override
  String get type => '$innerType*';
}

/// Representation of a type suitable for unit testing of code in the
/// `_fe_analyzer_shared` package.
///
/// Note that we don't want code in `_fe_analyzer_shared` to inadvertently
/// compare types using `==` (or to store types in sets/maps, which can trigger
/// `==` to be used to compare them); this could cause bugs by causing
/// alternative spellings of the same type to be treated differently (e.g.
/// `FutureOr<int?>?` should be treated equivalently to `FutureOr<int?>`).  To
/// help ensure this, both `==` and `hashCode` throw exceptions by default.  To
/// defeat this behavior (e.g. so that a type can be passed to `expect`, use
/// [Type.withComparisonsAllowed].
abstract class Type {
  static bool _allowComparisons = false;

  factory Type(String typeStr) => _TypeParser.parse(typeStr);

  const Type._();

  @override
  int get hashCode {
    if (!_allowComparisons) {
      // Types should not be compared using hashCode.  They should be compared
      // using relations like subtyping and assignability.
      fail('Unexpected use of operator== on types');
    }
    return type.hashCode;
  }

  String get type;

  @override
  bool operator ==(Object other) {
    if (!_allowComparisons) {
      // Types should not be compared using hashCode.  They should be compared
      // using relations like subtyping and assignability.
      fail('Unexpected use of operator== on types');
    }
    return other is Type && this.type == other.type;
  }

  @override
  String toString() => type;

  /// Executes [callback] while temporarily allowing types to be compared using
  /// `==` and `hashCode`.
  static T withComparisonsAllowed<T>(T Function() callback) {
    assert(!_allowComparisons);
    _allowComparisons = true;
    try {
      return callback();
    } finally {
      Type._allowComparisons = false;
    }
  }
}

/// Representation of the unknown type suitable for unit testing of code in the
/// `_fe_analyzer_shared` package.
class UnknownType extends Type {
  const UnknownType() : super._();

  @override
  String get type => '?';
}

class _TypeParser {
  static final _typeTokenizationRegexp =
      RegExp(_identifierPattern + r'|\(|\)|<|>|,|\?|\*|&');

  static const _identifierPattern = '[_a-zA-Z][_a-zA-Z0-9]*';

  static final _identifierRegexp = RegExp(_identifierPattern);

  final String _typeStr;

  final List<String> _tokens;

  int _i = 0;

  _TypeParser._(this._typeStr, this._tokens);

  String get _currentToken => _tokens[_i];

  void _next() {
    _i++;
  }

  Never _parseFailure(String message) {
    fail('Error parsing type `$_typeStr` at token $_currentToken: $message');
  }

  Type _parseNullability(Type innerType) {
    if (_currentToken == '?') {
      _next();
      return QuestionType(innerType);
    } else if (_currentToken == '*') {
      _next();
      return StarType(innerType);
    } else {
      return innerType;
    }
  }

  Type? _parseSuffix(Type type) {
    if (_currentToken == '&') {
      _next();
      var promotion = _parseType();
      return PromotedTypeVariableType(type, promotion);
    } else if (_currentToken == 'Function') {
      _next();
      if (_currentToken != '(') {
        _parseFailure('Expected `(`');
      }
      _next();
      var parameterTypes = <Type>[];
      if (_currentToken != ')') {
        while (true) {
          parameterTypes.add(_parseType());
          if (_currentToken == ')') break;
          if (_currentToken != ',') {
            _parseFailure('Expected `,` or `)`');
          }
          _next();
        }
      }
      _next();
      return _parseNullability(FunctionType(type, parameterTypes));
    } else {
      return null;
    }
  }

  Type _parseType() {
    // We currently accept the following grammar for types:
    //   type := identifier typeArgs? nullability suffix* | `?`
    //   typeArgs := `<` type (`,` type)* `>`
    //   nullability := (`?` | `*`)?
    //   suffix := `Function` `(` type (`,` type)* `)` suffix
    //           | `&` type
    // TODO(paulberry): support more syntax if needed
    if (_currentToken == '?') {
      _next();
      return const UnknownType();
    }
    var typeName = _currentToken;
    if (_identifierRegexp.matchAsPrefix(typeName) == null) {
      _parseFailure('Expected an identifier or `?`');
    }
    _next();
    List<Type> typeArgs;
    if (_currentToken == '<') {
      _next();
      typeArgs = [];
      while (true) {
        typeArgs.add(_parseType());
        if (_currentToken == '>') break;
        if (_currentToken != ',') {
          _parseFailure('Expected `,` or `>`');
        }
        _next();
      }
      _next();
    } else {
      typeArgs = const [];
    }
    var result = _parseNullability(NonFunctionType(typeName, args: typeArgs));
    while (true) {
      var newResult = _parseSuffix(result);
      if (newResult == null) break;
      result = newResult;
    }
    return result;
  }

  static Type parse(String typeStr) {
    var parser = _TypeParser._(typeStr, _tokenizeTypeStr(typeStr));
    var result = parser._parseType();
    if (parser._currentToken != '<END>') {
      fail('Extra tokens after parsing type `$typeStr`: '
          '${parser._tokens.sublist(parser._i, parser._tokens.length - 1)}');
    }
    return result;
  }

  static List<String> _tokenizeTypeStr(String typeStr) {
    var result = <String>[];
    int lastMatchEnd = 0;
    for (var match in _typeTokenizationRegexp.allMatches(typeStr)) {
      var extraChars = typeStr.substring(lastMatchEnd, match.start).trim();
      if (extraChars.isNotEmpty) {
        fail('Unrecognized character(s) in type `$typeStr`: $extraChars');
      }
      result.add(typeStr.substring(match.start, match.end));
      lastMatchEnd = match.end;
    }
    var extraChars = typeStr.substring(lastMatchEnd).trim();
    if (extraChars.isNotEmpty) {
      fail('Unrecognized character(s) in type `$typeStr`: $extraChars');
    }
    result.add('<END>');
    return result;
  }
}
