// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core' hide Symbol;
import 'dart:core' as core show Symbol;
import 'dart:_js_primitives' show printString;
import 'dart:_internal' show patch;
import 'dart:_interceptors' show JSArray;
import 'dart:_foreign_helper' show JS, JS_GET_FLAG;
import 'dart:_runtime' as dart;

@patch
bool typeAcceptsNull<T>() => !JS_GET_FLAG('SOUND_NULL_SAFETY') || null is T;

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
  static String computeUnmangledName(Symbol symbol) => symbol._name;
}

@patch
void printToConsole(String line) {
  printString('$line');
}

@patch
List<T> makeListFixedLength<T>(List<T> growableList) {
  JSArray.markFixedList(growableList);
  return growableList;
}

@patch
List<T> makeFixedListUnmodifiable<T>(List<T> fixedLengthList) {
  JSArray.markUnmodifiableList(fixedLengthList);
  return fixedLengthList;
}

@patch
Object? extractTypeArguments<T>(T instance, Function extract) =>
    dart.extractTypeArguments<T>(instance, extract);

@patch
T createSentinel<T>() => throw UnsupportedError('createSentinel');

@patch
bool isSentinel(dynamic value) => throw UnsupportedError('isSentinel');

@patch
T unsafeCast<T>(dynamic v) => v;
