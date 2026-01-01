// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core' hide Symbol;
import 'dart:core' as core show Symbol;
import 'dart:async' show Completer;
import 'dart:_js_primitives' show printString;
import 'dart:_internal' show patch;
import 'dart:_interceptors' show JSArray;
import 'dart:_foreign_helper' show JS;
import 'dart:_runtime' as dart;
import 'dart:typed_data' show Uint8List;

@patch
bool typeAcceptsNull<T>() => null is T;

int? getHotRestartGeneration() => dart.hotRestartGeneration();

/// Returns `true` when the provided [generation] matches the current hot
/// restart generation.
///
/// This is intended to avoid completing a Dart Future after a hot restart that
/// originated from a converted Promise before the hot restart.
///
/// See uses in `promiseToFuture` from `dart:js_util`.
bool isCurrentHotRestartGeneration(int generation) =>
    generation == dart.hotRestartGeneration();

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
  String toString() => 'Symbol("$_name")';

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

@patch
Future<Object?> loadDynamicModule({Uri? uri, Uint8List? bytes}) {
  if (bytes != null) {
    throw ArgumentError(
      'DDC implementation of dynamic modules doesn\'t'
      ' accept bytes as input',
    );
  }
  if (uri == null) {
    throw ArgumentError(
      'DDC implementation of dynamic modules expects a'
      'non-null Uri input.',
    );
  }
  if (dart.dynamicModuleLoader == null) {
    throw StateError('Dynamic module loader has not be configured.');
  }
  var completer = Completer<Object?>();
  void _callback(String moduleName) {
    try {
      var result = JS('!', '#(#)', dart.dynamicEntrypointHelper, moduleName);
      completer.complete(result);
    } catch (e, st) {
      completer.completeError(e, st);
    }
  }

  try {
    JS('!', '#(#, #)', dart.dynamicModuleLoader, uri.toString(), _callback);
  } catch (e, st) {
    completer.completeError(e, st);
  }
  return completer.future;
}

@patch
@pragma("vm:entry-point")
abstract interface class IsolateGroup {
  @patch
  static Object _runSync(Object computation) =>
      throw UnsupportedError("_runSync");
}
