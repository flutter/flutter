// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show patch, unsafeCast;
import 'dart:_js_helper' show isJSUndefined, JS;
import 'dart:_wasm';
import 'dart:js_interop' hide JS;
import 'dart:js_interop' as js_interop;
import 'dart:ffi' show Pointer, Struct, Union;

void _checkValidWeakTarget(Object object) {
  if ((object is bool) ||
      (object is num) ||
      (object is String) ||
      (object is Record) ||
      (object is Pointer) ||
      (object is Struct) ||
      (object is Union)) {
    throw new ArgumentError.value(
        object,
        "A string, number, boolean, record, Pointer, Struct or Union "
        "can't be a weak target");
  }
}

@patch
class Expando<T> {
  WasmExternRef? _jsWeakMap;

  @patch
  Expando([String? name]) : name = name {
    _jsWeakMap = JS<WasmExternRef?>("() => new WeakMap()");
  }

  @patch
  T? operator [](Object object) {
    _checkValidWeakTarget(object);
    final result =
        JS<WasmExternRef?>("(map, o) => map.get(o)", _jsWeakMap, object);
    // Coerce to null if JavaScript returns undefined.
    if (isJSUndefined(result)) return null;
    return unsafeCast(result.internalize()?.toObject());
  }

  @patch
  void operator []=(Object object, T? value) {
    _checkValidWeakTarget(object);
    JS<void>(
        "(map, o, v) => map.set(o, v)", _jsWeakMap, object, value as Object?);
  }
}

@js_interop.JS('WeakRef')
external JSFunction? _jsWeakRefFunction;
final bool _supportsWeakRef = _jsWeakRefFunction != null;

@js_interop.JS('WeakRef')
extension type _JSWeakRef<T extends Object>._(JSObject _) implements JSObject {
  external _JSWeakRef(ExternalDartReference<T> target);
  external ExternalDartReference<T>? deref();
}

@patch
class WeakReference<T extends Object> {
  @patch
  factory WeakReference(T target) {
    if (_supportsWeakRef) {
      _checkValidWeakTarget(target);
      return _WeakReferenceWrapper<T>(target);
    }
    // The polyfill does not validate [target]. This lets the tests distinguish
    // whether we run in polyfill mode or not (this behavior is mirrored from
    // what dart2js does).
    return _WeakReferencePolyfill<T>(target);
  }
}

class _WeakReferenceWrapper<T extends Object> implements WeakReference<T> {
  final _JSWeakRef<T> _jsWeakRef;
  _WeakReferenceWrapper(T target)
      : _jsWeakRef = _JSWeakRef(target.toExternalReference);
  T? get target => _jsWeakRef.deref()?.toDartObject;
}

class _WeakReferencePolyfill<T extends Object> implements WeakReference<T> {
  final T target;
  _WeakReferencePolyfill(this.target);
}

@js_interop.JS('FinalizationRegistry')
external JSFunction? _jsFinalizationRegistry;
final bool _supportsFinalizationRegistry = _jsFinalizationRegistry != null;

@js_interop.JS('FinalizationRegistry')
extension type _JSFinalizationRegistry<T>._(JSObject _) implements JSObject {
  external _JSFinalizationRegistry(JSFunction callback);
  @js_interop.JS('register')
  external void registerWithDetach(ExternalDartReference<Object> value,
      ExternalDartReference<T> peer, ExternalDartReference<Object> detach);
  external void register(
      ExternalDartReference<Object> value, ExternalDartReference<T> peer);
  external void unregister(ExternalDartReference<Object> detach);
}

@patch
class Finalizer<T> {
  @patch
  factory Finalizer(void Function(T) object) {
    return _supportsFinalizationRegistry
        ? _FinalizationRegistryWrapper<T>(object)
        : _FinalizationRegistryPolyfill<T>(object);
  }
}

class _FinalizationRegistryPolyfill<T> implements Finalizer<T> {
  _FinalizationRegistryPolyfill(void Function(T) callback);

  void attach(Object value, T peer, {Object? detach}) {
    // The polyfill does not validate [value] & [detach]. This lets the tests
    // distinguish whether we run in polyfill mode or not (this behavior is
    // mirrored from what dart2js does).
  }

  void detach(Object detach) {
    // The polyfill does not validate [detach]. This lets the tests distinguish
    // whether we run in polyfill mode or not (this behavior is mirrored from
    // what dart2js does).
  }
}

class _FinalizationRegistryWrapper<T> implements Finalizer<T> {
  final _JSFinalizationRegistry _jsFinalizationRegistry;

  _FinalizationRegistryWrapper(void Function(T) callback)
      : _jsFinalizationRegistry =
            _JSFinalizationRegistry(((ExternalDartReference<T> peer) {
          callback(peer.toDartObject);
        }).toJS);

  void attach(Object value, T peer, {Object? detach}) {
    _checkValidWeakTarget(value);
    if (detach != null) {
      _checkValidWeakTarget(detach);
      _jsFinalizationRegistry.registerWithDetach(value.toExternalReference,
          peer.toExternalReference, detach.toExternalReference);
    } else {
      _jsFinalizationRegistry.register(
          value.toExternalReference, peer.toExternalReference);
    }
  }

  void detach(Object detach) {
    _checkValidWeakTarget(detach);
    _jsFinalizationRegistry.unregister(detach.toExternalReference);
  }
}
