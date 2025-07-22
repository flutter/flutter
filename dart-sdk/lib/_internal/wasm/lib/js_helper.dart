// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Helpers for working with JS.
library dart._js_helper;

import 'dart:_error_utils';
import 'dart:_internal';
import 'dart:_js_annotations' as js;
import 'dart:_js_types' as js_types;
import 'dart:_string';
import 'dart:_wasm';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

part 'regexp_helper.dart';

// TODO(joshualitt): After we have JS types and more efficient JS interop, we
// should be able to rewrite a significant amount of logic in this file and
// `js_runtime_blob` such that most of the conversion logic can live in Dart.
// TODO(joshualitt): In many places we use `WasmExternRef?` when the ref can't
// be null, we should use `WasmExternRef` in those cases.

/// [JSValue] is just a box [WasmExternRef?]. For now, it is the single box for
/// all JS types, but in time we may want to make each JS type a unique box
/// type.
class JSValue {
  final WasmExternRef? _ref;

  JSValue(this._ref);

  // This is currently only used in js_util.
  // TODO(joshualitt): Remove [box] and [unbox] once `JSNull` is boxed and users
  // have been migrated over to the helpers in `dart:js_interop`.
  static JSValue? box(WasmExternRef? ref) =>
      isDartNull(ref) ? null : JSValue(ref);

  static T boxT<T>(WasmExternRef? ref) => unsafeCastOpaque<T>(box(ref));

  // We need to handle the case of a nullable [JSValue] to match the semantics
  // of the JS backends.
  static WasmExternRef? unbox(JSValue? v) =>
      v == null ? WasmExternRef.nullRef : v._ref;

  @override
  bool operator ==(Object that) =>
      that is JSValue && areEqualInJS(_ref, that._ref);

  // Because [JSValue] is a subtype of [Object] it can be used in Dart
  // collections. Unfortunately, JS does not expose an efficient hash code
  // operation. To avoid surprising behavior, we force all [JSValue]s to fall
  // back to differentiation via equality, essentially making [Set] and [Map]
  // a regular linked list when the keys are [JSValue]. This behavior is not
  // intuitive.
  // TODO(joshualitt): There are a lot of different directions we can go, but
  // the most straightforward to expose `JSMap` and `JSSet` from JS for users
  // who need to efficiently manage JS objects in collections.
  @override
  int get hashCode => 0;

  @override
  String toString() => stringify(_ref);

  // Overrides to avoid using [ObjectToJS].
  WasmExternRef? get toExternRef => _ref;
}

// Extension helpers to convert to an externref.
// TODO(srujzs): We should rename these to `getAsExternRef` so they don't
// collide with instance members of box objects.

extension DoubleToExternRef on double? {
  WasmExternRef? get toExternRef =>
      this == null ? WasmExternRef.nullRef : toJSNumber(this!);
}

extension StringToExternRef on String? {
  WasmExternRef? get toExternRef =>
      this == null
          ? WasmExternRef.nullRef
          : jsStringFromDartString(this!).toExternRef;
}

extension JSValueToExternRef on JSValue? {
  WasmExternRef? get toExternRef => JSValue.unbox(this);
}

extension JSAnyToExternRef on JSAny? {
  WasmExternRef? get toExternRef => JSValue.unbox(this as JSValue?);
}

// For `dartify` and `jsify`, we match the conflation of `JSUndefined`, `JSNull`
// and `null`.
bool isDartNull(WasmExternRef? ref) => ref.isNull || isJSUndefined(ref);

class JSArrayIteratorAdapter<T> implements Iterator<T> {
  final JSArray array;
  int index = -1;

  JSArrayIteratorAdapter(this.array);

  @override
  bool moveNext() {
    index++;
    int length = array.length;
    if (index > length) {
      throw 'Iterator out of bounds';
    }
    return index < length;
  }

  @override
  T get current => dartifyRaw(array[index].toExternRef) as T;
}

/// [JSArrayIterableAdapter] lazily adapts a [JSArray] to Dart's [Iterable]
/// interface.
class JSArrayIterableAdapter<T> extends EfficientLengthIterable<T>
    implements HideEfficientLengthIterable<T> {
  final JSArray array;

  JSArrayIterableAdapter(this.array);

  @override
  Iterator<T> get iterator => JSArrayIteratorAdapter<T>(array);

  @override
  int get length => array.length;
}

Object jsObjectToDartObject(WasmExternRef? ref) =>
    unsafeCastOpaque<Object>(ref.internalize());

WasmExternRef jsObjectFromDartObject(Object object) =>
    unsafeCastOpaque<WasmAnyRef>(object).externalize();

bool isJSUndefined(WasmExternRef? o) => JS<bool>('o => o === undefined', o);

bool isJSFunction(WasmExternRef? o) =>
    JS<bool>("o => typeof o === 'function'", o);

bool isJSWrappedDartFunction(WasmExternRef? o) => JS<bool>(
  "o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true",
  o,
);

bool isJSObject(WasmExternRef? o) => JS<bool>("o => o instanceof Object", o);

bool isJSSimpleObject(WasmExternRef? o) => JS<bool>("""o => {
            const proto = Object.getPrototypeOf(o);
            return proto === Object.prototype || proto === null;
          }""", o);

bool isJSRegExp(WasmExternRef? o) => JS<bool>("o => o instanceof RegExp", o);

bool areEqualInJS(WasmExternRef? l, WasmExternRef? r) =>
    JS<bool>("(l, r) => l === r", l, r);

// The JS runtime will run helpful conversion routines between refs and bool /
// double. In the longer term hopefully we can find a way to avoid the round
// trip.
double toDartNumber(WasmExternRef? o) => JS<double>("o => o", o);

WasmExternRef? toJSNumber(double o) => JS<WasmExternRef?>("o => o", o);

bool toDartBool(WasmExternRef? o) => JS<bool>("o => o", o);

WasmExternRef? toJSBoolean(bool b) => JS<WasmExternRef?>("b => !!b", b);

int objectLength(WasmExternRef? o) =>
    JS<WasmI32>("o => o.length", o).toIntSigned();

int byteLength(WasmExternRef? o) =>
    JS<WasmI32>("o => o.byteLength", o).toIntSigned();

WasmExternRef? objectReadIndex(WasmExternRef? o, int index) =>
    JS<WasmExternRef?>("(o, i) => o[i]", o, index.toWasmI32());

Function unwrapJSWrappedDartFunction(WasmExternRef? f) =>
    JS<Function>("f => f.dartFunction", f);

external WasmExternRef jsInt8ArrayFromDartInt8List(Int8List l);

external WasmExternRef jsUint8ArrayFromDartUint8List(Uint8List l);

external WasmExternRef jsUint8ClampedArrayFromDartUint8ClampedList(
  Uint8ClampedList l,
);

external WasmExternRef jsInt16ArrayFromDartInt16List(Int16List l);

external WasmExternRef jsUint16ArrayFromDartUint16List(Uint16List l);

external WasmExternRef jsInt32ArrayFromDartInt32List(Int32List l);

external WasmExternRef jsUint32ArrayFromDartUint32List(Uint32List l);

external WasmExternRef jsFloat32ArrayFromDartFloat32List(Float32List l);

external WasmExternRef jsFloat64ArrayFromDartFloat64List(Float64List l);

external WasmExternRef jsDataViewFromDartByteData(ByteData data, int length);

WasmExternRef? _jsifyRawList(List<Object?> list) {
  final length = list.length;
  final result = JSArray<JSAny?>.withLength(length);
  for (int i = 0; i < length; i++) {
    result[i] = JSValue.box(jsifyRaw(list[i])) as JSAny?;
  }
  return (result as JSValue).toExternRef;
}

external JSStringImpl jsStringFromDartString(String s);

WasmExternRef? newObjectRaw() => JS<WasmExternRef?>('() => ({})');

WasmExternRef? newArrayRaw() => JS<WasmExternRef?>('() => []');

WasmExternRef? newArrayFromLengthRaw(int length) =>
    JS<WasmExternRef?>('l => new Array(l)', length.toWasmI32());

WasmExternRef? globalThisRaw() => JS<WasmExternRef?>('() => globalThis');

WasmExternRef? callConstructorVarArgsRaw(
  WasmExternRef? o,
  WasmExternRef? args,
) =>
// Apply bind to the constructor. We pass `null` as the first argument
// to `bind.apply` because this is `bind`'s unused context
// argument(`new` will explicitly create a new context).
JS<WasmExternRef?>(
  """(constructor, args) => {
      const factoryFunction = constructor.bind.apply(
          constructor, [null, ...args]);
      return new factoryFunction();
    }""",
  o,
  args,
);

bool hasPropertyRaw(WasmExternRef? o, WasmExternRef? p) =>
    JS<bool>("(o, p) => p in o", o, p);

WasmExternRef? getPropertyRaw(WasmExternRef? o, WasmExternRef? p) =>
    JS<WasmExternRef?>("(o, p) => o[p]", o, p);

WasmExternRef? setPropertyRaw(
  WasmExternRef? o,
  WasmExternRef? p,
  WasmExternRef? v,
) => JS<WasmExternRef?>("(o, p, v) => o[p] = v", o, p, v);

WasmExternRef? callMethodVarArgsRaw(
  WasmExternRef? o,
  WasmExternRef? method,
  WasmExternRef? args,
) => JS<WasmExternRef?>("(o, m, a) => o[m].apply(o, a)", o, method, args);

String typeof(WasmExternRef? object) =>
    JSStringImpl(JS<WasmExternRef?>("o => typeof o", object));

String stringify(WasmExternRef? object) =>
    JSStringImpl(JS<WasmExternRef?>("o => String(o)", object));

void promiseThen(
  WasmExternRef? promise,
  WasmExternRef? successFunc,
  WasmExternRef? failureFunc,
) => JS<void>("(p, s, f) => p.then(s, f)", promise, successFunc, failureFunc);

// Currently, `allowInterop` returns a Function type. This is unfortunate for
// Dart2wasm because it means arbitrary Dart functions can flow to JS util
// calls. Our only solutions is to cache every function called with
// `allowInterop` and to replace them with the wrapped variant when they flow
// to JS.
// NOTE: We are not currently replacing functions returned from JS.
final Map<Function, JSValue> functionToJSWrapper = Map.identity();

WasmExternRef? jsArrayBufferFromDartByteBuffer(ByteBuffer buffer) {
  ByteData byteData = ByteData.view(buffer);
  WasmExternRef? dataView = jsDataViewFromDartByteData(
    byteData,
    byteData.lengthInBytes,
  );
  return getPropertyRaw(dataView, 'buffer'.toExternRef);
}

WasmExternRef? jsifyRaw(Object? o) {
  if (o == null) return WasmExternRef.nullRef;
  if (o is bool) return toJSBoolean(o);
  if (o is num) return jsifyNum(o);
  if (o is JSValue) return jsifyJSValue(o);
  if (o is String) return jsifyString(o);
  if (o is js_types.JSArrayBase) {
    if (o is js_types.JSInt8ArrayImpl) return jsifyJSInt8ArrayImpl(o);
    if (o is js_types.JSUint8ArrayImpl) return jsifyJSUint8ArrayImpl(o);
    if (o is js_types.JSUint8ClampedArrayImpl) {
      return jsifyJSUint8ClampedArrayImpl(o);
    }
    if (o is js_types.JSInt16ArrayImpl) return jsifyJSInt16ArrayImpl(o);
    if (o is js_types.JSUint16ArrayImpl) return jsifyJSUint16ArrayImpl(o);
    if (o is js_types.JSInt32ArrayImpl) return jsifyJSInt32ArrayImpl(o);
    if (o is js_types.JSUint32ArrayImpl) return jsifyJSUint32ArrayImpl(o);
    if (o is js_types.JSFloat32ArrayImpl) return jsifyJSFloat32ArrayImpl(o);
    if (o is js_types.JSFloat64ArrayImpl) return jsifyJSFloat64ArrayImpl(o);
  } else if (o is TypedData) {
    if (o is Int8List) return jsInt8ArrayFromDartInt8List(o);
    if (o is Uint8List) return jsUint8ArrayFromDartUint8List(o);
    if (o is Uint8ClampedList) {
      return jsUint8ClampedArrayFromDartUint8ClampedList(o);
    }
    if (o is Int16List) return jsInt16ArrayFromDartInt16List(o);
    if (o is Uint16List) return jsUint16ArrayFromDartUint16List(o);
    if (o is Int32List) return jsInt32ArrayFromDartInt32List(o);
    if (o is Uint32List) return jsUint32ArrayFromDartUint32List(o);
    if (o is Float32List) return jsFloat32ArrayFromDartFloat32List(o);
    if (o is Float64List) return jsFloat64ArrayFromDartFloat64List(o);
    if (o is js_types.JSDataViewImpl) return jsifyJSDataViewImpl(o);
    if (o is ByteData) return jsifyByteData(o);
  } else if (o is List<Object?>) {
    return _jsifyRawList(o);
  } else if (o is ByteBuffer) {
    if (o is js_types.JSArrayBufferImpl) return jsifyJSArrayBufferImpl(o);
    return jsArrayBufferFromDartByteBuffer(o);
  } else if (o is Function) {
    return jsifyFunction(o);
  } else {
    return jsObjectFromDartObject(o);
  }
}

@pragma('wasm:prefer-inline')
WasmExternRef? jsifyInt(int o) => toJSNumber(o.toDouble());

@pragma('wasm:prefer-inline')
WasmExternRef? jsifyNum(num o) => toJSNumber(o.toDouble());

@pragma('wasm:prefer-inline')
WasmExternRef? jsifyJSValue(JSValue o) => o.toExternRef;

@pragma('wasm:prefer-inline')
WasmExternRef? jsifyString(String o) => jsStringFromDartString(o).toExternRef;

@pragma('wasm:prefer-inline')
WasmExternRef? jsifyJSInt8ArrayImpl(js_types.JSInt8ArrayImpl o) =>
    o.toJSArrayExternRef();

@pragma('wasm:prefer-inline')
WasmExternRef? jsifyJSUint8ArrayImpl(js_types.JSUint8ArrayImpl o) =>
    o.toJSArrayExternRef();

@pragma('wasm:prefer-inline')
WasmExternRef? jsifyJSUint8ClampedArrayImpl(
  js_types.JSUint8ClampedArrayImpl o,
) => o.toJSArrayExternRef();

@pragma('wasm:prefer-inline')
WasmExternRef? jsifyJSInt16ArrayImpl(js_types.JSInt16ArrayImpl o) =>
    o.toJSArrayExternRef();

@pragma('wasm:prefer-inline')
WasmExternRef? jsifyJSUint16ArrayImpl(js_types.JSUint16ArrayImpl o) =>
    o.toJSArrayExternRef();

@pragma('wasm:prefer-inline')
WasmExternRef? jsifyJSInt32ArrayImpl(js_types.JSInt32ArrayImpl o) =>
    o.toJSArrayExternRef();

@pragma('wasm:prefer-inline')
WasmExternRef? jsifyJSUint32ArrayImpl(js_types.JSUint32ArrayImpl o) =>
    o.toJSArrayExternRef();

@pragma('wasm:prefer-inline')
WasmExternRef? jsifyJSFloat32ArrayImpl(js_types.JSFloat32ArrayImpl o) =>
    o.toJSArrayExternRef();

@pragma('wasm:prefer-inline')
WasmExternRef? jsifyJSFloat64ArrayImpl(js_types.JSFloat64ArrayImpl o) =>
    o.toJSArrayExternRef();

@pragma('wasm:prefer-inline')
WasmExternRef? jsifyJSDataViewImpl(js_types.JSDataViewImpl o) => o.toExternRef;

@pragma('wasm:prefer-inline')
WasmExternRef? jsifyJSArrayBufferImpl(js_types.JSArrayBufferImpl o) =>
    o.toExternRef;

@pragma('wasm:prefer-inline')
WasmExternRef? jsifyByteData(ByteData o) =>
    jsDataViewFromDartByteData(o, o.lengthInBytes);

@pragma('wasm:prefer-inline')
WasmExternRef? jsifyFunction(Function o) {
  assert(
    functionToJSWrapper.containsKey(o),
    'Must call `allowInterop` on functions before they flow to JS',
  );
  return functionToJSWrapper[o]!.toExternRef;
}

bool isWasmGCStruct(WasmExternRef? ref) => ref.internalize()?.isObject ?? false;

/// Container class for constants that represent the possible types of a
/// [WasmExternRef] that can then be used in a [dartifyRaw] call.
///
/// The values within this class should correspond to the values returned by
/// [externRefType] and should be updated if that function is updated. Constants
/// are preferred over enums for performance.
class ExternRefType {
  static const int null_ = 0;
  static const int undefined = 1;
  static const int boolean = 2;
  static const int number = 3;
  static const int string = 4;
  static const int array = 5;
  static const int int8Array = 6;
  static const int uint8Array = 7;
  static const int uint8ClampedArray = 8;
  static const int int16Array = 9;
  static const int uint16Array = 10;
  static const int int32Array = 11;
  static const int uint32Array = 12;
  static const int float32Array = 13;
  static const int float64Array = 14;
  static const int dataView = 15;
  static const int arrayBuffer = 16;
  static const int unknown = 17;
}

/// Returns an integer representing the type of [ref] that corresponds to one of
/// the constant values in [ExternRefType].
///
/// If this function is updated to return different values, [ExternRefType]
/// should be updated as well.
int externRefType(WasmExternRef? ref) {
  if (ref.isNull) return ExternRefType.null_;
  final val =
      JS<WasmI32>('''
  o => {
    if (o === undefined) return 1;
    var type = typeof o;
    if (type === 'boolean') return 2;
    if (type === 'number') return 3;
    if (type === 'string') return 4;
    if (o instanceof Array) return 5;
    if (ArrayBuffer.isView(o)) {
      if (o instanceof Int8Array) return 6;
      if (o instanceof Uint8Array) return 7;
      if (o instanceof Uint8ClampedArray) return 8;
      if (o instanceof Int16Array) return 9;
      if (o instanceof Uint16Array) return 10;
      if (o instanceof Int32Array) return 11;
      if (o instanceof Uint32Array) return 12;
      if (o instanceof Float32Array) return 13;
      if (o instanceof Float64Array) return 14;
      if (o instanceof DataView) return 15;
    }
    if (o instanceof ArrayBuffer) return 16;
    return 17;
  }
  ''', ref).toIntUnsigned();
  return val;
}

/// Non-recursively converts [ref] from a JS value to a Dart value for some JS
/// types.
///
/// If [refType] is not null, it is treated as one of the values from
/// [ExternRefType]. Otherwise, this method calls [externRefType] to determine
/// the right [ExternRefType].
Object? dartifyRaw(WasmExternRef? ref, [int? refType]) {
  refType ??= externRefType(ref);
  return switch (refType) {
    ExternRefType.null_ || ExternRefType.undefined => null,
    ExternRefType.boolean => toDartBool(ref),
    ExternRefType.number => toDartNumber(ref),
    ExternRefType.string => JSStringImpl.box(ref),
    ExternRefType.array => toDartList(ref),
    ExternRefType.int8Array => js_types.JSInt8ArrayImpl.fromJSArray(ref),
    ExternRefType.uint8Array => js_types.JSUint8ArrayImpl.fromJSArray(ref),
    ExternRefType.uint8ClampedArray => js_types
        .JSUint8ClampedArrayImpl.fromJSArray(ref),
    ExternRefType.int16Array => js_types.JSInt16ArrayImpl.fromJSArray(ref),
    ExternRefType.uint16Array => js_types.JSUint16ArrayImpl.fromJSArray(ref),
    ExternRefType.int32Array => js_types.JSInt32ArrayImpl.fromJSArray(ref),
    ExternRefType.uint32Array => js_types.JSUint32ArrayImpl.fromJSArray(ref),
    ExternRefType.float32Array => js_types.JSFloat32ArrayImpl.fromJSArray(ref),
    ExternRefType.float64Array => js_types.JSFloat64ArrayImpl.fromJSArray(ref),
    ExternRefType.arrayBuffer => js_types.JSArrayBufferImpl.fromRef(ref),
    ExternRefType.dataView => js_types.JSDataViewImpl.fromRef(ref),
    ExternRefType.unknown =>
      isJSWrappedDartFunction(ref)
          ? unwrapJSWrappedDartFunction(ref)
          : isWasmGCStruct(ref)
          ? jsObjectToDartObject(ref)
          : JSValue(ref),
    _ => () {
      // Assert that we've handled everything in the range.
      assert(refType! >= 0 && refType >= ExternRefType.unknown);
      throw 'Unhandled dartifyRaw type case: $refType';
    }(),
  };
}

List<double> jsFloatTypedArrayToDartFloatTypedData(
  WasmExternRef? ref,
  List<double> makeTypedData(int size),
) {
  int length = objectLength(ref);
  List<double> list = makeTypedData(length);
  for (int i = 0; i < length; i++) {
    list[i] = toDartNumber(objectReadIndex(ref, i));
  }
  return list;
}

List<int> jsIntTypedArrayToDartIntTypedData(
  WasmExternRef? ref,
  List<int> makeTypedData(int size),
) {
  int length = objectLength(ref);
  List<int> list = makeTypedData(length);
  for (int i = 0; i < length; i++) {
    list[i] = toDartNumber(objectReadIndex(ref, i)).toInt();
  }
  return list;
}

JSArray<T> toJSArray<T extends JSAny?>(List<T> list) {
  final length = list.length;

  if (length <= 4) {
    if (length == 0) {
      return JSArray<T>.withLength(0);
    }
    final list0 = list[0].toExternRef;
    if (length == 1) {
      return JSValue(JS<WasmExternRef>("o => [o]", list0)) as JSArray<T>;
    }
    final list1 = list[1].toExternRef;
    if (length == 2) {
      return JSValue(JS<WasmExternRef>("(o0, o1) => [o0, o1]", list0, list1))
          as JSArray<T>;
    }
    final list2 = list[2].toExternRef;
    if (length == 3) {
      return JSValue(
            JS<WasmExternRef>(
              "(o0, o1, o2) => [o0, o1, o2]",
              list0,
              list1,
              list2,
            ),
          )
          as JSArray<T>;
    }
    final list3 = list[3].toExternRef;
    if (length == 4) {
      return JSValue(
            JS<WasmExternRef>(
              "(o0, o1, o2, o3) => [o0, o1, o2, o3]",
              list0,
              list1,
              list2,
              list3,
            ),
          )
          as JSArray<T>;
    }
  }

  JSArray<T> result = JSArray<T>.withLength(length);
  for (int i = 0; i < length; i++) {
    result[i] = list[i];
  }
  return result;
}

List<Object?> toDartList(WasmExternRef? ref) => List<Object?>.generate(
  objectLength(ref),
  (int n) => dartifyRaw(objectReadIndex(ref, n)),
);

// These two trivial helpers are needed to work around an issue with tearing off
// functions that take / return [WasmExternRef].
bool _isDartFunctionWrapped<F extends Function>(F f) =>
    functionToJSWrapper.containsKey(f);

F _wrapDartFunction<F extends Function>(F f, WasmExternRef ref) {
  functionToJSWrapper[f] = JSValue(ref);
  return f;
}

/// Takes a [codeTemplate] string which must represent a valid JS function, and
/// a list of optional arguments. The [codeTemplate] will be inserted into the
/// JS runtime, and the call to [JS] will be replaced by a call to an external
/// static method stub that imports the JS function.
///
/// We will replace the enclosing procedure itself if:
///   1) The enclosing procedure is static.
///   2) The enclosing procedure has a body with a single statement, and that
///      statement is just the `StaticInvocation` of [JS] itself.
///   3) All of the arguments to [JS] are `VariableGet`s.
external T JS<T>(
  String codeTemplate, [
  arg0,
  arg1,
  arg2,
  arg3,
  arg4,
  arg5,
  arg6,
  arg7,
  arg8,
  arg9,
  arg10,
  arg11,
  arg12,
  arg13,
  arg14,
  arg51,
  arg16,
  arg17,
  arg18,
  arg19,
]);
