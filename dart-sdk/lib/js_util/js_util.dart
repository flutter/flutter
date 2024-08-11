// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Utility methods to manipulate `package:js` annotated JavaScript interop
/// objects in cases where the name to call is not known at runtime.
///
/// > [!Note]
/// > You should usually use `dart:js_interop` instead of this library.
/// > To learn more, check out the
/// > [JS interop documentation](https://dart.dev/interop/js-interop).
///
/// You should only use these methods when the same effect cannot be achieved
/// with `@JS()` annotations.
///
/// {@category Web (Legacy)}
library dart.js_util;

// Examples can assume:
// class JS { const JS(); }
// class Promise<T> {}

/// Recursively converts a JSON-like collection to JavaScript compatible
/// representation.
///
/// WARNING: performance of this method is much worse than other util
/// methods in this library. Only use this method as a last resort. Prefer
/// instead to use `@anonymous` `@JS()` annotated classes to create map-like
/// objects for JS interop.
///
/// If the argument are a [Map] or [Iterable], then they will be deeply
/// converted.  Maps are converted into JavaScript objects. Iterables are
/// converted into arrays. `@JS()` annotated objects are passed through
/// unmodified. Dart objects are also passed through unmodified, but their
/// members aren't usable from JavaScript.  The conversion logic for
/// primitives(numbers, bools, and Strings) is backend specific.
external dynamic jsify(Object? object);

external Object get globalThis;

external T newObject<T>();

external bool hasProperty(Object o, Object name);

external T getProperty<T>(Object o, Object name);

// A CFE transformation may optimize calls to `setProperty`, when [value] is
// statically known to be a non-function.
external T setProperty<T>(Object o, Object name, T? value);

// A CFE transformation may optimize calls to `callMethod` when [args] is a
// a list literal or const list containing at most 4 values, all of which are
// statically known to be non-functions.
external T callMethod<T>(Object o, Object method, List<Object?> args);

/// Check whether [o] is an instance of [type].
///
/// The value in [type] is expected to be a JS-interop object that
/// represents a valid JavaScript constructor function.
external bool instanceof(Object? o, Object type);

external T callConstructor<T>(Object constr, List<Object?>? arguments);

/// Perform JavaScript addition (`+`) on two values.
external T add<T>(Object? first, Object? second);

/// Perform JavaScript subtraction (`-`) on two values.
external T subtract<T>(Object? first, Object? second);

/// Perform JavaScript multiplication (`*`) on two values.
external T multiply<T>(Object? first, Object? second);

/// Perform JavaScript division (`/`) on two values.
external T divide<T>(Object? first, Object? second);

/// Perform JavaScript exponentiation (`**`) on two values.
external T exponentiate<T>(Object? first, Object? second);

/// Perform JavaScript remainder (`%`) on two values.
external T modulo<T>(Object? first, Object? second);

/// Perform JavaScript equality comparison (`==`) on two values.
external bool equal<T>(Object? first, Object? second);

/// Perform JavaScript strict equality comparison (`===`) on two values.
external bool strictEqual<T>(Object? first, Object? second);

/// Perform JavaScript inequality comparison (`!=`) on two values.
external bool notEqual<T>(Object? first, Object? second);

/// Perform JavaScript strict inequality comparison (`!==`) on two values.
external bool strictNotEqual<T>(Object? first, Object? second);

/// Perform JavaScript greater than comparison (`>`) of two values.
external bool greaterThan<T>(Object? first, Object? second);

/// Perform JavaScript greater than or equal comparison (`>=`) of two values.
external bool greaterThanOrEqual<T>(Object? first, Object? second);

/// Perform JavaScript less than comparison (`<`) of two values.
external bool lessThan<T>(Object? first, Object? second);

/// Perform JavaScript less than or equal comparison (`<=`) of two values.
external bool lessThanOrEqual<T>(Object? first, Object? second);

/// Perform JavaScript `typeof` operator on the given object and determine if
/// the result is equal to the given type. Exposes the whole `typeof` equal
/// expression to maximize browser optimization.
external bool typeofEquals<T>(Object? o, String type);

/// Perform JavaScript logical not (`!`) on the given object.
external T not<T>(Object? o);

/// Determines if the given object is truthy or falsy.
external bool isTruthy<T>(Object? o);

/// Perform JavaScript logical or comparison (`||`) of two expressions.
external T or<T>(Object? first, Object? second);

/// Perform JavaScript logical and comparison (`&&`) of two expressions.
external T and<T>(Object? first, Object? second);

/// Perform JavaScript delete operator (`delete`) on the given property of the
/// given object.
external bool delete<T>(Object o, Object property);

/// Perform JavaScript unsigned right shift operator (`>>>`) on the given left
/// operand by the amount specified by the given right operand.
external num unsignedRightShift(Object? leftOperand, Object? rightOperand);

/// Exception for when the promise is rejected with a `null` or `undefined`
/// value.
///
/// This is public to allow users to catch when the promise is rejected with
/// `null` or `undefined` versus some other value.
class NullRejectionException implements Exception {
  // Indicates whether the value is `undefined` or `null`.
  final bool isUndefined;

  NullRejectionException(this.isUndefined);

  @override
  String toString() {
    var value = this.isUndefined ? 'undefined' : 'null';
    return 'Promise was rejected with a value of `$value`.';
  }
}

/// Converts a JavaScript Promise to a Dart [Future].
///
/// ```dart template:top
/// @JS()
/// external Promise<num> get threePromise; // Resolves to 3
///
/// void main() async {
///   final Future<num> threeFuture = promiseToFuture(threePromise);
///
///   final three = await threeFuture; // == 3
/// }
/// ```
external Future<T> promiseToFuture<T>(Object jsPromise);

Object? _getConstructor(String constructorName) =>
    getProperty(globalThis, constructorName);

/// Like [instanceof] only takes a [String] for the object name instead of a
/// constructor object.
bool instanceOfString(Object? element, String objectType) {
  Object? constructor = _getConstructor(objectType);
  return constructor != null && instanceof(element, constructor);
}

/// Returns the prototype of a given object. Equivalent to
/// `Object.getPrototypeOf`.
external Object? objectGetPrototypeOf(Object? object);

/// Returns the `Object` prototype. Equivalent to `Object.prototype`.
external Object? get objectPrototype;

/// Returns the keys for a given object. Equivalent to `Object.keys(object)`.
external List<Object?> objectKeys(Object? object);

/// Returns `true` if a given object is a JavaScript array.
external bool isJavaScriptArray(value);

/// Returns `true` if a given object is a simple JavaScript object.
external bool isJavaScriptSimpleObject(value);

/// Effectively the inverse of [jsify], [dartify] Takes a JavaScript object, and
/// converts it to a Dart based object. Only JS primitives, arrays, or 'map'
/// like JS objects are supported.
external Object? dartify(Object? o);

/// Given a `@staticInterop` type T and an instance [dartMock] of a Dart class
/// U that implements the external extension members of T, creates a forwarding
/// mock.
///
/// Optionally, you may provide a JS prototype object e.g. the JS value
/// `Window.prototype` using [proto]. This allows instanceof and is checks with
/// `@Native` types to pass with the returned forwarding mock.
///
/// When external extension members are called, they will forward to the
/// corresponding implementing member in [dartMock]. If U does not implement the
/// needed external extension members of T, or if U does not properly override
/// them, it will be considered a compile-time error.
///
/// For example:
///
/// ```
/// @JS()
/// @staticInterop
/// class JSClass {}
///
/// extension JSClassExtension on JSClass {
///   external String stringify(int param);
/// }
///
/// @JSExport()
/// class DartClass {
///   String stringify(num param) => param.toString();
/// }
///
/// ...
///
/// JSClass mock = createStaticInteropMock<JSClass, DartClass>(DartClass());
/// ```
external T createStaticInteropMock<T extends Object, U extends Object>(
    U dartMock,
    [Object? proto = null]);

/// Given a Dart object that is marked exportable, creates a JS object literal
/// that forwards to that Dart class. Look at the `@JSExport` annotation to
/// determine what constitutes "exportable" for a Dart class. The object literal
/// will be a map of export names (which are either the written instance member
/// names or their rename) to their respective Dart instance members.
///
/// For example:
///
/// ```
/// @JSExport()
/// class ExportCounter {
///   int value = 0;
///   String stringify() => value.toString();
/// }
///
/// @JS()
/// @staticInterop
/// class Counter {}
///
/// extension on Counter {
///   external int get value;
///   external set value(int val);
///   external String stringify();
/// }
///
/// ...
///
/// var export = ExportCounter();
/// var counter = createDartExport(export) as Counter;
/// export.value = 1;
/// Expect.isTrue(counter.value, export.value);
/// Expect.isTrue(counter.stringify(), export.stringify());
/// ```
external Object createDartExport<T extends Object>(T dartObject);

/// Returns a wrapper around function [f] that can be called from JavaScript
/// using `package:js` JavaScript interop.
///
/// The calling conventions in Dart web backends differ from JavaScript and so,
/// by default, it is not possible to call a Dart function directly. Wrapping
/// with `allowInterop` creates a function that can be called from JavaScript or
/// Dart. The semantics of the wrapped function are still more strict than
/// JavaScript, and the function will throw if called with too many or too few
/// arguments.
///
/// Calling this method repeatedly on a function will return the same result.
external F allowInterop<F extends Function>(F f);

/// Returns a wrapper around function [f] that can be called from JavaScript
/// using `package:js` JavaScript interop, passing JavaScript `this` as the
/// first argument.
///
/// See [allowInterop].
///
/// When called from Dart, `null` will be passed as the first argument.
external Function allowInteropCaptureThis(Function f);
