// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Enables building up dynamic schemas with deep casts.
///
/// These schemas are built up "inside out" using [getAsTypedCast] to extract
/// the reified type argument from a [Cast],  and pass that to another [Cast]
/// instance.
class Cast<T> {
  const Cast();

  /// All casts happen in this method, custom [Cast] implementations must
  /// override this method, and no other methods.
  T _cast(Object? from) => from is T
      ? from
      : throw FailedCast(
          'expected type $T but got type ${from.runtimeType} for: $from');

  T cast(Object? from) => _cast(from);

  Cast<T?> get nullable => NullableCast._(this);

  /// Enables building up deeply nested generic types without requiring any
  /// static knowledge or type inference.
  ///
  /// Example usage:
  ///
  /// Cast<dynamic> x = Cast<int>();
  /// final y = x.getAsTypedCast(<T>(_) => Cast<Foo<T>>());
  /// print(y.runtimeType); // Cast<Foo<int>>
  R getAsTypedCast<R>(R Function<CastType>(Cast<CastType> self) callback) =>
      callback<T>(this);
}

/// Wraps a [Cast] such that it also accepts `null`.
class NullableCast<T> extends Cast<T?> {
  final Cast<T> _original;

  @override
  Cast<T?> get nullable => this;

  NullableCast._(this._original);

  @override
  T? _cast(Object? from) {
    if (from == null) return null;
    return _original._cast(from);
  }
}

/// Specialized [Cast] implementation for [Map]s which does deep casting of keys
/// and values.
class MapCast<K, V> extends Cast<Map<K, V>> {
  final Cast<K> _key;
  final Cast<V> _value;
  const MapCast._(Cast<K> key, Cast<V> value)
      : _key = key,
        _value = value;

  /// Builds a [MapCast] whose runtime type is built from the runtime type
  /// arguments of [keyCast] and [valueCast].
  ///
  /// The static type arguments are generally not interesting for these objects,
  /// and so `<Object?, Object?>` is used to avoid unnecessary casts.
  static MapCast<Object?, Object?> from(
          Cast<Object?> keyCast, Cast<Object?> valueCast) =>
      keyCast.getAsTypedCast(<K>(keyCast) => valueCast.getAsTypedCast(
          <V>(valueCast) => MapCast<K, V>._(keyCast, valueCast)));

  @override
  Map<K, V> _cast(Object? from) {
    if (from is! Map) {
      return super._cast(from);
    }
    Map<K, V> result = {};
    for (Object? key in from.keys) {
      K newKey = _key._cast(key);
      result[newKey] = _value._cast(from[key]);
    }
    return result;
  }
}

/// Specialized [Cast] implementation for [List]s which does deep casting of
/// entries.
class ListCast<E> extends Cast<List<E>> {
  final Cast<E> _entryCast;
  const ListCast._(this._entryCast);

  /// Builds a [ListCast] whose runtime type is built from the runtime type
  /// arguments of [entryCast].
  ///
  /// The static type argument is generally not interesting for these objects,
  /// and so `<Object?>` is used to avoid unnecessary casts.
  static ListCast<Object?> from(Cast entryCast) =>
      entryCast.getAsTypedCast(ListCast._);

  @override
  List<E> _cast(Object? from) {
    if (from is! List) {
      return super._cast(from);
    }
    return List<E>.generate(from.length, (i) => _entryCast._cast(from[i]));
  }
}

/// Specialized [Cast] implementation for [Set]s which does deep casting of
/// entries.
class SetCast<E> extends Cast<Set<E>> {
  final Cast<E> _entryCast;
  const SetCast._(this._entryCast);

  /// Builds a [SetCast] whose runtime type is built from the runtime type
  /// arguments of [entryCast].
  ///
  /// The static type argument is generally not interesting for these objects,
  /// and so `<Object?>` is used to avoid unnecessary casts.
  static SetCast<Object?> from(Cast entryCast) =>
      entryCast.getAsTypedCast(SetCast._);

  @override
  Set<E> _cast(Object? from) {
    if (from is! Set) {
      return super._cast(from);
    }
    return {
      for (int i = 0; i < from.length; i++) _entryCast._cast(from.elementAt(i)),
    };
  }
}

/// A specific [Exception] for failed casts with information about the full path
/// to the failed cast.
class FailedCast implements Exception {
  String message;
  FailedCast(this.message);

  @override
  toString() => "Failed cast: $message";
}
