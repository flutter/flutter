// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Interoperability, "interop" for short, with JavaScript and browser APIs.
///
/// JavaScript interop allows a Dart program to interact with a JavaScript
/// runtime. This can, for example, be to access JavaScript declarations and
/// interact with JavaScript values, or to adapt Dart values so that they can be
/// passed to and used by JavaScript code.
///
/// This JavaScript interop library works by introducing an abstraction over
/// JavaScript values, a Dart type hierarchy ("JS types") which mirrors known
/// JavaScript types, and a framework for introducing new Dart types that bind
/// Dart type declarations to JavaScript values and external member declarations
/// to JavaScript APIs.
///
/// This abstraction allows the same interop API to be used both when the Dart
/// code is compiled to JavaScript and when compiled to Wasm.
///
/// See https://dart.dev/interop/js-interop for more details on usage, types,
/// and previous JavaScript interop.
///
/// > [!NOTE]
/// > The types defined in this library only provide static guarantees.
/// > The runtime types differ based on the backend, so it is important to rely
/// > on static functionality like the conversion functions, for example `toJS`
/// > and not runtime mechanisms like type checks (`is`) and casts (`as`).
/// > Similarly, `identical` may return different results for the same JS value
/// > depending on the compiler. Use `==` to check for equality of two JS types
/// > instead.
///
/// {@category Web}
library;

import 'dart:_internal' show Since;
import 'dart:_js_annotations' show JSExport;
import 'dart:_js_types';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

// To support an easier transition, we allow users to use `@staticInterop`
// classes - with or without the `@anonymous` annotation.
export 'dart:_js_annotations' show staticInterop, anonymous, JSExport;
export 'dart:js_util' show NullRejectionException;

/// An annotation on a JavaScript interop declaration.
///
/// This annotation defines a given library, top-level external declaration, or
/// extension type as a JavaScript interop declaration.
///
/// Specifying [name] customizes the JavaScript name to use, which can be used
/// in the following scenarios:
///
/// - Adding a JavaScript prefix to all the external top-level declarations,
///   static members, and constructors of a library by parameterizing the
///   annotation on the library with [name].
/// - Specifying the JavaScript class to use for external static members and
///   constructors of an interop extension type by parameterizing the annotation
///   on the interop extension type with [name].
/// - Renaming external declarations by parameterizing the annotation on the
///   member with [name].
///
/// In the case where [name] is not specified, the Dart name of the extension
/// type or external declaration is used as the default.
///
/// See https://dart.dev/interop/js-interop/usage#js for more details on how to
/// use this annotation.
///
/// > [!NOTE]
/// > `package:js` exports an `@JS` annotation as well. Unlike that annotation,
/// > this annotation applies to extension types, and will result in more
/// > type-checking for external top-level declarations.
class JS {
  final String? name;
  const JS([this.name]);
}

/// A non-nullish JavaScript value.
///
/// A [JSAny] can be any JavaScript value except JavaScript `null` and
/// `undefined`. JavaScript `null` and `undefined` are instead converted to Dart
/// `null` by the compiler. Therefore, <code>[JSAny]?</code> is the top type of
/// the type hierarchy as it includes nullish JavaScript values as well.
extension type JSAny._(JSAnyRepType _jsAny) implements Object {}

/// A JavaScript `Object`.
///
/// [JSObject] is the supertype of all JavaScript objects, but not other JS
/// types, like primitives. See https://dart.dev/interop/js-interop for more
/// details on how to use JavaScript interop.
///
/// When declaring interop extension types, [JSObject] is usually the type you
/// will use as the representation type.
@JS('Object')
extension type JSObject._(JSObjectRepType _jsObject) implements JSAny {
  /// Creates a [JSObject] from an object provided by an earlier interop
  /// library.
  ///
  /// Accepts, for example, the types created using `package:js` or `dart:html`.
  ///
  /// This constructor is intended to allow users to avoid having to cast to and
  /// from [JSObject].
  JSObject.fromInteropObject(Object interopObject)
      : _jsObject = interopObject as JSObjectRepType;

  /// Creates a new empty JavaScript object.
  ///
  /// The object is created using the JavaScript object initializer syntax
  /// (`{}`), and this constructor is more efficient than `{}.jsify()`.
  JSObject() : _jsObject = _createObjectLiteral();
}

// TODO(srujzs): Move this member to `JSObject` once we can patch extension type
// members.
external JSObjectRepType _createObjectLiteral();

/// A JavaScript [`Function`](https://tc39.es/ecma262/#sec-function-objects)
/// value.
@JS('Function')
extension type JSFunction._(JSFunctionRepType _jsFunction)
    implements JSObject {}

/// A JavaScript callable function created from a Dart function.
///
/// See [FunctionToJSExportedDartFunction.toJS] for more details on how to
/// convert a Dart function.
@JS('Function')
extension type JSExportedDartFunction._(
        JSExportedDartFunctionRepType _jsExportedDartFunction)
    implements JSFunction {}

/// A JavaScript [`Array`](https://tc39.es/ecma262/#sec-array-objects).
///
/// Because [JSArray] is an extension type, [T] is only a static guarantee and
/// the array does not necessarily only contain [T] elements. For example:
///
/// ```dart
/// @JS()
/// external JSArray<JSNumber> get array;
/// ```
///
/// `array` is not actually checked to ensure it contains instances of
/// [JSNumber] when called.
///
/// [T] may introduce additional checking elsewhere, however. When accessing
/// elements of [JSArray] with type [T], there is a check to ensure the element
/// is a [T] to ensure soundness. Similarly, when converting to a [List<T>],
/// casts may be introduced to ensure that it is indeed a [List<T>].
@JS('Array')
extension type JSArray<T extends JSAny?>._(JSArrayRepType _jsArray)
    implements JSObject {
  /// Creates an empty JavaScript `Array`.
  ///
  /// Equivalent to `new Array()` and more efficient than `[].jsify()`.
  external JSArray();

  /// Creates a JavaScript `Array` of size [length] with no elements.
  external JSArray.withLength(int length);
}

/// A JavaScript `Promise` or a promise-like object.
///
/// Because [JSPromise] is an extension type, [T] is only a static guarantee and
/// the [JSPromise] may not actually resolve to a [T].
///
/// Also like with [JSArray], [T] may introduce additional checking elsewhere.
/// When converted to a [Future<T>], there is a cast to ensure that the [Future]
/// actually resolves to a [T] to ensure soundness.
@JS('Promise')
extension type JSPromise<T extends JSAny?>._(JSPromiseRepType _jsPromise)
    implements JSObject {
  external JSPromise(JSFunction executor);
}

/// A Dart object that is wrapped with a JavaScript object so that it can be
/// passed to JavaScript safely.
///
/// Unlike [ExternalDartReference], this can be used as a JS type and is a
/// subtype of [JSAny]. Users can also declare interop types using this as the
/// representation type or declare interop members on this type.
///
/// Use this interface when you want to pass Dart objects within the same
/// runtime through JavaScript. There are no usable members in the resulting
/// [JSBoxedDartObject].
///
/// See [ObjectToJSBoxedDartObject.toJSBox] to wrap an arbitrary [Object].
@JS('Object')
extension type JSBoxedDartObject._(JSBoxedDartObjectRepType _jsBoxedDartObject)
    implements JSObject {}

/// A JavaScript `ArrayBuffer`.
@JS('ArrayBuffer')
extension type JSArrayBuffer._(JSArrayBufferRepType _jsArrayBuffer)
    implements JSObject {}

/// A JavaScript `DataView`.
@JS('DataView')
extension type JSDataView._(JSDataViewRepType _jsDataView)
    implements JSObject {}

/// Abstract supertype of all JavaScript typed arrays.
extension type JSTypedArray._(JSTypedArrayRepType _jsTypedArray)
    implements JSObject {}

/// A JavaScript `Int8Array`.
@JS('Int8Array')
extension type JSInt8Array._(JSInt8ArrayRepType _jsInt8Array)
    implements JSTypedArray {}

/// A JavaScript `Uint8Array`.
@JS('Uint8Array')
extension type JSUint8Array._(JSUint8ArrayRepType _jsUint8Array)
    implements JSTypedArray {}

/// A JavaScript `Uint8ClampedArray`.
@JS('Uint8ClampedArray')
extension type JSUint8ClampedArray._(
    JSUint8ClampedArrayRepType _jsUint8ClampedArray) implements JSTypedArray {}

/// A JavaScript `Int16Array`.
@JS('Int16Array')
extension type JSInt16Array._(JSInt16ArrayRepType _jsInt16Array)
    implements JSTypedArray {}

/// A JavaScript `Uint16Array`.
@JS('Uint16Array')
extension type JSUint16Array._(JSUint16ArrayRepType _jsUint16Array)
    implements JSTypedArray {}

/// A JavaScript `Int32Array`.
@JS('Int32Array')
extension type JSInt32Array._(JSInt32ArrayRepType _jsInt32Array)
    implements JSTypedArray {}

/// A JavaScript `Uint32Array`.
@JS('Uint32Array')
extension type JSUint32Array._(JSUint32ArrayRepType _jsUint32Array)
    implements JSTypedArray {}

/// A JavaScript `Float32Array`.
@JS('Float32Array')
extension type JSFloat32Array._(JSFloat32ArrayRepType _jsFloat32Array)
    implements JSTypedArray {}

/// A JavaScript `Float64Array`.
@JS('Float64Array')
extension type JSFloat64Array._(JSFloat64ArrayRepType _jsFloat64Array)
    implements JSTypedArray {}

// The various JavaScript primitive types. Crucially, unlike the Dart type
// hierarchy, none of these types are subtypes of [JSObject]. They are just
// subtypes of [JSAny].

/// A JavaScript number.
extension type JSNumber._(JSNumberRepType _jsNumber) implements JSAny {}

/// A JavaScript boolean.
extension type JSBoolean._(JSBooleanRepType _jsBoolean) implements JSAny {}

/// A JavaScript string.
extension type JSString._(JSStringRepType _jsString) implements JSAny {}

/// A JavaScript `Symbol`.
extension type JSSymbol._(JSSymbolRepType _jsSymbol) implements JSAny {}

/// A JavaScript `BigInt`.
extension type JSBigInt._(JSBigIntRepType _jsBigInt) implements JSAny {}

/// An opaque reference to a Dart object that can be passed to JavaScript.
///
/// The reference representation depends on the underlying platform. When
/// compiling to JavaScript, a Dart object is a JavaScript object, and can be
/// used directly without any conversions. When compiling to Wasm, an internal
/// Wasm function is used to convert the Dart object to an opaque JavaScript
/// value, which can later be converted back using another internal function.
/// The underlying representation type is nullable, meaning a non-nullable
/// [ExternalDartReference] may be `null`.
///
/// This interface is a faster alternative to [JSBoxedDartObject] by not
/// wrapping the Dart object with a JavaScript object. However, unlike
/// [JSBoxedDartObject], this value belongs to the Dart runtime, and therefore
/// can not be used as a JS type. This means users cannot declare interop types
/// using this as the representation type or declare interop members on this
/// type. This type is also not a subtype of [JSAny]. This type can only be used
/// as parameter and return types of external JavaScript interop members or
/// callbacks. Use [JSBoxedDartObject] to avoid those limitations.
///
/// Besides these differences, [ExternalDartReference] operates functionally the
/// same as [JSBoxedDartObject]. Use it to pass Dart objects within the same
/// runtime through JavaScript. There are no usable members in the resulting
/// [ExternalDartReference].
///
/// See [ObjectToExternalDartReference.toExternalReference] to allow an
/// arbitrary value of type [T] to be passed to JavaScript.
extension type ExternalDartReference<T extends Object?>._(
    ExternalDartReferenceRepType<T> _externalDartReference) {}

/// JS type equivalent for `undefined` for interop member return types.
///
/// Prefer using `void` instead of this.
// TODO(srujzs): Mark this as deprecated. There are no performance costs from
// using `void`, and we'll likely provide a different way to box `undefined`.
typedef JSVoid = JSVoidRepType;

/// Helper methods to determine if a value is JavaScript `undefined` or `null`.
///
/// > [!NOTE]
/// > The members within these extensions may throw depending on the platform.
/// > Do not rely on them to be platform-consistent.
///
/// JavaScript `undefined` and JavaScript `null` are internalized differently
/// based on the backend. When compiling to JavaScript, Dart `null` can actually
/// be JavaScript `undefined` or JavaScript `null`. When compiling to Wasm,
/// that's not the case: there's only one Wasm value `null` can be. Therefore,
/// when an interop API returns JavaScript `null` or JavaScript `undefined`,
/// they are both converted to Dart `null` when compiling to Wasm, and when you
/// pass a Dart `null` to an interop API, it is called with JavaScript `null`.
/// When compiling to JavaScript, Dart `null` retains its original JavaScript
/// value. Avoid writing code where this distinction between `null` and
/// `undefined` matters.
// TODO(srujzs): Investigate what it takes to allow users to distinguish between
// the two "nullish" values. An annotation-based model where users annotate
// interop APIs to internalize `undefined` differently seems promising, but does
// not handle some cases like converting a `JSArray` with `undefined`s in it to
// `List<JSAny?>`. In this case, the implementation of the list wrapper needs to
// make the decision, not the user.
extension NullableUndefineableJSAnyExtension on JSAny? {
  /// Whether this value corresponds to JavaScript `undefined`.
  ///
  /// > [!NOTE]
  /// > Currently, there is no way to distinguish between JavaScript `undefined`
  /// > and JavaScript `null` when compiling to Wasm. Therefore, this getter
  /// > should only be used for code that compiles to JavaScript and will throw
  /// > when compiling to Wasm.
  external bool get isUndefined;

  /// Whether this value corresponds to JavaScript `null`.
  ///
  /// > [!NOTE]
  /// > Currently, there is no way to distinguish between JavaScript `undefined`
  /// > and JavaScript `null` when compiling to Wasm. Therefore, this getter
  /// > should only be used for code that compiles to JavaScript and will throw
  /// > when compiling to Wasm.
  external bool get isNull;

  bool get isUndefinedOrNull => this == null;
  bool get isDefinedAndNotNull => !isUndefinedOrNull;
}

/// Common utility functions that are useful for any JavaScript value.
extension JSAnyUtilityExtension on JSAny? {
  /// Whether the result of `typeof` on this <code>[JSAny]?</code> is
  /// [typeString].
  external bool typeofEquals(String typeString);

  /// Whether this <code>[JSAny]?</code> is an `instanceof` [constructor].
  external bool instanceof(JSFunction constructor);

  /// Whether this <code>[JSAny]?</code> is an `instanceof` the constructor that
  /// is defined by [constructorName], which is looked up in the
  /// [globalContext].
  ///
  /// If [constructorName] contains '.'s, the name is split into several parts
  /// in order to get the constructor. For example, `library1.JSClass` would
  /// involve fetching `library1` off of the [globalContext], and then fetching
  /// `JSClass` off of `library1` to get the constructor.
  ///
  /// If [constructorName] is empty or any of the parts or the constructor don't
  /// exist, returns false.
  bool instanceOfString(String constructorName) {
    if (constructorName.isEmpty) return false;
    final parts = constructorName.split('.');
    JSObject? constructor = globalContext;
    for (final part in parts) {
      constructor = constructor?[part] as JSObject?;
      if (constructor == null) return false;
    }
    return instanceof(constructor as JSFunction);
  }

  /// Whether this <code>[JSAny]?</code> is an instance of the JavaScript type
  /// that is declared by [T].
  ///
  /// This method uses a combination of `null`, `typeof`, and `instanceof`
  /// checks in order to do this check. Use this instead of `is` checks.
  ///
  /// If [T] is a primitive JS type like [JSString], this uses a `typeof` check
  /// that corresponds to that primitive type like `typeofEquals('string')`.
  ///
  /// If [T] is a non-primitive JS type like [JSArray] or an interop extension
  /// type on one, this uses an `instanceof` check using the name or the
  /// <code>@[JS]</code> rename of the given type like
  /// `instanceOfString('Array')`. Note that if you rename the library using the
  /// <code>@[JS]</code> annotation, this uses the rename in the `instanceof`
  /// check like `instanceOfString('library1.JSClass')`.
  ///
  /// To determine the JavaScript constructor to use as the second operand in
  /// the `instanceof` check, this function uses the JavaScript name associated
  /// with the extension type, which is either the argument given to the
  /// <code>@[JS]</code> annotation or the Dart declaration name. So, if you had
  /// an interop extension type `JSClass` that wraps `JSArray` without a rename,
  /// this does an `instanceOfString('JSClass')` check and not an
  /// `instanceOfString('Array')` check.
  ///
  /// There are two exceptions to this rule. The first exception is
  /// `JSTypedArray`. As `TypedArray` does not exist as a property in
  /// JavaScript, this does some prototype checking to make `isA<JSTypedArray>`
  /// do the right thing. The other exception is `JSAny`. If you do a
  /// `isA<JSAny>` check, it will only do a `null` check.
  ///
  /// Using this method with a [T] that has an object literal constructor will
  /// result in an error as you likely want to use [JSObject] instead.
  ///
  /// Using this method with a [T] that wraps a primitive JS type will result in
  /// an error telling you to use the primitive JS type instead.
  @Since('3.4')
  external bool isA<T extends JSAny?>();

  /// Converts a JavaScript value to the Dart equivalent if possible.
  ///
  /// Effectively the inverse of [NullableObjectUtilExtension.jsify], [dartify]
  /// takes a JavaScript value and recursively converts it to a Dart object.
  /// Only JavaScript primitives, `Array`s, typed arrays, and map-like objects
  /// with string property names are supported.
  ///
  /// > [!NOTE]
  /// > Prefer using the specific conversion method like `toDart` if you know
  /// > the JavaScript type as this method may perform many type-checks.
  // TODO(srujzs): We likely need stronger tests for this method to ensure
  // consistency.
  external Object? dartify();
}

/// Common utility functions for <code>[Object]?</code>s.
extension NullableObjectUtilExtension on Object? {
  /// Converts a Dart object to the JavaScript equivalent if possible.
  ///
  /// Effectively the inverse of [JSAnyUtilityExtension.dartify], [jsify] takes
  /// a Dart object and recursively converts it to a JavaScript value. Only Dart
  /// primitives, [Iterable]s, typed lists, and [Map]s are supported.
  ///
  /// > [!NOTE]
  /// > Prefer using the specific conversion method like `toJS` if you know the
  /// > Dart type as this method may perform many type-checks.
  // TODO(srujzs): We likely need stronger tests for this method to ensure
  // consistency.
  external JSAny? jsify();
}

/// Utility extensions for [JSFunction].
// TODO(srujzs): We may want to provide a syntax for users to avoid `.call` and
// directly call the function in JavaScript using `(...)`.
extension JSFunctionUtilExtension on JSFunction {
  /// Call this [JSFunction] using the JavaScript `.call` syntax and returns the
  /// result.
  ///
  /// Takes at most 4 args for consistency with other APIs and relative brevity.
  /// If more are needed, you can declare your own external member with the same
  /// syntax.
  // We rename this function since declaring a `call` member makes a class
  // callable in Dart. This is convenient, but unlike Dart functions, JavaScript
  // functions explicitly take a `this` argument (which users can provide `null`
  // for in the case where the function doesn't need it), which may lead to
  // confusion.
  // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Function/call
  @JS('call')
  external JSAny? callAsFunction(
      [JSAny? thisArg, JSAny? arg1, JSAny? arg2, JSAny? arg3, JSAny? arg4]);
}

// Extension members to support conversions between Dart types and JS types.
// Not all Dart types can be converted to JS types and vice versa.
// TODO(srujzs): Move some of these to the associated extension type.

/// Conversions from [JSExportedDartFunction] to [Function].
extension JSExportedDartFunctionToFunction on JSExportedDartFunction {
  /// The Dart [Function] that this [JSExportedDartFunction] wrapped.
  ///
  /// Must be a function that was wrapped with
  /// [FunctionToJSExportedDartFunction.toJS].
  external Function get toDart;
}

/// Conversions from [Function] to [JSExportedDartFunction].
extension FunctionToJSExportedDartFunction on Function {
  /// A callable JavaScript function that wraps this [Function].
  ///
  /// If the static type of the [Function] could not be determined or if
  /// the static type uses types that are disallowed, the call will fail to
  /// compile. See
  /// https://dart.dev/interop/js-interop/js-types#requirements-on-external-declarations-and-function-tojs
  /// for more details on what types are allowed.
  ///
  /// The max number of arguments that are passed to this [Function] from the
  /// wrapper JavaScript function is determined by this [Function]'s static
  /// type. Any extra arguments passed to the JavaScript function after the max
  /// number of arguments are discarded like they are with regular JavaScript
  /// functions.
  ///
  /// Calling this on the same [Function] again will always result in a new
  /// JavaScript function.
  external JSExportedDartFunction get toJS;
}

/// Conversions from [JSBoxedDartObject] to [Object].
extension JSBoxedDartObjectToObject on JSBoxedDartObject {
  /// The Dart [Object] that this [JSBoxedDartObject] wrapped.
  ///
  /// Throws an [Exception] if the Dart runtime was not the same as the one in
  /// which the [Object] was wrapped or if this was not a wrapped Dart [Object].
  external Object get toDart;
}

/// Conversions from [Object] to [JSBoxedDartObject].
extension ObjectToJSBoxedDartObject on Object {
  /// A JavaScript object that wraps this [Object].
  ///
  /// There are no usable members in the resulting [JSBoxedDartObject] and you
  /// may get a new [JSBoxedDartObject] when calling [toJSBox] on the same Dart
  /// [Object].
  ///
  /// Throws an [Exception] if this [Object] is a JavaScript value.
  ///
  /// Unlike [ObjectToExternalDartReference.toExternalReference], this returns a
  /// JavaScript value. Therefore, the representation is guaranteed to be
  /// consistent across all platforms and interop members can be declared on
  /// [JSBoxedDartObject]s.
  external JSBoxedDartObject get toJSBox;
}

/// Conversions from [ExternalDartReference] to the value of type [T].
extension ExternalDartReferenceToObject<T extends Object?>
    on ExternalDartReference<T> {
  /// The Dart value of type [T] that this [ExternalDartReference] refers to.
  ///
  /// When compiling to JavaScript, a Dart object is a JavaScript object, and
  /// therefore this directly returns the Dart object. When compiling to Wasm,
  /// an internal Wasm function is used to convert the opaque JavaScript value
  /// to the original Dart object.
  external T get toDartObject;
}

/// Conversions from a value of type [T] to [ExternalDartReference].
extension ObjectToExternalDartReference<T extends Object?> on T {
  /// An opaque reference to this value of type [T] which can be passed to
  /// JavaScript.
  ///
  /// When compiling to JavaScript, a Dart object is a JavaScript object, and
  /// therefore this directly returns the Dart object. When compiling to Wasm,
  /// an internal Wasm function is used to convert the Dart object to an opaque
  /// JavaScript value. If this value is `null`, returns `null`.
  ///
  /// A value of type [ExternalDartReference] should be treated as completely
  /// opaque. It can only be passed around as-is or converted back using
  /// [ExternalDartReferenceToObject.toDartObject].
  ///
  /// When this getter is called multiple times on the same Dart object, the
  /// underlying references in the resulting [ExternalDartReference]s are
  /// guaranteed to be equal. Therefore, `==` will always return true between
  /// such [ExternalDartReference]s. However, like JS types, `identical` between
  /// such values may return different results depending on the compiler.
  external ExternalDartReference<T> get toExternalReference;
}

/// Conversions from [JSPromise] to [Future].
extension JSPromiseToFuture<T extends JSAny?> on JSPromise<T> {
  /// A [Future] that either completes with the result of the resolved
  /// [JSPromise] or propagates the error that the [JSPromise] rejected with.
  external Future<T> get toDart;
}

/// Conversions from [Future] to [JSPromise] where the [Future] returns a value.
extension FutureOfJSAnyToJSPromise<T extends JSAny?> on Future<T> {
  /// A [JSPromise] that either resolves with the result of the completed
  /// [Future] or rejects with an object that contains its error.
  ///
  /// The rejected object contains the original error as a [JSBoxedDartObject]
  /// in the property `error` and the original stack trace as a [String] in the
  /// property `stack`.
  JSPromise<T> get toJS {
    return JSPromise<T>((JSFunction resolve, JSFunction reject) {
      this.then((JSAny? value) {
        resolve.callAsFunction(resolve, value);
        return value;
      }, onError: (Object error, StackTrace stackTrace) {
        // TODO(srujzs): Can we do something better here? This is pretty much
        // useless to the user unless they call a Dart callback that consumes
        // this value and unboxes.
        final errorConstructor = globalContext['Error'] as JSFunction;
        final wrapper = errorConstructor.callAsConstructor<JSObject>(
            "Dart exception thrown from converted Future. Use the properties "
                    "'error' to fetch the boxed error and 'stack' to recover "
                    "the stack trace."
                .toJS);
        wrapper['error'] = error.toJSBox;
        wrapper['stack'] = stackTrace.toString().toJS;
        reject.callAsFunction(reject, wrapper);
        return wrapper;
      });
    }.toJS);
  }
}

/// Conversions from [Future] to [JSPromise] where the [Future] does not return
/// a value.
extension FutureOfVoidToJSPromise on Future<void> {
  /// A [JSPromise] that either resolves once this [Future] completes or rejects
  /// with an object that contains its error.
  ///
  /// The rejected object contains the original error as a [JSBoxedDartObject]
  /// in the property `error` and the original stack trace as a [String] in the
  /// property `stack`.
  JSPromise get toJS {
    return JSPromise((JSFunction resolve, JSFunction reject) {
      this.then((_) => resolve.callAsFunction(resolve),
          onError: (Object error, StackTrace stackTrace) {
        // TODO(srujzs): Can we do something better here? This is pretty much
        // useless to the user unless they call a Dart callback that consumes
        // this value and unboxes.
        final errorConstructor = globalContext['Error'] as JSFunction;
        final wrapper = errorConstructor.callAsConstructor<JSObject>(
            "Dart exception thrown from converted Future. Use the properties "
                    "'error' to fetch the boxed error and 'stack' to recover "
                    "the stack trace."
                .toJS);
        wrapper['error'] = error.toJSBox;
        wrapper['stack'] = stackTrace.toString().toJS;
        reject.callAsFunction(reject, wrapper);
      });
    }.toJS);
  }
}

/// Conversions from [JSArrayBuffer] to [ByteBuffer].
extension JSArrayBufferToByteBuffer on JSArrayBuffer {
  /// Converts this [JSArrayBuffer] to a [ByteBuffer] by either casting or
  /// wrapping it.
  ///
  /// When compiling to JavaScript, [ByteBuffer]s are [JSArrayBuffer]s and this
  /// operation will be a cast. When compiling to Wasm, a wrapper is introduced.
  /// Modifications to this [JSArrayBuffer] will affect the [ByteBuffer] and
  /// vice versa.
  external ByteBuffer get toDart;
}

/// Conversions from [ByteBuffer] to [JSArrayBuffer].
extension ByteBufferToJSArrayBuffer on ByteBuffer {
  /// Converts this [ByteBuffer] to a [JSArrayBuffer] by either casting,
  /// unwrapping, or cloning the [ByteBuffer].
  ///
  /// > [!NOTE]
  /// > Depending on whether code is compiled to JavaScript or Wasm, this
  /// > conversion will have different semantics.
  /// > When compiling to JavaScript, all typed lists are the equivalent
  /// > JavaScript typed arrays, and therefore this method simply casts.
  /// > When compiling to Wasm, this [ByteBuffer] may or may not be a wrapper
  /// > depending on if it was converted from JavaScript or instantiated in
  /// > Dart. If it's a wrapper, this method unwraps it. If it's instantiated in
  /// > Dart, this method clones this [ByteBuffer]'s values into a new
  /// > [JSArrayBuffer].
  /// > Avoid assuming that modifications to this [ByteBuffer] will affect the
  /// > [JSArrayBuffer] and vice versa unless it was instantiated in JavaScript.
  external JSArrayBuffer get toJS;
}

/// Conversions from [JSDataView] to [ByteData].
extension JSDataViewToByteData on JSDataView {
  /// Converts this [JSDataView] to a [ByteData] by either casting or wrapping
  /// it.
  ///
  /// When compiling to JavaScript, [ByteData]s are [JSDataView]s and this
  /// operation will be a cast. When compiling to Wasm, a wrapper is introduced.
  /// Modifications to this [JSDataView] will affect the [ByteData] and vice
  /// versa.
  external ByteData get toDart;
}

/// Conversions from [ByteData] to [JSDataView].
extension ByteDataToJSDataView on ByteData {
  /// Converts this [ByteData] to a [JSDataView] by either casting, unwrapping,
  /// or cloning the [ByteData].
  ///
  /// > [!NOTE]
  /// > Depending on whether code is compiled to JavaScript or Wasm, this
  /// > conversion will have different semantics.
  /// > When compiling to JavaScript, all typed lists are the equivalent
  /// > JavaScript typed arrays, and therefore this method simply casts.
  /// > When compiling to Wasm, this [ByteData] may or may not be a wrapper
  /// > depending on if it was converted from JavaScript or instantiated in
  /// > Dart. If it's a wrapper, this method unwraps it. If it's instantiated in
  /// > Dart, this method clones this [ByteData]'s values into a new
  /// > [JSDataView].
  /// > Avoid assuming that modifications to this [ByteData] will affect the
  /// > [JSDataView] and vice versa unless it was instantiated in JavaScript.
  external JSDataView get toJS;
}

/// Conversions from [JSInt8Array] to [Int8List].
extension JSInt8ArrayToInt8List on JSInt8Array {
  /// Converts this [JSInt8Array] to a [Int8List] by either casting or wrapping
  /// it.
  ///
  /// When compiling to JavaScript, [Int8List]s are [JSInt8Array]s and this
  /// operation will be a cast. When compiling to Wasm, a wrapper is introduced.
  /// Modifications to this [JSInt8Array] will affect the [Int8List] and vice
  /// versa.
  external Int8List get toDart;
}

/// Conversions from [Int8List] to [JSInt8Array].
extension Int8ListToJSInt8Array on Int8List {
  /// Converts this [Int8List] to a [JSInt8Array] by either casting,
  /// unwrapping, or cloning the [Int8List].
  ///
  /// > [!NOTE]
  /// > Depending on whether code is compiled to JavaScript or Wasm, this
  /// > conversion will have different semantics.
  /// > When compiling to JavaScript, all typed lists are the equivalent
  /// > JavaScript typed arrays, and therefore this method simply casts.
  /// > When compiling to Wasm, this [Int8List] may or may not be a wrapper
  /// > depending on if it was converted from JavaScript or instantiated in
  /// > Dart. If it's a wrapper, this method unwraps it. If it's instantiated in
  /// > Dart, this method clones this [Int8List]'s values into a new
  /// > [JSInt8Array].
  /// > Avoid assuming that modifications to this [Int8List] will affect the
  /// > [JSInt8Array] and vice versa unless it was instantiated in JavaScript.
  external JSInt8Array get toJS;
}

/// Conversions from [JSUint8Array] to [Uint8List].
extension JSUint8ArrayToUint8List on JSUint8Array {
  /// Converts this [JSUint8Array] to a [Uint8List] by either casting or
  /// wrapping it.
  ///
  /// When compiling to JavaScript, [Uint8List]s are [JSUint8Array]s and this
  /// operation will be a cast. When compiling to Wasm, a wrapper is introduced.
  /// Modifications to this [JSUint8Array] will affect the [Uint8List] and vice
  /// versa.
  external Uint8List get toDart;
}

/// Conversions from [Uint8List] to [JSUint8Array].
extension Uint8ListToJSUint8Array on Uint8List {
  /// Converts this [Uint8List] to a [JSUint8Array] by either casting,
  /// unwrapping, or cloning the [Uint8List].
  ///
  /// > [!NOTE]
  /// > Depending on whether code is compiled to JavaScript or Wasm, this
  /// > conversion will have different semantics.
  /// > When compiling to JavaScript, all typed lists are the equivalent
  /// > JavaScript typed arrays, and therefore this method simply casts.
  /// > When compiling to Wasm, this [Uint8List] may or may not be a wrapper
  /// > depending on if it was converted from JavaScript or instantiated in
  /// > Dart. If it's a wrapper, this method unwraps it. If it's instantiated in
  /// > Dart, this method clones this [Uint8List]'s values into a new
  /// > [JSUint8Array].
  /// > Avoid assuming that modifications to this [Uint8List] will affect the
  /// > [JSUint8Array] and vice versa unless it was instantiated in JavaScript.
  external JSUint8Array get toJS;
}

/// Conversions from [JSUint8ClampedArray] to [Uint8ClampedList].
extension JSUint8ClampedArrayToUint8ClampedList on JSUint8ClampedArray {
  /// Converts this [JSUint8ClampedArray] to a [Uint8ClampedList] by either
  /// casting or wrapping it.
  ///
  /// When compiling to JavaScript, [Uint8ClampedList]s are
  /// [JSUint8ClampedArray]s and this operation will be a cast. When compiling
  /// to Wasm, a wrapper is introduced. Modifications to this
  /// [JSUint8ClampedArray] will affect the [Uint8ClampedList] and vice versa.
  external Uint8ClampedList get toDart;
}

/// Conversions from [Uint8ClampedList] to [JSUint8ClampedArray].
extension Uint8ClampedListToJSUint8ClampedArray on Uint8ClampedList {
  /// Converts this [Uint8ClampedList] to a [JSUint8ClampedArray] by either
  /// casting, unwrapping, or cloning the [Uint8ClampedList].
  ///
  /// > [!NOTE]
  /// > Depending on whether code is compiled to JavaScript or Wasm, this
  /// > conversion will have different semantics.
  /// > When compiling to JavaScript, all typed lists are the equivalent
  /// > JavaScript typed arrays, and therefore this method simply casts.
  /// > When compiling to Wasm, this [Uint8ClampedList] may or may not be a
  /// > wrapper depending on if it was converted from JavaScript or instantiated
  /// > in Dart. If it's a wrapper, this method unwraps it. If it's instantiated
  /// > in Dart, this method clones this [Uint8ClampedList]'s values into a new
  /// > [JSUint8ClampedArray].
  /// > Avoid assuming that modifications to this [Uint8ClampedList] will affect
  /// > the [JSUint8ClampedArray] and vice versa unless it was instantiated in
  /// > JavaScript.
  external JSUint8ClampedArray get toJS;
}

/// Conversions from [JSInt16Array] to [Int16List].
extension JSInt16ArrayToInt16List on JSInt16Array {
  /// Converts this [JSInt16Array] to a [Int16List] by either casting or
  /// wrapping it.
  ///
  /// When compiling to JavaScript, [Int16List]s are [JSInt16Array]s and this
  /// operation will be a cast. When compiling to Wasm, a wrapper is introduced.
  /// Modifications to this [JSInt16Array] will affect the [Int16List] and vice
  /// versa.
  external Int16List get toDart;
}

/// Conversions from [Int16List] to [JSInt16Array].
extension Int16ListToJSInt16Array on Int16List {
  /// Converts this [Int16List] to a [JSInt16Array] by either casting,
  /// unwrapping, or cloning the [Int16List].
  ///
  /// > [!NOTE]
  /// > Depending on whether code is compiled to JavaScript or Wasm, this
  /// > conversion will have different semantics.
  /// > When compiling to JavaScript, all typed lists are the equivalent
  /// > JavaScript typed arrays, and therefore this method simply casts.
  /// > When compiling to Wasm, this [Int16List] may or may not be a wrapper
  /// > depending on if it was converted from JavaScript or instantiated in
  /// > Dart. If it's a wrapper, this method unwraps it. If it's instantiated in
  /// > Dart, this method clones this [Int16List]'s values into a new
  /// > [JSInt16Array].
  /// > Avoid assuming that modifications to this [Int16List] will affect the
  /// > [JSInt16Array] and vice versa unless it was instantiated in JavaScript.
  external JSInt16Array get toJS;
}

/// Conversions from [JSUint16Array] to [Uint16List].
extension JSUint16ArrayToInt16List on JSUint16Array {
  /// Converts this [JSUint16Array] to a [Uint16List] by either casting or
  /// wrapping it.
  ///
  /// When compiling to JavaScript, [Uint16List]s are [JSUint16Array]s and this
  /// operation will be a cast. When compiling to Wasm, a wrapper is introduced.
  /// Modifications to this [JSUint16Array] will affect the [Uint16List] and
  /// vice versa.
  external Uint16List get toDart;
}

/// Conversions from [Uint16List] to [JSUint16Array].
extension Uint16ListToJSInt16Array on Uint16List {
  /// Converts this [Uint16List] to a [JSUint16Array] by either casting,
  /// unwrapping, or cloning the [Uint16List].
  ///
  /// > [!NOTE]
  /// > Depending on whether code is compiled to JavaScript or Wasm, this
  /// > conversion will have different semantics.
  /// > When compiling to JavaScript, all typed lists are the equivalent
  /// > JavaScript typed arrays, and therefore this method simply casts.
  /// > When compiling to Wasm, this [Uint16List] may or may not be a wrapper
  /// > depending on if it was converted from JavaScript or instantiated in
  /// > Dart. If it's a wrapper, this method unwraps it. If it's instantiated in
  /// > Dart, this method clones this [Uint16List]'s values into a new
  /// > [JSUint16Array].
  /// > Avoid assuming that modifications to this [Uint16List] will affect the
  /// > [JSUint16Array] and vice versa unless it was instantiated in JavaScript.
  external JSUint16Array get toJS;
}

/// Conversions from [JSInt32Array] to [Int32List].
extension JSInt32ArrayToInt32List on JSInt32Array {
  /// Converts this [JSInt32Array] to a [Int32List] by either casting or
  /// wrapping it.
  ///
  /// When compiling to JavaScript, [Int32List]s are [JSInt32Array]s and this
  /// operation will be a cast. When compiling to Wasm, a wrapper is introduced.
  /// Modifications to this [JSInt32Array] will affect the [Int32List] and vice
  /// versa.
  external Int32List get toDart;
}

/// Conversions from [Int32List] to [JSInt32Array].
extension Int32ListToJSInt32Array on Int32List {
  /// Converts this [Int32List] to a [JSInt32Array] by either casting,
  /// unwrapping, or cloning the [Int32List].
  ///
  /// > [!NOTE]
  /// > Depending on whether code is compiled to JavaScript or Wasm, this
  /// > conversion will have different semantics.
  /// > When compiling to JavaScript, all typed lists are the equivalent
  /// > JavaScript typed arrays, and therefore this method simply casts.
  /// > When compiling to Wasm, this [Int32List] may or may not be a wrapper
  /// > depending on if it was converted from JavaScript or instantiated in
  /// > Dart. If it's a wrapper, this method unwraps it. If it's instantiated in
  /// > Dart, this method clones this [Int32List]'s values into a new
  /// > [JSInt32Array].
  /// > Avoid assuming that modifications to this [Int32List] will affect the
  /// > [JSInt32Array] and vice versa unless it was instantiated in JavaScript.
  external JSInt32Array get toJS;
}

/// Conversions from [JSUint32Array] to [Uint32List].
extension JSUint32ArrayToUint32List on JSUint32Array {
  /// Converts this [JSUint32Array] to a [Uint32List] by either casting or
  /// wrapping it.
  ///
  /// When compiling to JavaScript, [Uint32List]s are [JSUint32Array]s and this
  /// operation will be a cast. When compiling to Wasm, a wrapper is introduced.
  /// Modifications to this [JSUint32Array] will affect the [Uint32List] and
  /// vice versa.
  external Uint32List get toDart;
}

/// Conversions from [Uint32List] to [JSUint32Array].
extension Uint32ListToJSUint32Array on Uint32List {
  /// Converts this [Uint32List] to a [JSUint32Array] by either casting,
  /// unwrapping, or cloning the [Uint32List].
  ///
  /// > [!NOTE]
  /// > Depending on whether code is compiled to JavaScript or Wasm, this
  /// > conversion will have different semantics.
  /// > When compiling to JavaScript, all typed lists are the equivalent
  /// > JavaScript typed arrays, and therefore this method simply casts.
  /// > When compiling to Wasm, this [Uint32List] may or may not be a wrapper
  /// > depending on if it was converted from JavaScript or instantiated in
  /// > Dart. If it's a wrapper, this method unwraps it. If it's instantiated in
  /// > Dart, this method clones this [Uint32List]'s values into a new
  /// > [JSUint32Array].
  /// > Avoid assuming that modifications to this [Uint32List] will affect the
  /// > [JSUint32Array] and vice versa unless it was instantiated in JavaScript.
  external JSUint32Array get toJS;
}

/// Conversions from [JSFloat32Array] to [Float32List].
extension JSFloat32ArrayToFloat32List on JSFloat32Array {
  /// Converts this [JSFloat32Array] to a [Float32List] by either casting or
  /// wrapping it.
  ///
  /// When compiling to JavaScript, [Float32List]s are [JSFloat32Array]s and
  /// this operation will be a cast. When compiling to Wasm, a wrapper is
  /// introduced. Modifications to this [JSFloat32Array] will affect the
  /// [Float32List] and vice versa.
  external Float32List get toDart;
}

/// Conversions from [Float32List] to [JSFloat32Array].
extension Float32ListToJSFloat32Array on Float32List {
  /// Converts this [Float32List] to a [JSFloat32Array] by either casting,
  /// unwrapping, or cloning the [Float32List].
  ///
  /// > [!NOTE]
  /// > Depending on whether code is compiled to JavaScript or Wasm, this
  /// > conversion will have different semantics.
  /// > When compiling to JavaScript, all typed lists are the equivalent
  /// > JavaScript typed arrays, and therefore this method simply casts.
  /// > When compiling to Wasm, this [Float32List] may or may not be a wrapper
  /// > depending on if it was converted from JavaScript or instantiated in
  /// > Dart. If it's a wrapper, this method unwraps it. If it's instantiated in
  /// > Dart, this method clones this [Float32List]'s values into a new
  /// > [JSFloat32Array].
  /// > Avoid assuming that modifications to this [Float32List] will affect the
  /// > [JSFloat32Array] and vice versa unless it was instantiated in
  /// > JavaScript.
  external JSFloat32Array get toJS;
}

/// Conversions from [JSFloat64Array] to [Float64List].
extension JSFloat64ArrayToFloat64List on JSFloat64Array {
  /// Converts this [JSFloat64Array] to a [Float64List] by either casting or
  /// wrapping it.
  ///
  /// When compiling to JavaScript, [Float64List]s are [JSFloat64Array]s and
  /// this operation will be a cast. When compiling to Wasm, a wrapper is
  /// introduced. Modifications to this [JSFloat64Array] will affect the
  /// [Float64List] and vice versa.
  external Float64List get toDart;
}

/// Conversions from [Float64List] to [JSFloat64Array].
extension Float64ListToJSFloat64Array on Float64List {
  /// Converts this [Float64List] to a [JSFloat64Array] by either casting,
  /// unwrapping, or cloning the [Float64List].
  ///
  /// > [!NOTE]
  /// > Depending on whether code is compiled to JavaScript or Wasm, this
  /// > conversion will have different semantics.
  /// > When compiling to JavaScript, all typed lists are the equivalent
  /// > JavaScript typed arrays, and therefore this method simply casts.
  /// > When compiling to Wasm, this [Float64List] may or may not be a wrapper
  /// > depending on if it was converted from JavaScript or instantiated in
  /// > Dart. If it's a wrapper, this method unwraps it. If it's instantiated in
  /// > Dart, this method clones this [Float64List]'s values into a new
  /// > [JSFloat64Array].
  /// > Avoid assuming that modifications to this [Float64List] will affect the
  /// > [JSFloat64Array] and vice versa unless it was instantiated in
  /// > JavaScript.
  external JSFloat64Array get toJS;
}

/// Conversions from [JSArray] to [List].
extension JSArrayToList<T extends JSAny?> on JSArray<T> {
  /// Converts this [JSArray] to a [List] by either casting or wrapping it.
  ///
  /// When compiling to JavaScript, [List]s are [JSArray]s and this will be a
  /// cast. When compiling to Wasm, a wrapper is introduced. Modifications to
  /// this [JSArray] will affect the [List] and vice versa. In order to ensure
  /// type soundness, this method may introduce casts when accessing elements in
  /// order to ensure they are of type [T].
  external List<T> get toDart;
}

/// Conversions from [List] to [JSArray].
extension ListToJSArray<T extends JSAny?> on List<T> {
  /// Converts this [List] to a [JSArray] by either casting, unwrapping, or
  /// cloning the [List].
  ///
  /// > [!NOTE]
  /// > Depending on whether code is compiled to JavaScript or Wasm, this
  /// > conversion will have different semantics.
  /// > When compiling to JavaScript, the core [List] is a JavaScript `Array`,
  /// > and therefore this method simply casts. User-defined [List]s are
  /// > currently unsupported when compiling to JavaScript.
  /// > When compiling to Wasm, this [List] may or may not be a wrapper
  /// > depending on if it was converted from JavaScript or instantiated in
  /// > Dart. If it's a wrapper, this method unwraps it. If it's instantiated in
  /// > Dart, this method clones this [List]'s values into a new [JSArray].
  /// > Avoid assuming that modifications to this [List] will affect the
  /// > [JSArray] and vice versa unless it was instantiated in JavaScript.
  external JSArray<T> get toJS;

  /// Converts this [List] to a [JSArray] by either casting, unwrapping, or
  /// proxying the [List].
  ///
  /// > [!NOTE]
  /// > Depending on whether code is compiled to JavaScript or Wasm, this
  /// > conversion will have different semantics.
  /// > When compiling to JavaScript, the core [List] is a JavaScript `Array`,
  /// > and therefore this method simply casts. User-defined [List]s are
  /// > currently unsupported when compiling to JavaScript.
  /// > When compiling to Wasm, this [List] may or may not be a wrapper
  /// > depending on if it was converted from JavaScript or instantiated in
  /// > Dart. If it's a wrapper, this method unwraps it. If it's instantiated in
  /// > Dart, this method proxies the [List] using a heavyweight `Array`
  /// > wrapper. Access to the original [List]'s elements may be very
  /// > unperformant.
  /// > Modifications to this [List] will affect the [JSArray] and vice versa.
  external JSArray<T> get toJSProxyOrRef;
}

/// Conversions from [JSNumber] to [double] or [int].
extension JSNumberToNumber on JSNumber {
  /// Converts this [JSNumber] to a [double].
  external double get toDartDouble;

  /// Converts this [JSNumber] to an [int].
  ///
  /// If this [JSNumber] is not an integer value, throws.
  external int get toDartInt;
}

/// Conversions from [double] to [JSNumber].
extension DoubleToJSNumber on double {
  /// Converts this [double] to a [JSNumber].
  external JSNumber get toJS;
}

/// Conversions from [num] to [JSNumber].
extension NumToJSExtension on num {
  /// Converts this [num] to a [JSNumber].
  JSNumber get toJS => DoubleToJSNumber(toDouble()).toJS;
}

/// Conversions from [JSBoolean] to [bool].
extension JSBooleanToBool on JSBoolean {
  /// Converts this [JSBoolean] to a [bool].
  external bool get toDart;
}

/// Conversions from [bool] to [JSBoolean].
extension BoolToJSBoolean on bool {
  /// Converts this [bool] to a [JSBoolean].
  external JSBoolean get toJS;
}

/// Conversions from [JSString] to [String].
extension JSStringToString on JSString {
  /// Converts this [JSString] to a [String].
  external String get toDart;
}

/// Conversions from [String] to [JSString].
extension StringToJSString on String {
  /// Converts this [String] to a [JSString].
  external JSString get toJS;
}

/// General-purpose JavaScript operators.
///
/// Indexing operators (`[]`, `[]=`) should be declared through operator
/// overloading instead like:
/// ```
/// external operator int [](int key);
/// ```
///
/// All operators in this extension shall accept and return only JS types.
// TODO(srujzs): Add more as needed. For now, we just expose the ones needed to
// migrate from `dart:js_util`.
extension JSAnyOperatorExtension on JSAny? {
  // Arithmetic operators.

  /// The result of <code>`this` + [any]</code> in JavaScript.
  external JSAny add(JSAny? any);

  /// The result of <code>`this` - [any]</code> in JavaScript.
  external JSAny subtract(JSAny? any);

  /// The result of <code>`this` * [any]</code> in JavaScript.
  external JSAny multiply(JSAny? any);

  /// The result of <code>`this` / [any]</code> in JavaScript.
  external JSAny divide(JSAny? any);

  /// The result of <code>`this` % [any]</code> in JavaScript.
  external JSAny modulo(JSAny? any);

  /// The result of <code>`this` ** [any]</code> in JavaScript.
  external JSAny exponentiate(JSAny? any);

  // Comparison operators.

  /// The result of <code>`this` > [any]</code> in JavaScript.
  external JSBoolean greaterThan(JSAny? any);

  /// The result of <code>`this` >= [any]</code> in JavaScript.
  external JSBoolean greaterThanOrEqualTo(JSAny? any);

  /// The result of <code>`this` < [any]</code> in JavaScript.
  external JSBoolean lessThan(JSAny? any);

  /// The result of <code>`this` <= [any]</code> in JavaScript.
  external JSBoolean lessThanOrEqualTo(JSAny? any);

  /// The result of <code>`this` == [any]</code> in JavaScript.
  external JSBoolean equals(JSAny? any);

  /// The result of <code>`this` != [any]</code> in JavaScript.
  external JSBoolean notEquals(JSAny? any);

  /// The result of <code>`this` === [any]</code> in JavaScript.
  external JSBoolean strictEquals(JSAny? any);

  /// The result of <code>`this` !== [any]</code> in JavaScript.
  external JSBoolean strictNotEquals(JSAny? any);

  // Bitwise operators.

  /// The result of <code>`this` >>> [any]</code> in JavaScript.
  // TODO(srujzs): This should return `num` or `double` instead.
  external JSNumber unsignedRightShift(JSAny? any);

  // Logical operators.

  /// The result of <code>`this` && [any]</code> in JavaScript.
  external JSAny? and(JSAny? any);

  /// The result of <code>`this` || [any]</code> in JavaScript.
  external JSAny? or(JSAny? any);

  /// The result of <code>!`this`</code> in JavaScript.
  external JSBoolean get not;

  /// The result of <code>!!`this`</code> in JavaScript.
  external JSBoolean get isTruthy;
}

/// The global scope that is used to find user-declared interop members.
///
/// For example:
///
/// ```
/// @JS()
/// external String get name;
/// ```
///
/// Reading `name` will execute JavaScript code like `globalContext.name`.
///
/// There are subtle differences depending on the compiler, but in general,
/// [globalContext] can be treated like JavaScript's `globalThis`.
external JSObject get globalContext;

/// Given a instance of a Dart class that contains an <code>@[JSExport]</code>
/// annotation, creates a JavaScript object that wraps the given Dart object.
///
/// The object literal will be a map of properties, which are either the written
/// instance member names or their renames, to callbacks that call the
/// corresponding Dart instance members.
///
/// See https://dart.dev/interop/js-interop/mock for more details on how to
/// declare classes that can be used in this method.
external JSObject createJSInteropWrapper<T extends Object>(T dartObject);

// TODO(srujzs): Expose this method when we handle conformance checking for
// interop extension types. We don't expose this method today due to the bound
// on `T`. `@staticInterop` types can't implement `JSObject`, so this method
// simply wouldn't work. We could make it extend `Object` to support the
// `@staticInterop` case, but if we ever refactor to `extends JSObject`, this
// would be a breaking change. For now, due to the low usage of
// `createStaticInteropMock`, we avoid introducing this method until later.
// external T createJSInteropMock<T extends JSObject, U extends Object>(
//     U dartMock, [JSObject? proto = null]);

/// Dynamically imports a JavaScript module with the given [moduleName] using
/// the JavaScript `import()` syntax.
///
/// See https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/import
/// for more details.
///
/// Returns a [JSPromise] that resolves to a [JSObject] that's the module
/// namespace object.
external JSPromise<JSObject> importModule(JSAny moduleName);
