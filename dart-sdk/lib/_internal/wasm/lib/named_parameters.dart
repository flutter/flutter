// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core_patch.dart";

/// Finds a named parameter in a named parameter list passed to a dynamic
/// forwarder or `Function.apply` (in which case the `Symbol` will be canonical
/// iff the target function accepts it).
///
/// Returns `null` if the name is not in the list.
@pragma("wasm:entry-point")
int? _getNamedParameterIndex(
  WasmArray<Object?> namedArguments,
  Symbol paramName,
) {
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
    map[unsafeCast<Symbol>(namedArguments[i])] = namedArguments[i + 1];
  }
  return map;
}

/// Converts a named parameter map passed to `Function.apply` to a list that
/// can be passed to dynamic call vtable entries.
///
/// The resulting array contains (symbol, value) pairs where
///   * the symbol is canonicalized iff the target closure has that symbol
///   * all symbols the target closure accepts will have the same order as the
///     target expects them
@pragma("wasm:entry-point")
WasmArray<Object?> _namedParameterMapToArray(
  Map<Symbol, Object?>? namedArguments,
  _Closure targetClosure,
) {
  if (namedArguments == null || namedArguments.isEmpty) {
    return const WasmArray.literal([]);
  }

  final targetFunctionType = _Closure._getClosureRuntimeType(targetClosure);
  final targetNamedParameters = targetFunctionType.namedParameters;

  List<_NamedParameterValue>? entries;
  int i = 0;
  namedArguments.forEach((symbol, value) {
    int position = _findSymbolPosition(symbol, targetNamedParameters);

    // If the target knows about [symbol] then we use it's canonicalized
    // [Symbol] object to ensure any following code can use `identical()`.
    if (position != -1) symbol = targetNamedParameters[position].name;

    final entry = _NamedParameterValue(symbol, value, position);
    if (entries == null) {
      i++;
      entries ??= List<_NamedParameterValue>.filled(
        namedArguments.length,
        entry,
      );
      return;
    }
    entries![i++] = entry;
  });

  final entriesNonNullable = entries!;
  entriesNonNullable.sort((a, b) => a.position.compareTo(b.position));

  final WasmArray<Object?> result = WasmArray<Object?>(
    2 * entriesNonNullable.length,
  );
  for (int i = 0; i < entriesNonNullable.length; ++i) {
    final entry = entriesNonNullable[i];
    result[2 * i] = entry.symbol;
    result[2 * i + 1] = entry.value;
  }

  return result;
}

int _findSymbolPosition(Symbol symbol, WasmArray<_NamedParameter> named) {
  for (int i = 0; i < named.length; ++i) {
    final targetSymbol = named[i].name;
    if (identical(targetSymbol, symbol) ||
        (!minify && targetSymbol == symbol)) {
      return i;
    }
  }
  return -1;
}

class _NamedParameterValue {
  final Symbol symbol;
  final Object? value;
  final int position;
  _NamedParameterValue(this.symbol, this.value, this.position);
}
