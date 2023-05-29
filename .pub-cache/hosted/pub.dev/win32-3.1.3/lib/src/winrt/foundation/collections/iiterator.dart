// iiterator.dart

// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../../com/iinspectable.dart';
import '../../../combase.dart';
import '../../../exceptions.dart';
import '../../../macros.dart';
import '../../../types.dart';
import '../../../utils.dart';
import '../../../win32/api_ms_win_core_winrt_string_l1_1_0.g.dart';
import '../../../winrt_helpers.dart';
import '../../internal/vector_helper.dart';
import '../uri.dart' as winrt_uri;

/// Supports simple iteration over a collection.
///
/// {@category Interface}
/// {@category winrt}
class IIterator<T> extends IInspectable {
  // vtable begins at 6, is 4 entries long.
  final T Function(Pointer<COMObject>)? _creator;
  final T Function(int)? _enumCreator;
  final Type? _intType;

  /// Creates an instance of [IIterator] using the given [ptr].
  ///
  /// [T] must be of type `int`, `String`, `Uri`, `WinRT` (e.g. `IHostName`,
  /// `IStorageFile`) or `WinRTEnum` (e.g. `DeviceClass`).
  ///
  /// [intType] must be specified if [T] is `int`. Supported types are: [Int16],
  /// [Int32], [Int64], [Uint8], [Uint16], [Uint32], [Uint64].
  /// ```dart
  /// final iterator = IIterator<int>.fromRawPointer(ptr, intType: Uint64);
  /// ```
  ///
  /// [creator] must be specified if [T] is a `WinRT` type.
  /// ```dart
  /// final iterator = IIterator<StorageFile>.fromRawPointer(ptr,
  ///    creator: StorageFile.fromRawPointer);
  /// ```
  ///
  /// [enumCreator] and [intType] must be specified if [T] is a `WinRTEnum`.
  /// ```dart
  /// final iterator = IIterator<DeviceClass>.fromRawPointer(ptr,
  ///     enumCreator: DeviceClass.from, intType: Int32);
  /// ```
  IIterator.fromRawPointer(
    super.ptr, {
    T Function(Pointer<COMObject>)? creator,
    T Function(int)? enumCreator,
    Type? intType,
  })  : _creator = creator,
        _enumCreator = enumCreator,
        _intType = intType {
    if (!isSameType<T, int>() &&
        !isSameType<T, String>() &&
        !isSameType<T, Uri>() &&
        !isSubtypeOfInspectable<T>() &&
        !isSubtypeOfWinRTEnum<T>()) {
      throw ArgumentError.value(T, 'T', 'Unsupported type');
    }

    if (isSameType<T, int>() && intType == null) {
      throw ArgumentError.notNull('intType');
    }

    if (isSubtypeOfInspectable<T>() && creator == null) {
      throw ArgumentError.notNull('creator');
    }

    if (isSubtypeOfWinRTEnum<T>()) {
      if (enumCreator == null) throw ArgumentError.notNull('enumCreator');
      if (intType == null) throw ArgumentError.notNull('intType');
    }

    if (intType != null && !supportedIntTypes.contains(intType)) {
      throw ArgumentError.value(intType, 'intType', 'Unsupported type');
    }
  }

  /// Gets the current item in the collection.
  T get current {
    if (isSameType<T, int>()) return _current_int() as T;
    if (isSameType<T, String>()) return _current_String() as T;
    if (isSameType<T, Uri>()) return _current_Uri() as T;
    if (isSubtypeOfWinRTEnum<T>()) return _enumCreator!(_current_int());
    return _creator!(_current_COMObject());
  }

  Pointer<COMObject> _current_COMObject() {
    final retValuePtr = calloc<COMObject>();

    final hr = ptr.ref.vtable
            .elementAt(6)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<COMObject>)>>>()
            .value
            .asFunction<int Function(Pointer, Pointer<COMObject>)>()(
        ptr.ref.lpVtbl, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }

    return retValuePtr;
  }

  int _current_int() {
    switch (_intType) {
      case Int16:
        return _current_Int16();
      case Int64:
        return _current_Int64();
      case Uint8:
        return _current_Uint8();
      case Uint16:
        return _current_Uint16();
      case Uint32:
        return _current_Uint32();
      case Uint64:
        return _current_Uint64();
      default:
        return _current_Int32();
    }
  }

  int _current_Int16() {
    final retValuePtr = calloc<Int16>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int16>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int16>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  int _current_Int32() {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  int _current_Int64() {
    final retValuePtr = calloc<Int64>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int64>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int64>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  int _current_Uint8() {
    final retValuePtr = calloc<Uint8>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Uint8>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Uint8>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  int _current_Uint16() {
    final retValuePtr = calloc<Uint16>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Uint16>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Uint16>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  int _current_Uint32() {
    final retValuePtr = calloc<Uint32>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Uint32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Uint32>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  int _current_Uint64() {
    final retValuePtr = calloc<Uint64>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Uint64>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Uint64>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  String _current_String() {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = ptr.ref.lpVtbl.value
              .elementAt(6)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(Pointer, Pointer<HSTRING>)>>>()
              .value
              .asFunction<int Function(Pointer, Pointer<HSTRING>)>()(
          ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  Uri _current_Uri() {
    final retValuePtr = calloc<COMObject>();

    try {
      final hr = ptr.ref.lpVtbl.value
              .elementAt(6)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(Pointer, Pointer<COMObject>)>>>()
              .value
              .asFunction<int Function(Pointer, Pointer<COMObject>)>()(
          ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final winrtUri = winrt_uri.Uri.fromRawPointer(retValuePtr);
      return Uri.parse(winrtUri.toString());
    } finally {
      free(retValuePtr);
    }
  }

  /// Gets a value that indicates whether the iterator refers to a current item
  /// or is at the end of the collection.
  bool get hasCurrent {
    final retValuePtr = calloc<Bool>();

    try {
      final hr = ptr.ref.lpVtbl.value
          .elementAt(7)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Bool>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Bool>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  /// Advances the iterator to the next item in the collection.
  bool moveNext() {
    final retValuePtr = calloc<Bool>();

    try {
      final hr = ptr.ref.lpVtbl.value
          .elementAt(8)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Bool>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Bool>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  /// Retrieves multiple items from the iterator.
  int getMany(int capacity, Pointer<NativeType> value) {
    if (isSameType<T, int>() || isSubtypeOfWinRTEnum<T>()) {
      return _getMany_int(capacity, value);
    }

    if (isSameType<T, String>()) return _getMany_String(capacity, value.cast());
    return _getMany_COMObject(capacity, value.cast());
  }

  int _getMany_COMObject(int capacity, Pointer<COMObject> value) {
    final retValuePtr = calloc<Uint32>();

    try {
      final hr = ptr.ref.vtable
              .elementAt(9)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(Pointer, Uint32, Pointer<COMObject>,
                              Pointer<Uint32>)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer, int, Pointer<COMObject>, Pointer<Uint32>)>()(
          ptr.ref.lpVtbl, capacity, value, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  int _getMany_int(int capacity, Pointer<NativeType> value) {
    switch (_intType) {
      case Int16:
        return _getMany_Int16(capacity, value.cast());
      case Int64:
        return _getMany_Int64(capacity, value.cast());
      case Uint8:
        return _getMany_Uint8(capacity, value.cast());
      case Uint16:
        return _getMany_Uint16(capacity, value.cast());
      case Uint32:
        return _getMany_Uint32(capacity, value.cast());
      case Uint64:
        return _getMany_Uint64(capacity, value.cast());
      default:
        return _getMany_Int32(capacity, value.cast());
    }
  }

  int _getMany_Int16(int capacity, Pointer<Int16> value) {
    final retValuePtr = calloc<Uint32>();

    try {
      final hr = ptr.ref.lpVtbl.value
              .elementAt(9)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(Pointer, Uint32, Pointer<Int16>,
                              Pointer<Uint32>)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer, int, Pointer<Int16>, Pointer<Uint32>)>()(
          ptr.ref.lpVtbl, capacity, value, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  int _getMany_Int32(int capacity, Pointer<Int32> value) {
    final retValuePtr = calloc<Uint32>();

    try {
      final hr = ptr.ref.lpVtbl.value
              .elementAt(9)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(Pointer, Uint32, Pointer<Int32>,
                              Pointer<Uint32>)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer, int, Pointer<Int32>, Pointer<Uint32>)>()(
          ptr.ref.lpVtbl, capacity, value, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  int _getMany_Int64(int capacity, Pointer<Int64> value) {
    final retValuePtr = calloc<Uint32>();

    try {
      final hr = ptr.ref.lpVtbl.value
              .elementAt(9)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(Pointer, Uint32, Pointer<Int64>,
                              Pointer<Uint32>)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer, int, Pointer<Int64>, Pointer<Uint32>)>()(
          ptr.ref.lpVtbl, capacity, value, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  int _getMany_Uint8(int capacity, Pointer<Uint8> value) {
    final retValuePtr = calloc<Uint32>();

    try {
      final hr = ptr.ref.lpVtbl.value
              .elementAt(9)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(Pointer, Uint32, Pointer<Uint8>,
                              Pointer<Uint32>)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer, int, Pointer<Uint8>, Pointer<Uint32>)>()(
          ptr.ref.lpVtbl, capacity, value, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  int _getMany_Uint16(int capacity, Pointer<Uint16> value) {
    final retValuePtr = calloc<Uint32>();

    try {
      final hr = ptr.ref.lpVtbl.value
              .elementAt(9)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(Pointer, Uint32, Pointer<Uint16>,
                              Pointer<Uint32>)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer, int, Pointer<Uint16>, Pointer<Uint32>)>()(
          ptr.ref.lpVtbl, capacity, value, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  int _getMany_Uint32(int capacity, Pointer<Uint32> value) {
    final retValuePtr = calloc<Uint32>();

    try {
      final hr = ptr.ref.lpVtbl.value
              .elementAt(9)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(Pointer, Uint32, Pointer<Uint32>,
                              Pointer<Uint32>)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer, int, Pointer<Uint32>, Pointer<Uint32>)>()(
          ptr.ref.lpVtbl, capacity, value, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  int _getMany_Uint64(int capacity, Pointer<Uint64> value) {
    final retValuePtr = calloc<Uint32>();

    try {
      final hr = ptr.ref.lpVtbl.value
              .elementAt(9)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(Pointer, Uint32, Pointer<Uint64>,
                              Pointer<Uint32>)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer, int, Pointer<Uint64>, Pointer<Uint32>)>()(
          ptr.ref.lpVtbl, capacity, value, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  int _getMany_String(int capacity, Pointer<HSTRING> value) {
    final retValuePtr = calloc<Uint32>();

    try {
      final hr = ptr.ref.lpVtbl.value
              .elementAt(9)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(Pointer, Uint32, Pointer<HSTRING>,
                              Pointer<Uint32>)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer, int, Pointer<HSTRING>, Pointer<Uint32>)>()(
          ptr.ref.lpVtbl, capacity, value, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }
}
