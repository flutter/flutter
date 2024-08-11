// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for dart:js_util library.
import 'dart:_foreign_helper' show JS;
import 'dart:_interceptors' show JavaScriptFunction;
import 'dart:_internal' show patch;
import 'dart:_runtime' as dart;

Expando<Function> _interopExpando = Expando<Function>();

@patch
F allowInterop<F extends Function>(F f) {
  if (!dart.isDartFunction(f)) return f;
  var ret = _interopExpando[f] as F?;
  if (ret == null) {
    ret = JS<F>(
        '',
        'function (...args) {'
            ' return #(#, args);'
            '}',
        dart.dcall,
        f);
    _interopExpando[f] = ret;
  }
  return ret;
}

Expando<Function> _interopCaptureThisExpando = Expando<Function>();

@patch
Function allowInteropCaptureThis(Function f) {
  if (!dart.isDartFunction(f)) return f;
  var ret = _interopCaptureThisExpando[f];
  if (ret == null) {
    ret = JS<Function>(
        '',
        'function(...arguments) {'
            '  let args = [this];'
            '  args.push.apply(args, arguments);'
            '  return #(#, args);'
            '}',
        dart.dcall,
        f);
    _interopCaptureThisExpando[f] = ret;
  }
  return ret;
}

// TODO(srujzs): In dart2js, this is guaranteed to be unique per isolate. DDC
// doesn't have a mechanism to guarantee that, so use a Symbol instead to match
// the unique-per-runtime semantics of [allowInterop].
final _functionToJSPropertyName = r'_$dart_dartClosure';
final _functionToJSProperty = JS('!', "Symbol($_functionToJSPropertyName)");

JavaScriptFunction _functionToJS0(Function f) {
  // This can only happen if a user casted a JavaScriptFunction to Function.
  // Such a cast is an error in dart2wasm, so we should make this behavior an
  // error as well.
  if (!dart.isDartFunction(f)) {
    throw ArgumentError('Attempting to rewrap a JS function.');
  }
  final ret = JS<JavaScriptFunction>(
      '!',
      '''
        function () {
          return #(#);
        }
      ''',
      _callDartFunctionFast0,
      f);
  JS('', '#[#] = #', ret, _functionToJSProperty, f);
  return ret;
}

JavaScriptFunction _functionToJS1(Function f) {
  if (!dart.isDartFunction(f)) {
    throw ArgumentError('Attempting to rewrap a JS function.');
  }
  final ret = JS<JavaScriptFunction>(
      '!',
      '''
        function (arg1) {
          return #(#, arg1, arguments.length);
        }
      ''',
      _callDartFunctionFast1,
      f);
  JS('', '#[#] = #', ret, _functionToJSProperty, f);
  return ret;
}

JavaScriptFunction _functionToJS2(Function f) {
  if (!dart.isDartFunction(f)) {
    throw ArgumentError('Attempting to rewrap a JS function.');
  }
  final ret = JS<JavaScriptFunction>(
      '!',
      '''
        function (arg1, arg2) {
          return #(#, arg1, arg2, arguments.length);
        }
      ''',
      _callDartFunctionFast2,
      f);
  JS('', '#[#] = #', ret, _functionToJSProperty, f);
  return ret;
}

JavaScriptFunction _functionToJS3(Function f) {
  if (!dart.isDartFunction(f)) {
    throw ArgumentError('Attempting to rewrap a JS function.');
  }
  final ret = JS<JavaScriptFunction>(
      '!',
      '''
        function (arg1, arg2, arg3) {
          return #(#, arg1, arg2, arg3, arguments.length);
        }
      ''',
      _callDartFunctionFast3,
      f);
  JS('', '#[#] = #', ret, _functionToJSProperty, f);
  return ret;
}

JavaScriptFunction _functionToJS4(Function f) {
  if (!dart.isDartFunction(f)) {
    throw ArgumentError('Attempting to rewrap a JS function.');
  }
  final ret = JS<JavaScriptFunction>(
      '!',
      '''
        function (arg1, arg2, arg3, arg4) {
          return #(#, arg1, arg2, arg3, arg4, arguments.length);
        }
      ''',
      _callDartFunctionFast4,
      f);
  JS('', '#[#] = #', ret, _functionToJSProperty, f);
  return ret;
}

JavaScriptFunction _functionToJS5(Function f) {
  if (!dart.isDartFunction(f)) {
    throw ArgumentError('Attempting to rewrap a JS function.');
  }
  final ret = JS<JavaScriptFunction>(
      '!',
      '''
        function (arg1, arg2, arg3, arg4, arg5) {
          return #(#, arg1, arg2, arg3, arg4, arg5, arguments.length);
        }
      ''',
      _callDartFunctionFast5,
      f);
  JS('', '#[#] = #', ret, _functionToJSProperty, f);
  return ret;
}

JavaScriptFunction _functionToJSN(Function f, int maxLength) {
  if (!dart.isDartFunction(f)) {
    throw ArgumentError('Attempting to rewrap a JS function.');
  }
  final ret = JS<JavaScriptFunction>(
      '!',
      '''
        function (...args) {
          return #(#, Array.prototype.slice.call(args, 0,
              Math.min(args.length, #)));
        }
      ''',
      dart.dcall,
      f,
      maxLength);
  JS('', '#[#] = #', ret, _functionToJSProperty, f);
  return ret;
}

_callDartFunctionFast0(callback) => JS('', '#()', callback);

_callDartFunctionFast1(callback, arg1, int length) {
  if (length >= 1) {
    final error =
        dart.validateFunctionToJSArgs(callback, JS<List>('!', '[#]', arg1));
    if (error != null) return error;
    return JS('', '#(#)', callback, arg1);
  } else {
    final error = dart.validateFunctionToJSArgs(callback, JS<List>('!', '[]'));
    if (error != null) return error;
    return JS('', '#()', callback);
  }
}

_callDartFunctionFast2(callback, arg1, arg2, int length) {
  if (length >= 2) {
    final error = dart.validateFunctionToJSArgs(
        callback, JS<List>('!', '[#, #]', arg1, arg2));
    if (error != null) return error;
    return JS('', '#(#, #)', callback, arg1, arg2);
  } else if (length == 1) {
    final error =
        dart.validateFunctionToJSArgs(callback, JS<List>('!', '[#]', arg1));
    if (error != null) return error;
    return JS('', '#(#)', callback, arg1);
  } else {
    final error = dart.validateFunctionToJSArgs(callback, JS<List>('!', '[]'));
    if (error != null) return error;
    return JS('', '#()', callback);
  }
}

_callDartFunctionFast3(callback, arg1, arg2, arg3, int length) {
  if (length >= 3) {
    final error = dart.validateFunctionToJSArgs(
        callback, JS<List>('!', '[#, #, #]', arg1, arg2, arg3));
    if (error != null) return error;
    return JS('', '#(#, #, #)', callback, arg1, arg2, arg3);
  } else if (length == 2) {
    final error = dart.validateFunctionToJSArgs(
        callback, JS<List>('!', '[#, #]', arg1, arg2));
    if (error != null) return error;
    return JS('', '#(#, #)', callback, arg1, arg2);
  } else if (length == 1) {
    final error =
        dart.validateFunctionToJSArgs(callback, JS<List>('!', '[#]', arg1));
    if (error != null) return error;
    return JS('', '#(#)', callback, arg1);
  } else {
    final error = dart.validateFunctionToJSArgs(callback, JS<List>('!', '[]'));
    if (error != null) return error;
    return JS('', '#()', callback);
  }
}

_callDartFunctionFast4(callback, arg1, arg2, arg3, arg4, int length) {
  if (length >= 4) {
    final error = dart.validateFunctionToJSArgs(
        callback, JS<List>('!', '[#, #, #, #]', arg1, arg2, arg3, arg4));
    if (error != null) return error;
    return JS('', '#(#, #, #, #)', callback, arg1, arg2, arg3, arg4);
  } else if (length == 3) {
    final error = dart.validateFunctionToJSArgs(
        callback, JS<List>('!', '[#, #, #]', arg1, arg2, arg3));
    if (error != null) return error;
    return JS('', '#(#, #, #)', callback, arg1, arg2, arg3);
  } else if (length == 2) {
    final error = dart.validateFunctionToJSArgs(
        callback, JS<List>('!', '[#, #]', arg1, arg2));
    if (error != null) return error;
    return JS('', '#(#, #)', callback, arg1, arg2);
  } else if (length == 1) {
    final error =
        dart.validateFunctionToJSArgs(callback, JS<List>('!', '[#]', arg1));
    if (error != null) return error;
    return JS('', '#(#)', callback, arg1);
  } else {
    final error = dart.validateFunctionToJSArgs(callback, JS<List>('!', '[]'));
    if (error != null) return error;
    return JS('', '#()', callback);
  }
}

_callDartFunctionFast5(callback, arg1, arg2, arg3, arg4, arg5, int length) {
  if (length >= 5) {
    final error = dart.validateFunctionToJSArgs(callback,
        JS<List>('!', '[#, #, #, #, #]', arg1, arg2, arg3, arg4, arg5));
    if (error != null) return error;
    return JS('', '#(#, #, #, #, #)', callback, arg1, arg2, arg3, arg4, arg5);
  } else if (length == 4) {
    final error = dart.validateFunctionToJSArgs(
        callback, JS<List>('!', '[#, #, #, #]', arg1, arg2, arg3, arg4));
    if (error != null) return error;
    return JS('', '#(#, #, #, #)', callback, arg1, arg2, arg3, arg4);
  } else if (length == 3) {
    final error = dart.validateFunctionToJSArgs(
        callback, JS<List>('!', '[#, #, #]', arg1, arg2, arg3));
    if (error != null) return error;
    return JS('', '#(#, #, #)', callback, arg1, arg2, arg3);
  } else if (length == 2) {
    final error = dart.validateFunctionToJSArgs(
        callback, JS<List>('!', '[#, #]', arg1, arg2));
    if (error != null) return error;
    return JS('', '#(#, #)', callback, arg1, arg2);
  } else if (length == 1) {
    final error =
        dart.validateFunctionToJSArgs(callback, JS<List>('!', '[#]', arg1));
    if (error != null) return error;
    return JS('', '#(#)', callback, arg1);
  } else {
    final error = dart.validateFunctionToJSArgs(callback, JS<List>('!', '[]'));
    if (error != null) return error;
    return JS('', '#()', callback);
  }
}

Function _jsFunctionToDart(JavaScriptFunction f) {
  return JS('Function', '#[#]', f, _functionToJSProperty);
}
