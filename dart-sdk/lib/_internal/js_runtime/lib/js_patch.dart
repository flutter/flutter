// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for dart:js library.
import 'dart:collection' show HashMap, ListMixin;
import 'dart:typed_data' show TypedData;

import 'dart:_foreign_helper' show JS, DART_CLOSURE_TO_JS;
import 'dart:_interceptors' show DART_CLOSURE_PROPERTY_NAME;
import 'dart:_internal' show patch;
import 'dart:_js_helper'
    show
        Primitives,
        getIsolateAffinityTag,
        isJSFunction,
        JS_FUNCTION_PROPERTY_NAME;
import 'dart:_js' show isBrowserObject, convertFromBrowserObject;

@patch
JsObject get context => _context;

final JsObject _context = _castToJsObject(_wrapToDart(JS('', 'self')));

_convertDartFunction(Function f, {bool captureThis = false}) {
  return JS(
      'JavaScriptFunction',
      '''
        function(_call, f, captureThis) {
          return function() {
            return _call(f, captureThis, this,
                Array.prototype.slice.apply(arguments));
          }
        }(#, #, #)
      ''',
      DART_CLOSURE_TO_JS(_callDartFunction),
      f,
      captureThis);
}

_callDartFunction(callback, bool captureThis, self, List arguments) {
  if (captureThis) {
    arguments = [self]..addAll(arguments);
  }
  var dartArgs = List.from(arguments.map(_convertToDart));
  return _convertToJS(Function.apply(callback, dartArgs));
}

@patch
class JsObject {
  // The wrapped JS object.
  final Object _jsObject;

  // This should only be called from _wrapToDart
  JsObject._fromJs(this._jsObject) {
    assert(_jsObject != null);
  }

  @patch
  factory JsObject(JsFunction constructor, [List? arguments]) {
    var ctor = _convertToJS(constructor);
    if (arguments == null) {
      return _castToJsObject(_wrapToDart(JS('', 'new #()', ctor)));
    }

    if (JS('bool', '# instanceof Array', arguments)) {
      int argumentCount = JS('int', '#.length', arguments);
      switch (argumentCount) {
        case 0:
          return _castToJsObject(_wrapToDart(JS('', 'new #()', ctor)));

        case 1:
          var arg0 = _convertToJS(JS('', '#[0]', arguments));
          return _castToJsObject(_wrapToDart(JS('', 'new #(#)', ctor, arg0)));

        case 2:
          var arg0 = _convertToJS(JS('', '#[0]', arguments));
          var arg1 = _convertToJS(JS('', '#[1]', arguments));
          return _castToJsObject(
              _wrapToDart(JS('', 'new #(#, #)', ctor, arg0, arg1)));

        case 3:
          var arg0 = _convertToJS(JS('', '#[0]', arguments));
          var arg1 = _convertToJS(JS('', '#[1]', arguments));
          var arg2 = _convertToJS(JS('', '#[2]', arguments));
          return _castToJsObject(
              _wrapToDart(JS('', 'new #(#, #, #)', ctor, arg0, arg1, arg2)));

        case 4:
          var arg0 = _convertToJS(JS('', '#[0]', arguments));
          var arg1 = _convertToJS(JS('', '#[1]', arguments));
          var arg2 = _convertToJS(JS('', '#[2]', arguments));
          var arg3 = _convertToJS(JS('', '#[3]', arguments));
          return _castToJsObject(_wrapToDart(
              JS('', 'new #(#, #, #, #)', ctor, arg0, arg1, arg2, arg3)));
      }
    }

    // The following code solves the problem of invoking a JavaScript
    // constructor with an unknown number arguments.
    // First bind the constructor to the argument list using bind.apply().
    // The first argument to bind() is the binding of 'this', so add 'null' to
    // the arguments list passed to apply().
    // After that, use the JavaScript 'new' operator which overrides any binding
    // of 'this' with the new instance.
    var args = <Object?>[null]..addAll(arguments.map(_convertToJS));
    var factoryFunction = JS('', '#.bind.apply(#, #)', ctor, ctor, args);
    // Without this line, calling factoryFunction as a constructor throws
    JS('String', 'String(#)', factoryFunction);
    // This could return an UnknownJavaScriptObject, or a native
    // object for which there is an interceptor
    var jsObj = JS('', 'new #()', factoryFunction);

    return _castToJsObject(_wrapToDart(jsObj));

    // TODO(sra): Investigate:
    //
    //     var jsObj = JS('', 'Object.create(#.prototype)', ctor);
    //     JS('', '#.apply(#, #)', ctor, jsObj,
    //         []..addAll(arguments.map(_convertToJS)));
    //     return _wrapToDart(jsObj);
  }

  @patch
  factory JsObject.fromBrowserObject(Object object) {
    if (object is num || object is String || object is bool || object == null) {
      throw ArgumentError("object cannot be a num, string, bool, or null");
    }
    return _castToJsObject(_wrapToDart(_convertToJS(object)));
  }

  @patch
  factory JsObject.jsify(Object object) {
    if ((object is! Map) && (object is! Iterable)) {
      throw ArgumentError("object must be a Map or Iterable");
    }
    return _castToJsObject(_wrapToDart(_convertDataTree(object)));
  }

  static _convertDataTree(Object data) {
    var _convertedObjects = HashMap.identity();

    _convert(Object? o) {
      if (_convertedObjects.containsKey(o)) {
        return _convertedObjects[o];
      }
      if (o is Map) {
        final convertedMap = JS('=Object', '{}');
        _convertedObjects[o] = convertedMap;
        for (var key in o.keys) {
          JS('=Object', '#[#] = #', convertedMap, key, _convert(o[key]));
        }
        return convertedMap;
      } else if (o is Iterable) {
        var convertedList = [];
        _convertedObjects[o] = convertedList;
        convertedList.addAll(o.map(_convert));
        return convertedList;
      } else {
        return _convertToJS(o);
      }
    }

    return _convert(data);
  }

  @patch
  dynamic operator [](Object property) {
    if (property is! String && property is! num) {
      throw ArgumentError("property is not a String or num");
    }
    return _convertToDart(JS('', '#[#]', _jsObject, property));
  }

  @patch
  void operator []=(Object property, Object? value) {
    if (property is! String && property is! num) {
      throw ArgumentError("property is not a String or num");
    }
    JS('', '#[#] = #', _jsObject, property, _convertToJS(value));
  }

  @patch
  bool operator ==(Object other) =>
      other is JsObject && JS('bool', '# === #', _jsObject, other._jsObject);

  @patch
  bool hasProperty(Object property) {
    if (property is! String && property is! num) {
      throw ArgumentError("property is not a String or num");
    }
    return JS('bool', '# in #', property, _jsObject);
  }

  @patch
  void deleteProperty(Object property) {
    if (property is! String && property is! num) {
      throw ArgumentError("property is not a String or num");
    }
    JS('bool', 'delete #[#]', _jsObject, property);
  }

  @patch
  bool instanceof(JsFunction type) {
    return JS('bool', '# instanceof #', _jsObject, _convertToJS(type));
  }

  @patch
  String toString() {
    try {
      return JS('String', 'String(#)', _jsObject);
    } catch (e) {
      return super.toString();
    }
  }

  @patch
  dynamic callMethod(Object method, [List? args]) {
    if (method is! String && method is! num) {
      throw ArgumentError("method is not a String or num");
    }
    return _convertToDart(JS('', '#[#].apply(#, #)', _jsObject, method,
        _jsObject, args == null ? null : List.from(args.map(_convertToJS))));
  }
}

@patch
class JsFunction extends JsObject {
  @patch
  factory JsFunction.withThis(Function f) {
    var jsFunc = _convertDartFunction(f, captureThis: true);
    return JsFunction._fromJs(jsFunc);
  }

  JsFunction._fromJs(Object jsObject) : super._fromJs(jsObject);

  @patch
  dynamic apply(List args, {thisArg}) => _convertToDart(JS(
      '',
      '#.apply(#, #)',
      _jsObject,
      _convertToJS(thisArg),
      args == null ? null : List.from(args.map(_convertToJS))));
}

@patch
// TODO(johnniwinther): Support with clause in patches/augmentations.
class JsArray<E> /*extends JsObject with ListMixin<E>*/ {
  @patch
  factory JsArray() => JsArray<E>._fromJs([]);

  @patch
  factory JsArray.from(Iterable<E> other) =>
      JsArray<E>._fromJs([]..addAll(other.map(_convertToJS)));

  JsArray._fromJs(Object jsObject) : super._fromJs(jsObject);

  _checkIndex(int index) {
    if (index is int && (index < 0 || index >= length)) {
      throw RangeError.range(index, 0, length);
    }
  }

  _checkInsertIndex(int index) {
    if (index is int && (index < 0 || index >= length + 1)) {
      throw RangeError.range(index, 0, length);
    }
  }

  static _checkRange(int start, int end, int length) {
    if (start < 0 || start > length) {
      throw RangeError.range(start, 0, length);
    }
    if (end < start || end > length) {
      throw RangeError.range(end, start, length);
    }
  }

  // Methods required by ListMixin

  @patch
  E operator [](Object index) {
    if (index is int) {
      _checkIndex(index);
    }
    return super[index];
  }

  @patch
  void operator []=(Object index, Object? value) {
    if (index is int) {
      _checkIndex(index);
    }
    super[index] = value;
  }

  @patch
  int get length {
    // Check the length honours the List contract.
    var len = JS('', '#.length', _jsObject);
    // JavaScript arrays have lengths which are unsigned 32-bit integers.
    if (JS('bool', 'typeof # === "number" && (# >>> 0) === #', len, len, len)) {
      return JS('int', '#', len);
    }
    throw StateError('Bad JsArray length');
  }

  @patch
  void set length(int length) {
    super['length'] = length;
  }

  // Methods overridden for better performance

  @patch
  void add(E value) {
    callMethod('push', [value]);
  }

  @patch
  void addAll(Iterable<E> iterable) {
    var list = (JS('bool', '# instanceof Array', iterable))
        ? JS<List>('JSArray', '#', iterable)
        : List.from(iterable);
    callMethod('push', list);
  }

  @patch
  void insert(int index, E element) {
    _checkInsertIndex(index);
    callMethod('splice', [index, 0, element]);
  }

  @patch
  E removeAt(int index) {
    _checkIndex(index);
    // Avoid optimizing. Static type of [callMethod] is dynamic which makes
    // indexing dynamic.
    // ignore: avoid_dynamic_calls
    return callMethod('splice', [index, 1])[0];
  }

  @patch
  E removeLast() {
    if (length == 0) throw RangeError(-1);
    return callMethod('pop');
  }

  @patch
  void removeRange(int start, int end) {
    _checkRange(start, end, length);
    callMethod('splice', [start, end - start]);
  }

  @patch
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    _checkRange(start, end, this.length);
    int length = end - start;
    if (length == 0) return;
    if (skipCount < 0) throw ArgumentError(skipCount);
    var args = <Object?>[start, length]
      ..addAll(iterable.skip(skipCount).take(length));
    callMethod('splice', args);
  }

  @patch
  void sort([int compare(E a, E b)?]) {
    // Note: arr.sort(null) is a type error in FF
    callMethod('sort', compare == null ? [] : [compare]);
  }
}

// property added to a Dart object referencing its JS-side DartObject proxy
final String _DART_OBJECT_PROPERTY_NAME =
    getIsolateAffinityTag(r'_$dart_dartObject');

// property added to a JS object referencing its Dart-side JsObject proxy
const _JS_OBJECT_PROPERTY_NAME = r'_$dart_jsObject';

@pragma('dart2js:tryInline')
JsObject _castToJsObject(o) => JS<JsObject>('', '#', o);

bool _defineProperty(o, String name, value) {
  try {
    if (_isExtensible(o) &&
        // TODO(ahe): Calling _hasOwnProperty to work around
        // https://code.google.com/p/dart/issues/detail?id=21331.
        !_hasOwnProperty(o, name)) {
      JS('void', 'Object.defineProperty(#, #, { value: #})', o, name, value);
      return true;
    }
  } catch (e) {
    // object is native and lies about being extensible
    // see https://bugzilla.mozilla.org/show_bug.cgi?id=775185
    // Or, isExtensible throws for this object.
  }
  return false;
}

bool _hasOwnProperty(o, String name) {
  return JS('bool', 'Object.prototype.hasOwnProperty.call(#, #)', o, name);
}

bool _isExtensible(o) => JS('bool', 'Object.isExtensible(#)', o);

Object? _getOwnProperty(o, String name) {
  if (_hasOwnProperty(o, name)) {
    return JS('', '#[#]', o, name);
  }
  return null;
}

bool _isLocalObject(o) => JS('bool', '# instanceof Object', o);

// The shared constructor function for proxies to Dart objects in JavaScript.
final _dartProxyCtor = JS('', 'function DartObject(o) { this.o = o; }');

Object? _convertToJS(Object? o) {
  // Note: we don't write `if (o == null) return null;` to make sure dart2js
  // doesn't convert `return null;` into `return;` (which would make `null` be
  // `undefined` in JavaScript). See dartbug.com/20305 for details.
  if (o == null || o is String || o is num || o is bool) {
    return o;
  }
  if (o is JsObject) {
    return o._jsObject;
  }
  if (isBrowserObject(o)) {
    return o;
  }
  if (o is TypedData) {
    return o;
  }
  if (o is DateTime) {
    return Primitives.lazyAsJsDate(o);
  }
  if (o is Function) {
    return _getJsProxy(o, JS_FUNCTION_PROPERTY_NAME, (o) {
      var jsFunction = _convertDartFunction(o);
      // set a property on the JS closure referencing the Dart closure
      _defineProperty(jsFunction, DART_CLOSURE_PROPERTY_NAME, o);
      return jsFunction;
    });
  }
  var ctor = _dartProxyCtor;
  return _getJsProxy(
      o, _JS_OBJECT_PROPERTY_NAME, (o) => JS('', 'new #(#)', ctor, o));
}

Object? _getJsProxy(o, String propertyName, createProxy(o)) {
  var jsProxy = _getOwnProperty(o, propertyName);
  if (jsProxy == null) {
    jsProxy = createProxy(o);
    _defineProperty(o, propertyName, jsProxy);
  }
  return jsProxy;
}

// converts a Dart object to a reference to a native JS object
// which might be a DartObject JS->Dart proxy
Object? _convertToDart(o) {
  if (JS('bool', '# == null', o) ||
      JS('bool', 'typeof # == "string"', o) ||
      JS('bool', 'typeof # == "number"', o) ||
      JS('bool', 'typeof # == "boolean"', o)) {
    return o;
  } else if (_isLocalObject(o) && isBrowserObject(o)) {
    return convertFromBrowserObject(o);
  } else if (_isLocalObject(o) && o is TypedData) {
    return JS('TypedData', '#', o);
  } else if (JS('bool', '# instanceof Date', o)) {
    var ms = JS('num', '#.getTime()', o);
    return DateTime.fromMillisecondsSinceEpoch(ms);
  } else if (JS('bool', '#.constructor === #', o, _dartProxyCtor)) {
    return JS('', '#.o', o);
  } else {
    return _wrapToDart(o);
  }
}

Object _wrapToDart(o) {
  if (JS('bool', 'typeof # == "function"', o)) {
    return _getDartProxy(
        o, DART_CLOSURE_PROPERTY_NAME, (o) => JsFunction._fromJs(o));
  }
  if (JS('bool', '# instanceof Array', o)) {
    return _getDartProxy(
        o, _DART_OBJECT_PROPERTY_NAME, (o) => JsArray._fromJs(o));
  }
  return _getDartProxy(
      o, _DART_OBJECT_PROPERTY_NAME, (o) => JsObject._fromJs(o));
}

Object _getDartProxy(o, String propertyName, JsObject createProxy(o)) {
  var dartProxy = _getOwnProperty(o, propertyName);
  // Temporary fix for dartbug.com/15193
  // In some cases it's possible to see a JavaScript object that
  // came from a different context and was previously proxied to
  // Dart in that context. The JS object will have a cached proxy
  // but it won't be a valid Dart object in this context.
  // For now we throw away the cached proxy, but we should be able
  // to cache proxies from multiple JS contexts and Dart isolates.
  if (dartProxy == null || !_isLocalObject(o)) {
    dartProxy = createProxy(o);
    _defineProperty(o, propertyName, dartProxy);
  }
  return dartProxy;
}
