// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core_patch.dart";

/// Base class for closure objects.
final class _Closure implements Function {
  @pragma("wasm:entry-point")
  WasmStructRef context;

  @pragma("wasm:entry-point")
  _Closure._(this.context);

  @override
  bool operator ==(Object other) {
    if (other is! _Closure) {
      return false;
    }

    if (identical(this, other)) {
      return true;
    }

    final thisIsInstantiation = _isInstantiationClosure;
    final otherIsInstantiation = other._isInstantiationClosure;

    if (thisIsInstantiation != otherIsInstantiation) {
      return false;
    }

    if (thisIsInstantiation) {
      final thisInstantiatedClosure = _instantiatedClosure;
      final otherInstantiatedClosure = other._instantiatedClosure;
      return thisInstantiatedClosure == otherInstantiatedClosure &&
          _instantiationClosureTypeEquals(other);
    }

    if (_vtable != other._vtable) {
      return false;
    }

    final thisIsTearOff = _isInstanceTearOff;
    final otherIsTearOff = other._isInstanceTearOff;

    if (thisIsTearOff != otherIsTearOff) {
      return false;
    }

    if (thisIsTearOff) {
      return _instanceTearOffReceiver == other._instanceTearOffReceiver;
    }

    return false;
  }

  @pragma("wasm:entry-point")
  @pragma("wasm:prefer-inline")
  external static _FunctionType _getClosureRuntimeType(_Closure closure);

  @override
  int get hashCode {
    if (_isInstantiationClosure) {
      return Object.hash(_instantiatedClosure, _instantiationClosureTypeHash());
    }

    if (_isInstanceTearOff) {
      return Object.hash(
          _instanceTearOffReceiver, _getClosureRuntimeType(this));
    }

    return Object._objectHashCode(this); // identity hash
  }

  // Support dynamic tear-off of `.call` on functions
  @pragma("wasm:entry-point")
  Function get call => this;

  @override
  String toString() => 'Closure: $runtimeType';

  // Helpers for implementing `hashCode`, `operator ==`.

  /// Whether the closure is an instantiation.
  external bool get _isInstantiationClosure;

  /// When the closure is an instantiation, get the instantiated closure.
  ///
  /// Traps when the closure is not an instantiation.
  external _Closure get _instantiatedClosure;

  /// When the closure is an instantiation, returns the combined hash code of
  /// the captured types.
  ///
  /// Traps when the closure is not an instantiation.
  external int _instantiationClosureTypeHash();

  /// When this [_Closure] and [other] are instantiations, compare captured
  /// types for equality.
  ///
  /// Traps when one or both of the closures are not an instantiation.
  external bool _instantiationClosureTypeEquals(_Closure other);

  /// Whether the closure is an instance tear-off.
  ///
  /// Instance tear-offs will have receivers.
  external bool get _isInstanceTearOff;

  /// When the closure is an instance tear-off, returns the receiver.
  ///
  /// Traps when the closure is not an instance tear-off.
  external Object? get _instanceTearOffReceiver;

  /// The vtable of the closure.
  external WasmAnyRef get _vtable;
}
