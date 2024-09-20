// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for dart:js_util library.

import 'dart:_foreign_helper' show JS, DART_CLOSURE_TO_JS;
import 'dart:_interceptors' show DART_CLOSURE_PROPERTY_NAME, JavaScriptFunction;
import 'dart:_internal' show patch;
import 'dart:_js_helper'
    show
        isJSFunction,
        JS_FUNCTION_PROPERTY_NAME,
        JS_FUNCTION_PROPERTY_NAME_CAPTURE_THIS;

_convertDartFunctionFast(Function f) {
  var existing = JS('', '#.#', f, JS_FUNCTION_PROPERTY_NAME);
  if (existing != null) return existing;
  var ret = JS(
      'JavaScriptFunction',
      '''
        function(_call, f) {
          return function() {
            return _call(f, Array.prototype.slice.apply(arguments));
          }
        }(#, #)
      ''',
      DART_CLOSURE_TO_JS(_callDartFunctionFast),
      f);
  JS('', '#.# = #', ret, DART_CLOSURE_PROPERTY_NAME, f);
  JS('', '#.# = #', f, JS_FUNCTION_PROPERTY_NAME, ret);
  return ret;
}

_convertDartFunctionFastCaptureThis(Function f) {
  var existing = JS('', '#.#', f, JS_FUNCTION_PROPERTY_NAME_CAPTURE_THIS);
  if (existing != null) return existing;
  var ret = JS(
      'JavaScriptFunction',
      '''
        function(_call, f) {
          return function() {
            return _call(f, this,Array.prototype.slice.apply(arguments));
          }
        }(#, #)
      ''',
      DART_CLOSURE_TO_JS(_callDartFunctionFastCaptureThis),
      f);
  JS('', '#.# = #', ret, DART_CLOSURE_PROPERTY_NAME, f);
  JS('', '#.# = #', f, JS_FUNCTION_PROPERTY_NAME_CAPTURE_THIS, ret);
  return ret;
}

_callDartFunctionFast(callback, List arguments) {
  return Function.apply(callback, arguments);
}

_callDartFunctionFastCaptureThis(callback, self, List arguments) {
  return Function.apply(callback, [self]..addAll(arguments));
}

@patch
F allowInterop<F extends Function>(F f) {
  if (isJSFunction(f)) {
    // Already supports interop, just use the existing function.
    return f;
  } else {
    return _convertDartFunctionFast(f);
  }
}

@patch
Function allowInteropCaptureThis(Function f) {
  if (isJSFunction(f)) {
    // Behavior when the function is already a JS function is unspecified.
    throw ArgumentError(
        "Function is already a JS function so cannot capture this.");
    return f;
  } else {
    return _convertDartFunctionFastCaptureThis(f);
  }
}

JavaScriptFunction _functionToJS0(Function f) {
  // This can only happen if a user casted a JavaScriptFunction to Function.
  // Such a cast is an error in dart2wasm, so we should make this behavior an
  // error as well.
  if (isJSFunction(f)) {
    throw ArgumentError('Attempting to rewrap a JS function.');
  }
  final result = JS(
      'JavaScriptFunction',
      '''
        function(_call, f) {
          return function() {
            return _call(f);
          }
        }(#, #)
      ''',
      DART_CLOSURE_TO_JS(_callDartFunctionFast0),
      f);
  JS('', '#.# = #', result, DART_CLOSURE_PROPERTY_NAME, f);
  return result;
}

JavaScriptFunction _functionToJS1(Function f) {
  if (isJSFunction(f)) {
    throw ArgumentError('Attempting to rewrap a JS function.');
  }
  final result = JS(
      'JavaScriptFunction',
      '''
        function(_call, f) {
          return function(arg1) {
            return _call(f, arg1, arguments.length);
          }
        }(#, #)
      ''',
      DART_CLOSURE_TO_JS(_callDartFunctionFast1),
      f);
  JS('', '#.# = #', result, DART_CLOSURE_PROPERTY_NAME, f);
  return result;
}

JavaScriptFunction _functionToJS2(Function f) {
  if (isJSFunction(f)) {
    throw ArgumentError('Attempting to rewrap a JS function.');
  }
  final result = JS(
      'JavaScriptFunction',
      '''
        function(_call, f) {
          return function(arg1, arg2) {
            return _call(f, arg1, arg2, arguments.length);
          }
        }(#, #)
      ''',
      DART_CLOSURE_TO_JS(_callDartFunctionFast2),
      f);
  JS('', '#.# = #', result, DART_CLOSURE_PROPERTY_NAME, f);
  return result;
}

JavaScriptFunction _functionToJS3(Function f) {
  if (isJSFunction(f)) {
    throw ArgumentError('Attempting to rewrap a JS function.');
  }
  final result = JS(
      'JavaScriptFunction',
      '''
        function(_call, f) {
          return function(arg1, arg2, arg3) {
            return _call(f, arg1, arg2, arg3, arguments.length);
          }
        }(#, #)
      ''',
      DART_CLOSURE_TO_JS(_callDartFunctionFast3),
      f);
  JS('', '#.# = #', result, DART_CLOSURE_PROPERTY_NAME, f);
  return result;
}

JavaScriptFunction _functionToJS4(Function f) {
  if (isJSFunction(f)) {
    throw ArgumentError('Attempting to rewrap a JS function.');
  }
  final result = JS(
      'JavaScriptFunction',
      '''
        function(_call, f) {
          return function(arg1, arg2, arg3, arg4) {
            return _call(f, arg1, arg2, arg3, arg4, arguments.length);
          }
        }(#, #)
      ''',
      DART_CLOSURE_TO_JS(_callDartFunctionFast4),
      f);
  JS('', '#.# = #', result, DART_CLOSURE_PROPERTY_NAME, f);
  return result;
}

JavaScriptFunction _functionToJS5(Function f) {
  if (isJSFunction(f)) {
    throw ArgumentError('Attempting to rewrap a JS function.');
  }
  final result = JS(
      'JavaScriptFunction',
      '''
        function(_call, f) {
          return function(arg1, arg2, arg3, arg4, arg5) {
            return _call(f, arg1, arg2, arg3, arg4, arg5, arguments.length);
          }
        }(#, #)
      ''',
      DART_CLOSURE_TO_JS(_callDartFunctionFast5),
      f);
  JS('', '#.# = #', result, DART_CLOSURE_PROPERTY_NAME, f);
  return result;
}

JavaScriptFunction _functionToJSN(Function f, int maxLength) {
  if (isJSFunction(f)) {
    throw ArgumentError('Attempting to rewrap a JS function.');
  }
  final result = JS(
      'JavaScriptFunction',
      '''
        function(_call, f, maxLength) {
          return function () {
              return _call(f, Array.prototype.slice.call(arguments, 0,
                  Math.min(arguments.length, maxLength)));
          }
        }(#, #, #)
      ''',
      DART_CLOSURE_TO_JS(_callDartFunctionFastN),
      f,
      maxLength);
  JS('', '#.# = #', result, DART_CLOSURE_PROPERTY_NAME, f);
  return result;
}

_callDartFunctionFast0(Function callback) => callback();

_callDartFunctionFast1(Function callback, arg1, int length) {
  if (length >= 1) return callback(arg1);
  return callback();
}

_callDartFunctionFast2(Function callback, arg1, arg2, int length) {
  if (length >= 2) return callback(arg1, arg2);
  if (length == 1) return callback(arg1);
  return callback();
}

_callDartFunctionFast3(Function callback, arg1, arg2, arg3, int length) {
  if (length >= 3) return callback(arg1, arg2, arg3);
  if (length == 2) return callback(arg1, arg2);
  if (length == 1) return callback(arg1);
  return callback();
}

_callDartFunctionFast4(Function callback, arg1, arg2, arg3, arg4, int length) {
  if (length >= 4) return callback(arg1, arg2, arg3, arg4);
  if (length == 3) return callback(arg1, arg2, arg3);
  if (length == 2) return callback(arg1, arg2);
  if (length == 1) return callback(arg1);
  return callback();
}

_callDartFunctionFast5(
    Function callback, arg1, arg2, arg3, arg4, arg5, int length) {
  if (length >= 5) return callback(arg1, arg2, arg3, arg4, arg5);
  if (length == 4) return callback(arg1, arg2, arg3, arg4);
  if (length == 3) return callback(arg1, arg2, arg3);
  if (length == 2) return callback(arg1, arg2);
  if (length == 1) return callback(arg1);
  return callback();
}

_callDartFunctionFastN(Function callback, List arguments) {
  return Function.apply(callback, arguments);
}

Function _jsFunctionToDart(JavaScriptFunction f) {
  return JS('Function', '#.#', f, DART_CLOSURE_PROPERTY_NAME);
}
