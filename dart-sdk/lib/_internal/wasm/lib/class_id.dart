// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "internal_patch.dart";

@pragma("wasm:entry-point")
class ClassID {
  external static int getID(Object? value);

  @pragma("wasm:class-id", "dart.typed_data#_ExternalUint8Array")
  external static int get cidExternalUint8Array;
  @pragma("wasm:class-id", "dart.typed_data#_Uint8List")
  external static int get cidUint8Array;
  @pragma("wasm:class-id", "dart.typed_data#_Uint8ArrayView")
  external static int get cidUint8ArrayView;
  @pragma("wasm:class-id", "dart.typed_data#Uint8ClampedList")
  external static int get cidUint8ClampedList;
  @pragma("wasm:class-id", "dart.typed_data#_Uint8ClampedList")
  external static int get cid_Uint8ClampedList;
  @pragma("wasm:class-id", "dart.typed_data#_Uint8ClampedArrayView")
  external static int get cidUint8ClampedArrayView;
  @pragma("wasm:class-id", "dart.typed_data#Int8List")
  external static int get cidInt8List;
  @pragma("wasm:class-id", "dart.typed_data#_Int8List")
  external static int get cid_Int8List;
  @pragma("wasm:class-id", "dart.typed_data#_Int8ArrayView")
  external static int get cidInt8ArrayView;
  @pragma("wasm:class-id", "dart.async#Future")
  external static int get cidFuture;
  @pragma("wasm:class-id", "dart.core#Function")
  external static int get cidFunction;
  @pragma("wasm:class-id", "dart.core#_Closure")
  external static int get cid_Closure;
  @pragma("wasm:class-id", "dart.core#List")
  external static int get cidList;
  @pragma("wasm:class-id", "dart._list#ModifiableFixedLengthList")
  external static int get cidFixedLengthList;
  @pragma("wasm:class-id", "dart._list#WasmListBase")
  external static int get cidListBase;
  @pragma("wasm:class-id", "dart._list#GrowableList")
  external static int get cidGrowableList;
  @pragma("wasm:class-id", "dart._list#ImmutableList")
  external static int get cidImmutableList;
  @pragma("wasm:class-id", "dart.core#Record")
  external static int get cidRecord;
  @pragma("wasm:class-id", "dart.core#Symbol")
  external static int get cidSymbol;

  // Class IDs for RTI Types.
  @pragma("wasm:class-id", "dart.core#_BottomType")
  external static int get cidBottomType;
  @pragma("wasm:class-id", "dart.core#_TopType")
  external static int get cidTopType;
  @pragma("wasm:class-id", "dart.core#_FutureOrType")
  external static int get cidFutureOrType;
  @pragma("wasm:class-id", "dart.core#_InterfaceType")
  external static int get cidInterfaceType;
  @pragma("wasm:class-id", "dart.core#_AbstractFunctionType")
  external static int get cidAbstractFunctionType;
  @pragma("wasm:class-id", "dart.core#_FunctionType")
  external static int get cidFunctionType;
  @pragma("wasm:class-id", "dart.core#_FunctionTypeParameterType")
  external static int get cidFunctionTypeParameterType;
  @pragma("wasm:class-id", "dart.core#_InterfaceTypeParameterType")
  external static int get cidInterfaceTypeParameterType;
  @pragma("wasm:class-id", "dart.core#_AbstractRecordType")
  external static int get cidAbstractRecordType;
  @pragma("wasm:class-id", "dart.core#_RecordType")
  external static int get cidRecordType;
  @pragma("wasm:class-id", "dart.core#_NamedParameter")
  external static int get cidNamedParameter;

  // From this class id onwards, all concrete classes are interface classes and
  // do not need to be masqueraded.
  external static int get firstNonMasqueradedInterfaceClassCid;

  // Dummy, only used by VM-specific hash table code.
  static final int numPredefinedCids = 1;
}
