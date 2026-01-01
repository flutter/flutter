// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "internal_patch.dart";

@pragma("wasm:entry-point")
class ClassID {
  @pragma("wasm:intrinsic")
  external static WasmI32 getID(Object value);

  @pragma("wasm:class-id", "dart.typed_data#_ExternalUint8Array")
  external static WasmI32 get cidExternalUint8Array;
  @pragma("wasm:class-id", "dart.typed_data#_Uint8List")
  external static WasmI32 get cidUint8Array;
  @pragma("wasm:class-id", "dart.typed_data#_Uint8ArrayView")
  external static WasmI32 get cidUint8ArrayView;
  @pragma("wasm:class-id", "dart.typed_data#Uint8ClampedList")
  external static WasmI32 get cidUint8ClampedList;
  @pragma("wasm:class-id", "dart.typed_data#_Uint8ClampedList")
  external static WasmI32 get cid_Uint8ClampedList;
  @pragma("wasm:class-id", "dart.typed_data#_Uint8ClampedArrayView")
  external static WasmI32 get cidUint8ClampedArrayView;
  @pragma("wasm:class-id", "dart.typed_data#Int8List")
  external static WasmI32 get cidInt8List;
  @pragma("wasm:class-id", "dart.typed_data#_Int8List")
  external static WasmI32 get cid_Int8List;
  @pragma("wasm:class-id", "dart.typed_data#_Int8ArrayView")
  external static WasmI32 get cidInt8ArrayView;
  @pragma("wasm:class-id", "dart.async#Future")
  external static WasmI32 get cidFuture;
  @pragma("wasm:class-id", "dart.core#Function")
  external static WasmI32 get cidFunction;
  @pragma("wasm:class-id", "dart.core#_Closure")
  external static WasmI32 get cid_Closure;
  @pragma("wasm:class-id", "dart.core#List")
  external static WasmI32 get cidList;
  @pragma("wasm:class-id", "dart._list#ModifiableFixedLengthList")
  external static WasmI32 get cidFixedLengthList;
  @pragma("wasm:class-id", "dart._list#WasmListBase")
  external static WasmI32 get cidListBase;
  @pragma("wasm:class-id", "dart._list#GrowableList")
  external static WasmI32 get cidGrowableList;
  @pragma("wasm:class-id", "dart._list#ImmutableList")
  external static WasmI32 get cidImmutableList;
  @pragma("wasm:class-id", "dart.core#Record")
  external static WasmI32 get cidRecord;
  @pragma("wasm:class-id", "dart.core#Symbol")
  external static WasmI32 get cidSymbol;

  // Class IDs for RTI Types.
  @pragma("wasm:class-id", "dart.core#_BottomType")
  external static WasmI32 get cidBottomType;
  @pragma("wasm:class-id", "dart.core#_TopType")
  external static WasmI32 get cidTopType;
  @pragma("wasm:class-id", "dart.core#_FutureOrType")
  external static WasmI32 get cidFutureOrType;
  @pragma("wasm:class-id", "dart.core#_InterfaceType")
  external static WasmI32 get cidInterfaceType;
  @pragma("wasm:class-id", "dart.core#_AbstractFunctionType")
  external static WasmI32 get cidAbstractFunctionType;
  @pragma("wasm:class-id", "dart.core#_FunctionType")
  external static WasmI32 get cidFunctionType;
  @pragma("wasm:class-id", "dart.core#_FunctionTypeParameterType")
  external static WasmI32 get cidFunctionTypeParameterType;
  @pragma("wasm:class-id", "dart.core#_InterfaceTypeParameterType")
  external static WasmI32 get cidInterfaceTypeParameterType;
  @pragma("wasm:class-id", "dart.core#_AbstractRecordType")
  external static WasmI32 get cidAbstractRecordType;
  @pragma("wasm:class-id", "dart.core#_RecordType")
  external static WasmI32 get cidRecordType;
  @pragma("wasm:class-id", "dart.core#_NamedParameter")
  external static WasmI32 get cidNamedParameter;

  // From this class id onwards, all concrete classes are interface classes and
  // do not need to be masqueraded.
  external static WasmI32 get firstNonMasqueradedInterfaceClassCid;

  // Dummy, only used by VM-specific hash table code.
  static final WasmI32 numPredefinedCids = 1.toWasmI32();

  // The maximum class ID in the main module of the program.
  external static WasmI32 get maxClassId;
}

const int mainModuleId = 0;

/// The ith entry in this array is the max global class ID for module i.
WasmArray<WasmI32> _moduleMaxClassId = WasmArray.filled(1, ClassID.maxClassId);

/// Gets the module ID for a given global class ID.
@pragma('dyn-module:callable')
int classIdToModuleId(WasmI32 classId) {
  if (!hasDynamicModuleSupport) {
    assert(
      _moduleMaxClassId.length == 1 &&
          classId <= _moduleMaxClassId[mainModuleId],
    );
    return mainModuleId;
  }
  // NOTE: This could be made into binary search if many modules are getting
  // registered. For now we expect few so a linear search is fine.
  final array = _moduleMaxClassId;
  for (int i = 0; i < array.length; i++) {
    if (classId <= array[i]) return i;
  }
  throw ArgumentError();
}

/// Registers a new dynamic module based on the size of its new class ID range.
@pragma('dyn-module:callable')
int registerModuleClassRange(WasmI32 rangeSize) {
  final oldRanges = _moduleMaxClassId;
  final moduleId = oldRanges.length;

  final newRanges = WasmArray<WasmI32>.filled(moduleId + 1, 0.toWasmI32());
  newRanges.copy(0, oldRanges, 0, oldRanges.length);
  newRanges[moduleId] = rangeSize + oldRanges[moduleId - 1];
  _moduleMaxClassId = newRanges;
  return moduleId;
}

/// Scopes a class ID to the enclosing module giving an ID relative to only
/// classes defined in the module defining the class.
@pragma('dyn-module:callable')
WasmI32 scopeClassId(WasmI32 classId) {
  final moduleId = classIdToModuleId(classId);
  if (moduleId == 0) return classId;
  return classId - (_moduleMaxClassId[moduleId - 1] + 1.toWasmI32());
}

/// Produces a localized class ID from a global class ID. A local ID is offset
/// relative to the main module rather than the global ID space. The compiler
/// produces localized IDs since it can't track global IDs. Multiple classes
/// can map to the same localized class ID.
@pragma('dyn-module:callable')
WasmI32 localizeClassId(WasmI32 classId) {
  final moduleId = classIdToModuleId(classId);
  if (moduleId == 0) return classId;
  return classId - _moduleMaxClassId[moduleId - 1] + ClassID.maxClassId;
}

/// Produces a global class ID from a local class ID. A global ID is offset
/// relative to all registered dynamic modules. Each class will have a unique
/// global class ID.
@pragma('dyn-module:callable')
WasmI32 globalizeClassId(WasmI32 classId, int moduleId) {
  if (moduleId == 0) return classId;
  return classId - ClassID.maxClassId + _moduleMaxClassId[moduleId - 1];
}
