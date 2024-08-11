// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core_patch.dart";

/// Finds a named parameter in a named parameter list passed to a dynamic
/// forwarder and returns the index of the value of that named parameter.
/// Returns `null` if the name is not in the list.
@pragma("wasm:entry-point")
int? _getNamedParameterIndex(
    WasmArray<Object?> namedArguments, Symbol paramName) {
  for (int i = 0; i < namedArguments.length; i += 2) {
    if (identical(namedArguments[i], paramName)) {
      return i + 1;
    }
  }
  return null;
}

/// Converts type arguments passed to a dynamic forwarder to a
/// list that can be passed to `Invocation` constructors.
@pragma("wasm:entry-point")
List<_Type?> _typeArgumentsToList(WasmArray<_Type> typeArgs) {
  final result = <_Type>[];
  for (int i = 0; i < typeArgs.length; ++i) {
    result.add(typeArgs[i]);
  }
  return result;
}

/// Converts a positional parameter list passed to a dynamic forwarder to a
/// list that can be passed to `Invocation` constructors.
@pragma("wasm:entry-point")
List<Object?> _positionalParametersToList(WasmArray<Object?> positional) {
  final result = <Object?>[];
  for (int i = 0; i < positional.length; ++i) {
    result.add(positional[i]);
  }
  return result;
}

/// Converts a named parameter list passed to a dynamic forwarder to a map that
/// can be passed to `Invocation` constructors.
@pragma("wasm:entry-point")
Map<Symbol, Object?> _namedParametersToMap(WasmArray<Object?> namedArguments) {
  final Map<Symbol, Object?> map = {};
  for (int i = 0; i < namedArguments.length; i += 2) {
    map[namedArguments[i] as Symbol] = namedArguments[i + 1];
  }
  return map;
}

/// Converts a named parameter map passed to `Function.apply` to a list that
/// can be passed to dynamic call vtable entries.
///
/// This is the opposite of [_namedParameterListToMap].
@pragma("wasm:entry-point")
WasmArray<Object?> _namedParameterMapToArray(
    Map<Symbol, Object?>? namedArguments) {
  if (namedArguments == null || namedArguments.isEmpty) {
    return const WasmArray.literal([]);
  }

  final List<MapEntry<Symbol, Object?>> entries = namedArguments.entries
      .toList()
    ..sort((entry1, entry2) =>
        _symbolToString(entry1.key).compareTo(_symbolToString(entry2.key)));

  final WasmArray<Object?> result = WasmArray<Object?>(2 * entries.length);

  for (int i = 0; i < entries.length; ++i) {
    result[2 * i] = entries[i].key;
    result[2 * i + 1] = entries[i].value;
  }

  return result;
}
