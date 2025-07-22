// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._runtime;

/// This library defines a set of general javascript utilities for us
/// by the Dart runtime.
// TODO(ochafik): Rewrite some of these in Dart when possible.

final Function(dynamic, dynamic, dynamic) defineProperty = JS(
  '',
  'Object.defineProperty',
);

defineValue(obj, name, value) {
  defineAccessor(obj, name, value: value, configurable: true, writable: true);
  return value;
}

final Function(
  dynamic,
  dynamic, {
  dynamic get,
  dynamic set,
  dynamic value,
  bool? configurable,
  bool? enumerable,
  bool? writable,
})
defineAccessor = JS('', 'Object.defineProperty');

final dynamic Function(dynamic, dynamic) getOwnPropertyDescriptor = JS(
  '',
  'Object.getOwnPropertyDescriptor',
);

final List Function(dynamic) getOwnPropertyNames = JS(
  '',
  'Object.getOwnPropertyNames',
);

final List Function(dynamic) getOwnPropertySymbols = JS(
  '',
  'Object.getOwnPropertySymbols',
);

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

copyTheseProperties(
  to,
  from,
  namesAndSymbols, {
  bool Function(Object)? copyWhen,
  Object Function(Object)? transform,
}) {
  for (int i = 0, n = JS('!', '#.length', namesAndSymbols); i < n; ++i) {
    var nameOrSymbol = JS<Object>('!', '#[#]', namesAndSymbols, i);
    if ('constructor' == nameOrSymbol) continue;
    if ('prototype' == nameOrSymbol) continue;
    if (copyWhen != null && !copyWhen(nameOrSymbol)) continue;
    copyProperty(to, from, nameOrSymbol, transform: transform);
  }
  return to;
}

copyProperty(to, from, name, {Object Function(Object)? transform}) {
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
  if (transform != null) {
    desc = JS<Object>('', '#(#)', transform, desc);
  }
  defineProperty(to, name, desc);
}

@JSExportName('export')
exportProperty(to, from, name) => copyProperty(to, from, name);

/// Copy properties from source to destination object.
/// This operation is commonly called `mixin` in JS.
///
/// [copyWhen] allows you to specify when a JS property will be copied.
/// [transform] allows you to specify a value based on a property descriptor.
copyProperties(
  to,
  from, {
  bool Function(Object)? copyWhen,
  Object Function(Object)? transform,
}) {
  return copyTheseProperties(
    to,
    from,
    getOwnNamesAndSymbols(from),
    copyWhen: copyWhen,
    transform: transform,
  );
}
