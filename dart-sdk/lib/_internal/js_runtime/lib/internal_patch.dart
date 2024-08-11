// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core' hide Symbol;
import 'dart:core' as core show Symbol;
import 'dart:_js_primitives' show printString;
import 'dart:_internal' show patch;
import 'dart:_interceptors' show JSArray;
import 'dart:_foreign_helper'
    show JS, JS_GET_FLAG, createJsSentinel, isJsSentinel;

@patch
@pragma('dart2js:tryInline')
bool typeAcceptsNull<T>() {
  bool isLegacySubtyping = JS_GET_FLAG('LEGACY');
  return isLegacySubtyping || null is T;
}

@patch
class Symbol implements core.Symbol {
  @patch
  const Symbol(String name) : this._name = name;

  @patch
  int get hashCode {
    int? hash = JS('int|Null', '#._hashCode', this);
    if (hash != null) return hash;
    const arbitraryPrime = 664597;
    hash = 0x1fffffff & (arbitraryPrime * _name.hashCode);
    JS('', '#._hashCode = #', this, hash);
    return hash;
  }

  @patch
  toString() => 'Symbol("$_name")';

  @patch
  static String computeUnmangledName(Symbol symbol) {
    throw "unsupported operation";
  }
}

@patch
void printToConsole(String line) {
  printString('$line');
}

@patch
List<T> makeListFixedLength<T>(List<T> growableList) {
  return JSArray.markFixedList(growableList);
}

@patch
List<T> makeFixedListUnmodifiable<T>(List<T> fixedLengthList) {
  return JSArray.markUnmodifiableList(fixedLengthList);
}

@patch
@pragma('dart2js:noInline')
Object? extractTypeArguments<T>(T instance, Function extract) {
  // This function is recognized and replaced with calls to js_runtime.

  // This call to [extract] is required to model that the function is called and
  // the returned value flows to the result of extractTypeArguments.
  return extract();
}

@patch
@pragma('dart2js:tryInline')
T createSentinel<T>() => createJsSentinel<T>();

@patch
@pragma('dart2js:tryInline')
bool isSentinel(dynamic value) => isJsSentinel(value);

@patch
@pragma('dart2js:tryInline')
T unsafeCast<T>(dynamic v) => v;
