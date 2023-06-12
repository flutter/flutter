// Copyright 2013 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:collection';

/// A value that might be absent.
///
/// Use Optional as an alternative to allowing fields, parameters or return
/// values to be null. It signals that a value is not required and provides
/// convenience methods for dealing with the absent case.
///
/// With the introduction of non-null by default in Dart SDK 2.12, developers
/// should avoid adding more uses of this type. Existing users should migrate
/// away from the `Optional` type to types marked nullable: `T?`.
class Optional<T> extends IterableBase<T> {
  /// Constructs an empty Optional.
  const Optional.absent() : _value = null;

  /// Constructs an Optional of the given [value].
  ///
  /// Throws [ArgumentError] if [value] is null.
  Optional.of(T value) : _value = value {
    // TODO(cbracken): Delete and make this ctor const once mixed-mode
    // execution is no longer around.
    ArgumentError.checkNotNull(value);
  }

  /// Constructs an Optional of the given [value].
  ///
  /// If [value] is null, returns [absent()].
  const Optional.fromNullable(T? value) : _value = value;

  final T? _value;

  /// True when this optional contains a value.
  bool get isPresent => _value != null;

  /// True when this optional contains no value.
  bool get isNotPresent => _value == null;

  /// Gets the Optional value.
  ///
  /// Throws [StateError] if [value] is null.
  T get value {
    if (_value == null) {
      throw StateError('value called on absent Optional.');
    }
    return _value!;
  }

  /// Executes a function if the Optional value is present.
  void ifPresent(void ifPresent(T value)) {
    if (isPresent) {
      ifPresent(_value!);
    }
  }

  /// Execution a function if the Optional value is absent.
  void ifAbsent(void ifAbsent()) {
    if (!isPresent) {
      ifAbsent();
    }
  }

  /// Gets the Optional value with a default.
  ///
  /// The default is returned if the Optional is [absent()].
  ///
  /// Throws [ArgumentError] if [defaultValue] is null.
  T or(T defaultValue) {
    return _value ?? defaultValue;
  }

  /// Gets the Optional value, or [null] if there is none.
  T? get orNull => _value;

  /// Transforms the Optional value.
  ///
  /// If the Optional is [absent()], returns [absent()] without applying the transformer.
  ///
  /// The transformer must not return [null]. If it does, an [ArgumentError] is thrown.
  Optional<S> transform<S extends Object>(S transformer(T value)) {
    return _value == null
        ? Optional<S>.absent()
        : Optional<S>.of(transformer(_value!));
  }

  /// Transforms the Optional value.
  ///
  /// If the Optional is [absent()], returns [absent()] without applying the transformer.
  ///
  /// Returns [absent()] if the transformer returns [null].
  Optional<S> transformNullable<S extends Object>(S? transformer(T value)) {
    return _value == null
        ? Optional<S>.absent()
        : Optional<S>.fromNullable(transformer(_value!));
  }

  @override
  Iterator<T> get iterator =>
      isPresent ? <T>[_value!].iterator : Iterable<T>.empty().iterator;

  /// Delegates to the underlying [value] hashCode.
  @override
  int get hashCode => _value.hashCode;

  /// Delegates to the underlying [value] operator==.
  @override
  bool operator ==(Object o) => o is Optional<T> && o._value == _value;

  @override
  String toString() {
    return _value == null
        ? 'Optional { absent }'
        : 'Optional { value: $_value }';
  }
}
