// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._runtime;

/// This library defines a set of general javascript utilities for us
/// by the Dart runtime.
// TODO(ochafik): Rewrite some of these in Dart when possible.

final Function(dynamic, dynamic, dynamic) defineProperty =
    JS('', 'Object.defineProperty');

defineValue(obj, name, value) {
  defineAccessor(obj, name, value: value, configurable: true, writable: true);
  return value;
}

final Function(dynamic, dynamic,
    {dynamic get,
    dynamic set,
    dynamic value,
    bool? configurable,
    bool? enumerable,
    bool? writable}) defineAccessor = JS('', 'Object.defineProperty');

final dynamic Function(dynamic, dynamic) getOwnPropertyDescriptor =
    JS('', 'Object.getOwnPropertyDescriptor');

final List Function(dynamic) getOwnPropertyNames =
    JS('', 'Object.getOwnPropertyNames');

final List Function(dynamic) getOwnPropertySymbols =
    JS('', 'Object.getOwnPropertySymbols');

final Function(dynamic) getPrototypeOf = JS('', 'Object.getPrototypeOf');

/// This error indicates a strong mode specific failure, other than a type
/// assertion failure (TypeError) or CastError.
void throwTypeError(String message) {
  throw TypeErrorImpl(message);
}

/// This error indicates a bug in the runtime or the compiler.
void throwInternalError(String message) {
  JS('', 'throw Error(#)', message);
}

Iterable getOwnNamesAndSymbols(obj) {
  var names = getOwnPropertyNames(obj);
  var symbols = getOwnPropertySymbols(obj);
  return JS('', '#.concat(#)', names, symbols);
}

/// Returns the value of field `name` on `obj`.
///
/// We use this instead of obj[name] since obj[name] checks the entire
/// prototype chain instead of just `obj`.
safeGetOwnProperty(obj, name) {
  if (JS<bool>('!', '#.hasOwnProperty(#)', obj, name))
    return JS<Object>('', '#[#]', obj, name);
}

copyTheseProperties(to, from, names) {
  for (int i = 0, n = JS('!', '#.length', names); i < n; ++i) {
    var name = JS('', '#[#]', names, i);
    if ('constructor' == name) continue;
    copyProperty(to, from, name);
  }
  return to;
}

copyProperty(to, from, name) {
  var desc = getOwnPropertyDescriptor(from, name);
  if (JS('!', '# == Symbol.iterator', name)) {
    // On native types, Symbol.iterator may already be present.
    // TODO(jmesserly): investigate if we still need this.
    // If so, we need to find a better solution.
    // See https://github.com/dart-lang/sdk/issues/28324
    var existing = getOwnPropertyDescriptor(to, name);
    if (existing != null) {
      if (JS('!', '#.writable', existing)) {
        JS('', '#[#] = #.value', to, name, desc);
      }
      return;
    }
  }
  defineProperty(to, name, desc);
}

@JSExportName('export')
exportProperty(to, from, name) => copyProperty(to, from, name);

/// Copy properties from source to destination object.
/// This operation is commonly called `mixin` in JS.
copyProperties(to, from) {
  return copyTheseProperties(to, from, getOwnNamesAndSymbols(from));
}
