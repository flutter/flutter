// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart.js_util;

import "dart:_internal";
import "dart:_js_helper";
import "dart:_js_types";
import "dart:js_interop"
    show
        JSAnyUtilityExtension,
        FunctionToJSExportedDartFunction,
        dartify,
        JSAny;
import "dart:_wasm";
import "dart:async" show Completer, FutureOr;
import "dart:collection";
import "dart:typed_data";

@patch
dynamic jsify(Object? object) {
  final convertedObjects = HashMap<Object?, Object?>.identity();
  Object? convert(Object? o) {
    if (convertedObjects.containsKey(o)) {
      return convertedObjects[o];
    }

    if (o == null ||
        o is num ||
        o is bool ||
        o is JSValue ||
        o is String ||
        o is Int8List ||
        o is Uint8List ||
        o is Uint8ClampedList ||
        o is Int16List ||
        o is Uint16List ||
        o is Int32List ||
        o is Uint32List ||
        o is Float32List ||
        o is Float64List ||
        o is ByteBuffer ||
        o is ByteData) {
      return JSValue(jsifyRaw(o));
    }

    if (o is Map<Object?, Object?>) {
      final convertedMap = newObject<JSValue>();
      convertedObjects[o] = convertedMap;
      for (final key in o.keys) {
        final convertedKey = convert(key) as JSValue?;
        setPropertyRaw(convertedMap.toExternRef, convertedKey.toExternRef,
            (convert(o[key]) as JSValue?).toExternRef);
      }
      return convertedMap;
    } else if (o is Iterable<Object?>) {
      final convertedIterable = _newArray();
      convertedObjects[o] = convertedIterable;
      for (final item in o) {
        callMethod(convertedIterable, 'push', [convert(item)]);
      }
      return convertedIterable;
    } else {
      // None of the objects left will require recursive conversions.
      return JSValue(jsifyRaw(o));
    }
  }

  return convert(object);
}

@patch
Object get globalThis => JSValue(globalThisRaw());

@patch
T newObject<T>() => JSValue(newObjectRaw()) as T;

JSValue _newArray() => JSValue(newArrayRaw());

@patch
bool hasProperty(Object o, Object name) =>
    hasPropertyRaw(jsifyRaw(o), jsifyRaw(name));

@patch
T getProperty<T>(Object o, Object name) =>
    dartifyRaw(getPropertyRaw(jsifyRaw(o), jsifyRaw(name))) as T;

@patch
T setProperty<T>(Object o, Object name, T? value) =>
    dartifyRaw(setPropertyRaw(jsifyRaw(o), jsifyRaw(name), jsifyRaw(value)))
        as T;

@patch
T callMethod<T>(Object o, Object method, List<Object?> args) => dartifyRaw(
    callMethodVarArgsRaw(jsifyRaw(o), jsifyRaw(method), jsifyRaw(args))) as T;

@patch
bool instanceof(Object? o, Object type) =>
    JS<bool>("(o, t) => o instanceof t", jsifyRaw(o), jsifyRaw(type));

@patch
T callConstructor<T>(Object o, List<Object?>? args) =>
    dartifyRaw(callConstructorVarArgsRaw(jsifyRaw(o), jsifyRaw(args))) as T;

@patch
T add<T>(Object? first, Object? second) => throw 'unimplemented';

@patch
T subtract<T>(Object? first, Object? second) => throw 'unimplemented';

@patch
T multiply<T>(Object? first, Object? second) => throw 'unimplemented';

@patch
T divide<T>(Object? first, Object? second) => throw 'unimplemented';

@patch
T exponentiate<T>(Object? first, Object? second) => throw 'unimplemented';

@patch
T modulo<T>(Object? first, Object? second) => throw 'unimplemented';

@patch
bool equal<T>(Object? first, Object? second) => throw 'unimplemented';

@patch
bool strictEqual<T>(Object? first, Object? second) => throw 'unimplemented';

@patch
bool notEqual<T>(Object? first, Object? second) => throw 'unimplemented';

@patch
bool strictNotEqual<T>(Object? first, Object? second) => throw 'unimplemented';

@patch
bool greaterThan<T>(Object? first, Object? second) => throw 'unimplemented';

@patch
bool greaterThanOrEqual<T>(Object? first, Object? second) =>
    throw 'unimplemented';

@patch
bool lessThan<T>(Object? first, Object? second) => throw 'unimplemented';

@patch
bool lessThanOrEqual<T>(Object? first, Object? second) => throw 'unimplemented';

@patch
bool typeofEquals<T>(Object? o, String type) =>
    JS<bool>('(o, t) => typeof o === t', jsifyRaw(o), jsifyRaw(type));

typedef _PromiseSuccessFunc = void Function(Object? value);
typedef _PromiseFailureFunc = void Function(Object? error);

@patch
Future<T> promiseToFuture<T>(Object jsPromise) {
  Completer<T> completer = Completer<T>();

  final success = ((JSAny? jsValue) {
    final r = dartifyRaw(jsValue.toExternRef);
    return completer.complete(r as FutureOr<T>?);
  }).toJS;
  final error = ((JSAny? jsError) {
    // Note that `completeError` expects a non-nullable error regardless of
    // whether null-safety is enabled, so a `NullRejectionException` is always
    // provided if the error is `null` or `undefined`.
    // TODO(joshualitt): At this point `undefined` has been replaced with `null`
    // so we cannot tell them apart. In the future we should reify `undefined`
    // in Dart.
    final e = dartifyRaw(jsError.toExternRef);
    if (e == null) {
      return completer.completeError(NullRejectionException(false));
    }
    return completer.completeError(e);
  }).toJS;

  promiseThen(jsifyRaw(jsPromise), success.toExternRef, error.toExternRef);
  return completer.future;
}

@patch
Object? objectGetPrototypeOf(Object? object) => throw 'unimplemented';

@patch
Object? get objectPrototype => throw 'unimplemented';

@patch
List<Object?> objectKeys(Object? o) =>
    dartifyRaw(JS<WasmExternRef?>('o => Object.keys(o)', jsifyRaw(o)))
        as List<Object?>;

@patch
Object? dartify(Object? object) {
  final convertedObjects = HashMap<Object?, Object?>.identity();
  Object? convert(Object? o) {
    if (convertedObjects.containsKey(o)) {
      return convertedObjects[o];
    }

    // Because [List] needs to be shallowly converted across the interop
    // boundary, we have to double check for the case where a shallowly
    // converted [List] is passed back into [dartify].
    if (o is List<Object?>) {
      final converted = <Object?>[];
      for (final item in o) {
        converted.add(convert(item));
      }
      return converted;
    }

    if (o is! JSValue) {
      return o;
    }

    WasmExternRef? ref = o.toExternRef;
    if (ref.isNull ||
        isJSBoolean(ref) ||
        isJSNumber(ref) ||
        isJSString(ref) ||
        isJSUndefined(ref) ||
        isJSBoolean(ref) ||
        isJSNumber(ref) ||
        isJSString(ref) ||
        isJSInt8Array(ref) ||
        isJSUint8Array(ref) ||
        isJSUint8ClampedArray(ref) ||
        isJSInt16Array(ref) ||
        isJSUint16Array(ref) ||
        isJSInt32Array(ref) ||
        isJSUint32Array(ref) ||
        isJSFloat32Array(ref) ||
        isJSFloat64Array(ref) ||
        isJSArrayBuffer(ref) ||
        isJSDataView(ref)) {
      return dartifyRaw(ref);
    }

    // TODO(joshualitt) handle Date and Promise.

    if (isJSSimpleObject(ref)) {
      final dartMap = <Object?, Object?>{};
      convertedObjects[o] = dartMap;
      // Keys will be a list of Dart [String]s.
      final keys = objectKeys(o);
      for (int i = 0; i < keys.length; i++) {
        final key = keys[i];
        if (key != null) {
          dartMap[key] =
              convert(JSValue.box(getPropertyRaw(ref, jsifyRaw(key))));
        }
      }
      return dartMap;
    } else if (isJSArray(ref)) {
      final dartList = <Object?>[];
      convertedObjects[o] = dartList;
      final length = getProperty<double>(o, 'length').toInt();
      for (int i = 0; i < length; i++) {
        dartList.add(convert(JSValue.box(objectReadIndex(ref, i))));
      }
      return dartList;
    } else {
      return dartifyRaw(ref);
    }
  }

  return convert(object);
}

/// This will be lowered to a a call to `_wrapDartCallback`.
@patch
F allowInterop<F extends Function>(F f) => throw UnimplementedError();

@patch
Function allowInteropCaptureThis(Function f) => throw UnimplementedError();
