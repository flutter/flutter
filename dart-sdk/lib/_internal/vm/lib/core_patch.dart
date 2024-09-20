// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Note: the VM concatenates all patch files into a single patch file. This
/// file is the first patch in "dart:core" which contains all the imports
/// used by patches of that library. We plan to change this when we have a
/// shared front end and simply use parts.

import "dart:_internal" as internal show Symbol;

import "dart:_internal"
    show
        allocateOneByteString,
        allocateTwoByteString,
        checkValidWeakTarget,
        ClassID,
        CodeUnits,
        copyRangeFromUint8ListToOneByteString,
        EfficientLengthIterable,
        FinalizerBase,
        FinalizerBaseMembers,
        FinalizerEntry,
        FixedLengthListBase,
        IterableElementError,
        ListIterator,
        Lists,
        POWERS_OF_TEN,
        SubListIterable,
        SystemHash,
        UnmodifiableListMixin,
        makeFixedListUnmodifiable,
        makeListFixedLength,
        patch,
        reachabilityFence,
        unsafeCast,
        writeIntoOneByteString,
        writeIntoTwoByteString;

import "dart:async" show Completer, DeferredLoadException, Future, Timer, Zone;

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

import "dart:convert" show ascii, Encoding, json, latin1, utf8;

import "dart:ffi" show Pointer, Struct, Union, NativePort;

import "dart:isolate" show Isolate, RawReceivePort;

import "dart:typed_data" show Uint8List, Uint16List, Int32List;

/// These are the additional parts of this patch library:
part "array.dart";
part "double.dart";
part "double_patch.dart";
part "errors_patch.dart";
part "expando_patch.dart";
part "finalizer_patch.dart";
part "function.dart";
part "function_patch.dart";
part "growable_array.dart";
part "identical_patch.dart";
part "integers.dart";
part "invocation_mirror_patch.dart";
part "lib_prefix.dart";
part "object_patch.dart";
part "record_patch.dart";
part "regexp_patch.dart";
part "stacktrace.dart";
part "stopwatch_patch.dart";
part "string_patch.dart";
part "type_patch.dart";
part "uri_patch.dart";
part "weak_property.dart";

@patch
@pragma('vm:deeply-immutable')
class num {
  num _addFromInteger(int other);
  num _subFromInteger(int other);
  num _mulFromInteger(int other);
  int _truncDivFromInteger(int other);
  num _moduloFromInteger(int other);
  num _remainderFromInteger(int other);
  bool _greaterThanFromInteger(int other);
  bool _equalToInteger(int other);
}

@patch
class StackTrace {
  @patch
  @pragma("vm:external-name", "StackTrace_current")
  external static StackTrace get current;
}
