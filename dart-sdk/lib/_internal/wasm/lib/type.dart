// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'core_patch.dart';

// Representation of runtime types. Code in this file should avoid using `is` or
// `as` entirely to avoid a dependency on any inline type checks.

// Helper for type literals used for all singleton types. By using actual type
// literals and letting those through the compiler, rather than calling the
// constructors of the corresponding representation classes, we ensure that they
// are properly canonicalized by the constant instantiator.
@pragma("wasm:prefer-inline")
_Type _literal<T>() => unsafeCast(T);

extension on WasmArray<_Type> {
  @pragma("wasm:prefer-inline")
  bool get isEmpty => length == 0;

  @pragma("wasm:prefer-inline")
  bool get isNotEmpty => length != 0;

  @pragma("wasm:prefer-inline")
  WasmArray<_Type> map(_Type Function(_Type) fun) {
    if (isEmpty) return const WasmArray<_Type>.literal(<_Type>[]);
    final mapped = WasmArray<_Type>.filled(length, fun(this[0]));
    for (int i = 1; i < length; ++i) {
      mapped[i] = fun(this[i]);
    }
    return mapped;
  }
}

extension on WasmArray<_NamedParameter> {
  @pragma("wasm:prefer-inline")
  bool get isEmpty => length == 0;

  @pragma("wasm:prefer-inline")
  bool get isNotEmpty => length != 0;

  @pragma("wasm:prefer-inline")
  WasmArray<_NamedParameter> map(
      _NamedParameter Function(_NamedParameter) fun) {
    if (isEmpty)
      return const WasmArray<_NamedParameter>.literal(<_NamedParameter>[]);
    final mapped = WasmArray<_NamedParameter>.filled(length, fun(this[0]));
    for (int i = 1; i < length; ++i) {
      mapped[i] = fun(this[i]);
    }
    return mapped;
  }
}

extension on WasmArray<String> {
  @pragma("wasm:prefer-inline")
  bool get isNotEmpty => length != 0;
}

// TODO(joshualitt): We can cache the result of [_FutureOrType.asFuture].
abstract class _Type implements Type {
  final bool isDeclaredNullable;

  const _Type(this.isDeclaredNullable);

  @pragma("wasm:prefer-inline")
  bool _testID(int value) => ClassID.getID(this) == value;

  bool get isBottom => _testID(ClassID.cidBottomType);
  bool get isTop => _testID(ClassID.cidTopType);
  bool get isFutureOr => _testID(ClassID.cidFutureOrType);
  bool get isInterface => _testID(ClassID.cidInterfaceType);
  bool get isInterfaceTypeParameterType =>
      _testID(ClassID.cidInterfaceTypeParameterType);
  bool get isFunctionTypeParameterType =>
      _testID(ClassID.cidFunctionTypeParameterType);
  bool get isAbstractFunction => _testID(ClassID.cidAbstractFunctionType);
  bool get isFunction => _testID(ClassID.cidFunctionType);
  bool get isAbstractRecord => _testID(ClassID.cidAbstractRecordType);
  bool get isRecord => _testID(ClassID.cidRecordType);

  @pragma("wasm:prefer-inline")
  T as<T>() => unsafeCast<T>(this);

  @pragma("wasm:prefer-inline")
  _Type get asNullable => isDeclaredNullable ? this : _asNullable;

  _Type get _asNullable;

  /// Check whether the given object is of this type.
  bool _checkInstance(Object o);
}

@pragma("wasm:entry-point")
class _BottomType extends _Type {
  // To ensure that the `Null` and `Never` types are singleton runtime type
  // objects, we only allocate these objects via the constant instantiator.
  external const _BottomType();

  @override
  _Type get _asNullable => _literal<Null>();

  @override
  bool _checkInstance(Object o) => false;

  @override
  String toString() => isDeclaredNullable ? 'Null' : 'Never';
}

@pragma("wasm:entry-point")
class _TopType extends _Type {
  final int _kind;

  // Values for the `_kind` field. Must match the definitions in `TopTypeKind`.
  static const int _objectKind = 0;
  static const int _dynamicKind = 1;
  static const int _voidKind = 2;

  // To ensure that the `Object`, `Object?`, `dynamic` and `void` types are
  // singleton runtime type objects, we only allocate these objects via the
  // constant instantiator.
  external const _TopType();

  // Only called if Object
  @override
  _Type get _asNullable => _literal<Object?>();

  @override
  bool _checkInstance(Object o) => true;

  @override
  String toString() {
    switch (_kind) {
      case _objectKind:
        return isDeclaredNullable ? 'Object?' : 'Object';
      case _dynamicKind:
        return 'dynamic';
      case _voidKind:
        return 'void';
      default:
        throw 'Invalid top type kind';
    }
  }
}

/// Reference to a type parameter of an interface type.
///
/// This type is only used in the representation of the supertype type parameter
/// mapping and never occurs in runtime types.
@pragma("wasm:entry-point")
class _InterfaceTypeParameterType extends _Type {
  final int environmentIndex;

  @pragma("wasm:entry-point")
  const _InterfaceTypeParameterType(
      super.isDeclaredNullable, this.environmentIndex);

  @override
  _Type get _asNullable =>
      throw 'Type parameter should have been substituted already.';

  @override
  bool _checkInstance(Object o) =>
      throw 'Type parameter should have been substituted already.';

  @override
  String toString() => 'T$environmentIndex';
}

/// Reference to a type parameter of a function type.
///
/// This type only occurs inside generic function types.
@pragma("wasm:entry-point")
class _FunctionTypeParameterType extends _Type {
  final int index;

  @pragma("wasm:entry-point")
  const _FunctionTypeParameterType(super.isDeclaredNullable, this.index);

  @override
  _Type get _asNullable => _FunctionTypeParameterType(true, index);

  @override
  bool _checkInstance(Object o) =>
      throw 'Instance check should not reach function type parameter.';

  @override
  bool operator ==(Object o) {
    if (ClassID.getID(o) != ClassID.cidFunctionTypeParameterType) return false;
    _FunctionTypeParameterType other =
        unsafeCast<_FunctionTypeParameterType>(o);
    // References to different type parameters can have the same index and thus
    // sometimes compare equal even if they are not. However, this can only
    // happen if the containing types are different in other places, in which
    // case the comparison as a whole correctly compares unequal.
    return index == other.index;
  }

  @override
  int get hashCode {
    int hash = mix64(ClassID.cidFunctionTypeParameterType);
    hash = mix64(hash ^ (isDeclaredNullable ? 1 : 0));
    return mix64(hash ^ index.hashCode);
  }

  @override
  String toString() => 'X$index';
}

@pragma("wasm:entry-point")
class _FutureOrType extends _Type {
  final _Type typeArgument;

  @pragma("wasm:entry-point")
  const _FutureOrType(super.isDeclaredNullable, this.typeArgument);

  _InterfaceType get asFuture => _InterfaceType(ClassID.cidFuture,
      isDeclaredNullable, WasmArray<_Type>.literal([typeArgument]));

  @override
  _Type get _asNullable =>
      _TypeUniverse.createNormalizedFutureOrType(true, typeArgument);

  @override
  bool _checkInstance(Object o) {
    return typeArgument._checkInstance(o) || asFuture._checkInstance(o);
  }

  @override
  bool operator ==(Object o) {
    if (ClassID.getID(o) != ClassID.cidFutureOrType) return false;
    _FutureOrType other = unsafeCast<_FutureOrType>(o);
    if (isDeclaredNullable != other.isDeclaredNullable) return false;
    return typeArgument == other.typeArgument;
  }

  @override
  int get hashCode {
    int hash = mix64(ClassID.cidFutureOrType);
    hash = mix64(hash ^ (isDeclaredNullable ? 1 : 0));
    return mix64(hash ^ typeArgument.hashCode);
  }

  @override
  String toString() {
    StringBuffer s = StringBuffer();
    s.write("FutureOr");
    s.write("<");
    s.write(typeArgument);
    s.write(">");
    // Omit the question mark if the type argument is nullable in order to match
    // the specified normalization rules for `FutureOr` types.
    if (isDeclaredNullable && !typeArgument.isDeclaredNullable) s.write("?");
    return s.toString();
  }
}

@pragma("wasm:entry-point")
class _InterfaceType extends _Type {
  final int classId;
  final WasmArray<_Type> typeArguments;

  @pragma("wasm:entry-point")
  const _InterfaceType(this.classId, super.isDeclaredNullable,
      [this.typeArguments = const WasmArray<_Type>.literal([])]);

  @override
  _Type get _asNullable => _InterfaceType(classId, true, typeArguments);

  @override
  bool _checkInstance(Object o) {
    // We don't need to check whether the object is of interface type, since
    // non-interface class IDs ([Object], closures, records) will be rejected by
    // the interface type subtype check.
    if (typeArguments.length == 0) {
      return _TypeUniverse.isObjectInterfaceSubtype0(o, classId);
    }
    if (typeArguments.length == 1) {
      return _TypeUniverse.isObjectInterfaceSubtype1(
          o, classId, typeArguments[0]);
    }
    if (typeArguments.length == 2) {
      return _TypeUniverse.isObjectInterfaceSubtype2(
          o, classId, typeArguments[0], typeArguments[1]);
    }
    return _TypeUniverse.isObjectInterfaceSubtypeN(o, classId, typeArguments);
  }

  @override
  bool operator ==(Object o) {
    if (ClassID.getID(o) != ClassID.cidInterfaceType) return false;
    _InterfaceType other = unsafeCast<_InterfaceType>(o);
    if (classId != other.classId) return false;
    if (isDeclaredNullable != other.isDeclaredNullable) return false;
    assert(typeArguments.length == other.typeArguments.length);
    for (int i = 0; i < typeArguments.length; i++) {
      if (typeArguments[i] != other.typeArguments[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    int hash = mix64(ClassID.cidInterfaceType);
    hash = mix64(hash ^ classId);
    hash = mix64(hash ^ (isDeclaredNullable ? 1 : 0));
    for (int i = 0; i < typeArguments.length; i++) {
      hash = mix64(hash ^ typeArguments[i].hashCode);
    }
    return hash;
  }

  @override
  String toString() {
    StringBuffer s = StringBuffer();
    s.write(_typeNames?[classId] ?? 'minified:Class${classId}');
    if (typeArguments.isNotEmpty) {
      s.write("<");
      for (int i = 0; i < typeArguments.length; i++) {
        if (i > 0) s.write(", ");
        s.write(typeArguments[i]);
      }
      s.write(">");
    }
    if (isDeclaredNullable) s.write("?");
    return s.toString();
  }
}

class _NamedParameter {
  final String name;
  final _Type type;
  final bool isRequired;

  @pragma("wasm:entry-point")
  const _NamedParameter(this.name, this.type, this.isRequired);

  @override
  bool operator ==(Object o) {
    if (ClassID.getID(o) != ClassID.cidNamedParameter) return false;
    _NamedParameter other = unsafeCast<_NamedParameter>(o);
    return this.name == other.name &&
        this.type == other.type &&
        isRequired == other.isRequired;
  }

  @override
  int get hashCode {
    int hash = mix64(ClassID.cidNamedParameter);
    hash = mix64(hash ^ name.hashCode);
    hash = mix64(hash ^ type.hashCode);
    return mix64(hash ^ (isRequired ? 1 : 0));
  }

  @override
  String toString() {
    StringBuffer s = StringBuffer();
    if (isRequired) s.write('required ');
    s.write(type);
    s.write(' ');
    s.write(name);
    return s.toString();
  }
}

@pragma("wasm:entry-point")
class _AbstractFunctionType extends _Type {
  // To ensure that the `Function` and `Function?` types are singleton runtime
  // type objects, we only allocate these objects via the constant instantiator.
  external const _AbstractFunctionType();

  @override
  _Type get _asNullable => _literal<Function?>();

  @override
  bool _checkInstance(Object o) => ClassID.getID(o) == ClassID.cid_Closure;

  @override
  String toString() {
    return isDeclaredNullable ? 'Function?' : 'Function';
  }
}

@pragma("wasm:entry-point")
class _FunctionType extends _Type {
  // TODO(askesc): The [typeParameterOffset] is 0 except in the rare case where
  // the function type contains a nested generic function type that contains a
  // reference to one of this type's type parameters. It seems wasteful to have
  // an `i64` in every function type object for this. Consider alternative
  // representations that don't have this overhead in the common case.
  final int typeParameterOffset;
  final WasmArray<_Type> typeParameterBounds;
  @pragma("wasm:entry-point")
  final WasmArray<_Type> typeParameterDefaults;
  final _Type returnType;
  final WasmArray<_Type> positionalParameters;
  final int requiredParameterCount;
  final WasmArray<_NamedParameter> namedParameters;

  @pragma("wasm:entry-point")
  const _FunctionType(
      this.typeParameterOffset,
      this.typeParameterBounds,
      this.typeParameterDefaults,
      this.returnType,
      this.positionalParameters,
      this.requiredParameterCount,
      this.namedParameters,
      super.isDeclaredNullable);

  @override
  _Type get _asNullable => _FunctionType(
      typeParameterOffset,
      typeParameterBounds,
      typeParameterDefaults,
      returnType,
      positionalParameters,
      requiredParameterCount,
      namedParameters,
      true);

  @override
  bool _checkInstance(Object o) {
    if (ClassID.getID(o) != ClassID.cid_Closure) return false;
    return _TypeUniverse.isFunctionSubtype(
        _Closure._getClosureRuntimeType(unsafeCast(o)), null, this, null);
  }

  bool operator ==(Object o) {
    if (ClassID.getID(o) != ClassID.cidFunctionType) return false;
    _FunctionType other = unsafeCast<_FunctionType>(o);
    if (isDeclaredNullable != other.isDeclaredNullable) return false;
    if (typeParameterBounds.length != other.typeParameterBounds.length) {
      return false;
    }
    if (returnType != other.returnType) return false;
    if (positionalParameters.length != other.positionalParameters.length) {
      return false;
    }
    if (requiredParameterCount != other.requiredParameterCount) return false;
    if (namedParameters.length != other.namedParameters.length) return false;
    for (int i = 0; i < typeParameterBounds.length; i++) {
      if (typeParameterBounds[i] != other.typeParameterBounds[i]) {
        return false;
      }
    }
    for (int i = 0; i < positionalParameters.length; i++) {
      if (positionalParameters[i] != other.positionalParameters[i]) {
        return false;
      }
    }
    for (int i = 0; i < namedParameters.length; i++) {
      if (namedParameters[i] != other.namedParameters[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode {
    int hash = mix64(ClassID.cidFunctionType);
    for (int i = 0; i < typeParameterBounds.length; i++) {
      hash = mix64(hash ^ typeParameterBounds[i].hashCode);
    }
    hash = mix64(hash ^ (isDeclaredNullable ? 1 : 0));
    hash = mix64(hash ^ returnType.hashCode);
    for (int i = 0; i < positionalParameters.length; i++) {
      hash = mix64(hash ^ positionalParameters[i].hashCode);
    }
    hash = mix64(hash ^ requiredParameterCount);
    for (int i = 0; i < namedParameters.length; i++) {
      hash = mix64(hash ^ namedParameters[i].hashCode);
    }
    return hash;
  }

  @override
  String toString() {
    StringBuffer s = StringBuffer();
    if (typeParameterBounds.isNotEmpty) {
      s.write("<");
      for (int i = 0; i < typeParameterBounds.length; i++) {
        if (i > 0) s.write(", ");
        s.write("X${typeParameterOffset + i}");
        final bound = typeParameterBounds[i];
        if (!(bound.isTop && bound.isDeclaredNullable)) {
          s.write(" extends ");
          s.write(bound);
        }
      }
      s.write(">");
    }
    s.write("(");
    for (int i = 0; i < positionalParameters.length; i++) {
      if (i > 0) s.write(", ");
      if (i == requiredParameterCount) s.write("[");
      s.write(positionalParameters[i]);
    }
    if (requiredParameterCount < positionalParameters.length) s.write("]");
    if (namedParameters.isNotEmpty) {
      if (positionalParameters.isNotEmpty) s.write(", ");
      s.write("{");
      for (int i = 0; i < namedParameters.length; i++) {
        if (i > 0) s.write(", ");
        s.write(namedParameters[i]);
      }
      s.write("}");
    }
    s.write(")");
    s.write(" => ");
    s.write(returnType);
    return s.toString();
  }
}

@pragma("wasm:entry-point")
class _AbstractRecordType extends _Type {
  // To ensure that the `Record` and `Record?` types are singleton runtime type
  // objects, we only allocate these objects via the constant instantiator.
  external const factory _AbstractRecordType();

  @override
  _Type get _asNullable => _literal<Record?>();

  @override
  bool _checkInstance(Object o) {
    return _isRecordClassId(ClassID.getID(o));
  }

  @override
  String toString() {
    return isDeclaredNullable ? 'Record?' : 'Record';
  }
}

@pragma("wasm:entry-point")
class _RecordType extends _Type {
  final WasmArray<String> names;
  final WasmArray<_Type> fieldTypes;

  @pragma("wasm:entry-point")
  _RecordType(this.names, this.fieldTypes, super.isDeclaredNullable);

  @override
  _Type get _asNullable => _RecordType(names, fieldTypes, true);

  @override
  bool _checkInstance(Object o) {
    if (!_isRecordClassId(ClassID.getID(o))) return false;
    return unsafeCast<Record>(o)._checkRecordType(fieldTypes, names);
  }

  @override
  String toString() {
    StringBuffer buffer = StringBuffer('(');

    final int numPositionals = fieldTypes.length - names.length;
    final int numNames = names.length;

    for (int i = 0; i < numPositionals; i += 1) {
      buffer.write(fieldTypes[i]);
      if (i != fieldTypes.length - 1) {
        buffer.write(', ');
      }
    }

    if (names.isNotEmpty) {
      buffer.write('{');
      for (int i = 0; i < numNames; i += 1) {
        final String fieldName = names[i];
        final _Type fieldType = fieldTypes[numPositionals + i];
        buffer.write(fieldType);
        buffer.write(' ');
        buffer.write(fieldName);
        if (i != numNames - 1) {
          buffer.write(', ');
        }
      }
      buffer.write('}');
    }

    buffer.write(')');
    if (isDeclaredNullable) {
      buffer.write('?');
    }
    return buffer.toString();
  }

  @override
  bool operator ==(Object o) {
    if (ClassID.getID(o) != ClassID.cidRecordType) return false;
    _RecordType other = unsafeCast<_RecordType>(o);

    if (!_sameShape(other)) {
      return false;
    }

    for (int fieldIdx = 0; fieldIdx < fieldTypes.length; fieldIdx += 1) {
      if (fieldTypes[fieldIdx] != other.fieldTypes[fieldIdx]) {
        return false;
      }
    }

    return true;
  }

  bool _sameShape(_RecordType other) =>
      fieldTypes.length == other.fieldTypes.length &&
      // Name lists are constants and can be compared with `identical`.
      identical(names, other.names);
}

/// Rules that describe whether two classes are related in a hierarchy and if so
/// how to translate a subtype's class's type arguments to the type arguments of
/// a supertype's class.
///
/// The table has key for every class in the system. The value is an array of
/// `(superClassId1, ..., superClassIdN,
///   canonicalSubstitutionIndex1, ..., canonicalSubstitutionIndexN)`.
///
/// For example, let's assume we have these classes:
///
///   ```
///   class Sub<T> extends Foo<List<T>> {}
///   class Foo<T> implements Bar<int, T> {}
///   class Bar<T, H> {}
///   ```
///
/// The table will have an entry for every transitively extended/implemented
/// class (except `Object`).
///
/// ```
///   _typeRulesSupers = [
///     ...
///     @Sub.classId: [(Foo.classId, Bar.classId), (IDX-X, IDX-Y)]
///     ...
///   ]
/// ```
///
/// Where the `IDX-X` and `IDX-Y` are integer indices into the canonical
/// substitution table, which would look like this:
/// ```
///   _canonicalSubstitutionTable = [
///     ...
///     @IDX-X: [
///               _InterfaceType(List.classId, args: [_InterfaceTypeParameterType(index=0)])
///             ]
///     ...
///     @IDX-Y: [
///               _InterfaceType(int.classId args: []),
///               _InterfaceType(List.classId, args: [_InterfaceTypeParameterType(index=0)])
///             ]
///     ...
///   ]
/// ```
///
external WasmArray<WasmArray<WasmI32>> get _typeRulesSupers;

/// Canonical substitution table used to translate type arguments from one class
/// to a related other class.
///
/// See [_typeRulesSupers] for more information on how they are used.
external WasmArray<WasmArray<_Type>> get _canonicalSubstitutionTable;

/// The names of all classes (indexed by class id) or null (if `--minify` was
/// used)
external WasmArray<String>? get _typeNames;

/// The non-negative index into [_canonicalSubstitutionTable] that represents
/// that no substitution is needed.
external WasmI32 get _noSubstitutionIndex;

/// Type parameter environment used while comparing function types.
///
/// In the case of nested function types, the environment refers to the
/// innermost function type and has a reference to the enclosing function type
/// environment.
class _Environment {
  /// The environment of the enclosing function type, or `null` if this is the
  /// outermost function type.
  final _Environment? parent;

  /// The current function type.
  final _FunctionType type;

  /// The nesting depth of the current function type.
  final int depth;

  _Environment(this.parent, this.type)
      : depth = parent == null ? 0 : parent.depth + 1;

  /// Look up the bound of a function type parameter in the environment.
  _Type lookup(_FunctionTypeParameterType param) {
    return adjust(param).lookupAdjusted(param);
  }

  /// Adjust the environment to the one where the type parameter is declared.
  _Environment adjust(_FunctionTypeParameterType param) {
    // The `typeParameterOffset` of the function types and the `index` of the
    // function type parameters are assigned such that the function type to
    // which a type parameter belongs is the innermost function type enclosing
    // the type parameter type for which the index falls within the type
    // parameter index range of the function type.
    _Environment env = this;
    while (param.index - env.type.typeParameterOffset >=
        env.type.typeParameterBounds.length) {
      env = env.parent!;
    }
    return env;
  }

  /// Look up the bound of a type parameter in its adjusted environment.
  _Type lookupAdjusted(_FunctionTypeParameterType param) {
    return type.typeParameterBounds[param.index - type.typeParameterOffset];
  }
}

abstract class _TypeUniverse {
  static _Type substituteInterfaceTypeParameter(
      _InterfaceTypeParameterType typeParameter,
      WasmArray<_Type> substitutions) {
    // If the type parameter is non-nullable, or the substitution type is
    // nullable, then just return the substitution type. Otherwise, we return
    // [type] as nullable.
    // Note: This will throw if the required nullability is impossible to
    // generate.
    _Type substitution = substitutions[typeParameter.environmentIndex];
    if (typeParameter.isDeclaredNullable) return substitution.asNullable;
    return substitution;
  }

  static _Type substituteFunctionTypeParameter(
      _FunctionTypeParameterType typeParameter,
      WasmArray<_Type> substitutions,
      _FunctionType? rootFunction) {
    if (rootFunction != null &&
        typeParameter.index >= rootFunction.typeParameterOffset) {
      _Type substitution =
          substitutions[typeParameter.index - rootFunction.typeParameterOffset];
      if (typeParameter.isDeclaredNullable) return substitution.asNullable;
      return substitution;
    } else {
      return typeParameter;
    }
  }

  @pragma("wasm:entry-point")
  static _FunctionType substituteFunctionTypeArgument(
      _FunctionType functionType, WasmArray<_Type> substitutions) {
    return substituteTypeArgument(functionType, substitutions, functionType)
        .as<_FunctionType>();
  }

  /// Substitute the type parameters of an interface type or function type.
  ///
  /// For interface types, [rootFunction] is always `null`.
  ///
  /// For function types, [rootFunction] is the function whose type parameters
  /// are being substituted, or `null` when inside a nested function type that
  /// is guaranteed not to contain any type parameter types that are to be
  /// substituted.
  static _Type substituteTypeArgument(
      _Type type, WasmArray<_Type> substitutions, _FunctionType? rootFunction) {
    if (type.isBottom || type.isTop) {
      return type;
    } else if (type.isFutureOr) {
      return createNormalizedFutureOrType(
          type.isDeclaredNullable,
          substituteTypeArgument(type.as<_FutureOrType>().typeArgument,
              substitutions, rootFunction));
    } else if (type.isInterface) {
      final interfaceType = type.as<_InterfaceType>();
      final arguments = interfaceType.typeArguments;
      if (arguments.length == 0) return interfaceType;
      final newArguments =
          WasmArray<_Type>.filled(arguments.length, _literal<dynamic>());
      for (int i = 0; i < arguments.length; i++) {
        newArguments[i] =
            substituteTypeArgument(arguments[i], substitutions, rootFunction);
      }
      return _InterfaceType(interfaceType.classId,
          interfaceType.isDeclaredNullable, newArguments);
    } else if (type.isInterfaceTypeParameterType) {
      assert(rootFunction == null);
      return substituteInterfaceTypeParameter(
          type.as<_InterfaceTypeParameterType>(), substitutions);
    } else if (type.isRecord) {
      final recordType = type.as<_RecordType>();
      final fieldTypes = WasmArray<_Type>.filled(
          recordType.fieldTypes.length, _literal<dynamic>());
      for (int i = 0; i < recordType.fieldTypes.length; i++) {
        fieldTypes[i] = substituteTypeArgument(
            recordType.fieldTypes[i], substitutions, rootFunction);
      }
      return _RecordType(
          recordType.names, fieldTypes, recordType.isDeclaredNullable);
    } else if (type.isFunction) {
      _FunctionType functionType = type.as<_FunctionType>();
      bool isRoot = identical(type, rootFunction);
      if (!isRoot &&
          rootFunction != null &&
          functionType.typeParameterOffset +
                  functionType.typeParameterBounds.length >
              rootFunction.typeParameterOffset) {
        // The type parameter index range of this nested generic function type
        // overlaps that of the root function, which means it does not contain
        // any function type parameter types referring to the root function.
        // Pass `null` as the `rootFunction` to avoid mis-interpreting enclosed
        // type parameter types as referring to the root function.
        rootFunction = null;
      }

      final WasmArray<_Type> bounds;
      if (isRoot) {
        bounds = const WasmArray<_Type>.literal(<_Type>[]);
      } else {
        bounds = functionType.typeParameterBounds.map((_Type type) =>
            substituteTypeArgument(type, substitutions, rootFunction));
      }

      final WasmArray<_Type> defaults;
      if (isRoot) {
        defaults = const WasmArray<_Type>.literal(<_Type>[]);
      } else {
        defaults = functionType.typeParameterDefaults.map((_Type type) =>
            substituteTypeArgument(type, substitutions, rootFunction));
      }

      final WasmArray<_Type> positionals = functionType.positionalParameters
          .map((_Type type) =>
              substituteTypeArgument(type, substitutions, rootFunction));

      final WasmArray<_NamedParameter> named = functionType.namedParameters.map(
          (_NamedParameter named) => _NamedParameter(
              named.name,
              substituteTypeArgument(named.type, substitutions, rootFunction),
              named.isRequired));

      final returnType = substituteTypeArgument(
          functionType.returnType, substitutions, rootFunction);

      return _FunctionType(
          functionType.typeParameterOffset,
          bounds,
          defaults,
          returnType,
          positionals,
          functionType.requiredParameterCount,
          named,
          functionType.isDeclaredNullable);
    } else if (type.isFunctionTypeParameterType) {
      return substituteFunctionTypeParameter(
          type.as<_FunctionTypeParameterType>(), substitutions, rootFunction);
    } else {
      throw 'Type argument substitution not supported for $type';
    }
  }

  static _Type createNormalizedFutureOrType(
      bool isDeclaredNullable, _Type typeArgument) {
    if (typeArgument.isTop) {
      return isDeclaredNullable ? typeArgument.asNullable : typeArgument;
    } else if (typeArgument.isBottom) {
      return _InterfaceType(
          ClassID.cidFuture,
          isDeclaredNullable || typeArgument.isDeclaredNullable,
          WasmArray<_Type>.literal([typeArgument]));
    }

    // Note: We diverge from the spec here and normalize the type to nullable if
    // its type argument is nullable, since this simplifies subtype checking.
    // We compensate for this difference when converting the type to a string,
    // making the discrepancy invisible to the user.
    bool declaredNullability =
        isDeclaredNullable || typeArgument.isDeclaredNullable;
    return _FutureOrType(declaredNullability, typeArgument);
  }

  static bool isInterfaceSubtype(_InterfaceType s, _Environment? sEnv,
      _InterfaceType t, _Environment? tEnv) {
    final sId = s.classId;
    final tId = t.classId;

    // Return early if [sId] isn't a direct/indirect subclass of [tId].
    final int substitutionIndex =
        _checkSubclassRelationship(sId, tId).toIntSigned();
    if (substitutionIndex == -1) return false;

    // Return early if we don't have to check type arguments as the destination
    // type is non-generic.
    final tTypeArguments = t.typeArguments;
    if (tTypeArguments.isEmpty) return true;

    final sTypeArguments = s.typeArguments;
    return areTypeArgumentsSubtypes(
        sTypeArguments, sEnv, tTypeArguments, tEnv, substitutionIndex);
  }

  static bool isObjectInterfaceSubtype0(Object o, int tId) {
    final int sId = ClassID.getID(o);
    return _checkSubclassRelationship(sId, tId).toIntSigned() != -1;
  }

  static bool isObjectInterfaceSubtype1(
      Object o, int tId, _Type tTypeArgument0) {
    final int sId = ClassID.getID(o);

    // Return early if [sId] isn't a direct/indirect subclass of [tId].
    final int substitutionIndex =
        _checkSubclassRelationship(sId, tId).toIntSigned();
    if (substitutionIndex == -1) return false;

    // Check individual type arguments without substitution (fast case).
    final sTypeArguments = Object._getTypeArguments(o);
    return areTypeArgumentsSubtypes1(
        sTypeArguments, tTypeArgument0, substitutionIndex);
  }

  static bool isObjectInterfaceSubtype2(
      Object o, int tId, _Type tTypeArgument0, _Type tTypeArgument1) {
    final int sId = ClassID.getID(o);

    // Return early if [sId] isn't a direct/indirect subclass of [tId].
    final int substitutionIndex =
        _checkSubclassRelationship(sId, tId).toIntSigned();
    if (substitutionIndex == -1) return false;

    // Check individual type arguments without substitution (fast case).
    final sTypeArguments = Object._getTypeArguments(o);
    return areTypeArgumentsSubtypes2(
        sTypeArguments, tTypeArgument0, tTypeArgument1, substitutionIndex);
  }

  static bool isObjectInterfaceSubtypeN(
      Object o, int tId, WasmArray<_Type> tTypeArguments) {
    final int sId = ClassID.getID(o);

    // Return early if [sId] isn't a direct/indirect subclass of [tId].
    final int substitutionIndex =
        _checkSubclassRelationship(sId, tId).toIntSigned();
    if (substitutionIndex == -1) return false;

    // Return early if we don't have to check type arguments as the destination
    // type is non-generic.
    if (tTypeArguments.isEmpty) return true;

    // Check individual type arguments without substitution (fast case).
    final sTypeArguments = Object._getTypeArguments(o);
    return areTypeArgumentsSubtypes(
        sTypeArguments, null, tTypeArguments, null, substitutionIndex);
  }

  static bool areTypeArgumentsSubtypes1(WasmArray<_Type> sTypeArguments,
      _Type tTypeArgument0, int substitutionIndex) {
    // Check individual type arguments without substitution (fast case).
    if (substitutionIndex == _noSubstitutionIndex.toIntSigned()) {
      return isSubtype(sTypeArguments[0], null, tTypeArgument0, null);
    }

    // Substitue each argument before performing the subtype check (slow case).
    final substitutions = _canonicalSubstitutionTable[substitutionIndex];
    assert(substitutions.length == 1);
    final sArgForClassT =
        substituteTypeArgument(substitutions[0], sTypeArguments, null);
    return isSubtype(sArgForClassT, null, tTypeArgument0, null);
  }

  static bool areTypeArgumentsSubtypes2(WasmArray<_Type> sTypeArguments,
      _Type tTypeArgument0, _Type tTypeArgument1, int substitutionIndex) {
    // Check individual type arguments without substitution (fast case).
    if (substitutionIndex == _noSubstitutionIndex.toIntSigned()) {
      return isSubtype(sTypeArguments[1], null, tTypeArgument1, null) &&
          isSubtype(sTypeArguments[0], null, tTypeArgument0, null);
    }

    // Substitue each argument before performing the subtype check (slow case).
    final substitutions = _canonicalSubstitutionTable[substitutionIndex];
    assert(substitutions.length == 2);
    final sArg1ForClassT =
        substituteTypeArgument(substitutions[1], sTypeArguments, null);
    final sArg0ForClassT =
        substituteTypeArgument(substitutions[0], sTypeArguments, null);
    return isSubtype(sArg0ForClassT, null, tTypeArgument0, null) &&
        isSubtype(sArg1ForClassT, null, tTypeArgument1, null);
  }

  static bool areTypeArgumentsSubtypes(
      WasmArray<_Type> sTypeArguments,
      _Environment? sEnv,
      WasmArray<_Type> tTypeArguments,
      _Environment? tEnv,
      int substitutionIndex) {
    // Check individual type arguments without substitution (fast case).
    if (substitutionIndex == _noSubstitutionIndex.toIntSigned()) {
      for (int i = 0; i < tTypeArguments.length; i++) {
        if (!isSubtype(sTypeArguments[i], sEnv, tTypeArguments[i], tEnv)) {
          return false;
        }
      }
      return true;
    }

    // Substitute each argument before performing the subtype check (slow case).
    final substitutions = _canonicalSubstitutionTable[substitutionIndex];
    assert(substitutions.length == tTypeArguments.length);
    for (int i = 0; i < tTypeArguments.length; i++) {
      final sArgForClassT =
          substituteTypeArgument(substitutions[i], sTypeArguments, null);
      if (!isSubtype(sArgForClassT, sEnv, tTypeArguments[i], tEnv)) {
        return false;
      }
    }
    return true;
  }

  /// Checks that [sId] is direct/indirect subclass of [tId] and obtains
  /// substitution array index to translate [sId]s type arguments to [tId]s
  /// type arguments.
  ///
  /// Returns `null` if [sId] does not have [tId] in its transitive
  /// extends/implements chain or
  @pragma('wasm:prefer-inline')
  static WasmI32 _checkSubclassRelationship(int sId, int tId) {
    // Caller should ensure that the target cannot be a top type (which is
    // usually the case as callers have an [_InterfaceType].
    assert(!_isObjectClassId(tId));

    // The [sSupers] array below doesn't encode the class itself.
    if (sId == tId) return _noSubstitutionIndex;

    // Otherwise, check if [s] is a subtype of [t], and if it is then compare
    // [s]'s type substitutions with [t]'s type arguments.
    final WasmArray<WasmI32> sSupers = _typeRulesSupers[sId];
    if (sSupers.length == 0) return (-1).toWasmI32();

    final int substitutionIndex = _searchSupers(sSupers, tId);
    if (substitutionIndex == -1) return (-1).toWasmI32();
    return sSupers[substitutionIndex];
  }

  static int _searchSupers(WasmArray<WasmI32> table, int key) {
    final int end = table.length >> 1;
    return (end < 8)
        ? _linearSearch(table, end, key)
        : _binarySearch(table, end, key);
  }

  @pragma('wasm:prefer-inline')
  static int _linearSearch(WasmArray<WasmI32> table, int end, int key) {
    for (int i = 0; i < end; i++) {
      if (table.readUnsigned(i) == key) return end + i;
    }
    return -1;
  }

  @pragma('wasm:prefer-inline')
  static int _binarySearch(WasmArray<WasmI32> table, int end, int key) {
    int lower = 0;
    int upper = end - 1;
    while (lower <= upper) {
      final int mid = (lower + upper) >> 1;
      final int entry = table.readUnsigned(mid);
      if (key < entry) {
        upper = mid - 1;
        continue;
      }
      if (entry < key) {
        lower = mid + 1;
        continue;
      }
      assert(entry == key);
      assert(_linearSearch(table, end, key) == (end + mid));
      return end + mid;
    }
    assert(_linearSearch(table, end, key) == -1);
    return -1;
  }

  static bool isFunctionSubtype(_FunctionType s, _Environment? sEnv,
      _FunctionType t, _Environment? tEnv) {
    // Set up environments
    sEnv = _Environment(sEnv, s);
    tEnv = _Environment(tEnv, t);

    // Check that [s] and [t] have the same number of type parameters and that
    // their bounds are equivalent.
    int sTypeParameterCount = s.typeParameterBounds.length;
    int tTypeParameterCount = t.typeParameterBounds.length;
    if (sTypeParameterCount != tTypeParameterCount) return false;
    for (int i = 0; i < sTypeParameterCount; i++) {
      if (!areEquivalent(
          s.typeParameterBounds[i], sEnv, t.typeParameterBounds[i], tEnv)) {
        return false;
      }
    }

    if (!isSubtype(s.returnType, sEnv, t.returnType, tEnv)) return false;

    // Check [s] does not have more required positional arguments than [t].
    int sRequiredCount = s.requiredParameterCount;
    int tRequiredCount = t.requiredParameterCount;
    if (sRequiredCount > tRequiredCount) {
      return false;
    }

    // Check [s] has enough required and optional positional arguments to
    // potentially be a valid subtype of [t].
    WasmArray<_Type> sPositional = s.positionalParameters;
    WasmArray<_Type> tPositional = t.positionalParameters;
    int sPositionalLength = sPositional.length;
    int tPositionalLength = tPositional.length;
    if (sPositionalLength < tPositionalLength) {
      return false;
    }

    // Check all [t] positional arguments are subtypes of [s] positional
    // arguments.
    for (int i = 0; i < tPositionalLength; i++) {
      _Type sParameter = sPositional[i];
      _Type tParameter = tPositional[i];
      if (!isSubtype(tParameter, tEnv, sParameter, sEnv)) {
        return false;
      }
    }

    // Check that [t]'s named arguments are subtypes of [s]'s named arguments.
    // This logic assumes the named arguments are stored in sorted order.
    WasmArray<_NamedParameter> sNamed = s.namedParameters;
    WasmArray<_NamedParameter> tNamed = t.namedParameters;
    int sNamedLength = sNamed.length;
    int tNamedLength = tNamed.length;
    int sIndex = 0;
    for (int tIndex = 0; tIndex < tNamedLength; tIndex++) {
      _NamedParameter tNamedParameter = tNamed[tIndex];
      String tName = tNamedParameter.name;
      while (true) {
        if (sIndex >= sNamedLength) return false;
        _NamedParameter sNamedParameter = sNamed[sIndex];
        String sName = sNamedParameter.name;
        sIndex++;
        int sNameComparedToTName = sName.compareTo(tName);
        if (sNameComparedToTName > 0) return false;
        bool sIsRequired = sNamedParameter.isRequired;
        if (sNameComparedToTName < 0) {
          if (sIsRequired) return false;
          continue;
        }
        bool tIsRequired = tNamedParameter.isRequired;
        if (sIsRequired && !tIsRequired) return false;
        if (!isSubtype(
            tNamedParameter.type, tEnv, sNamedParameter.type, sEnv)) {
          return false;
        }
        break;
      }
    }
    while (sIndex < sNamedLength) {
      if (sNamed[sIndex].isRequired) return false;
      sIndex++;
    }
    return true;
  }

  static bool isRecordSubtype(
      _RecordType s, _Environment? sEnv, _RecordType t, _Environment? tEnv) {
    // [s] <: [t] iff s and t have the same shape and fields of `s` are
    // subtypes of the same field in `t` by index.
    if (!s._sameShape(t)) {
      return false;
    }

    final int numFields = s.fieldTypes.length;
    for (int fieldIdx = 0; fieldIdx < numFields; fieldIdx += 1) {
      if (!isSubtype(
          s.fieldTypes[fieldIdx], sEnv, t.fieldTypes[fieldIdx], tEnv)) {
        return false;
      }
    }

    return true;
  }

  // Subtype check based off of sdk/lib/_internal/js_runtime/lib/rti.dart.
  // Returns true if [s] is a subtype of [t], false otherwise.
  static bool isSubtype(
      _Type s, _Environment? sEnv, _Type t, _Environment? tEnv) {
    // Reflexivity:
    if (identical(s, t)) return true;

    // Compare nullabilities:
    if (s.isDeclaredNullable && !t.isDeclaredNullable) return false;

    // Left bottom:
    if (s.isBottom) return true;

    // Right top:
    if (t.isTop) return true;

    // Right bottom:
    if (t.isBottom) return false;

    // Left Type Variable Bound 1:
    if (s.isFunctionTypeParameterType) {
      final sTypeParam = s.as<_FunctionTypeParameterType>();
      _Environment sEnvAdjusted = sEnv!.adjust(sTypeParam);
      // A function type parameter type is a subtype of another function type
      // parameter type if they refer to the same type parameter.
      if (t.isFunctionTypeParameterType) {
        final tTypeParam = t.as<_FunctionTypeParameterType>();
        _Environment tEnvAdjusted = tEnv!.adjust(tTypeParam);
        if (sEnvAdjusted.depth == tEnvAdjusted.depth &&
            sTypeParam.index - sEnvAdjusted.type.typeParameterOffset ==
                tTypeParam.index - tEnvAdjusted.type.typeParameterOffset) {
          return true;
        }
      }

      // A function type parameter type is a subtype of `FutureOr<T>` if it's a
      // subtype of `T`.
      if (t.isFutureOr) {
        _FutureOrType tFutureOr = t.as<_FutureOrType>();
        if (isSubtype(s, sEnv, tFutureOr.typeArgument, tEnv)) {
          return true;
        }
      }

      // Otherwise, compare the bound to the other type.
      _Type bound = sEnvAdjusted.lookupAdjusted(sTypeParam);
      return isSubtype(bound, sEnvAdjusted, t, tEnv);
    }

    // Left FutureOr:
    if (s.isFutureOr) {
      _FutureOrType sFutureOr = s.as<_FutureOrType>();
      if (!isSubtype(sFutureOr.typeArgument, sEnv, t, tEnv)) {
        return false;
      }
      return isSubtype(sFutureOr.asFuture, sEnv, t, tEnv);
    }

    // Type Variable Reflexivity 1 is subsumed by Reflexivity and therefore
    // elided.
    // Type Variable Reflexivity 2 does not apply at runtime.
    // Right Promoted Variable does not apply at runtime.

    // Right FutureOr:
    if (t.isFutureOr) {
      _FutureOrType tFutureOr = t.as<_FutureOrType>();
      if (isSubtype(s, sEnv, tFutureOr.typeArgument, tEnv)) {
        return true;
      }
      return isSubtype(s, sEnv, tFutureOr.asFuture, tEnv);
    }

    // Left Promoted Variable does not apply at runtime.

    // Function Type / Function:
    if (s.isFunction && t.isAbstractFunction) {
      return true;
    }

    if (s.isFunction && t.isFunction) {
      return isFunctionSubtype(
          s.as<_FunctionType>(), sEnv, t.as<_FunctionType>(), tEnv);
    }

    // Records:
    if (s.isRecord && t.isRecord) {
      return isRecordSubtype(
          s.as<_RecordType>(), sEnv, t.as<_RecordType>(), tEnv);
    }

    // Records are subtypes of the `Record` type:
    if (s.isRecord && t.isAbstractRecord) {
      return true;
    }

    // Interface Compositionality + Super-Interface:
    if (s.isInterface &&
        t.isInterface &&
        isInterfaceSubtype(
            s.as<_InterfaceType>(), sEnv, t.as<_InterfaceType>(), tEnv)) {
      return true;
    }

    return false;
  }

  // Check whether two types are both subtypes of each other.
  static bool areEquivalent(
      _Type s, _Environment? sEnv, _Type t, _Environment? tEnv) {
    return isSubtype(s, sEnv, t, tEnv) && isSubtype(t, tEnv, s, sEnv);
  }
}

@pragma("wasm:entry-point")
@pragma("wasm:prefer-inline")
bool _isSubtype(Object? o, _Type t) {
  // With this function being inlined, Binaryen is often able to optimize parts
  // of it away, for instance:
  // - Omit the null check when the operand is known to be non-null.
  // - Substitute a constant result for the null check when the nullability of
  //   the type is known.
  // - Devirtualize the [_checkInstance] call when the category of the type is
  //   known.
  if (o == null) return t.isDeclaredNullable;
  return t._checkInstance(o);
}

@pragma("wasm:entry-point")
@pragma("wasm:prefer-inline")
bool _isInterfaceSubtype(Object? o, bool isDeclaredNullable, int tId,
    WasmArray<_Type> typeArguments) {
  final t = _InterfaceType(tId, isDeclaredNullable, typeArguments);
  if (o == null) return t.isDeclaredNullable;
  return t._checkInstance(o);
}

@pragma("wasm:entry-point")
@pragma("wasm:prefer-inline")
bool _isInterfaceSubtype0(Object? o, bool isDeclaredNullable, int tId) {
  if (o == null) return isDeclaredNullable;
  return _TypeUniverse.isObjectInterfaceSubtype0(o, tId);
}

@pragma("wasm:entry-point")
@pragma("wasm:prefer-inline")
bool _isInterfaceSubtype1(
    Object? o, bool isDeclaredNullable, int tId, _Type tTypeArgument0) {
  if (o == null) return isDeclaredNullable;
  return _TypeUniverse.isObjectInterfaceSubtype1(o, tId, tTypeArgument0);
}

@pragma("wasm:entry-point")
@pragma("wasm:prefer-inline")
bool _isInterfaceSubtype2(Object? o, bool isDeclaredNullable, int tId,
    _Type tTypeArgument0, _Type tTypeArgument1) {
  if (o == null) return isDeclaredNullable;
  return _TypeUniverse.isObjectInterfaceSubtype2(
      o, tId, tTypeArgument0, tTypeArgument1);
}

@pragma("wasm:entry-point")
@pragma("wasm:prefer-inline")
bool _isTypeSubtype(_Type s, _Type t) {
  return _TypeUniverse.isSubtype(s, null, t, null);
}

@pragma("wasm:entry-point")
@pragma("wasm:prefer-inline")
void _asSubtype(Object? o, _Type t) {
  if (!_isSubtype(o, t)) {
    _TypeError._throwAsCheckError(o, t);
  }
}

@pragma("wasm:entry-point")
@pragma("wasm:prefer-inline")
void _asInterfaceSubtype(Object? o, bool isDeclaredNullable, int tId,
    WasmArray<_Type> typeArguments) {
  if (!_isInterfaceSubtype(o, isDeclaredNullable, tId, typeArguments)) {
    _throwInterfaceTypeAsCheckError(o, isDeclaredNullable, tId, typeArguments);
  }
}

@pragma("wasm:entry-point")
@pragma("wasm:prefer-inline")
void _asInterfaceSubtype0(Object? o, bool isDeclaredNullable, int tId) {
  if (!_isInterfaceSubtype0(o, isDeclaredNullable, tId)) {
    _throwInterfaceTypeAsCheckError0(o, isDeclaredNullable, tId);
  }
}

@pragma("wasm:entry-point")
@pragma("wasm:prefer-inline")
void _asInterfaceSubtype1(
    Object? o, bool isDeclaredNullable, int tId, _Type typeArgument0) {
  if (!_isInterfaceSubtype1(o, isDeclaredNullable, tId, typeArgument0)) {
    _throwInterfaceTypeAsCheckError1(o, isDeclaredNullable, tId, typeArgument0);
  }
}

@pragma("wasm:entry-point")
@pragma("wasm:prefer-inline")
void _asInterfaceSubtype2(Object? o, bool isDeclaredNullable, int tId,
    _Type typeArgument0, _Type typeArgument1) {
  if (!_isInterfaceSubtype2(
      o, isDeclaredNullable, tId, typeArgument0, typeArgument1)) {
    _throwInterfaceTypeAsCheckError2(
        o, isDeclaredNullable, tId, typeArgument0, typeArgument1);
  }
}

@pragma('wasm:never-inline')
void _throwInterfaceTypeAsCheckError0(
    Object? o, bool isDeclaredNullable, int tId) {
  final typeArguments = const WasmArray<_Type>.literal([]);
  _TypeError._throwAsCheckError(
      o, _InterfaceType(tId, isDeclaredNullable, typeArguments));
}

@pragma('wasm:never-inline')
void _throwInterfaceTypeAsCheckError1(
    Object? o, bool isDeclaredNullable, int tId, _Type typeArgument0) {
  final typeArguments = WasmArray<_Type>.literal([typeArgument0]);
  _TypeError._throwAsCheckError(
      o, _InterfaceType(tId, isDeclaredNullable, typeArguments));
}

@pragma('wasm:never-inline')
void _throwInterfaceTypeAsCheckError2(Object? o, bool isDeclaredNullable,
    int tId, _Type typeArgument0, _Type typeArgument1) {
  final typeArguments =
      WasmArray<_Type>.literal([typeArgument0, typeArgument1]);
  _TypeError._throwAsCheckError(
      o, _InterfaceType(tId, isDeclaredNullable, typeArguments));
}

@pragma('wasm:never-inline')
void _throwInterfaceTypeAsCheckError(Object? o, bool isDeclaredNullable,
    int tId, WasmArray<_Type> typeArguments) {
  _TypeError._throwAsCheckError(
      o, _InterfaceType(tId, isDeclaredNullable, typeArguments));
}

@pragma("wasm:entry-point")
bool _verifyOptimizedTypeCheck(
    bool result, Object? o, _Type t, String? location) {
  _Type s = _getActualRuntimeTypeNullable(o);
  bool reference = _isTypeSubtype(s, t);
  if (result != reference) {
    throw _TypeCheckVerificationError(s, t, result, reference, location);
  }
  return result;
}

class _TypeCheckVerificationError extends Error {
  final _Type left;
  final _Type right;
  final bool optimized;
  final bool reference;
  final String? location;

  _TypeCheckVerificationError(
      this.left, this.right, this.optimized, this.reference, this.location);

  String toString() {
    String locationString = location != null ? " at $location" : "";
    return "Type check verification error$locationString\n"
        "Checking $left <: $right\n"
        "Optimized result $optimized, reference result $reference\n";
  }
}

/// Checks that argument lists have expected number of arguments for the
/// closure.
///
/// If the type argument list ([typeArguments]) is empty but the closure has
/// type parameters, updates [typeArguments] with the default bounds of the
/// type parameters.
///
/// [namedArguments] is a list of `Symbol` and `Object?` pairs.
@pragma("wasm:entry-point")
bool _checkClosureShape(
    _FunctionType functionType,
    WasmArray<_Type> typeArguments,
    WasmArray<Object?> positionalArguments,
    WasmArray<dynamic> namedArguments) {
  if (typeArguments.length != functionType.typeParameterDefaults.length) {
    return false;
  }

  // Check positional args
  if (positionalArguments.length < functionType.requiredParameterCount ||
      positionalArguments.length > functionType.positionalParameters.length) {
    return false;
  }

  // Check named args. Both parameters and args are sorted, so we can iterate
  // them in parallel.
  int namedParamIdx = 0;
  int namedArgIdx = 0;
  while (namedParamIdx < functionType.namedParameters.length) {
    _NamedParameter param = functionType.namedParameters[namedParamIdx];

    if (namedArgIdx * 2 >= namedArguments.length) {
      if (param.isRequired) {
        return false;
      }
      namedParamIdx += 1;
      continue;
    }

    String argName = _symbolToString(namedArguments[namedArgIdx * 2] as Symbol);

    final cmp = argName.compareTo(param.name);

    if (cmp == 0) {
      // Expected arg passed
      namedParamIdx += 1;
      namedArgIdx += 1;
    } else if (cmp < 0) {
      // Unexpected arg passed
      return false;
    } else if (param.isRequired) {
      // Required param not passed
      return false;
    } else {
      // Optional param not passed
      namedParamIdx += 1;
    }
  }

  // All named parameters checked, any extra arguments are unexpected
  if (namedArgIdx * 2 < namedArguments.length) {
    return false;
  }

  return true;
}

/// Checks that values in argument lists have expected types.
///
/// Throws [TypeError] when a type check fails.
///
/// Assumes that shape check ([_checkClosureShape]) passed and the type list is
/// adjusted with default bounds if necessary.
///
/// [namedArguments] is a list of `Symbol` and `Object?` pairs.
@pragma("wasm:entry-point")
void _checkClosureType(
    _FunctionType functionType,
    WasmArray<_Type> typeArguments,
    WasmArray<Object?> positionalArguments,
    WasmArray<dynamic> namedArguments) {
  assert(functionType.typeParameterBounds.length == typeArguments.length);

  if (!typeArguments.isEmpty) {
    for (int i = 0; i < typeArguments.length; i += 1) {
      final typeArgument = typeArguments[i];
      final paramBound = _TypeUniverse.substituteTypeArgument(
          functionType.typeParameterBounds[i], typeArguments, functionType);
      if (!_TypeUniverse.isSubtype(typeArgument, null, paramBound, null)) {
        final stackTrace = StackTrace.current;
        final typeError = _TypeError.fromMessageAndStackTrace(
            "Type argument '$typeArgument' is not a "
            "subtype of type parameter bound '$paramBound'",
            stackTrace);
        Error._throw(typeError, stackTrace);
      }
    }

    functionType = _TypeUniverse.substituteFunctionTypeArgument(
        functionType, typeArguments);
  }

  // Check positional arguments
  for (int i = 0; i < positionalArguments.length; i += 1) {
    final Object? arg = positionalArguments[i];
    final _Type paramTy = functionType.positionalParameters[i];
    if (!_isSubtype(arg, paramTy)) {
      // TODO(50991): Positional parameter names not available in runtime
      _TypeError._throwArgumentTypeCheckError(
          arg, paramTy, '???', StackTrace.current);
    }
  }

  // Check named arguments. Since the shape check passed we know that passed
  // names exist in named parameters of the function.
  int namedParamIdx = 0;
  int namedArgIdx = 0;
  while (namedArgIdx * 2 < namedArguments.length) {
    final String argName =
        _symbolToString(namedArguments[namedArgIdx * 2] as Symbol);
    if (argName == functionType.namedParameters[namedParamIdx].name) {
      final arg = namedArguments[namedArgIdx * 2 + 1];
      final paramTy = functionType.namedParameters[namedParamIdx].type;
      if (!_isSubtype(arg, paramTy)) {
        _TypeError._throwArgumentTypeCheckError(
            arg, paramTy, argName, StackTrace.current);
      }
      namedParamIdx += 1;
      namedArgIdx += 1;
    } else {
      namedParamIdx += 1;
    }
  }
}

_Type _getActualRuntimeType(Object object) {
  final classId = ClassID.getID(object);

  if (_isObjectClassId(classId)) return _literal<Object>();
  if (_isRecordClassId(classId)) {
    return Record._getMasqueradedRecordRuntimeType(unsafeCast<Record>(object));
  }
  if (_isClosureClassId(classId)) {
    return _Closure._getClosureRuntimeType(unsafeCast<_Closure>(object));
  }
  return _InterfaceType(classId, false, Object._getTypeArguments(object));
}

@pragma("wasm:prefer-inline")
_Type _getActualRuntimeTypeNullable(Object? object) =>
    object == null ? _literal<Null>() : _getActualRuntimeType(object);

@pragma("wasm:entry-point")
_Type _getMasqueradedRuntimeType(Object object) {
  final classId = ClassID.getID(object);

  // Fast path: Most usages of `.runtimeType` may be on user-defined classes
  // (e.g. `Widget.runtimeType`, ...)
  if (ClassID.firstNonMasqueradedInterfaceClassCid <= classId) {
    // Non-masqueraded interface type.
    return _InterfaceType(classId, false, Object._getTypeArguments(object));
  }

  if (_isObjectClassId(classId)) return _literal<Object>();
  if (_isRecordClassId(classId)) {
    return Record._getMasqueradedRecordRuntimeType(unsafeCast<Record>(object));
  }
  if (_isClosureClassId(classId)) {
    return _Closure._getClosureRuntimeType(unsafeCast<_Closure>(object));
  }

  // This method is not used in the RTT implementation, it's purely used for
  // producing `Type` objects for `<obj>.runtimeType`.
  //
  // => We can use normal `is` checks in here that will be desugared to class-id
  //    range checks.

  if (object is bool) return _literal<bool>();
  if (object is int) return _literal<int>();
  if (object is double) return _literal<double>();
  if (object is _Type) return _literal<Type>();
  if (object is WasmListBase) {
    return _InterfaceType(
        ClassID.cidList, false, Object._getTypeArguments(object));
  }

  if (_isJsCompatibility) {
    if (object is String) return _literal<String>();
    if (object is TypedData) {
      if (object is ByteData) return _literal<ByteData>();
      if (object is Int8List) return _literal<Int8List>();
      if (object is Uint8List) return _literal<Uint8List>();
      if (object is Uint8ClampedList) return _literal<Uint8ClampedList>();
      if (object is Int16List) return _literal<Int16List>();
      if (object is Uint16List) return _literal<Uint16List>();
      if (object is Int32List) return _literal<Int32List>();
      if (object is Uint32List) return _literal<Uint32List>();
      if (object is Int64List) return _literal<Int64List>();
      if (object is Uint64List) return _literal<Uint64List>();
      if (object is Float32List) return _literal<Float32List>();
      if (object is Float64List) return _literal<Float64List>();
      if (object is Int32x4List) return _literal<Int32x4List>();
      if (object is Float32x4List) return _literal<Float32x4List>();
      if (object is Float64x2List) return _literal<Float64x2List>();
    }
    if (object is ByteBuffer) return _literal<ByteBuffer>();
    if (object is Float32x4) return _literal<Float32x4>();
    if (object is Float64x2) return _literal<Float64x2>();
    if (object is Int32x4) return _literal<Int32x4>();
  } else {
    if (object is WasmStringBase) return _literal<String>();
    if (object is WasmTypedDataBase) {
      if (object is ByteData) return _literal<ByteData>();
      if (object is Int8List) return _literal<Int8List>();
      if (object is Uint8List) return _literal<Uint8List>();
      if (object is Uint8ClampedList) return _literal<Uint8ClampedList>();
      if (object is Int16List) return _literal<Int16List>();
      if (object is Uint16List) return _literal<Uint16List>();
      if (object is Int32List) return _literal<Int32List>();
      if (object is Uint32List) return _literal<Uint32List>();
      if (object is Int64List) return _literal<Int64List>();
      if (object is Uint64List) return _literal<Uint64List>();
      if (object is Float32List) return _literal<Float32List>();
      if (object is Float64List) return _literal<Float64List>();
      if (object is Int32x4List) return _literal<Int32x4List>();
      if (object is Float32x4List) return _literal<Float32x4List>();
      if (object is Float64x2List) return _literal<Float64x2List>();
      if (object is ByteBuffer) return _literal<ByteBuffer>();
      if (object is Float32x4) return _literal<Float32x4>();
      if (object is Float64x2) return _literal<Float64x2>();
      if (object is Int32x4) return _literal<Int32x4>();
    }
  }

  // Non-masqueraded interface type.
  return _InterfaceType(classId, false, Object._getTypeArguments(object));
}

const bool _isJsCompatibility =
    bool.fromEnvironment('dart.wasm.js_compatibility');

@pragma("wasm:prefer-inline")
_Type _getMasqueradedRuntimeTypeNullable(Object? object) =>
    object == null ? _literal<Null>() : _getMasqueradedRuntimeType(object);

external bool _isObjectClassId(int classId);
external bool _isClosureClassId(int classId);
external bool _isRecordClassId(int classId);

// Used by the generated code to compare types captured by instantiation
// closures. Because we don't have a way of forcing adding a member the
// dispatch table (like the entry-point pragma) we can't generate a virtual
// call to `_Type.==` directly in the generated code.
@pragma("wasm:entry-point")
@pragma("wasm:prefer-inline")
bool _runtimeTypeEquals(_Type t1, _Type t2) => t1 == t2;

// Same as [_RuntimeTypeEquals], but for `Object.hashCode`.
@pragma("wasm:entry-point")
@pragma("wasm:prefer-inline")
int _runtimeTypeHashCode(_Type t) => t.hashCode;
