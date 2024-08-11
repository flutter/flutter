// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show patch;
import 'dart:_js_helper' as js_helper;
import 'dart:_js_helper' hide JS;
import 'dart:_js_types' as js_types;
import 'dart:_string';
import 'dart:_wasm';
import 'dart:async' show Completer;
import 'dart:js_interop';
import 'dart:js_interop_unsafe' as unsafe;
import 'dart:js_util' as js_util;
import 'dart:typed_data';

@patch
js_types.JSObjectRepType _createObjectLiteral() =>
    JSValue(js_helper.newObjectRaw());

// This should match the global context we use in our static interop lowerings.
@patch
JSObject get globalContext => js_util.globalThis as JSObject;

// Helper for working with the JSAny? top type in a backend agnostic way.
@patch
extension NullableUndefineableJSAnyExtension on JSAny? {
  // TODO(joshualitt): To support incremental migration of existing users to
  // reified `JSUndefined` and `JSNull`, we have to handle the case where
  // `this == null`. However, after migration we can remove these checks.
  @patch
  bool get isUndefined =>
      throw UnimplementedError("JS 'null' and 'undefined' are internalized as "
          "Dart null in dart2wasm. As such, they can not be differentiated and "
          "this API should not be used when compiling to Wasm.");

  @patch
  bool get isNull =>
      throw UnimplementedError("JS 'null' and 'undefined' are internalized as "
          "Dart null in dart2wasm. As such, they can not be differentiated and "
          "this API should not be used when compiling to Wasm.");
}

@patch
extension JSAnyUtilityExtension on JSAny? {
  @patch
  bool typeofEquals(String type) => js_helper
      .JS<WasmI32>(
          '(o, t) => typeof o === t', this.toExternRef, type.toJS.toExternRef)
      .toBool();

  @patch
  bool instanceof(JSFunction constructor) => js_helper
      .JS<WasmI32>(
          '(o, c) => o instanceof c', toExternRef, constructor.toExternRef)
      .toBool();

  @patch
  bool isA<T>() => throw UnimplementedError(
      "This should never be called. Calls to 'isA' should have been "
      'transformed by the interop transformer.');

  @patch
  Object? dartify() => js_util.dartify(this);
}

// Utility extensions for Object?.
@patch
extension NullableObjectUtilExtension on Object? {
  @patch
  JSAny? jsify() => js_util.jsify(this);
}

// -----------------------------------------------------------------------------
// JSExportedDartFunction <-> Function
@patch
extension JSExportedDartFunctionToFunction on JSExportedDartFunction {
  @patch
  Function get toDart {
    final ref = toExternRef;
    if (!js_helper.isJSWrappedDartFunction(ref)) {
      throw 'Expected JS wrapped function, but got type '
          '${js_helper.typeof(ref)}.';
    }
    return unwrapJSWrappedDartFunction(ref);
  }
}

@patch
extension FunctionToJSExportedDartFunction on Function {
  @patch
  JSExportedDartFunction get toJS => throw UnimplementedError(
      "This should never be called. Calls to 'toJS' should have been "
      'transformed by the interop transformer.');
}

// Embedded global property for wrapped Dart objects passed via JS interop.
//
// This is a Symbol so that different Dart applications don't share Dart
// objects from different Dart runtimes. We expect all JSBoxedDartObjects to
// have this Symbol.
final JSSymbol _jsBoxedDartObjectProperty = JSSymbol._(JSValue(
    js_helper.JS<WasmExternRef?>('() => Symbol("jsBoxedDartObjectProperty")')));

// -----------------------------------------------------------------------------
// JSBoxedDartObject <-> Object
@patch
extension JSBoxedDartObjectToObject on JSBoxedDartObject {
  @patch
  Object get toDart {
    final val = js_helper.JS<WasmExternRef?>('(o,s) => o[s]', this.toExternRef,
        _jsBoxedDartObjectProperty.toExternRef);
    if (isDartNull(val)) {
      throw 'Expected a wrapped Dart object, but got a JS object or a wrapped '
          'Dart object from a separate runtime instead.';
    }
    return jsObjectToDartObject(val);
  }
}

@patch
extension ObjectToJSBoxedDartObject on Object {
  @patch
  JSBoxedDartObject get toJSBox {
    if (this is JSValue) {
      throw 'Attempting to box non-Dart object.';
    }
    final box = JSObject();
    js_helper.JS<WasmExternRef?>('(o,s,v) => o[s] = v', box.toExternRef,
        _jsBoxedDartObjectProperty.toExternRef, jsObjectFromDartObject(this));
    return JSBoxedDartObject._(box._jsObject);
  }
}

// -----------------------------------------------------------------------------
// ExternalDartReference <-> Object
@patch
extension ExternalDartReferenceToObject<T extends Object?>
    on ExternalDartReference<T> {
  @patch
  T get toDartObject {
    // TODO(srujzs): We could do an `unsafeCast` here for performance, but
    // that can result in unsoundness for users. Alternatively, we can
    // introduce a generic version of `JSValue` which would allow us to safely
    // `unsafeCast`. However, this has its own issues where a user can't
    // do casts like `ExternalDartReference<Object> as
    // ExternalDartReference<int>` since `JSValue<Object>` is not a subtype of
    // `JSValue<int>`, even though it may be valid to do such a cast.
    final t = this._externalDartReference;
    return (t == null ? null : jsObjectToDartObject(t.toExternRef)) as T;
  }
}

@patch
extension ObjectToExternalDartReference<T extends Object?> on T {
  @patch
  ExternalDartReference<T> get toExternalReference {
    final t = this;
    return ExternalDartReference<T>._(
        t == null ? null : JSValue(jsObjectFromDartObject(t)));
  }
}

// JSPromise -> Future
@patch
extension JSPromiseToFuture<T extends JSAny?> on JSPromise<T> {
  @patch
  Future<T> get toDart {
    final completer = Completer<T>();
    final success = (JSAny? r) {
      // Note that we explicitly type the parameter as `JSAny?` instead of `T`.
      // This is because if there's a `TypeError` with the cast, we want to
      // bubble that up through the completer, so we end up doing a try-catch
      // here to do so.
      try {
        final value = r as T;
        completer.complete(value);
      } catch (e) {
        completer.completeError(e);
      }
    }.toJS;
    final error = (JSAny? e) {
      // TODO(joshualitt): Investigate reifying `JSNull` and `JSUndefined` on
      // all backends and if it is feasible, or feasible for some limited use
      // cases, then we should pass [e] directly to `completeError`.
      // TODO(joshualitt): Use helpers to avoid conflating `null` and `JSNull` /
      // `JSUndefined`.
      if (e == null) {
        // Note that we pass false as a default. It's not currently possible to
        // be able to differentiate between null and undefined.
        completer.completeError(js_util.NullRejectionException(false));
        return;
      }
      completer.completeError(e);
    }.toJS;
    promiseThen(toExternRef, success.toExternRef, error.toExternRef);
    return completer.future;
  }
}

// -----------------------------------------------------------------------------
// JSArrayBuffer <-> ByteBuffer
@patch
extension JSArrayBufferToByteBuffer on JSArrayBuffer {
  @patch
  ByteBuffer get toDart => js_types.JSArrayBufferImpl.fromRef(toExternRef);
}

@patch
extension ByteBufferToJSArrayBuffer on ByteBuffer {
  // Note: While this general style of 'test for JS backed subtype' is quite
  // common, we still specialize each case to avoid a genric `is` check.
  @patch
  JSArrayBuffer get toJS {
    final t = this;
    return JSArrayBuffer._(JSValue(t is js_types.JSArrayBufferImpl
        ? t.toExternRef
        : jsArrayBufferFromDartByteBuffer(t)));
  }
}

// -----------------------------------------------------------------------------
// JSDataView <-> ByteData
@patch
extension JSDataViewToByteData on JSDataView {
  @patch
  ByteData get toDart => js_types.JSDataViewImpl.fromRef(toExternRef);
}

@patch
extension ByteDataToJSDataView on ByteData {
  @patch
  JSDataView get toJS {
    final t = this;
    return JSDataView._(JSValue(t is js_types.JSDataViewImpl
        ? t.toExternRef
        : jsDataViewFromDartByteData(t, lengthInBytes)));
  }
}

// -----------------------------------------------------------------------------
// JSInt8Array <-> Int8List
@patch
extension JSInt8ArrayToInt8List on JSInt8Array {
  @patch
  Int8List get toDart => js_types.JSInt8ArrayImpl.fromJSArray(toExternRef);
}

@patch
extension Int8ListToJSInt8Array on Int8List {
  @patch
  JSInt8Array get toJS {
    final t = this;
    return JSInt8Array._(JSValue(t is js_types.JSInt8ArrayImpl
        ? t.toJSArrayExternRef()
        : jsInt8ArrayFromDartInt8List(t)));
  }
}

// -----------------------------------------------------------------------------
// JSUint8Array <-> Uint8List
@patch
extension JSUint8ArrayToUint8List on JSUint8Array {
  @patch
  Uint8List get toDart => js_types.JSUint8ArrayImpl.fromJSArray(toExternRef);
}

@patch
extension Uint8ListToJSUint8Array on Uint8List {
  @patch
  JSUint8Array get toJS {
    final t = this;
    return JSUint8Array._(JSValue(t is js_types.JSUint8ArrayImpl
        ? t.toJSArrayExternRef()
        : jsUint8ArrayFromDartUint8List(t)));
  }
}

// -----------------------------------------------------------------------------
// JSUint8ClampedArray <-> Uint8ClampedList
@patch
extension JSUint8ClampedArrayToUint8ClampedList on JSUint8ClampedArray {
  @patch
  Uint8ClampedList get toDart =>
      js_types.JSUint8ClampedArrayImpl.fromJSArray(toExternRef);
}

@patch
extension Uint8ClampedListToJSUint8ClampedArray on Uint8ClampedList {
  @patch
  JSUint8ClampedArray get toJS {
    final t = this;
    return JSUint8ClampedArray._(JSValue(t is js_types.JSUint8ClampedArrayImpl
        ? t.toJSArrayExternRef()
        : jsUint8ClampedArrayFromDartUint8ClampedList(t)));
  }
}

// -----------------------------------------------------------------------------
// JSInt16Array <-> Int16List
@patch
extension JSInt16ArrayToInt16List on JSInt16Array {
  @patch
  Int16List get toDart => js_types.JSInt16ArrayImpl.fromJSArray(toExternRef);
}

@patch
extension Int16ListToJSInt16Array on Int16List {
  @patch
  JSInt16Array get toJS {
    final t = this;
    return JSInt16Array._(JSValue(t is js_types.JSInt16ArrayImpl
        ? t.toJSArrayExternRef()
        : jsInt16ArrayFromDartInt16List(t)));
  }
}

// -----------------------------------------------------------------------------
// JSUint16Array <-> Uint16List
@patch
extension JSUint16ArrayToInt16List on JSUint16Array {
  @patch
  Uint16List get toDart => js_types.JSUint16ArrayImpl.fromJSArray(toExternRef);
}

@patch
extension Uint16ListToJSInt16Array on Uint16List {
  @patch
  JSUint16Array get toJS {
    final t = this;
    return JSUint16Array._(JSValue(t is js_types.JSUint16ArrayImpl
        ? t.toJSArrayExternRef()
        : jsUint16ArrayFromDartUint16List(t)));
  }
}

// -----------------------------------------------------------------------------
// JSInt32Array <-> Int32List
@patch
extension JSInt32ArrayToInt32List on JSInt32Array {
  @patch
  Int32List get toDart => js_types.JSInt32ArrayImpl.fromJSArray(toExternRef);
}

@patch
extension Int32ListToJSInt32Array on Int32List {
  @patch
  JSInt32Array get toJS {
    final t = this;
    return JSInt32Array._(JSValue(t is js_types.JSInt32ArrayImpl
        ? t.toJSArrayExternRef()
        : jsInt32ArrayFromDartInt32List(t)));
  }
}

// -----------------------------------------------------------------------------
// JSUint32Array <-> Uint32List
@patch
extension JSUint32ArrayToUint32List on JSUint32Array {
  @patch
  Uint32List get toDart => js_types.JSUint32ArrayImpl.fromJSArray(toExternRef);
}

@patch
extension Uint32ListToJSUint32Array on Uint32List {
  @patch
  JSUint32Array get toJS {
    final t = this;
    return JSUint32Array._(JSValue(t is js_types.JSUint32ArrayImpl
        ? t.toJSArrayExternRef()
        : jsUint32ArrayFromDartUint32List(t)));
  }
}

// -----------------------------------------------------------------------------
// JSFloat32Array <-> Float32List
@patch
extension JSFloat32ArrayToFloat32List on JSFloat32Array {
  @patch
  Float32List get toDart =>
      js_types.JSFloat32ArrayImpl.fromJSArray(toExternRef);
}

@patch
extension Float32ListToJSFloat32Array on Float32List {
  @patch
  JSFloat32Array get toJS {
    final t = this;
    return JSFloat32Array._(JSValue(t is js_types.JSFloat32ArrayImpl
        ? t.toJSArrayExternRef()
        : jsFloat32ArrayFromDartFloat32List(t)));
  }
}

// -----------------------------------------------------------------------------
// JSFloat64Array <-> Float64List
@patch
extension JSFloat64ArrayToFloat64List on JSFloat64Array {
  @patch
  Float64List get toDart =>
      js_types.JSFloat64ArrayImpl.fromJSArray(toExternRef);
}

@patch
extension Float64ListToJSFloat64Array on Float64List {
  @patch
  JSFloat64Array get toJS {
    final t = this;
    return JSFloat64Array._(JSValue(t is js_types.JSFloat64ArrayImpl
        ? t.toJSArrayExternRef()
        : jsFloat64ArrayFromDartFloat64List(t)));
  }
}

// -----------------------------------------------------------------------------
// JSArray <-> List
@patch
extension JSArrayToList<T extends JSAny?> on JSArray<T> {
  @patch
  List<T> get toDart => js_types.JSArrayImpl<T>(toExternRef);
}

@patch
extension ListToJSArray<T extends JSAny?> on List<T> {
  JSArray<T>? get _underlyingArray {
    final t = this;
    return t is js_types.JSArrayImpl
        // Explicit cast to avoid using the extension method.
        ? JSArray<T>._(JSValue((t as js_types.JSArrayImpl).toExternRef))
        : null;
  }

  @patch
  JSArray<T> get toJS => _underlyingArray ?? toJSArray<T>(this);

  @patch
  JSArray<T> get toJSProxyOrRef =>
      _underlyingArray ?? _createJSProxyOfList<T>(this);
}

// -----------------------------------------------------------------------------
// JSNumber -> double or int
@patch
extension JSNumberToNumber on JSNumber {
  @patch
  double get toDartDouble => toDartNumber(toExternRef);

  @patch
  int get toDartInt {
    final number = toDartNumber(toExternRef);
    final intVal = number.toInt();
    if (number == intVal) {
      return intVal;
    } else {
      throw 'Expected integer value, but was not integer.';
    }
  }
}

@patch
extension DoubleToJSNumber on double {
  @patch
  JSNumber get toJS => JSNumber._(JSValue(toJSNumber(this)));
}

// -----------------------------------------------------------------------------
// JSBoolean <-> bool
@patch
extension JSBooleanToBool on JSBoolean {
  @patch
  bool get toDart => toDartBool(toExternRef);
}

@patch
extension BoolToJSBoolean on bool {
  @patch
  JSBoolean get toJS => JSBoolean._(JSValue(toJSBoolean(this)));
}

// -----------------------------------------------------------------------------
// JSString <-> String
@patch
extension JSStringToString on JSString {
  @patch
  String get toDart => JSStringImpl(toExternRef);
}

@patch
extension StringToJSString on String {
  @patch
  JSString get toJS {
    final t = this;
    return JSString._(JSValue(
        (t is JSStringImpl ? t : jsStringFromDartString(t)).toExternRef));
  }
}

@patch
extension JSAnyOperatorExtension on JSAny? {
  @patch
  JSAny add(JSAny? any) => JSAny._(JSValue(js_helper.JS<WasmExternRef?>(
      '(o, a) => o + a', this.toExternRef, any.toExternRef)));

  @patch
  JSAny subtract(JSAny? any) => JSAny._(JSValue(js_helper.JS<WasmExternRef?>(
      '(o, a) => o - a', this.toExternRef, any.toExternRef)));

  @patch
  JSAny multiply(JSAny? any) => JSAny._(JSValue(js_helper.JS<WasmExternRef?>(
      '(o, a) => o * a', this.toExternRef, any.toExternRef)));

  @patch
  JSAny divide(JSAny? any) => JSAny._(JSValue(js_helper.JS<WasmExternRef?>(
      '(o, a) => o / a', this.toExternRef, any.toExternRef)));

  @patch
  JSAny modulo(JSAny? any) => JSAny._(JSValue(js_helper.JS<WasmExternRef?>(
      '(o, a) => o % a', this.toExternRef, any.toExternRef)));

  @patch
  JSAny exponentiate(JSAny? any) =>
      JSAny._(JSValue(js_helper.JS<WasmExternRef?>(
          '(o, a) => o ** a', this.toExternRef, any.toExternRef)));

  @patch
  JSBoolean greaterThan(JSAny? any) =>
      JSBoolean._(JSValue(js_helper.JS<WasmExternRef?>(
          '(o, a) => o > a', this.toExternRef, any.toExternRef)));

  @patch
  JSBoolean greaterThanOrEqualTo(JSAny? any) =>
      JSBoolean._(JSValue(js_helper.JS<WasmExternRef?>(
          '(o, a) => o >= a', this.toExternRef, any.toExternRef)));

  @patch
  JSBoolean lessThan(JSAny? any) =>
      JSBoolean._(JSValue(js_helper.JS<WasmExternRef?>(
          '(o, a) => o < a', this.toExternRef, any.toExternRef)));

  @patch
  JSBoolean lessThanOrEqualTo(JSAny? any) =>
      JSBoolean._(JSValue(js_helper.JS<WasmExternRef?>(
          '(o, a) => o <= a', this.toExternRef, any.toExternRef)));

  @patch
  JSBoolean equals(JSAny? any) =>
      JSBoolean._(JSValue(js_helper.JS<WasmExternRef?>(
          '(o, a) => o == a', this.toExternRef, any.toExternRef)));

  @patch
  JSBoolean notEquals(JSAny? any) =>
      JSBoolean._(JSValue(js_helper.JS<WasmExternRef?>(
          '(o, a) => o != a', this.toExternRef, any.toExternRef)));

  @patch
  JSBoolean strictEquals(JSAny? any) =>
      JSBoolean._(JSValue(js_helper.JS<WasmExternRef?>(
          '(o, a) => o === a', this.toExternRef, any.toExternRef)));

  @patch
  JSBoolean strictNotEquals(JSAny? any) =>
      JSBoolean._(JSValue(js_helper.JS<WasmExternRef?>(
          '(o, a) => o !== a', this.toExternRef, any.toExternRef)));

  @patch
  JSNumber unsignedRightShift(JSAny? any) =>
      JSNumber._(JSValue(js_helper.JS<WasmExternRef?>(
          '(o, a) => o >>> a', this.toExternRef, any.toExternRef)));

  @patch
  JSAny? and(JSAny? any) => JSValue.box(js_helper.JS<WasmExternRef?>(
      '(o, a) => o && a', this.toExternRef, any.toExternRef)) as JSAny?;

  @patch
  JSAny? or(JSAny? any) => JSValue.box(js_helper.JS<WasmExternRef?>(
      '(o, a) => o || a', this.toExternRef, any.toExternRef)) as JSAny?;

  @patch
  JSBoolean get not => JSBoolean._(
      JSValue(js_helper.JS<WasmExternRef?>('(o) => !o', this.toExternRef)));

  @patch
  JSBoolean get isTruthy => JSBoolean._(
      JSValue(js_helper.JS<WasmExternRef?>('(o) => !!o', this.toExternRef)));
}

@patch
JSPromise<JSObject> importModule(JSAny moduleName) =>
    JSPromise<JSObject>._(JSValue(js_helper.JS<WasmExternRef?>(
        '(m) => import(m)', moduleName.toExternRef)));

@JS('Array')
@staticInterop
class _Array {
  external static JSObject get prototype;
}

@JS('Symbol')
@staticInterop
class _Symbol {
  external static JSSymbol get isConcatSpreadable;
}

// Used only so we can use `createStaticInteropMock`'s prototype-setting.
@JS()
@staticInterop
class __ListBackedJSArray {}

// Implementation of indexing, `length`, and core handler methods.
//
// JavaScript's `Array` methods are similar to Dart's `ListMixin`, because they
// only rely on the implementation of `length` and indexing methods (and
// support for any JS operators like `in` or `delete`).
// https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array#generic_array_methods
class _ListBackedJSArray {
  final List<JSAny?> _list;
  // The proxy that wraps this list.
  late final JSArray proxy;

  _ListBackedJSArray(this._list);

  @JSExport()
  int get length => _list.length;

  // TODO(srujzs): Resizing the list populates the list with `null`. Should we
  // instead populate it with `undefined` as JS does?
  @JSExport()
  void set length(int val) => _list.length = val;

  // []
  @JSExport()
  JSAny? _getIndex(int index) => _list[index];

  // []=
  @JSExport()
  void _setIndex(int index, JSAny? value) {
    // Need to resize the array if out of bounds.
    if (index >= length) length = index + 1;
    _list[index] = value;
  }

  // in
  @JSExport()
  bool _hasIndex(int index) => index >= 0 && index < length;

  // delete
  @JSExport()
  bool _deleteIndex(int index) {
    if (_hasIndex(index)) {
      _list.removeAt(index);
      return true;
    }
    return false;
  }
}

JSArray<T> _createJSProxyOfList<T extends JSAny?>(List<T> list) {
  final wrapper = _ListBackedJSArray(list);
  final jsExportWrapper =
      js_util.createStaticInteropMock<__ListBackedJSArray, _ListBackedJSArray>(
          wrapper, _Array.prototype) as JSObject;

  // Needed for `concat` to spread the contents of the current array instead of
  // prepending.
  // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Symbol/isConcatSpreadable
  jsExportWrapper.setProperty(_Symbol.isConcatSpreadable, true.toJS);

  final getIndex = jsExportWrapper['_getIndex']!.toExternRef;
  final setIndex = jsExportWrapper['_setIndex']!.toExternRef;
  final hasIndex = jsExportWrapper['_hasIndex']!.toExternRef;
  final deleteIndex = jsExportWrapper['_deleteIndex']!.toExternRef;

  final proxy = JSArray<T>._(JSValue(js_helper.JS<WasmExternRef?>('''
    (wrapper, getIndex, setIndex, hasIndex, deleteIndex) => new Proxy(wrapper, {
      'get': function (target, prop, receiver) {
        if (typeof prop == 'string') {
          const numProp = Number(prop);
          if (Number.isInteger(numProp)) {
            const args = new Array();
            args.push(numProp);
            return Reflect.apply(getIndex, wrapper, args);
          }
        }
        return Reflect.get(target, prop, receiver);
      },
      'set': function (target, prop, value, receiver) {
        if (typeof prop == 'string') {
          const numProp = Number(prop);
          if (Number.isInteger(numProp)) {
            const args = new Array();
            args.push(numProp, value);
            Reflect.apply(setIndex, wrapper, args);
            return true;
          }
        }
        // Note that handler set is required to return a bool (whether it
        // succeeded or not), so `[]=` won't return the value set.
        return Reflect.set(target, prop, value, receiver);
      },
      'has': function (target, prop) {
        if (typeof prop == 'string') {
          const numProp = Number(prop);
          if (Number.isInteger(numProp)) {
            const args = new Array();
            args.push(numProp);
            // Array-like objects are assumed to have indices as properties.
            return Reflect.apply(hasIndex, wrapper, args);
          }
        }
        return Reflect.has(target, prop);
      },
      'deleteProperty': function (target, prop) {
        if (typeof prop == 'string') {
          const numProp = Number(prop);
          if (Number.isInteger(numProp)) {
            const args = new Array();
            args.push(numProp);
            return Reflect.apply(deleteIndex, wrapper, args);
          }
        }
        return Reflect.deleteProperty(target, prop);
      }
    })''', jsExportWrapper.toExternRef, getIndex, setIndex, hasIndex,
      deleteIndex)));
  wrapper.proxy = proxy;
  return proxy;
}
