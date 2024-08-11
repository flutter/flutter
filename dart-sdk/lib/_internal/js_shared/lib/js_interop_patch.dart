// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_foreign_helper' as foreign_helper;
import 'dart:_interceptors' show JavaScriptObject;
import 'dart:_internal' show patch;
import 'dart:_js_helper' show createObjectLiteral, staticInteropGlobalContext;
import 'dart:_js_types';
import 'dart:js_interop';
import 'dart:js_util' as js_util;
import 'dart:typed_data';

@patch
JSObjectRepType _createObjectLiteral() =>
    createObjectLiteral<JSObjectRepType>();

@patch
@pragma('dart2js:prefer-inline')
JSObject get globalContext => staticInteropGlobalContext as JSObject;

// Helper for working with the JSAny? top type in a backend agnostic way.
@patch
extension NullableUndefineableJSAnyExtension on JSAny? {
  @patch
  @pragma('dart2js:prefer-inline')
  bool get isUndefined => typeofEquals('undefined');

  @patch
  @pragma('dart2js:prefer-inline')
  bool get isNull => foreign_helper.JS('bool', '# === null', this);
}

@patch
extension JSAnyUtilityExtension on JSAny? {
  @patch
  @pragma('dart2js:prefer-inline')
  bool typeofEquals(String typeString) =>
      foreign_helper.JS('bool', 'typeof # === #', this, typeString);

  @patch
  @pragma('dart2js:prefer-inline')
  bool instanceof(JSFunction constructor) =>
      foreign_helper.JS('bool', '# instanceof #', this, constructor);

  @patch
  bool isA<T>() => throw UnimplementedError(
      "This should never be called. Calls to 'isA' should have been "
      'transformed by the interop transformer.');

  @patch
  @pragma('dart2js:prefer-inline')
  Object? dartify() => js_util.dartify(this);
}

// Utility extensions for Object?.
@patch
extension NullableObjectUtilExtension on Object? {
  @patch
  @pragma('dart2js:prefer-inline')
  JSAny? jsify() => js_util.jsify(this);
}

// -----------------------------------------------------------------------------
// JSExportedDartFunction <-> Function
@patch
extension JSExportedDartFunctionToFunction on JSExportedDartFunction {
  @patch
  Function get toDart => throw UnimplementedError(
      "'toDart' should never directly be called. Calls to 'toDart' should have "
      'been transformed by the interop transformer.');
}

@patch
extension FunctionToJSExportedDartFunction on Function {
  @patch
  JSExportedDartFunction get toJS => throw UnimplementedError(
      "'toJS' should never directly be called. Calls to 'toJS' should have "
      'been transformed by the interop transformer.');
}

// Embedded global property for wrapped Dart objects passed via JS interop.
//
// This is a Symbol so that different Dart applications don't share Dart
// objects from different Dart runtimes. We expect all JSBoxedDartObjects to
// have this Symbol.
final Object _jsBoxedDartObjectProperty =
    foreign_helper.JS('', 'Symbol("jsBoxedDartObjectProperty")');

// -----------------------------------------------------------------------------
// JSBoxedDartObject <-> Object
@patch
extension JSBoxedDartObjectToObject on JSBoxedDartObject {
  @patch
  @pragma('dart2js:prefer-inline')
  Object get toDart {
    final val = js_util.getProperty<Object?>(this, _jsBoxedDartObjectProperty);
    if (val == null) {
      throw 'Expected a wrapped Dart object, but got a JS object or a wrapped '
          'Dart object from a separate runtime instead.';
    }
    return val;
  }
}

@patch
extension ObjectToJSBoxedDartObject on Object {
  @patch
  @pragma('dart2js:prefer-inline')
  JSBoxedDartObject get toJSBox {
    if (this is JavaScriptObject) {
      throw 'Attempting to box non-Dart object.';
    }
    final box = js_util.newObject();
    // Use JS foreign function to avoid assertInterop check when `this` is a
    // `Function` for `setProperty`.
    foreign_helper.JS('', '#[#]=#', box, _jsBoxedDartObjectProperty, this);
    return JSBoxedDartObject._(box);
  }
}

// -----------------------------------------------------------------------------
// ExternalDartReference <-> T
@patch
extension ExternalDartReferenceToObject<T extends Object?>
    on ExternalDartReference<T> {
  @patch
  @pragma('dart2js:prefer-inline')
  T get toDartObject => _externalDartReference;
}

@patch
extension ObjectToExternalDartReference<T extends Object?> on T {
  @patch
  @pragma('dart2js:prefer-inline')
  ExternalDartReference<T> get toExternalReference =>
      ExternalDartReference<T>._(this);
}

// JSPromise -> Future
@patch
extension JSPromiseToFuture<T extends JSAny?> on JSPromise<T> {
  @patch
  @pragma('dart2js:prefer-inline')
  Future<T> get toDart => js_util.promiseToFuture<T>(this);
}

// -----------------------------------------------------------------------------
// JSArrayBuffer <-> ByteBuffer
@patch
extension JSArrayBufferToByteBuffer on JSArrayBuffer {
  @patch
  @pragma('dart2js:prefer-inline')
  ByteBuffer get toDart => this._jsArrayBuffer;
}

@patch
extension ByteBufferToJSArrayBuffer on ByteBuffer {
  @patch
  @pragma('dart2js:prefer-inline')
  JSArrayBuffer get toJS => this as JSArrayBuffer;
}

// -----------------------------------------------------------------------------
// JSDataView <-> ByteData
@patch
extension JSDataViewToByteData on JSDataView {
  @patch
  @pragma('dart2js:prefer-inline')
  ByteData get toDart => this._jsDataView;
}

@patch
extension ByteDataToJSDataView on ByteData {
  @patch
  @pragma('dart2js:prefer-inline')
  JSDataView get toJS => this as JSDataView;
}

// -----------------------------------------------------------------------------
// JSInt8Array <-> Int8List
@patch
extension JSInt8ArrayToInt8List on JSInt8Array {
  @patch
  @pragma('dart2js:prefer-inline')
  Int8List get toDart => this._jsInt8Array;
}

@patch
extension Int8ListToJSInt8Array on Int8List {
  @patch
  @pragma('dart2js:prefer-inline')
  JSInt8Array get toJS => this as JSInt8Array;
}

// -----------------------------------------------------------------------------
// JSUint8Array <-> Uint8List
@patch
extension JSUint8ArrayToUint8List on JSUint8Array {
  @patch
  @pragma('dart2js:prefer-inline')
  Uint8List get toDart => this._jsUint8Array;
}

@patch
extension Uint8ListToJSUint8Array on Uint8List {
  @patch
  @pragma('dart2js:prefer-inline')
  JSUint8Array get toJS => this as JSUint8Array;
}

// -----------------------------------------------------------------------------
// JSUint8ClampedArray <-> Uint8ClampedList
@patch
extension JSUint8ClampedArrayToUint8ClampedList on JSUint8ClampedArray {
  @patch
  @pragma('dart2js:prefer-inline')
  Uint8ClampedList get toDart => this._jsUint8ClampedArray;
}

@patch
extension Uint8ClampedListToJSUint8ClampedArray on Uint8ClampedList {
  @patch
  @pragma('dart2js:prefer-inline')
  JSUint8ClampedArray get toJS => this as JSUint8ClampedArray;
}

// -----------------------------------------------------------------------------
// JSInt16Array <-> Int16List
@patch
extension JSInt16ArrayToInt16List on JSInt16Array {
  @patch
  @pragma('dart2js:prefer-inline')
  Int16List get toDart => this._jsInt16Array;
}

@patch
extension Int16ListToJSInt16Array on Int16List {
  @patch
  @pragma('dart2js:prefer-inline')
  JSInt16Array get toJS => this as JSInt16Array;
}

// -----------------------------------------------------------------------------
// JSUint16Array <-> Uint16List
@patch
extension JSUint16ArrayToInt16List on JSUint16Array {
  @patch
  @pragma('dart2js:prefer-inline')
  Uint16List get toDart => this._jsUint16Array;
}

@patch
extension Uint16ListToJSInt16Array on Uint16List {
  @patch
  @pragma('dart2js:prefer-inline')
  JSUint16Array get toJS => this as JSUint16Array;
}

// -----------------------------------------------------------------------------
// JSInt32Array <-> Int32List
@patch
extension JSInt32ArrayToInt32List on JSInt32Array {
  @patch
  @pragma('dart2js:prefer-inline')
  Int32List get toDart => this._jsInt32Array;
}

@patch
extension Int32ListToJSInt32Array on Int32List {
  @patch
  @pragma('dart2js:prefer-inline')
  JSInt32Array get toJS => this as JSInt32Array;
}

// -----------------------------------------------------------------------------
// JSUint32Array <-> Uint32List
@patch
extension JSUint32ArrayToUint32List on JSUint32Array {
  @patch
  @pragma('dart2js:prefer-inline')
  Uint32List get toDart => this._jsUint32Array;
}

@patch
extension Uint32ListToJSUint32Array on Uint32List {
  @patch
  @pragma('dart2js:prefer-inline')
  JSUint32Array get toJS => this as JSUint32Array;
}

// -----------------------------------------------------------------------------
// JSFloat32Array <-> Float32List
@patch
extension JSFloat32ArrayToFloat32List on JSFloat32Array {
  @patch
  @pragma('dart2js:prefer-inline')
  Float32List get toDart => this._jsFloat32Array;
}

@patch
extension Float32ListToJSFloat32Array on Float32List {
  @patch
  @pragma('dart2js:prefer-inline')
  JSFloat32Array get toJS => this as JSFloat32Array;
}

// -----------------------------------------------------------------------------
// JSFloat64Array <-> Float64List
@patch
extension JSFloat64ArrayToFloat64List on JSFloat64Array {
  @patch
  @pragma('dart2js:prefer-inline')
  Float64List get toDart => this._jsFloat64Array;
}

@patch
extension Float64ListToJSFloat64Array on Float64List {
  @patch
  @pragma('dart2js:prefer-inline')
  JSFloat64Array get toJS => this as JSFloat64Array;
}

// -----------------------------------------------------------------------------
// JSArray <-> List
@patch
extension JSArrayToList<T extends JSAny?> on JSArray<T> {
  @patch
  @pragma('dart2js:prefer-inline')
  List<T> get toDart {
    // Upcast `interceptors.JSArray<Object?>` first to a `List<Object?>` so that
    // we only need one type promotion.
    List<Object?> t = _jsArray;
    return t is List<T> ? t : t.cast<T>();
  }
}

@patch
extension ListToJSArray<T extends JSAny?> on List<T> {
  @patch
  @pragma('dart2js:prefer-inline')
  JSArray<T> get toJS => this as JSArray<T>;

  // TODO(srujzs): Should we do a check to make sure this List is a JSArray
  // under the hood and then potentially proxy? This applies for user lists. For
  // now, don't do the check to avoid the cost of the check in the general case,
  // and user lists will likely crash. Note that on dart2js, we do an
  // `Array.isArray` check instead of `instanceof Array` when we cast to a
  // `List`, which is what `JSArray` is. This won't work for proxy objects as
  // they're not actually Arrays, so the cast will fail unless we change that
  // check.
  @patch
  @pragma('dart2js:prefer-inline')
  JSArray<T> get toJSProxyOrRef => this as JSArray<T>;
}

// -----------------------------------------------------------------------------
// JSNumber -> double or int
@patch
extension JSNumberToNumber on JSNumber {
  @patch
  @pragma('dart2js:prefer-inline')
  double get toDartDouble => this._jsNumber;

  @patch
  @pragma('dart2js:prefer-inline')
  int get toDartInt => this as int;
}

// -----------------------------------------------------------------------------
// double -> JSNumber
@patch
extension DoubleToJSNumber on double {
  @patch
  @pragma('dart2js:prefer-inline')
  JSNumber get toJS => JSNumber._(this);
}

// -----------------------------------------------------------------------------
// JSBoolean <-> bool
@patch
extension JSBooleanToBool on JSBoolean {
  @patch
  @pragma('dart2js:prefer-inline')
  bool get toDart => this._jsBoolean;
}

@patch
extension BoolToJSBoolean on bool {
  @patch
  @pragma('dart2js:prefer-inline')
  JSBoolean get toJS => JSBoolean._(this);
}

// -----------------------------------------------------------------------------
// JSString <-> String
@patch
extension JSStringToString on JSString {
  @patch
  @pragma('dart2js:prefer-inline')
  String get toDart => this._jsString;
}

@patch
extension StringToJSString on String {
  @patch
  @pragma('dart2js:prefer-inline')
  JSString get toJS => JSString._(this);
}

@patch
extension JSAnyOperatorExtension on JSAny? {
  @patch
  @pragma('dart2js:prefer-inline')
  JSAny add(JSAny? any) => js_util.add(this, any);

  @patch
  @pragma('dart2js:prefer-inline')
  JSAny subtract(JSAny? any) => js_util.subtract(this, any);

  @patch
  @pragma('dart2js:prefer-inline')
  JSAny multiply(JSAny? any) => js_util.multiply(this, any);

  @patch
  @pragma('dart2js:prefer-inline')
  JSAny divide(JSAny? any) => js_util.divide(this, any);

  @patch
  @pragma('dart2js:prefer-inline')
  JSAny modulo(JSAny? any) => js_util.modulo(this, any);

  @patch
  @pragma('dart2js:prefer-inline')
  JSAny exponentiate(JSAny? any) => js_util.exponentiate(this, any);

  @patch
  @pragma('dart2js:prefer-inline')
  JSBoolean greaterThan(JSAny? any) =>
      JSBoolean._(js_util.greaterThan(this, any));

  @patch
  @pragma('dart2js:prefer-inline')
  JSBoolean greaterThanOrEqualTo(JSAny? any) =>
      JSBoolean._(js_util.greaterThanOrEqual(this, any));

  @patch
  @pragma('dart2js:prefer-inline')
  JSBoolean lessThan(JSAny? any) => JSBoolean._(js_util.lessThan(this, any));

  @patch
  @pragma('dart2js:prefer-inline')
  JSBoolean lessThanOrEqualTo(JSAny? any) =>
      JSBoolean._(js_util.lessThanOrEqual(this, any));

  @patch
  @pragma('dart2js:prefer-inline')
  JSBoolean equals(JSAny? any) => JSBoolean._(js_util.equal(this, any));

  @patch
  @pragma('dart2js:prefer-inline')
  JSBoolean notEquals(JSAny? any) => JSBoolean._(js_util.notEqual(this, any));

  @patch
  @pragma('dart2js:prefer-inline')
  JSBoolean strictEquals(JSAny? any) =>
      JSBoolean._(js_util.strictEqual(this, any));

  @patch
  @pragma('dart2js:prefer-inline')
  JSBoolean strictNotEquals(JSAny? any) =>
      JSBoolean._(js_util.strictNotEqual(this, any));

  @patch
  @pragma('dart2js:prefer-inline')
  JSNumber unsignedRightShift(JSAny? any) =>
      js_util.unsignedRightShift(this, any).toJS;

  @patch
  @pragma('dart2js:prefer-inline')
  JSAny? and(JSAny? any) => js_util.and(this, any);

  @patch
  @pragma('dart2js:prefer-inline')
  JSAny? or(JSAny? any) => js_util.or(this, any);

  @patch
  @pragma('dart2js:prefer-inline')
  JSBoolean get not => js_util.not(this);

  @patch
  @pragma('dart2js:prefer-inline')
  JSBoolean get isTruthy => JSBoolean._(js_util.isTruthy(this));
}

@patch
@pragma('dart2js:prefer-inline')
JSPromise<JSObject> importModule(JSAny moduleName) =>
    foreign_helper.JS('', 'import(#)', moduleName);
