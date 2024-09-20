// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/// Representation of the invocation of a member on an object.
///
/// This is the type of objects passed to [Object.noSuchMethod] when
/// an object doesn't support the member invocation that was attempted
/// on it.
abstract class Invocation {
  Invocation();

  /// Creates an invocation corresponding to a method invocation.
  ///
  /// The method invocation has no type arguments.
  /// If the named arguments are omitted, they default to no named arguments.
  @pragma("wasm:entry-point")
  factory Invocation.method(
          Symbol memberName, Iterable<Object?>? positionalArguments,
          [Map<Symbol, Object?>? namedArguments]) =>
      _Invocation.method(memberName, null, positionalArguments, namedArguments);

  /// Creates an invocation corresponding to a generic method invocation.
  ///
  /// If [typeArguments] is `null` or empty, the constructor is equivalent to
  /// calling [Invocation.method] with the remaining arguments.
  /// All the individual type arguments must be non-null.
  ///
  /// If the named arguments are omitted, they default to no named arguments.
  @pragma("wasm:entry-point")
  factory Invocation.genericMethod(Symbol memberName,
          Iterable<Type>? typeArguments, Iterable<Object?>? positionalArguments,
          [Map<Symbol, Object?>? namedArguments]) =>
      _Invocation.method(
          memberName, typeArguments, positionalArguments, namedArguments);

  /// Creates an invocation corresponding to a getter invocation.
  @pragma("wasm:entry-point")
  factory Invocation.getter(Symbol name) = _Invocation.getter;

  /// Creates an invocation corresponding to a setter invocation.
  ///
  /// This constructor accepts any [Symbol] as [memberName], but remember that
  /// *actual setter names* end in `=`, so the invocation corresponding
  /// to `object.member = value` is
  /// ```dart
  /// Invocation.setter(const Symbol("member="), value)
  /// ```
  @pragma("wasm:entry-point")
  factory Invocation.setter(Symbol memberName, Object? argument) =
      _Invocation.setter;

  /// The name of the invoked member.
  Symbol get memberName;

  /// An unmodifiable view of the type arguments of the call.
  ///
  /// If the member is a getter, setter or operator,
  /// the type argument list is always empty.
  List<Type> get typeArguments => const <Type>[];

  /// An unmodifiable view of the positional arguments of the call.
  ///
  /// If the member is a getter, the positional arguments list is
  /// always empty.
  List<dynamic> get positionalArguments;

  /// An unmodifiable view of the named arguments of the call.
  ///
  /// If the member is a getter, setter or operator,
  /// the named arguments map is always empty.
  Map<Symbol, dynamic> get namedArguments;

  /// Whether the invocation was a method call.
  bool get isMethod;

  /// Whether the invocation was a getter call.
  /// If so, all three types of arguments lists are empty.
  bool get isGetter;

  /// Whether the invocation was a setter call.
  ///
  /// If so, [positionalArguments] has exactly one positional
  /// argument, [namedArguments] is empty, and typeArguments is
  /// empty.
  bool get isSetter;

  /// Whether the invocation was a getter or a setter call.
  bool get isAccessor => isGetter || isSetter;
}

/// Implementation of [Invocation] used by its factory constructors.
class _Invocation implements Invocation {
  final Symbol memberName;
  final List<Type> typeArguments;
  // Positional arguments is `null` for getters only.
  final List<Object?>? _positional;
  // Named arguments is `null` for accessors only.
  final Map<Symbol, Object?>? _named;

  _Invocation.method(this.memberName, Iterable<Type>? types,
      Iterable<Object?>? positional, Map<Symbol, Object?>? named)
      : typeArguments = _ensureNonNullTypes(types),
        _positional = positional == null
            ? const <Object?>[]
            : List<Object?>.unmodifiable(positional),
        _named = (named == null || named.isEmpty)
            ? const <Symbol, Object?>{}
            : Map<Symbol, Object?>.unmodifiable(named);

  _Invocation.getter(this.memberName)
      : typeArguments = const <Type>[],
        _positional = null,
        _named = null;

  _Invocation.setter(this.memberName, Object? argument)
      : typeArguments = const <Type>[],
        _positional = List<Object?>.unmodifiable([argument]),
        _named = null;

  List<dynamic> get positionalArguments => _positional ?? const <Object>[];

  Map<Symbol, dynamic> get namedArguments => _named ?? const <Symbol, Object>{};

  bool get isMethod => _named != null;
  bool get isGetter => _positional == null;
  bool get isSetter => _positional != null && _named == null;
  bool get isAccessor => _named == null;

  /// Checks that the elements of [types] are not null.
  static List<Type> _ensureNonNullTypes(Iterable<Type>? types) {
    if (types == null) return const <Type>[];
    List<Type> typeArguments = List<Type>.unmodifiable(types);
    for (int i = 0; i < typeArguments.length; i++) {
      if (typeArguments[i] == null) {
        throw ArgumentError.value(types, "types",
            "Type arguments must be non-null, was null at index $i.");
      }
    }
    return typeArguments;
  }
}
