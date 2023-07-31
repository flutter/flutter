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
/// Optional parameters, named parameters, and type parameters are not (yet)
/// supported.
class FunctionType extends Type {
  /// The return type.
  final Type returnType;

  /// A list of the types of positional parameters.
  final List<Type> positionalParameters;

  FunctionType(this.returnType, this.positionalParameters) : super._();

  @override
  Type? recursivelyDemote({required bool covariant}) {
    Type? newReturnType = returnType.recursivelyDemote(covariant: covariant);
    List<Type>? newPositionalParameters =
        positionalParameters.recursivelyDemote(covariant: !covariant);
    if (newReturnType == null && newPositionalParameters == null) {
      return null;
    }
    return FunctionType(newReturnType ?? returnType,
        newPositionalParameters ?? positionalParameters);
  }

  @override
  String _toString({required bool allowSuffixes}) {
    var result = '$returnType Function(${positionalParameters.join(', ')})';
    if (!allowSuffixes) {
      result = '($result)';
    }
    return result;
  }
}

/// Exception thrown if a type fails to parse properly.
class ParseError extends Error {
  final String message;

  ParseError(this.message);

  @override
  String toString() => message;
}

/// Representation of a primary type suitable for unit testing of code in the
/// `_fe_analyzer_shared` package.  A primary type is either an interface type
/// with zero or more type parameters (e.g. `double`, or `Map<int, String>`), a
/// reference to a type parameter, or one of the special types whose name is a
/// single word (e.g. `dynamic`).
class PrimaryType extends Type {
  /// The name of the type.
  final String name;

  /// The type arguments, or `const []` if there are no type arguments.
  final List<Type> args;

  PrimaryType(this.name, {this.args = const []}) : super._();

  @override
  Type? recursivelyDemote({required bool covariant}) {
    List<Type>? newArgs = args.recursivelyDemote(covariant: covariant);
    if (newArgs == null) return null;
    return PrimaryType(name, args: newArgs);
  }

  @override
  String _toString({required bool allowSuffixes}) {
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
  Type? recursivelyDemote({required bool covariant}) =>
      covariant ? innerType : new PrimaryType('Never');

  @override
  String _toString({required bool allowSuffixes}) {
    var result = '$innerType&${promotion._toString(allowSuffixes: false)}';
    if (!allowSuffixes) {
      result = '($result)';
    }
    return result;
  }
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
  Type? recursivelyDemote({required bool covariant}) {
    Type? newInnerType = innerType.recursivelyDemote(covariant: covariant);
    if (newInnerType == null) return null;
    return QuestionType(newInnerType);
  }

  @override
  String _toString({required bool allowSuffixes}) {
    var result = '$innerType?';
    if (!allowSuffixes) {
      result = '($result)';
    }
    return result;
  }
}

class RecordType extends Type {
  final List<Type> positional;
  final Map<String, Type> named;

  RecordType({
    required this.positional,
    required this.named,
  }) : super._();

  @override
  Type? recursivelyDemote({required bool covariant}) {
    List<Type>? newPositional;
    for (var i = 0; i < positional.length; i++) {
      var newType = positional[i].recursivelyDemote(covariant: covariant);
      if (newType != null) {
        newPositional ??= positional.toList();
        newPositional[i] = newType;
      }
    }

    Map<String, Type>? newNamed = _recursivelyDemoteNamed(covariant: covariant);

    if (newPositional == null && newNamed == null) {
      return null;
    }
    return RecordType(
      positional: newPositional ?? positional,
      named: newNamed ?? named,
    );
  }

  Map<String, Type>? _recursivelyDemoteNamed({required bool covariant}) {
    Map<String, Type> newNamed = {};
    bool hasChanged = false;
    for (var entry in named.entries) {
      var value = entry.value;
      var newType = value.recursivelyDemote(covariant: covariant);
      if (newType != null) hasChanged = true;
      newNamed[entry.key] = newType ?? value;
    }
    return hasChanged ? newNamed : null;
  }

  @override
  String _toString({required bool allowSuffixes}) {
    var positionalStr = positional.map((e) => '$e').join(', ');
    var namedStr = named.entries.map((e) => '${e.value} ${e.key}').join(', ');
    if (namedStr.isNotEmpty) {
      if (positional.isNotEmpty) {
        return '($positionalStr, {$namedStr})';
      } else {
        return '({$namedStr})';
      }
    } else if (positional.length == 1) {
      return '($positionalStr,)';
    } else {
      return '($positionalStr)';
    }
  }
}

/// Representation of a "star" type suitable for unit testing of code in the
/// `_fe_analyzer_shared` package.
class StarType extends Type {
  final Type innerType;

  StarType(this.innerType) : super._();

  @override
  Type? recursivelyDemote({required bool covariant}) {
    Type? newInnerType = innerType.recursivelyDemote(covariant: covariant);
    if (newInnerType == null) return null;
    return StarType(newInnerType);
  }

  @override
  String _toString({required bool allowSuffixes}) {
    var result = '$innerType*';
    if (!allowSuffixes) {
      result = '($result)';
    }
    return result;
  }
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

  String get type => _toString(allowSuffixes: true);

  @override
  bool operator ==(Object other) {
    if (!_allowComparisons) {
      // Types should not be compared using hashCode.  They should be compared
      // using relations like subtyping and assignability.
      fail('Unexpected use of operator== on types');
    }
    return other is Type && this.type == other.type;
  }

  /// Finds the nearest type that doesn't involve any type parameter promotion.
  /// If `covariant` is `true`, a supertype will be returned (replacing promoted
  /// type parameters with their unpromoted counterparts); otherwise a subtype
  /// will be returned (replacing promoted type parameters with `Never`).
  ///
  /// Returns `null` if this type is already free from type promotion.
  Type? recursivelyDemote({required bool covariant});

  @override
  String toString() => type;

  /// Returns a string representation of this type.  If `allowSuffixes` is
  /// `false`, then the result will be surrounded in parenthesis if it would
  /// otherwise have ended in a suffix.
  String _toString({required bool allowSuffixes});

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

class TypeSystem {
  static final Map<String, List<Type> Function(List<Type>)>
      _coreSuperInterfaceTemplates = {
    'bool': (_) => [Type('Object')],
    'double': (_) => [Type('num'), Type('Object')],
    'Future': (_) => [Type('Object')],
    'int': (_) => [Type('num'), Type('Object')],
    'Iterable': (_) => [Type('Object')],
    'List': (args) => [PrimaryType('Iterable', args: args), Type('Object')],
    'Map': (_) => [Type('Object')],
    'Object': (_) => [],
    'num': (_) => [Type('Object')],
    'String': (_) => [Type('Object')],
  };

  static final _nullType = Type('Null');

  static final _objectQuestionType = Type('Object?');

  static final _objectType = Type('Object');

  final Map<String, Type> _typeVarBounds = {};

  final Map<String, List<Type> Function(List<Type>)> _superInterfaceTemplates =
      Map.of(_coreSuperInterfaceTemplates);

  void addSuperInterfaces(
      String className, List<Type> Function(List<Type>) template) {
    _superInterfaceTemplates[className] = template;
  }

  void addTypeVariable(String name, {String? bound}) {
    _typeVarBounds[name] = Type(bound ?? 'Object?');
  }

  Type factor(Type t, Type s) {
    // If T <: S then Never
    if (isSubtype(t, s)) return Type('Never');

    // Else if T is R? and Null <: S then factor(R, S)
    if (t is QuestionType && isSubtype(_nullType, s)) {
      return factor(t.innerType, s);
    }

    // Else if T is R? then factor(R, S)?
    if (t is QuestionType) return QuestionType(factor(t.innerType, s));

    // Else if T is R* and Null <: S then factor(R, S)
    if (t is StarType && isSubtype(_nullType, s)) return factor(t.innerType, s);

    // Else if T is R* then factor(R, S)*
    if (t is StarType) return StarType(factor(t.innerType, s));

    // Else if T is FutureOr<R> and Future<R> <: S then factor(R, S)
    if (t is PrimaryType && t.args.length == 1 && t.name == 'FutureOr') {
      var r = t.args[0];
      if (isSubtype(PrimaryType('Future', args: [r]), s)) return factor(r, s);
    }

    // Else if T is FutureOr<R> and R <: S then factor(Future<R>, S)
    if (t is PrimaryType && t.args.length == 1 && t.name == 'FutureOr') {
      var r = t.args[0];
      if (isSubtype(r, s)) return factor(PrimaryType('Future', args: [r]), s);
    }

    // Else T
    return t;
  }

  bool isSubtype(Type t0, Type t1) {
    // Reflexivity: if T0 and T1 are the same type then T0 <: T1
    //
    // - Note that this check is necessary as the base case for primitive types,
    //   and type variables but not for composite types.  We only check it for
    //   types with a single name and no type arguments (this covers both
    //   primitive types and type variables).
    if (t0 is PrimaryType &&
        t0.args.isEmpty &&
        t1 is PrimaryType &&
        t1.args.isEmpty &&
        t0.name == t1.name) {
      return true;
    }

    // Unknown types (note: this is not in the spec, but necessary because there
    // are circumstances where we do subtype tests between types and type
    // schemas): if T0 or T1 is the unknown type then T0 <: T1.
    if (t0 is UnknownType || t1 is UnknownType) return true;

    // Right Top: if T1 is a top type (i.e. dynamic, or void, or Object?) then
    // T0 <: T1
    if (_isTop(t1)) return true;

    // Left Top: if T0 is dynamic or void then T0 <: T1 if Object? <: T1
    if (t0 is PrimaryType &&
        t0.args.isEmpty &&
        (t0.name == 'dynamic' || t0.name == 'void')) {
      return isSubtype(_objectQuestionType, t1);
    }

    // Left Bottom: if T0 is Never then T0 <: T1
    if (t0 is PrimaryType && t0.args.isEmpty && t0.name == 'Never') return true;

    // Right Object: if T1 is Object then:
    if (t1 is PrimaryType && t1.args.isEmpty && t1.name == 'Object') {
      // - if T0 is an unpromoted type variable with bound B then T0 <: T1 iff
      //   B <: Object
      if (t0 is PrimaryType && _isTypeVar(t0)) {
        return isSubtype(_typeVarBound(t0), _objectType);
      }

      // - if T0 is a promoted type variable X & S then T0 <: T1 iff S <: Object
      if (t0 is PromotedTypeVariableType) {
        return isSubtype(t0.promotion, _objectType);
      }

      // - if T0 is FutureOr<S> for some S, then T0 <: T1 iff S <: Object.
      if (t0 is PrimaryType && t0.args.length == 1 && t0.name == 'FutureOr') {
        return isSubtype(t0.args[0], _objectType);
      }

      // - if T0 is S* for any S, then T0 <: T1 iff S <: T1
      if (t0 is StarType) return isSubtype(t0.innerType, t1);

      // - if T0 is Null, dynamic, void, or S? for any S, then the subtyping
      //   does not hold (per above, the result of the subtyping query is
      //   false).
      if (t0 is PrimaryType &&
              t0.args.isEmpty &&
              (t0.name == 'Null' ||
                  t0.name == 'dynamic' ||
                  t0.name == 'void') ||
          t0 is QuestionType) {
        return false;
      }

      // - Otherwise T0 <: T1 is true.
      return true;
    }

    // Left Null: if T0 is Null then:
    if (t0 is PrimaryType && t0.args.isEmpty && t0.name == 'Null') {
      // - if T1 is a type variable (promoted or not) the query is false
      if (_isTypeVar(t1)) return false;

      // - If T1 is FutureOr<S> for some S, then the query is true iff
      //   Null <: S.
      if (t1 is PrimaryType && t1.args.length == 1 && t1.name == 'FutureOr') {
        return isSubtype(_nullType, t0.args[0]);
      }

      // - If T1 is Null, S? or S* for some S, then the query is true.
      if (t1 is PrimaryType && t1.args.isEmpty && t1.name == 'Null' ||
          t1 is QuestionType ||
          t1 is StarType) {
        return true;
      }

      // - Otherwise, the query is false
      return false;
    }

    // Left Legacy: if T0 is S0* then:
    if (t0 is StarType) {
      // - T0 <: T1 iff S0 <: T1.
      return isSubtype(t0.innerType, t1);
    }

    // Right Legacy: if T1 is S1* then:
    if (t1 is StarType) {
      // - T0 <: T1 iff T0 <: S1?.
      return isSubtype(t0, QuestionType(t1.innerType));
    }

    // Left FutureOr: if T0 is FutureOr<S0> then:
    if (t0 is PrimaryType && t0.args.length == 1 && t0.name == 'FutureOr') {
      var s0 = t0.args[0];

      // - T0 <: T1 iff Future<S0> <: T1 and S0 <: T1
      return isSubtype(PrimaryType('Future', args: [s0]), t1) &&
          isSubtype(s0, t1);
    }

    // Left Nullable: if T0 is S0? then:
    if (t0 is QuestionType) {
      // - T0 <: T1 iff S0 <: T1 and Null <: T1
      return isSubtype(t0.innerType, t1) && isSubtype(_nullType, t1);
    }

    // Type Variable Reflexivity 1: if T0 is a type variable X0 or a promoted
    // type variables X0 & S0 and T1 is X0 then:
    if (_isTypeVar(t0) &&
        t1 is PrimaryType &&
        t1.args.isEmpty &&
        _typeVarName(t0) == t1.name) {
      // - T0 <: T1
      return true;
    }

    // Type Variable Reflexivity 2: if T0 is a type variable X0 or a promoted
    // type variables X0 & S0 and T1 is X0 & S1 then:
    if (_isTypeVar(t0) &&
        t1 is PromotedTypeVariableType &&
        _typeVarName(t0) == _typeVarName(t1)) {
      // - T0 <: T1 iff T0 <: S1.
      return isSubtype(t0, t1.promotion);
    }

    // Right Promoted Variable: if T1 is a promoted type variable X1 & S1 then:
    if (t1 is PromotedTypeVariableType) {
      // - T0 <: T1 iff T0 <: X1 and T0 <: S1
      return isSubtype(t0, t1.innerType) && isSubtype(t0, t1.promotion);
    }

    // Right FutureOr: if T1 is FutureOr<S1> then:
    if (t1 is PrimaryType && t1.args.length == 1 && t1.name == 'FutureOr') {
      var s1 = t1.args[0];

      // - T0 <: T1 iff any of the following hold:
      return
          //   - either T0 <: Future<S1>
          isSubtype(t0, PrimaryType('Future', args: [s1])) ||
              //   - or T0 <: S1
              isSubtype(t0, s1) ||
              //   - or T0 is X0 and X0 has bound S0 and S0 <: T1
              t0 is PrimaryType &&
                  _isTypeVar(t0) &&
                  isSubtype(_typeVarBound(t0), t1) ||
              //   - or T0 is X0 & S0 and S0 <: T1
              t0 is PromotedTypeVariableType && isSubtype(t0.promotion, t1);
    }

    // Right Nullable: if T1 is S1? then:
    if (t1 is QuestionType) {
      var s1 = t1.innerType;

      // - T0 <: T1 iff any of the following hold:
      return
          //   - either T0 <: S1
          isSubtype(t0, s1) ||
              //   - or T0 <: Null
              isSubtype(t0, _nullType) ||
              //   - or T0 is X0 and X0 has bound S0 and S0 <: T1
              t0 is PrimaryType &&
                  _isTypeVar(t0) &&
                  isSubtype(_typeVarBound(t0), t1) ||
              //   - or T0 is X0 & S0 and S0 <: T1
              t0 is PromotedTypeVariableType && isSubtype(t0.promotion, t1);
    }

    // Left Promoted Variable: T0 is a promoted type variable X0 & S0
    if (t0 is PromotedTypeVariableType) {
      // - and S0 <: T1
      if (isSubtype(t0.promotion, t1)) return true;
    }

    // Left Type Variable Bound: T0 is a type variable X0 with bound B0
    if (t0 is PrimaryType && _isTypeVar(t0)) {
      // - and B0 <: T1
      if (isSubtype(_typeVarBound(t0), t1)) return true;
    }

    // Function Type/Function: T0 is a function type and T1 is Function
    if (t0 is FunctionType &&
        t1 is PrimaryType &&
        t1.args.isEmpty &&
        t1.name == 'Function') {
      return true;
    }

    // Record Type/Record: T0 is a record type and T1 is Record
    if (t0 is RecordType &&
        t1 is PrimaryType &&
        t1.args.isEmpty &&
        t1.name == 'Record') {
      return true;
    }

    bool isInterfaceCompositionalitySubtype() {
      // Interface Compositionality: T0 is an interface type C0<S0, ..., Sk> and
      // T1 is C0<U0, ..., Uk>
      if (t0 is! PrimaryType ||
          t1 is! PrimaryType ||
          t0.args.length != t1.args.length ||
          t0.name != t1.name) {
        return false;
      }
      // - and each Si <: Ui
      for (int i = 0; i < t0.args.length; i++) {
        if (!isSubtype(t0.args[i], t1.args[i])) {
          return false;
        }
      }
      return true;
    }

    if (isInterfaceCompositionalitySubtype()) return true;

    // Super-Interface: T0 is an interface type with super-interfaces S0,...Sn
    bool isSuperInterfaceSubtype() {
      if (t0 is! PrimaryType || _isTypeVar(t0)) return false;
      var superInterfaceTemplate = _superInterfaceTemplates[t0.name];
      if (superInterfaceTemplate == null) {
        assert(false, 'Superinterfaces for $t0 not known');
        return false;
      }
      var superInterfaces = superInterfaceTemplate(t0.args);

      // - and Si <: T1 for some i
      for (var superInterface in superInterfaces) {
        if (isSubtype(superInterface, t1)) return true;
      }
      return false;
    }

    if (isSuperInterfaceSubtype()) return true;

    bool isPositionalFunctionSubtype() {
      // Positional Function Types: T0 is U0 Function<X0 extends B00, ...,
      // Xk extends B0k>(V0 x0, ..., Vn xn, [Vn+1 xn+1, ..., Vm xm])
      if (t0 is! FunctionType) return false;
      var n = t0.positionalParameters.length;
      // (Note: we don't support optional parameters)
      var m = n;

      // - and T1 is U1 Function<Y0 extends B10, ..., Yk extends B1k>(S0 y0,
      //   ..., Sp yp, [Sp+1 yp+1, ..., Sq yq])
      if (t1 is! FunctionType) return false;
      var p = t1.positionalParameters.length;
      var q = p;

      // - and p >= n
      if (p < n) return false;

      // - and m >= q
      if (m < q) return false;

      // (Note: no substitution is needed in the code below; we don't support
      // type arguments on function types)

      // - and Si[Z0/Y0, ..., Zk/Yk] <: Vi[Z0/X0, ..., Zk/Xk] for i in 0...q
      for (int i = 0; i < q; i++) {
        if (!isSubtype(
            t1.positionalParameters[i], t0.positionalParameters[i])) {
          return false;
        }
      }

      // - and U0[Z0/X0, ..., Zk/Xk] <: U1[Z0/Y0, ..., Zk/Yk]
      if (!isSubtype(t0.returnType, t1.returnType)) return false;

      // - and B0i[Z0/X0, ..., Zk/Xk] === B1i[Z0/Y0, ..., Zk/Yk] for i in 0...k
      // - where the Zi are fresh type variables with bounds B0i[Z0/X0, ...,
      //   Zk/Xk]
      // (No check needed here since we don't support type arguments on function
      // types)
      return true;
    }

    if (isPositionalFunctionSubtype()) return true;

    bool isNamedFunctionSubtype() {
      // Named Function Types: T0 is U0 Function<X0 extends B00, ..., Xk extends
      // B0k>(V0 x0, ..., Vn xn, {r0n+1 Vn+1 xn+1, ..., r0m Vm xm}) where r0j is
      // empty or required for j in n+1...m
      //
      // - and T1 is U1 Function<Y0 extends B10, ..., Yk extends B1k>(S0 y0,
      //   ..., Sn yn, {r1n+1 Sn+1 yn+1, ..., r1q Sq yq}) where r1j is empty or
      //   required for j in n+1...q
      // - and {yn+1, ... , yq} subsetof {xn+1, ... , xm}
      // - and Si[Z0/Y0, ..., Zk/Yk] <: Vi[Z0/X0, ..., Zk/Xk] for i in 0...n
      // - and Si[Z0/Y0, ..., Zk/Yk] <: Tj[Z0/X0, ..., Zk/Xk] for i in n+1...q,
      //   yj = xi
      // - and for each j such that r0j is required, then there exists an i in
      //   n+1...q such that xj = yi, and r1i is required
      // - and U0[Z0/X0, ..., Zk/Xk] <: U1[Z0/Y0, ..., Zk/Yk]
      // - and B0i[Z0/X0, ..., Zk/Xk] === B1i[Z0/Y0, ..., Zk/Yk] for i in 0...k
      // - where the Zi are fresh type variables with bounds B0i[Z0/X0, ...,
      //   Zk/Xk]

      // Note: nothing to do here; we don't support named arguments on function
      // types.
      return false;
    }

    if (isNamedFunctionSubtype()) return true;

    // Record Types: T0 is (V0, ..., Vn, {Vn+1 dn+1, ..., Vm dm})
    //
    // - and T1 is (S0, ..., Sn, {Sn+1 dn+1, ..., Sm dm})
    // - and Vi <: Si for i in 0...m
    bool isRecordSubtype() {
      if (t0 is! RecordType || t1 is! RecordType) return false;
      if (t0.positional.length != t1.positional.length) return false;
      for (int i = 0; i < t0.positional.length; i++) {
        if (!isSubtype(t0.positional[i], t1.positional[i])) return false;
      }
      if (t0.named.length != t1.named.length) return false;
      for (var entry in t0.named.entries) {
        var vi = entry.value;
        var si = t1.named[entry.key];
        if (si == null) return false;
        if (!isSubtype(vi, si)) return false;
      }
      return true;
    }

    if (isRecordSubtype()) return true;

    return false;
  }

  bool _isTop(Type t) {
    if (t is PrimaryType) {
      return t.args.isEmpty && (t.name == 'dynamic' || t.name == 'void');
    } else if (t is QuestionType) {
      var innerType = t.innerType;
      return innerType is PrimaryType &&
          innerType.args.isEmpty &&
          innerType.name == 'Object';
    }
    return false;
  }

  bool _isTypeVar(Type t) {
    if (t is PromotedTypeVariableType) {
      assert(_isTypeVar(t.innerType));
      return true;
    } else if (t is PrimaryType && t.args.isEmpty) {
      return _typeVarBounds.containsKey(t.name);
    } else {
      return false;
    }
  }

  Type _typeVarBound(Type t) => _typeVarBounds[_typeVarName(t)]!;

  String _typeVarName(Type t) {
    assert(_isTypeVar(t));
    if (t is PromotedTypeVariableType) {
      return _typeVarName(t.innerType);
    } else {
      return (t as PrimaryType).name;
    }
  }
}

/// Representation of the unknown type suitable for unit testing of code in the
/// `_fe_analyzer_shared` package.
class UnknownType extends Type {
  const UnknownType() : super._();

  @override
  Type? recursivelyDemote({required bool covariant}) => null;

  @override
  String _toString({required bool allowSuffixes}) => '?';
}

class _TypeParser {
  static final _typeTokenizationRegexp =
      RegExp(_identifierPattern + r'|\(|\)|<|>|,|\?|\*|&|{|}');

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
    throw ParseError(
        'Error parsing type `$_typeStr` at token $_currentToken: $message');
  }

  Map<String, Type> _parseRecordTypeNamedFields() {
    assert(_currentToken == '{');
    _next();
    var namedTypes = <String, Type>{};
    while (_currentToken != '}') {
      var type = _parseType();
      var name = _currentToken;
      if (_identifierRegexp.matchAsPrefix(name) == null) {
        _parseFailure('Expected an identifier');
      }
      namedTypes[name] = type;
      _next();
      if (_currentToken == ',') {
        _next();
        continue;
      }
      if (_currentToken == '}') {
        break;
      }
      _parseFailure('Expected `}` or `,`');
    }
    if (namedTypes.isEmpty) {
      _parseFailure('Must have at least one named type between {}');
    }
    _next();
    return namedTypes;
  }

  Type _parseRecordTypeRest(List<Type> positionalTypes) {
    Map<String, Type>? namedTypes;
    while (_currentToken != ')') {
      if (_currentToken == '{') {
        namedTypes = _parseRecordTypeNamedFields();
        if (_currentToken != ')') {
          _parseFailure('Expected `)`');
        }
        break;
      }
      positionalTypes.add(_parseType());
      if (_currentToken == ',') {
        _next();
        continue;
      }
      if (_currentToken == ')') {
        break;
      }
      _parseFailure('Expected `)` or `,`');
    }
    _next();
    return RecordType(
        positional: positionalTypes, named: namedTypes ?? const {});
  }

  Type? _parseSuffix(Type type) {
    if (_currentToken == '?') {
      _next();
      return QuestionType(type);
    } else if (_currentToken == '*') {
      _next();
      return StarType(type);
    } else if (_currentToken == '&') {
      _next();
      var promotion = _parseUnsuffixedType();
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
      return FunctionType(type, parameterTypes);
    } else {
      return null;
    }
  }

  Type _parseType() {
    // We currently accept the following grammar for types:
    //   type := unsuffixedType nullability suffix*
    //   unsuffixedType := identifier typeArgs?
    //                   | `?`
    //                   | `(` type `)`
    //                   | `(` recordTypeFields `,` recordTypeNamedFields `)`
    //                   | `(` recordTypeFields `,`? `)`
    //                   | `(` recordTypeNamedFields? `)`
    //   recordTypeFields := type (`,` type)*
    //   recordTypeNamedFields := `{` recordTypeNamedField
    //                            (`,` recordTypeNamedField)* `,`? `}`
    //   recordTypeNamedField := type identifier
    //   typeArgs := `<` type (`,` type)* `>`
    //   nullability := (`?` | `*`)?
    //   suffix := `Function` `(` type (`,` type)* `)`
    //           | `?`
    //           | `*`
    //           | `&` unsuffixedType
    // TODO(paulberry): support more syntax if needed
    var result = _parseUnsuffixedType();
    while (true) {
      var newResult = _parseSuffix(result);
      if (newResult == null) break;
      result = newResult;
    }
    return result;
  }

  Type _parseUnsuffixedType() {
    if (_currentToken == '?') {
      _next();
      return const UnknownType();
    }
    if (_currentToken == '(') {
      _next();
      if (_currentToken == ')' || _currentToken == '{') {
        return _parseRecordTypeRest([]);
      }
      var type = _parseType();
      if (_currentToken == ',') {
        _next();
        return _parseRecordTypeRest([type]);
      }
      if (_currentToken != ')') {
        _parseFailure('Expected `)` or `,`');
      }
      _next();
      return type;
    }
    var typeName = _currentToken;
    if (_identifierRegexp.matchAsPrefix(typeName) == null) {
      _parseFailure('Expected an identifier, `?`, or `(`');
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
    return PrimaryType(typeName, args: typeArgs);
  }

  static Type parse(String typeStr) {
    var parser = _TypeParser._(typeStr, _tokenizeTypeStr(typeStr));
    var result = parser._parseType();
    if (parser._currentToken != '<END>') {
      throw ParseError('Extra tokens after parsing type `$typeStr`: '
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
        throw ParseError(
            'Unrecognized character(s) in type `$typeStr`: $extraChars');
      }
      result.add(typeStr.substring(match.start, match.end));
      lastMatchEnd = match.end;
    }
    var extraChars = typeStr.substring(lastMatchEnd).trim();
    if (extraChars.isNotEmpty) {
      throw ParseError(
          'Unrecognized character(s) in type `$typeStr`: $extraChars');
    }
    result.add('<END>');
    return result;
  }
}

extension on List<Type> {
  /// Calls [Type.recursivelyDemote] to translate every list member into a type
  /// that doesn't involve any type promotion.  If no type would be changed by
  /// this operation, returns `null`.
  List<Type>? recursivelyDemote({required bool covariant}) {
    List<Type>? newList;
    for (int i = 0; i < length; i++) {
      Type type = this[i];
      Type? newType = type.recursivelyDemote(covariant: covariant);
      if (newList == null) {
        if (newType == null) continue;
        newList = sublist(0, i);
      }
      newList.add(newType ?? type);
    }
    return newList;
  }
}
