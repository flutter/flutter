// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library defines the representation of runtime types.
part of dart._runtime;

@notNull
bool _nativeNonNullAsserts = true;

/// Enables null assertions on native APIs to make sure values returned from the
/// browser are sound.
///
/// These apply to dart:html and similar web libraries.
void nativeNonNullAsserts(bool enable) {
  // This value is only read from `checkNativeNonNull` and calls to that method
  // are only generated in sound null safe code.
  _nativeNonNullAsserts = enable;
}

@notNull
bool _jsInteropNonNullAsserts = false;

/// Enables null assertions on non-static JavaScript interop APIs to make sure
/// values returned are sound with respect to the nullability.
void jsInteropNonNullAsserts(bool enable) {
  // This value is only read from `jsInteropNullCheck`.
  _jsInteropNonNullAsserts = enable;
}

/// A JavaScript Symbol used to store the Rti signature object on a function.
///
/// Accessed by a call to `JS_GET_NAME(JsGetName.SIGNATURE_NAME)`.
final _functionRti = JS('', r'Symbol("$signatureRti")');

/// Asserts that [f] is a native JS function and returns it if so.
///
/// This function should be used to ensure that a function is a native JS
/// function before it is passed to native JS code.
///
/// NOTE: The generic type argument bound is not enforced due to the
/// `@NoReifyGeneric` annotation. In practice values of other types are passed
/// as [f]. All non-function values are allowed to pass through as well and
/// are returned without error.
@NoReifyGeneric()
F assertInterop<F extends Function?>(F f) {
  assert(
    f is LegacyJavaScriptObject ||
        !JS<bool>('bool', '# instanceof #.Function', f, global_),
    'Dart function requires `allowInterop` to be passed to JavaScript.',
  );
  return f;
}

/// Returns `true` when [obj] represents a Dart class.
@notNull
bool isDartClass(Object? obj) {
  // All Dart classes are instances of JavaScript functions.
  if (!JS<bool>('!', '# instanceof Function', obj)) return false;
  // All Dart classes have an interface type recipe attached to them. We put the
  // `!=` check in the foreign function call, since the Dart `!=` check would
  // lower to `!==`. In the case where [obj] is a JS function, the result of
  // getting this property would be `undefined`, and therefore `!== null` would
  // be true, which is not what we want.
  return JS<bool>('!', '#.# != null', obj, rti.interfaceTypeRecipePropertyName);
}

/// Returns `true` when [obj] represents a Dart function.
@notNull
bool isDartFunction(Object? obj) {
  // All Dart functions are instances of JavaScript functions.
  if (!JS<bool>('!', '# instanceof Function', obj)) return false;
  // All Dart functions have a signature attached to them. We put the `!=` check
  // in the foreign function call, since the Dart `!=` check would lower to
  // `!==`. In the case where [obj] is a JS function, the result of getting this
  // property would be `undefined`, and therefore `!== null` would be true,
  // which is not what we want.
  return JS<bool>(
    '!',
    '#[#] != null',
    obj,
    JS_GET_NAME(JsGetName.SIGNATURE_NAME),
  );
}

Expando<Function> _assertInteropExpando = Expando<Function>();

@NoReifyGeneric()
F tearoffInterop<F extends Function?>(F f, bool checkReturnType) {
  // Wrap a JS function with a closure that ensures all function arguments are
  // native JS functions.
  if (f is! LegacyJavaScriptObject || f == null) return f;
  var ret = _assertInteropExpando[f];
  if (ret == null) {
    ret =
        checkReturnType
            ? JS(
              '',
              'function (...arguments) {'
                  ' var args = arguments.map(#);'
                  ' return #(#.apply(this, args));'
                  '}',
              assertInterop,
              jsInteropNullCheck,
              f,
            )
            : JS(
              '',
              'function (...arguments) {'
                  ' var args = arguments.map(#);'
                  ' return #.apply(this, args);'
                  '}',
              assertInterop,
              f,
            );
    _assertInteropExpando[f] = ret;
  }
  // Suppress a cast back to F.
  return JS('', '#', ret);
}

void _warn(arg) {
  JS('void', 'console.warn(#)', arg);
}

void checkTypeBound(
  @notNull Object type,
  @notNull Object bound,
  @notNull String name,
) {
  var validSubtype = rti.isSubtype(
    JS_EMBEDDED_GLOBAL('', RTI_UNIVERSE),
    JS<rti.Rti>('!', '#', type),
    JS<rti.Rti>('!', '#', bound),
  );
  if (!validSubtype) {
    throwTypeError('type `$type` does not extend `$bound` of `$name`.');
  }
}

@notNull
String typeName(Object? type) {
  if (JS<bool>('!', '# === void 0', type)) return 'undefined type';
  if (type == null) return 'null type';
  return rti.rtiToString(type);
}

/// Wraps the JavaScript `instanceof` operator returning `true` if [obj] is an
/// instance of the JavaScript class reference for [cls].
///
/// This method is equivalent to:
///
///    JS<bool>('!', '# instanceof #', obj, JS_CLASS_REF(cls));
///
/// but the code is generated by the compiler directly (a low-tech way of
/// inlining).
@notNull
external bool _jsInstanceOf(obj, cls);

/// The extraction and function call are inlined directly by the compiler
///
/// See compiler.dart, `visitStaticInvocation()`).
external Object? extractTypeArguments<T>(T instance, Function f);
