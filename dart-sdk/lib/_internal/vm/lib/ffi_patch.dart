// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal" show patch, has63BitSmis;
import 'dart:async';
import 'dart:typed_data';
import 'dart:isolate';
import 'dart:typed_data';

const Map<Type, int> _knownSizes = {
  Int8: 1,
  Uint8: 1,
  Int16: 2,
  Uint16: 2,
  Int32: 4,
  Uint32: 4,
  Int64: 8,
  Uint64: 8,
  Float: 4,
  Double: 8,
};

// Keep consistent with pkg/vm/lib/transformations/ffi/abi.dart.
@pragma("vm:prefer-inline")
int get _intPtrSize => (const [
      4, // androidArm,
      8, // androidArm64,
      4, // androidIA32,
      8, // androidX64,
      8, // androidRiscv64,
      8, // fuchsiaArm64,
      8, // fuchsiaX64,
      8, // fuchsiaRiscv64,
      4, // iosArm,
      8, // iosArm64,
      8, // iosX64,
      4, // linuxArm,
      8, // linuxArm64,
      4, // linuxIA32,
      8, // linuxX64,
      4, // linuxRiscv32,
      8, // linuxRiscv64,
      8, // macosArm64,
      8, // macosX64,
      8, // windowsArm64,
      4, // windowsIA32,
      8, // windowsX64,
    ])[_abi()];

@pragma("vm:prefer-inline")
int get _smiMax {
  // See runtime/vm/globals.h for how smiMax is calculated.
  final smiBits = has63BitSmis ? 62 : 30;
  return (1 << smiBits) - 1;
}

@pragma("vm:prefer-inline")
void _checkExternalTypedDataLength(int length, int elementSize) {
  final maxElements = _smiMax ~/ elementSize;
  if (length < 0 || length > maxElements) {
    throw ArgumentError("length must be in the range [0, $maxElements].");
  }
}

@pragma("vm:prefer-inline")
void _checkPointerAlignment(int address, int elementSize) {
  if (address & (elementSize - 1) != 0) {
    throw ArgumentError("Pointer address must be aligned to a multiple of "
        "the element size ($elementSize).");
  }
}

@patch
int sizeOf<T extends SizedNativeType>() {
  // This case should have been rewritten in pre-processing.
  throw UnimplementedError("$T");
}

@pragma("vm:idempotent")
@pragma("vm:recognized", "other")
@pragma("vm:idempotent")
external Pointer<T> _fromAddress<T extends NativeType>(int ptr);

/// Argument for vm:ffi:call-closure pragma describing FFI call.
final class _FfiCall<NativeSignature> {
  // Implementation note: VM hardcodes the layout of this class (number and
  // order of its fields), so adding/removing/changing fields requires
  // updating the VM code (see Function::GetFfiCallClosurePragmaValue()).
  final bool isLeaf;
  const _FfiCall({this.isLeaf = false});
}

// Helper function to perform FFI call.
// Inserted by FFI kernel transformation into the FFI call closures.
// Implemented in BuildFfiCall
// in runtime/vm/compiler/frontend/kernel_binary_flowgraph.cc.
@pragma("vm:recognized", "other")
external ReturnType _ffiCall<ReturnType>(Pointer<NativeFunction> target);

@pragma("vm:recognized", "other")
@pragma("vm:idempotent")
@pragma("vm:exact-result-type", "dart:typed_data#_ExternalInt8Array")
external Int8List _asExternalTypedDataInt8(Pointer<Int8> ptr, int length);

@pragma("vm:recognized", "other")
@pragma("vm:idempotent")
@pragma("vm:exact-result-type", "dart:typed_data#_ExternalInt16Array")
external Int16List _asExternalTypedDataInt16(Pointer<Int16> ptr, int length);

@pragma("vm:recognized", "other")
@pragma("vm:idempotent")
@pragma("vm:exact-result-type", "dart:typed_data#_ExternalInt32Array")
external Int32List _asExternalTypedDataInt32(Pointer<Int32> ptr, int length);

@pragma("vm:recognized", "other")
@pragma("vm:idempotent")
@pragma("vm:exact-result-type", "dart:typed_data#_ExternalInt64Array")
external Int64List _asExternalTypedDataInt64(Pointer<Int64> ptr, int length);

@pragma("vm:recognized", "other")
@pragma("vm:idempotent")
@pragma("vm:exact-result-type", "dart:typed_data#_ExternalUint8Array")
external Uint8List _asExternalTypedDataUint8(Pointer<Uint8> ptr, int length);

@pragma("vm:recognized", "other")
@pragma("vm:idempotent")
@pragma("vm:exact-result-type", "dart:typed_data#_ExternalUint16Array")
external Uint16List _asExternalTypedDataUint16(Pointer<Uint16> ptr, int length);

@pragma("vm:recognized", "other")
@pragma("vm:idempotent")
@pragma("vm:exact-result-type", "dart:typed_data#_ExternalUint32Array")
external Uint32List _asExternalTypedDataUint32(Pointer<Uint32> ptr, int length);

@pragma("vm:recognized", "other")
@pragma("vm:idempotent")
@pragma("vm:exact-result-type", "dart:typed_data#_ExternalUint64Array")
external Uint64List _asExternalTypedDataUint64(Pointer<Uint64> ptr, int length);

@pragma("vm:recognized", "other")
@pragma("vm:idempotent")
@pragma("vm:exact-result-type", "dart:typed_data#_ExternalFloat32Array")
external Float32List _asExternalTypedDataFloat(Pointer<Float> ptr, int length);

@pragma("vm:recognized", "other")
@pragma("vm:idempotent")
@pragma("vm:exact-result-type", "dart:typed_data#_ExternalFloat64Array")
external Float64List _asExternalTypedDataDouble(
    Pointer<Double> ptr, int length);

// Returns a Function object for a native callback.
//
// Calls to [Pointer.fromFunction] are re-written by the FE into calls to this
// method + _pointerFromFunction. All three arguments must be constants.
//
// In AOT we evaluate calls to this function during precompilation and replace
// them with Constant instruction referencing the callback trampoline, to ensure
// that it will be precompiled.
//
// In all JIT modes we call a native runtime entry. We *cannot* use the IL
// implementation, since that would pull the callback trampoline into JIT
// snapshots. The callback trampolines can only be serialized into AOT snapshots
// because they embed the addresses of runtime routines in JIT mode.
//
// Function objects returned by this native method are not Dart instances,
// so we need to use top type as a return type to avoid type check.
@pragma("vm:recognized", "other")
@pragma("vm:external-name", "Ffi_nativeCallbackFunction")
external dynamic _nativeCallbackFunction<NS extends Function>(
    Function target, Object? exceptionalReturn);

@pragma("vm:recognized", "other")
@pragma("vm:external-name", "Ffi_nativeAsyncCallbackFunction")
external dynamic _nativeAsyncCallbackFunction<NS extends Function>();

@pragma("vm:external-name", "Ffi_createNativeCallableListener")
external Pointer<NS> _createNativeCallableListener<NS extends NativeFunction>(
    dynamic function, RawReceivePort port);

@pragma("vm:external-name", "Ffi_createNativeCallableIsolateLocal")
external Pointer<NS>
    _createNativeCallableIsolateLocal<NS extends NativeFunction>(
        dynamic trampoline, dynamic target, bool keepIsolateAlive);

@pragma("vm:external-name", "Ffi_deleteNativeCallable")
external void _deleteNativeCallable<NS extends NativeFunction>(
    Pointer<NS> pointer);

@pragma("vm:external-name", "Ffi_updateNativeCallableKeepIsolateAliveCounter")
external void
    _updateNativeCallableKeepIsolateAliveCounter<NS extends NativeFunction>(
        int delta);

@pragma("vm:recognized", "other")
@pragma("vm:external-name", "Ffi_nativeIsolateLocalCallbackFunction")
external dynamic _nativeIsolateLocalCallbackFunction<NS extends Function>(
    dynamic exceptionalReturn);

@patch
@pragma('vm:deeply-immutable')
@pragma("vm:entry-point")
final class Pointer<T extends NativeType> implements SizedNativeType {
  @patch
  factory Pointer.fromAddress(int ptr) => _fromAddress(ptr);

  // All static calls to this method are replaced by the FE into
  // _nativeCallbackFunction + _pointerFromFunction.
  //
  // We still need to throw an error on a dynamic invocations, invocations
  // through tearoffs or reflective calls.
  @patch
  static Pointer<NativeFunction<T>> fromFunction<T extends Function>(
      @DartRepresentationOf("T") Function f,
      [Object? exceptionalReturn]) {
    throw UnsupportedError(
        "Pointer.fromFunction cannot be called dynamically.");
  }

  @patch
  @pragma("vm:recognized", "other")
  @pragma("vm:idempotent")
  external int get address;

  Pointer<T> _offsetBy(int offsetInBytes) =>
      Pointer.fromAddress(address + offsetInBytes);

  @patch
  Pointer<U> cast<U extends NativeType>() => Pointer.fromAddress(address);
}

abstract final class _NativeCallableBase<T extends Function>
    implements NativeCallable<T> {
  Pointer<NativeFunction<T>> _pointer;

  _NativeCallableBase(this._pointer);

  @override
  Pointer<NativeFunction<T>> get nativeFunction {
    if (_isClosed) {
      throw StateError("NativeCallable is already closed.");
    }
    return _pointer;
  }

  @override
  void close() {
    if (!_isClosed) {
      _close();
      _deleteNativeCallable(_pointer);
      _pointer = nullptr;
    }
  }

  @override
  void set keepIsolateAlive(bool value) {
    if (!_isClosed) {
      _keepIsolateAlive = value;
    }
  }

  @override
  bool get keepIsolateAlive => !_isClosed && _keepIsolateAlive;

  abstract bool _keepIsolateAlive;
  void _close();
  bool get _isClosed => _pointer == nullptr;
}

final class _NativeCallableIsolateLocal<T extends Function>
    extends _NativeCallableBase<T> {
  bool _isKeepingIsolateAlive = true;

  _NativeCallableIsolateLocal(super._pointer);

  @override
  void _close() {
    _keepIsolateAlive = false;
  }

  @override
  void set _keepIsolateAlive(bool value) {
    if (_isKeepingIsolateAlive != value) {
      _isKeepingIsolateAlive = value;
      _updateNativeCallableKeepIsolateAliveCounter(value ? 1 : -1);
    }
  }

  @override
  bool get _keepIsolateAlive => _isKeepingIsolateAlive;
}

final class _NativeCallableListener<T extends Function>
    extends _NativeCallableBase<T> {
  final RawReceivePort _port;

  _NativeCallableListener(void Function(List) handler, String portDebugName)
      : _port = RawReceivePort(
            Zone.current.bindUnaryCallbackGuarded(handler), portDebugName),
        super(nullptr);

  @override
  void _close() {
    _port.close();
  }

  @override
  void set _keepIsolateAlive(bool value) {
    _port.keepIsolateAlive = value;
  }

  @override
  bool get _keepIsolateAlive => _port.keepIsolateAlive;
}

@patch
@pragma("vm:entry-point")
final class Array<T extends NativeType> extends _Compound {
  @pragma("vm:entry-point")
  final int _size;

  @pragma("vm:entry-point")
  final List<int> _nestedDimensions;

  int? _nestedDimensionsFlattenedCache;
  int? _nestedDimensionsFirstCache;
  List<int>? _nestedDimensionsRestCache;

  @pragma("vm:entry-point")
  Array._(
    super._typedDataBase,
    super._offsetInBytes,
    this._size,
    this._nestedDimensions,
  ) : super._fromTypedDataBase();

  int get _nestedDimensionsFlattened =>
      _nestedDimensionsFlattenedCache ??= _nestedDimensions.fold<int>(
          1, (accumulator, element) => accumulator * element);

  int get _nestedDimensionsFirst =>
      _nestedDimensionsFirstCache ??= _nestedDimensions.first;

  List<int> get _nestedDimensionsRest =>
      _nestedDimensionsRestCache ??= _nestedDimensions.sublist(1);

  void _checkIndex(int index) {
    if (index < 0 || index >= _size) {
      throw RangeError.range(index, 0, _size - 1);
    }
  }
}

/// Returns an integer encoding the ABI used for size and alignment
/// calculations. See pkg/vm/lib/transformations/ffi.dart.
@pragma("vm:recognized", "other")
@pragma('vm:prefer-inline')
@pragma("vm:idempotent")
external int _abi();

@patch
@pragma("vm:entry-point")
final class Abi {
  @patch
  @pragma("vm:prefer-inline")
  factory Abi.current() => values[_abi()];
}

@pragma("vm:entry-point")
final class _FfiAbiSpecificMapping {
  /// A more concise representation of `AbiSpecificIntegerMapping`.
  ///
  /// `AbiSpecificIntegerMapping` contain a mapping from Abi to DartType.
  /// Keys can be missing in `AbiSpecificIntegerMapping`.
  ///
  /// For easy access in the VM, this is a list, indexed by [Abi.index].
  @pragma("vm:entry-point")
  final List<Type?> nativeTypes;

  const _FfiAbiSpecificMapping(this.nativeTypes);
}

/// Copies data byte-wise from [source] to [target].
///
/// [source] and [target] should either be [Pointer] or [TypedData].
@pragma("vm:entry-point")
@pragma("vm:recognized", "other")
external void _memCopy(Object target, int targetOffsetInBytes, Object source,
    int sourceOffsetInBytes, int lengthInBytes);

// The following functions are implemented in the method recognizer.
//
// TODO(38172): Since these are not inlined (force optimize), they force
// allocating a Pointer with in elementAt/offsetBy. Allocating these pointers
// and GCing new spaces takes a lot of the benchmark time. The next speedup is
// getting rid of these allocations by inlining these functions.
@pragma("vm:entry-point")
@pragma("vm:recognized", "other")
@pragma("vm:idempotent")
external int _loadInt8(Object typedDataBase, int offsetInBytes);

@pragma("vm:entry-point")
@pragma("vm:recognized", "other")
@pragma("vm:idempotent")
external int _loadInt16(Object typedDataBase, int offsetInBytes);

@pragma("vm:entry-point")
@pragma("vm:recognized", "other")
@pragma("vm:idempotent")
external int _loadInt32(Object typedDataBase, int offsetInBytes);

@pragma("vm:entry-point")
@pragma("vm:recognized", "other")
@pragma("vm:idempotent")
external int _loadInt64(Object typedDataBase, int offsetInBytes);

@pragma("vm:entry-point")
@pragma("vm:recognized", "other")
@pragma("vm:idempotent")
external int _loadUint8(Object typedDataBase, int offsetInBytes);

@pragma("vm:entry-point")
@pragma("vm:recognized", "other")
@pragma("vm:idempotent")
external int _loadUint16(Object typedDataBase, int offsetInBytes);

@pragma("vm:entry-point")
@pragma("vm:recognized", "other")
@pragma("vm:idempotent")
external int _loadUint32(Object typedDataBase, int offsetInBytes);

@pragma("vm:entry-point")
@pragma("vm:recognized", "other")
@pragma("vm:idempotent")
external int _loadUint64(Object typedDataBase, int offsetInBytes);

@pragma("vm:recognized", "other")
@pragma("vm:idempotent")
external int _loadAbiSpecificInt<T extends AbiSpecificInteger>(
    Object typedDataBase, int offsetInBytes);

@pragma("vm:recognized", "other")
@pragma("vm:idempotent")
external int _loadAbiSpecificIntAtIndex<T extends AbiSpecificInteger>(
    Object typedDataBase, int offsetInBytes, int index);

@pragma("vm:recognized", "other")
@pragma("vm:idempotent")
external double _loadFloat(Object typedDataBase, int offsetInBytes);

@pragma("vm:recognized", "other")
@pragma("vm:idempotent")
external double _loadDouble(Object typedDataBase, int offsetInBytes);

@pragma("vm:recognized", "other")
@pragma("vm:idempotent")
external double _loadFloatUnaligned(Object typedDataBase, int offsetInBytes);

@pragma("vm:recognized", "other")
@pragma("vm:idempotent")
external double _loadDoubleUnaligned(Object typedDataBase, int offsetInBytes);

@pragma("vm:recognized", "other")
@pragma("vm:idempotent")
external Pointer<S> _loadPointer<S extends NativeType>(
    Object typedDataBase, int offsetInBytes);

@pragma("vm:entry-point")
@pragma("vm:recognized", "other")
@pragma("vm:idempotent")
external void _storeInt8(Object typedDataBase, int offsetInBytes, int value);

@pragma("vm:entry-point")
@pragma("vm:recognized", "other")
@pragma("vm:idempotent")
external void _storeInt16(Object typedDataBase, int offsetInBytes, int value);

@pragma("vm:entry-point")
@pragma("vm:recognized", "other")
@pragma("vm:idempotent")
external void _storeInt32(Object typedDataBase, int offsetInBytes, int value);

@pragma("vm:entry-point")
@pragma("vm:recognized", "other")
@pragma("vm:idempotent")
external void _storeInt64(Object typedDataBase, int offsetInBytes, int value);

@pragma("vm:entry-point")
@pragma("vm:recognized", "other")
@pragma("vm:idempotent")
external void _storeUint8(Object typedDataBase, int offsetInBytes, int value);

@pragma("vm:entry-point")
@pragma("vm:recognized", "other")
@pragma("vm:idempotent")
external void _storeUint16(Object typedDataBase, int offsetInBytes, int value);

@pragma("vm:entry-point")
@pragma("vm:recognized", "other")
@pragma("vm:idempotent")
external void _storeUint32(Object typedDataBase, int offsetInBytes, int value);

@pragma("vm:entry-point")
@pragma("vm:recognized", "other")
@pragma("vm:idempotent")
external void _storeUint64(Object typedDataBase, int offsetInBytes, int value);

@pragma("vm:recognized", "other")
@pragma("vm:idempotent")
external int _storeAbiSpecificInt<T extends AbiSpecificInteger>(
    Object typedDataBase, int offsetInBytes, int value);

@pragma("vm:recognized", "other")
@pragma("vm:idempotent")
external int _storeAbiSpecificIntAtIndex<T extends AbiSpecificInteger>(
    Object typedDataBase, int offsetInBytes, int index, int value);

@pragma("vm:recognized", "other")
@pragma("vm:idempotent")
external void _storeFloat(
    Object typedDataBase, int offsetInBytes, double value);

@pragma("vm:recognized", "other")
@pragma("vm:idempotent")
external void _storeDouble(
    Object typedDataBase, int offsetInBytes, double value);

@pragma("vm:recognized", "other")
@pragma("vm:idempotent")
external void _storeFloatUnaligned(
    Object typedDataBase, int offsetInBytes, double value);

@pragma("vm:recognized", "other")
@pragma("vm:idempotent")
external void _storeDoubleUnaligned(
    Object typedDataBase, int offsetInBytes, double value);

@pragma("vm:recognized", "other")
@pragma("vm:idempotent")
external void _storePointer<S extends NativeType>(
    Object typedDataBase, int offsetInBytes, Pointer<S> value);

@pragma("vm:prefer-inline")
bool _loadBool(Object typedDataBase, int offsetInBytes) =>
    _loadUint8(typedDataBase, offsetInBytes) != 0;

@pragma("vm:prefer-inline")
void _storeBool(Object typedDataBase, int offsetInBytes, bool value) =>
    _storeUint8(typedDataBase, offsetInBytes, value ? 1 : 0);

@pragma("vm:prefer-inline")
@pragma("vm:entry-point")
T _checkAbiSpecificIntegerMapping<T>(T? object) {
  if (object == null) {
    throw ArgumentError(
        'AbiSpecificInteger is missing mapping for "${Abi.current()}".');
  }
  return object;
}

@patch
extension NativeFunctionPointer<NF extends Function>
    on Pointer<NativeFunction<NF>> {
  @patch
  DF asFunction<DF extends Function>({bool isLeaf = false}) =>
      throw UnsupportedError("The body is inlined in the frontend.");
}

//
// The following code is generated, do not edit by hand.
//
// Code generated by `runtime/tools/ffi/sdk_lib_ffi_generator.dart`.
//

@patch
extension Int8Pointer on Pointer<Int8> {
  @patch
  @pragma("vm:prefer-inline")
  int get value => _loadInt8(this, 0);

  @patch
  @pragma("vm:prefer-inline")
  set value(int value) => _storeInt8(this, 0, value);

  @patch
  @pragma("vm:prefer-inline")
  int operator [](int index) => _loadInt8(this, index);

  @patch
  @pragma("vm:prefer-inline")
  operator []=(int index, int value) => _storeInt8(this, index, value);

  @patch
  @pragma("vm:prefer-inline")
  Int8List asTypedList(
    int length, {
    Pointer<NativeFinalizerFunction>? finalizer,
    Pointer<Void>? token,
  }) {
    ArgumentError.checkNotNull(this, "Pointer<Int8>");
    ArgumentError.checkNotNull(length, "length");
    _checkExternalTypedDataLength(length, 1);
    _checkPointerAlignment(address, 1);
    final result = _asExternalTypedDataInt8(this, length);
    if (finalizer != null) {
      _attachAsTypedListFinalizer(finalizer, result, token ?? this, length);
    }
    return result;
  }
}

@patch
extension Int16Pointer on Pointer<Int16> {
  @patch
  @pragma("vm:prefer-inline")
  int get value => _loadInt16(this, 0);

  @patch
  @pragma("vm:prefer-inline")
  set value(int value) => _storeInt16(this, 0, value);

  @patch
  @pragma("vm:prefer-inline")
  int operator [](int index) => _loadInt16(this, 2 * index);

  @patch
  @pragma("vm:prefer-inline")
  operator []=(int index, int value) => _storeInt16(this, 2 * index, value);

  @patch
  @pragma("vm:prefer-inline")
  Int16List asTypedList(
    int length, {
    Pointer<NativeFinalizerFunction>? finalizer,
    Pointer<Void>? token,
  }) {
    ArgumentError.checkNotNull(this, "Pointer<Int16>");
    ArgumentError.checkNotNull(length, "length");
    _checkExternalTypedDataLength(length, 2);
    _checkPointerAlignment(address, 2);
    final result = _asExternalTypedDataInt16(this, length);
    if (finalizer != null) {
      _attachAsTypedListFinalizer(finalizer, result, token ?? this, 2 * length);
    }
    return result;
  }
}

@patch
extension Int32Pointer on Pointer<Int32> {
  @patch
  @pragma("vm:prefer-inline")
  int get value => _loadInt32(this, 0);

  @patch
  @pragma("vm:prefer-inline")
  set value(int value) => _storeInt32(this, 0, value);

  @patch
  @pragma("vm:prefer-inline")
  int operator [](int index) => _loadInt32(this, 4 * index);

  @patch
  @pragma("vm:prefer-inline")
  operator []=(int index, int value) => _storeInt32(this, 4 * index, value);

  @patch
  @pragma("vm:prefer-inline")
  Int32List asTypedList(
    int length, {
    Pointer<NativeFinalizerFunction>? finalizer,
    Pointer<Void>? token,
  }) {
    ArgumentError.checkNotNull(this, "Pointer<Int32>");
    ArgumentError.checkNotNull(length, "length");
    _checkExternalTypedDataLength(length, 4);
    _checkPointerAlignment(address, 4);
    final result = _asExternalTypedDataInt32(this, length);
    if (finalizer != null) {
      _attachAsTypedListFinalizer(finalizer, result, token ?? this, 4 * length);
    }
    return result;
  }
}

@patch
extension Int64Pointer on Pointer<Int64> {
  @patch
  @pragma("vm:prefer-inline")
  int get value => _loadInt64(this, 0);

  @patch
  @pragma("vm:prefer-inline")
  set value(int value) => _storeInt64(this, 0, value);

  @patch
  @pragma("vm:prefer-inline")
  int operator [](int index) => _loadInt64(this, 8 * index);

  @patch
  @pragma("vm:prefer-inline")
  operator []=(int index, int value) => _storeInt64(this, 8 * index, value);

  @patch
  @pragma("vm:prefer-inline")
  Int64List asTypedList(
    int length, {
    Pointer<NativeFinalizerFunction>? finalizer,
    Pointer<Void>? token,
  }) {
    ArgumentError.checkNotNull(this, "Pointer<Int64>");
    ArgumentError.checkNotNull(length, "length");
    _checkExternalTypedDataLength(length, 8);
    _checkPointerAlignment(address, 8);
    final result = _asExternalTypedDataInt64(this, length);
    if (finalizer != null) {
      _attachAsTypedListFinalizer(finalizer, result, token ?? this, 8 * length);
    }
    return result;
  }
}

@patch
extension Uint8Pointer on Pointer<Uint8> {
  @patch
  @pragma("vm:prefer-inline")
  int get value => _loadUint8(this, 0);

  @patch
  @pragma("vm:prefer-inline")
  set value(int value) => _storeUint8(this, 0, value);

  @patch
  @pragma("vm:prefer-inline")
  int operator [](int index) => _loadUint8(this, index);

  @patch
  @pragma("vm:prefer-inline")
  operator []=(int index, int value) => _storeUint8(this, index, value);

  @patch
  @pragma("vm:prefer-inline")
  Uint8List asTypedList(
    int length, {
    Pointer<NativeFinalizerFunction>? finalizer,
    Pointer<Void>? token,
  }) {
    ArgumentError.checkNotNull(this, "Pointer<Uint8>");
    ArgumentError.checkNotNull(length, "length");
    _checkExternalTypedDataLength(length, 1);
    _checkPointerAlignment(address, 1);
    final result = _asExternalTypedDataUint8(this, length);
    if (finalizer != null) {
      _attachAsTypedListFinalizer(finalizer, result, token ?? this, length);
    }
    return result;
  }
}

@patch
extension Uint16Pointer on Pointer<Uint16> {
  @patch
  @pragma("vm:prefer-inline")
  int get value => _loadUint16(this, 0);

  @patch
  @pragma("vm:prefer-inline")
  set value(int value) => _storeUint16(this, 0, value);

  @patch
  @pragma("vm:prefer-inline")
  int operator [](int index) => _loadUint16(this, 2 * index);

  @patch
  @pragma("vm:prefer-inline")
  operator []=(int index, int value) => _storeUint16(this, 2 * index, value);

  @patch
  @pragma("vm:prefer-inline")
  Uint16List asTypedList(
    int length, {
    Pointer<NativeFinalizerFunction>? finalizer,
    Pointer<Void>? token,
  }) {
    ArgumentError.checkNotNull(this, "Pointer<Uint16>");
    ArgumentError.checkNotNull(length, "length");
    _checkExternalTypedDataLength(length, 2);
    _checkPointerAlignment(address, 2);
    final result = _asExternalTypedDataUint16(this, length);
    if (finalizer != null) {
      _attachAsTypedListFinalizer(finalizer, result, token ?? this, 2 * length);
    }
    return result;
  }
}

@patch
extension Uint32Pointer on Pointer<Uint32> {
  @patch
  @pragma("vm:prefer-inline")
  int get value => _loadUint32(this, 0);

  @patch
  @pragma("vm:prefer-inline")
  set value(int value) => _storeUint32(this, 0, value);

  @patch
  @pragma("vm:prefer-inline")
  int operator [](int index) => _loadUint32(this, 4 * index);

  @patch
  @pragma("vm:prefer-inline")
  operator []=(int index, int value) => _storeUint32(this, 4 * index, value);

  @patch
  @pragma("vm:prefer-inline")
  Uint32List asTypedList(
    int length, {
    Pointer<NativeFinalizerFunction>? finalizer,
    Pointer<Void>? token,
  }) {
    ArgumentError.checkNotNull(this, "Pointer<Uint32>");
    ArgumentError.checkNotNull(length, "length");
    _checkExternalTypedDataLength(length, 4);
    _checkPointerAlignment(address, 4);
    final result = _asExternalTypedDataUint32(this, length);
    if (finalizer != null) {
      _attachAsTypedListFinalizer(finalizer, result, token ?? this, 4 * length);
    }
    return result;
  }
}

@patch
extension Uint64Pointer on Pointer<Uint64> {
  @patch
  @pragma("vm:prefer-inline")
  int get value => _loadUint64(this, 0);

  @patch
  @pragma("vm:prefer-inline")
  set value(int value) => _storeUint64(this, 0, value);

  @patch
  @pragma("vm:prefer-inline")
  int operator [](int index) => _loadUint64(this, 8 * index);

  @patch
  @pragma("vm:prefer-inline")
  operator []=(int index, int value) => _storeUint64(this, 8 * index, value);

  @patch
  @pragma("vm:prefer-inline")
  Uint64List asTypedList(
    int length, {
    Pointer<NativeFinalizerFunction>? finalizer,
    Pointer<Void>? token,
  }) {
    ArgumentError.checkNotNull(this, "Pointer<Uint64>");
    ArgumentError.checkNotNull(length, "length");
    _checkExternalTypedDataLength(length, 8);
    _checkPointerAlignment(address, 8);
    final result = _asExternalTypedDataUint64(this, length);
    if (finalizer != null) {
      _attachAsTypedListFinalizer(finalizer, result, token ?? this, 8 * length);
    }
    return result;
  }
}

@patch
extension FloatPointer on Pointer<Float> {
  @patch
  @pragma("vm:prefer-inline")
  double get value => _loadFloat(this, 0);

  @patch
  @pragma("vm:prefer-inline")
  set value(double value) => _storeFloat(this, 0, value);

  @patch
  @pragma("vm:prefer-inline")
  double operator [](int index) => _loadFloat(this, 4 * index);

  @patch
  @pragma("vm:prefer-inline")
  operator []=(int index, double value) => _storeFloat(this, 4 * index, value);

  @patch
  @pragma("vm:prefer-inline")
  Float32List asTypedList(
    int length, {
    Pointer<NativeFinalizerFunction>? finalizer,
    Pointer<Void>? token,
  }) {
    ArgumentError.checkNotNull(this, "Pointer<Float>");
    ArgumentError.checkNotNull(length, "length");
    _checkExternalTypedDataLength(length, 4);
    _checkPointerAlignment(address, 4);
    final result = _asExternalTypedDataFloat(this, length);
    if (finalizer != null) {
      _attachAsTypedListFinalizer(finalizer, result, token ?? this, 4 * length);
    }
    return result;
  }
}

@patch
extension DoublePointer on Pointer<Double> {
  @patch
  @pragma("vm:prefer-inline")
  double get value => _loadDouble(this, 0);

  @patch
  @pragma("vm:prefer-inline")
  set value(double value) => _storeDouble(this, 0, value);

  @patch
  @pragma("vm:prefer-inline")
  double operator [](int index) => _loadDouble(this, 8 * index);

  @patch
  @pragma("vm:prefer-inline")
  operator []=(int index, double value) => _storeDouble(this, 8 * index, value);

  @patch
  @pragma("vm:prefer-inline")
  Float64List asTypedList(
    int length, {
    Pointer<NativeFinalizerFunction>? finalizer,
    Pointer<Void>? token,
  }) {
    ArgumentError.checkNotNull(this, "Pointer<Double>");
    ArgumentError.checkNotNull(length, "length");
    _checkExternalTypedDataLength(length, 8);
    _checkPointerAlignment(address, 8);
    final result = _asExternalTypedDataDouble(this, length);
    if (finalizer != null) {
      _attachAsTypedListFinalizer(finalizer, result, token ?? this, 8 * length);
    }
    return result;
  }
}

@patch
extension BoolPointer on Pointer<Bool> {
  @patch
  @pragma("vm:prefer-inline")
  bool get value => _loadBool(this, 0);

  @patch
  @pragma("vm:prefer-inline")
  set value(bool value) => _storeBool(this, 0, value);

  @patch
  @pragma("vm:prefer-inline")
  bool operator [](int index) => _loadBool(this, index);

  @patch
  @pragma("vm:prefer-inline")
  operator []=(int index, bool value) => _storeBool(this, index, value);
}

@patch
extension Int8Array on Array<Int8> {
  @patch
  int operator [](int index) {
    _checkIndex(index);
    return _loadInt8(
      _typedDataBase,
      _offsetInBytes + index,
    );
  }

  @patch
  operator []=(int index, int value) {
    _checkIndex(index);
    return _storeInt8(
      _typedDataBase,
      _offsetInBytes + index,
      value,
    );
  }
}

@patch
extension Int16Array on Array<Int16> {
  @patch
  int operator [](int index) {
    _checkIndex(index);
    return _loadInt16(
      _typedDataBase,
      _offsetInBytes + 2 * index,
    );
  }

  @patch
  operator []=(int index, int value) {
    _checkIndex(index);
    return _storeInt16(
      _typedDataBase,
      _offsetInBytes + 2 * index,
      value,
    );
  }
}

@patch
extension Int32Array on Array<Int32> {
  @patch
  int operator [](int index) {
    _checkIndex(index);
    return _loadInt32(
      _typedDataBase,
      _offsetInBytes + 4 * index,
    );
  }

  @patch
  operator []=(int index, int value) {
    _checkIndex(index);
    return _storeInt32(
      _typedDataBase,
      _offsetInBytes + 4 * index,
      value,
    );
  }
}

@patch
extension Int64Array on Array<Int64> {
  @patch
  int operator [](int index) {
    _checkIndex(index);
    return _loadInt64(
      _typedDataBase,
      _offsetInBytes + 8 * index,
    );
  }

  @patch
  operator []=(int index, int value) {
    _checkIndex(index);
    return _storeInt64(
      _typedDataBase,
      _offsetInBytes + 8 * index,
      value,
    );
  }
}

@patch
extension Uint8Array on Array<Uint8> {
  @patch
  int operator [](int index) {
    _checkIndex(index);
    return _loadUint8(
      _typedDataBase,
      _offsetInBytes + index,
    );
  }

  @patch
  operator []=(int index, int value) {
    _checkIndex(index);
    return _storeUint8(
      _typedDataBase,
      _offsetInBytes + index,
      value,
    );
  }
}

@patch
extension Uint16Array on Array<Uint16> {
  @patch
  int operator [](int index) {
    _checkIndex(index);
    return _loadUint16(
      _typedDataBase,
      _offsetInBytes + 2 * index,
    );
  }

  @patch
  operator []=(int index, int value) {
    _checkIndex(index);
    return _storeUint16(
      _typedDataBase,
      _offsetInBytes + 2 * index,
      value,
    );
  }
}

@patch
extension Uint32Array on Array<Uint32> {
  @patch
  int operator [](int index) {
    _checkIndex(index);
    return _loadUint32(
      _typedDataBase,
      _offsetInBytes + 4 * index,
    );
  }

  @patch
  operator []=(int index, int value) {
    _checkIndex(index);
    return _storeUint32(
      _typedDataBase,
      _offsetInBytes + 4 * index,
      value,
    );
  }
}

@patch
extension Uint64Array on Array<Uint64> {
  @patch
  int operator [](int index) {
    _checkIndex(index);
    return _loadUint64(
      _typedDataBase,
      _offsetInBytes + 8 * index,
    );
  }

  @patch
  operator []=(int index, int value) {
    _checkIndex(index);
    return _storeUint64(
      _typedDataBase,
      _offsetInBytes + 8 * index,
      value,
    );
  }
}

@patch
extension FloatArray on Array<Float> {
  @patch
  double operator [](int index) {
    _checkIndex(index);
    return _loadFloat(
      _typedDataBase,
      _offsetInBytes + 4 * index,
    );
  }

  @patch
  operator []=(int index, double value) {
    _checkIndex(index);
    return _storeFloat(
      _typedDataBase,
      _offsetInBytes + 4 * index,
      value,
    );
  }
}

@patch
extension DoubleArray on Array<Double> {
  @patch
  double operator [](int index) {
    _checkIndex(index);
    return _loadDouble(
      _typedDataBase,
      _offsetInBytes + 8 * index,
    );
  }

  @patch
  operator []=(int index, double value) {
    _checkIndex(index);
    return _storeDouble(
      _typedDataBase,
      _offsetInBytes + 8 * index,
      value,
    );
  }
}

@patch
extension BoolArray on Array<Bool> {
  @patch
  bool operator [](int index) {
    _checkIndex(index);
    return _loadBool(
      _typedDataBase,
      _offsetInBytes + index,
    );
  }

  @patch
  operator []=(int index, bool value) {
    _checkIndex(index);
    return _storeBool(
      _typedDataBase,
      _offsetInBytes + index,
      value,
    );
  }
}

//
// End of generated code.
//

@patch
extension PointerPointer<T extends NativeType> on Pointer<Pointer<T>> {
  @patch
  Pointer<T> get value => _loadPointer(this, 0);

  @patch
  set value(Pointer<T> value) => _storePointer(this, 0, value);

  @patch
  Pointer<T> operator [](int index) => _loadPointer(this, _intPtrSize * index);

  @patch
  Pointer<Pointer<T>> elementAt(int index) =>
      Pointer.fromAddress(address + _intPtrSize * index);

  @patch
  Pointer<Pointer<T>> operator +(int offset) =>
      Pointer.fromAddress(address + _intPtrSize * offset);

  @patch
  Pointer<Pointer<T>> operator -(int offset) =>
      Pointer.fromAddress(address - _intPtrSize * offset);

  @patch
  operator []=(int index, Pointer<T> value) =>
      _storePointer(this, _intPtrSize * index, value);
}

@patch
extension StructPointer<T extends Struct> on Pointer<T> {
  @patch
  T get ref =>
      throw "UNREACHABLE: This case should have been rewritten in the CFE.";

  @patch
  set ref(T value) =>
      throw "UNREACHABLE: This case should have been rewritten in the CFE";

  @patch
  T operator [](int index) =>
      throw "UNREACHABLE: This case should have been rewritten in the CFE.";

  @patch
  void operator []=(int index, T value) =>
      throw "UNREACHABLE: This case should have been rewritten in the CFE.";

  @patch
  Pointer<T> elementAt(int index) =>
      throw "UNREACHABLE: This case should have been rewritten in the CFE.";

  @patch
  Pointer<T> operator +(int offset) =>
      throw "UNREACHABLE: This case should have been rewritten in the CFE.";

  @patch
  Pointer<T> operator -(int offset) =>
      throw "UNREACHABLE: This case should have been rewritten in the CFE.";
}

@patch
extension UnionPointer<T extends Union> on Pointer<T> {
  @patch
  T get ref =>
      throw "UNREACHABLE: This case should have been rewritten in the CFE.";

  @patch
  set ref(T value) =>
      throw "UNREACHABLE: This case should have been rewritten in the CFE";

  @patch
  T operator [](int index) =>
      throw "UNREACHABLE: This case should have been rewritten in the CFE.";

  @patch
  void operator []=(int index, T value) =>
      throw "UNREACHABLE: This case should have been rewritten in the CFE.";

  @patch
  Pointer<T> elementAt(int index) =>
      throw "UNREACHABLE: This case should have been rewritten in the CFE.";

  @patch
  Pointer<T> operator +(int offset) =>
      throw "UNREACHABLE: This case should have been rewritten in the CFE.";

  @patch
  Pointer<T> operator -(int offset) =>
      throw "UNREACHABLE: This case should have been rewritten in the CFE.";
}

@patch
extension AbiSpecificIntegerPointer<T extends AbiSpecificInteger>
    on Pointer<T> {
  @patch
  int get value =>
      throw "UNREACHABLE: This case should have been rewritten in the CFE.";

  @patch
  void set value(int value) =>
      throw "UNREACHABLE: This case should have been rewritten in the CFE.";

  @patch
  int operator [](int index) =>
      throw "UNREACHABLE: This case should have been rewritten in the CFE.";

  @patch
  void operator []=(int index, int value) =>
      throw "UNREACHABLE: This case should have been rewritten in the CFE.";

  @patch
  Pointer<T> elementAt(int index) =>
      throw "UNREACHABLE: This case should have been rewritten in the CFE.";

  @patch
  Pointer<T> operator +(int offset) =>
      throw "UNREACHABLE: This case should have been rewritten in the CFE.";

  @patch
  Pointer<T> operator -(int offset) =>
      throw "UNREACHABLE: This case should have been rewritten in the CFE.";
}

@patch
extension PointerArray<T extends NativeType> on Array<Pointer<T>> {
  @patch
  Pointer<T> operator [](int index) {
    _checkIndex(index);
    return _loadPointer(
      _typedDataBase,
      _offsetInBytes + _intPtrSize * index,
    );
  }

  @patch
  void operator []=(int index, Pointer<T> value) {
    _checkIndex(index);
    return _storePointer(
      _typedDataBase,
      _offsetInBytes + _intPtrSize * index,
      value,
    );
  }
}

@patch
extension ArrayArray<T extends NativeType> on Array<Array<T>> {
  @patch
  Array<T> operator [](int index) =>
      throw "UNREACHABLE: This case should have been rewritten in the CFE.";

  @patch
  void operator []=(int index, Array<T> value) =>
      throw "UNREACHABLE: This case should have been rewritten in the CFE.";
}

@patch
extension StructArray<T extends Struct> on Array<T> {
  @patch
  T operator [](int index) {
    throw ArgumentError(
        "T ($T) should be a subtype of Struct at compile-time.");
  }
}

@patch
extension UnionArray<T extends Union> on Array<T> {
  @patch
  T operator [](int index) {
    throw ArgumentError("T ($T) should be a subtype of Union at compile-time.");
  }
}

@patch
extension AbiSpecificIntegerArray<T extends AbiSpecificInteger> on Array<T> {
  @patch
  int operator [](int index) {
    throw ArgumentError(
        "Receiver should be a subtype of AbiSpecificInteger at compile-time.");
  }

  @patch
  void operator []=(int index, int value) {
    throw ArgumentError(
        "Receiver should be a subtype of AbiSpecificInteger at compile-time.");
  }
}

@patch
extension NativePort on SendPort {
  @patch
  @pragma("vm:external-name", "SendPort_get_id")
  external int get nativePort;
}

@pragma("vm:external-name", "DartNativeApiFunctionPointer")
external int _nativeApiFunctionPointer(String symbol);

@pragma("vm:external-name", "DartApiDLInitializeData")
external int _initializeApiDLData();

@pragma("vm:external-name", "DartApiDLMajorVersion")
external int _dartApiMajorVersion();

@pragma("vm:external-name", "DartApiDLMinorVersion")
external int _dartApiMinorVersion();

@patch
abstract final class NativeApi {
  @patch
  static Pointer<NativeFunction<Int8 Function(Int64, Pointer<Dart_CObject>)>>
      get postCObject =>
          Pointer.fromAddress(_nativeApiFunctionPointer("Dart_PostCObject"));

  @patch
  static Pointer<
      NativeFunction<
          Int64 Function(
              Pointer<Uint8>,
              Pointer<NativeFunction<Dart_NativeMessageHandler>>,
              Int8)>> get newNativePort =>
      Pointer.fromAddress(_nativeApiFunctionPointer("Dart_NewNativePort"));

  @patch
  static Pointer<NativeFunction<Int8 Function(Int64)>> get closeNativePort =>
      Pointer.fromAddress(_nativeApiFunctionPointer("Dart_CloseNativePort"));

  @patch
  static int get majorVersion => _dartApiMajorVersion();

  @patch
  static int get minorVersion => _dartApiMinorVersion();

  @patch
  static Pointer<Void> get initializeApiDLData =>
      Pointer.fromAddress(_initializeApiDLData());
}

// Implementations needed to implement the private member added in the
// patch class of [Array].

@patch
final class _ArraySize<T extends NativeType> implements Array<T> {
  _checkIndex(int index) => throw UnsupportedError('_ArraySize._checkIndex');

  List<int> get _nestedDimensions =>
      throw UnsupportedError('_ArraySize._nestedDimensions');

  int get _nestedDimensionsFirst =>
      throw UnsupportedError('_ArraySize._nestedDimensionsFirst');

  int? get _nestedDimensionsFirstCache =>
      throw UnsupportedError('_ArraySize._nestedDimensionsFirstCache');

  void set _nestedDimensionsFirstCache(int? _) {
    throw UnsupportedError('_ArraySize._nestedDimensionsFirstCache');
  }

  int get _nestedDimensionsFlattened =>
      throw UnsupportedError('_ArraySize._nestedDimensionsFlattened');

  int? get _nestedDimensionsFlattenedCache =>
      throw UnsupportedError('_ArraySize._nestedDimensionsFlattenedCache');

  void set _nestedDimensionsFlattenedCache(int? _) {
    throw UnsupportedError('_ArraySize._nestedDimensionsFlattenedCache');
  }

  List<int> get _nestedDimensionsRest =>
      throw UnsupportedError('_ArraySize._nestedDimensionsRest');

  List<int>? get _nestedDimensionsRestCache =>
      throw UnsupportedError('_ArraySize._nestedDimensionsRestCache');

  void set _nestedDimensionsRestCache(List<int>? _) {
    throw UnsupportedError('_ArraySize._nestedDimensionsRestCache');
  }

  int get _size => throw UnsupportedError('_ArraySize._size');

  Object get _typedDataBase =>
      throw UnsupportedError('_ArraySize._typedDataBase');

  int get _offsetInBytes => throw UnsupportedError('_ArraySize._offsetInBytes');
}

@patch
@pragma("vm:entry-point")
class Native<T> {
  @patch
  static Pointer<T> addressOf<T extends NativeType>(
      @DartRepresentationOf('T') Object native) {
    throw 'UNREACHABLE: This case should have been rewritten in the CFE.';
  }

  @pragma('vm:recognized', 'other')
  external static Pointer<T> _addressOf<T extends NativeType>(
      Native<T> annotation);

  // Bootstrapping native for getting the FFI native C function pointer to look
  // up the FFI resolver.
  @pragma('vm:external-name', 'Ffi_GetFfiNativeResolver')
  external static Pointer<
          NativeFunction<IntPtr Function(Handle, Handle, IntPtr)>>
      _get_ffi_native_resolver<T extends NativeFunction>();

  // Resolver for FFI Native C function pointers.
  @pragma('vm:entry-point')
  static final _ffi_resolver = _get_ffi_native_resolver<
          NativeFunction<IntPtr Function(Handle, Handle, IntPtr)>>()
      .asFunction<int Function(Object, Object, int)>();

  @pragma('vm:entry-point')
  static int _ffi_resolver_function(Object a, Object s, int n) =>
      _ffi_resolver(a, s, n);
}
