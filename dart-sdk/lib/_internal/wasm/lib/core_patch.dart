// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal"
    show
        ClassID,
        CodeUnits,
        doubleToIntBits,
        EfficientLengthIterable,
        FixedLengthListMixin,
        indexCheckWithName,
        intBitsToDouble,
        IterableElementError,
        jsonEncode,
        ListIterator,
        Lists,
        makeFixedListUnmodifiable,
        makeListFixedLength,
        mix64,
        patch,
        POWERS_OF_TEN,
        SubListIterable,
        Symbol,
        UnmodifiableListMixin,
        unsafeCast,
        WasmStringBase,
        WasmTypedDataBase;

import "dart:_internal" as _internal;

import 'dart:_js_helper'
    show
        JS,
        JSSyntaxRegExp,
        quoteStringForRegExp,
        jsStringFromDartString,
        jsStringToDartString;

import 'dart:_list';

import 'dart:_string' show JSStringImpl, JSStringImplExt;

import "dart:collection"
    show
        HashMap,
        LinkedHashMap,
        LinkedList,
        LinkedListEntry,
        ListBase,
        MapBase,
        Maps,
        UnmodifiableMapBase,
        UnmodifiableMapView;

import 'dart:convert' show Encoding, utf8;

import 'dart:math' show Random;

import "dart:typed_data";

import 'dart:_object_helper';
import 'dart:_string_helper';

import 'dart:_wasm';

part "bool.dart";
part "closure.dart";
part "double_patch.dart";
part "errors_patch.dart";
part "identical_patch.dart";
part "named_parameters.dart";
part "object_patch.dart";
part "record_patch.dart";
part "regexp_patch.dart";
part "stack_trace_patch.dart";
part "stopwatch_patch.dart";
part "type.dart";
part "uri_patch.dart";

typedef _Smi = int; // For compatibility with VM patch files

String _symbolToString(Symbol s) =>
    _internal.Symbol.getName(s as _internal.Symbol);
