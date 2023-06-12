// ivectorview.dart

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
import '../winrt_enum.dart';
import 'iiterable.dart';
import 'iiterator.dart';

/// Represents an immutable view into a vector.
///
/// {@category Interface}
/// {@category winrt}
class IVectorView<T> extends IInspectable implements IIterable<T> {
  // vtable begins at 6, is 4 entries long.
  final T Function(Pointer<COMObject>)? _creator;
  final T Function(int)? _enumCreator;
  final Type? _intType;

  /// Creates an instance of [IVectorView] using the given [ptr].
  ///
  /// [T] must be of type `int`, `Uri`, `String`, `WinRT` (e.g. `IHostName`,
  /// `IStorageFile`) or `WinRTEnum` (e.g. `DeviceClass`).
  ///
  /// [intType] must be specified if [T] is `int`. Supported types are: [Int16],
  /// [Int32], [Int64], [Uint8], [Uint16], [Uint32], [Uint64].
  /// ```dart
  /// final vectorView = IVectorView<int>.fromRawPointer(ptr, intType: Uint64);
  /// ```
  ///
  /// [creator] must be specified if [T] is a `WinRT` type.
  /// ```dart
  /// final vectorView = IVectorView<StorageFile>.fromRawPointer(ptr,
  ///    creator: StorageFile.fromRawPointer);
  /// ```
  ///
  /// [enumCreator] and [intType] must be specified if [T] is a `WinRTEnum`.
  /// ```dart
  /// final vectorView = IVectorView<DeviceClass>.fromRawPointer(ptr,
  ///     enumCreator: DeviceClass.from, intType: Int32);
  /// ```
  IVectorView.fromRawPointer(
    super.ptr, {
    T Function(Pointer<COMObject>)? creator,
    T Function(int)? enumCreator,
    Type? intType,
  })  : _creator = creator,
        _enumCreator = enumCreator,
        _intType = intType {
    if (!isSameType<T, int>() &&
        !isSameType<T, Uri>() &&
        !isSameType<T, String>() &&
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

  /// Returns the item at the specified index in the vector view.
  T getAt(int index) {
    if (isSameType<T, int>()) return _getAt_int(index) as T;
    if (isSameType<T, Uri>()) return _getAt_Uri(index) as T;
    if (isSameType<T, String>()) return _getAt_String(index) as T;
    if (isSubtypeOfWinRTEnum<T>()) return _enumCreator!(_getAt_int(index));
    return _creator!(_getAt_COMObject(index));
  }

  Pointer<COMObject> _getAt_COMObject(int index) {
    final retValuePtr = calloc<COMObject>();

    final hr =
        ptr.ref.vtable
                .elementAt(6)
                .cast<
                    Pointer<
                        NativeFunction<
                            HRESULT Function(
                                Pointer, Uint32, Pointer<COMObject>)>>>()
                .value
                .asFunction<int Function(Pointer, int, Pointer<COMObject>)>()(
            ptr.ref.lpVtbl, index, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }

    return retValuePtr;
  }

  int _getAt_int(int index) {
    switch (_intType) {
      case Int16:
        return _getAt_Int16(index);
      case Int64:
        return _getAt_Int64(index);
      case Uint8:
        return _getAt_Uint8(index);
      case Uint16:
        return _getAt_Uint16(index);
      case Uint32:
        return _getAt_Uint32(index);
      case Uint64:
        return _getAt_Uint64(index);
      default:
        return _getAt_Int32(index);
    }
  }

  int _getAt_Int16(int index) {
    final retValuePtr = calloc<Int16>();

    try {
      final hr = ptr.ref.vtable
              .elementAt(6)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(Pointer, Uint32, Pointer<Int16>)>>>()
              .value
              .asFunction<int Function(Pointer, int, Pointer<Int16>)>()(
          ptr.ref.lpVtbl, index, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  int _getAt_Int32(int index) {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = ptr.ref.vtable
              .elementAt(6)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(Pointer, Uint32, Pointer<Int32>)>>>()
              .value
              .asFunction<int Function(Pointer, int, Pointer<Int32>)>()(
          ptr.ref.lpVtbl, index, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  int _getAt_Int64(int index) {
    final retValuePtr = calloc<Int64>();

    try {
      final hr = ptr.ref.vtable
              .elementAt(6)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(Pointer, Uint32, Pointer<Int64>)>>>()
              .value
              .asFunction<int Function(Pointer, int, Pointer<Int64>)>()(
          ptr.ref.lpVtbl, index, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  int _getAt_Uint8(int index) {
    final retValuePtr = calloc<Uint8>();

    try {
      final hr = ptr.ref.vtable
              .elementAt(6)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(Pointer, Uint32, Pointer<Uint8>)>>>()
              .value
              .asFunction<int Function(Pointer, int, Pointer<Uint8>)>()(
          ptr.ref.lpVtbl, index, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  int _getAt_Uint16(int index) {
    final retValuePtr = calloc<Uint16>();

    try {
      final hr =
          ptr.ref.vtable
                  .elementAt(6)
                  .cast<
                      Pointer<
                          NativeFunction<
                              HRESULT Function(
                                  Pointer, Uint32, Pointer<Uint16>)>>>()
                  .value
                  .asFunction<int Function(Pointer, int, Pointer<Uint16>)>()(
              ptr.ref.lpVtbl, index, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  int _getAt_Uint32(int index) {
    final retValuePtr = calloc<Uint32>();

    try {
      final hr =
          ptr.ref.vtable
                  .elementAt(6)
                  .cast<
                      Pointer<
                          NativeFunction<
                              HRESULT Function(
                                  Pointer, Uint32, Pointer<Uint32>)>>>()
                  .value
                  .asFunction<int Function(Pointer, int, Pointer<Uint32>)>()(
              ptr.ref.lpVtbl, index, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  int _getAt_Uint64(int index) {
    final retValuePtr = calloc<Uint64>();

    try {
      final hr =
          ptr.ref.vtable
                  .elementAt(6)
                  .cast<
                      Pointer<
                          NativeFunction<
                              HRESULT Function(
                                  Pointer, Uint32, Pointer<Uint64>)>>>()
                  .value
                  .asFunction<int Function(Pointer, int, Pointer<Uint64>)>()(
              ptr.ref.lpVtbl, index, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  Uri _getAt_Uri(int index) {
    final retValuePtr = calloc<COMObject>();

    try {
      final hr =
          ptr.ref.vtable
                  .elementAt(6)
                  .cast<
                      Pointer<
                          NativeFunction<
                              HRESULT Function(
                                  Pointer, Uint32, Pointer<COMObject>)>>>()
                  .value
                  .asFunction<int Function(Pointer, int, Pointer<COMObject>)>()(
              ptr.ref.lpVtbl, index, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final winrtUri = winrt_uri.Uri.fromRawPointer(retValuePtr);
      return Uri.parse(winrtUri.toString());
    } finally {
      free(retValuePtr);
    }
  }

  String _getAt_String(int index) {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr =
          ptr.ref.vtable
                  .elementAt(6)
                  .cast<
                      Pointer<
                          NativeFunction<
                              HRESULT Function(
                                  Pointer, Uint32, Pointer<HSTRING>)>>>()
                  .value
                  .asFunction<int Function(Pointer, int, Pointer<HSTRING>)>()(
              ptr.ref.lpVtbl, index, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  /// Gets the number of items in the vector view.
  int get size {
    final retValuePtr = calloc<Uint32>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(7)
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

  /// Retrieves the index of a specified item in the vector view.
  ///
  /// Does not work for `Uri` [value]s.
  bool indexOf(T value, Pointer<Uint32> index) {
    if (isSameType<T, int>()) return _indexOf_int(value as int, index);
    if (isSameType<T, Uri>()) return _indexOf_Uri(value as Uri, index);
    if (isSameType<T, String>()) return _indexOf_String(value as String, index);
    if (isSubtypeOfWinRTEnum<T>()) {
      return _indexOf_enum(value as WinRTEnum, index);
    }

    return _indexOf_COMObject(value, index);
  }

  bool _indexOf_COMObject(T value, Pointer<Uint32> index) {
    final retValuePtr = calloc<Bool>();

    try {
      final hr = ptr.ref.vtable
              .elementAt(8)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(Pointer, COMObject, Pointer<Uint32>,
                              Pointer<Bool>)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer, COMObject, Pointer<Uint32>, Pointer<Bool>)>()(
          ptr.ref.lpVtbl, (value as IInspectable).ptr.ref, index, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  bool _indexOf_enum(WinRTEnum value, Pointer<Uint32> index) {
    switch (_intType) {
      case Uint32:
        return _indexOf_Uint32(value.value, index);
      default:
        return _indexOf_Int32(value.value, index);
    }
  }

  bool _indexOf_int(int value, Pointer<Uint32> index) {
    switch (_intType) {
      case Int16:
        return _indexOf_Int16(value, index);
      case Int64:
        return _indexOf_Int64(value, index);
      case Uint8:
        return _indexOf_Uint8(value, index);
      case Uint16:
        return _indexOf_Uint16(value, index);
      case Uint32:
        return _indexOf_Uint32(value, index);
      case Uint64:
        return _indexOf_Uint64(value, index);
      default:
        return _indexOf_Int32(value, index);
    }
  }

  bool _indexOf_Int16(int value, Pointer<Uint32> index) {
    final retValuePtr = calloc<Bool>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(8)
          .cast<
              Pointer<
                  NativeFunction<
                      HRESULT Function(
                          Pointer, Int16, Pointer<Uint32>, Pointer<Bool>)>>>()
          .value
          .asFunction<
              int Function(Pointer, int, Pointer<Uint32>,
                  Pointer<Bool>)>()(ptr.ref.lpVtbl, value, index, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  bool _indexOf_Int32(int value, Pointer<Uint32> index) {
    final retValuePtr = calloc<Bool>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(8)
          .cast<
              Pointer<
                  NativeFunction<
                      HRESULT Function(
                          Pointer, Int32, Pointer<Uint32>, Pointer<Bool>)>>>()
          .value
          .asFunction<
              int Function(Pointer, int, Pointer<Uint32>,
                  Pointer<Bool>)>()(ptr.ref.lpVtbl, value, index, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  bool _indexOf_Int64(int value, Pointer<Uint32> index) {
    final retValuePtr = calloc<Bool>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(8)
          .cast<
              Pointer<
                  NativeFunction<
                      HRESULT Function(
                          Pointer, Int64, Pointer<Uint32>, Pointer<Bool>)>>>()
          .value
          .asFunction<
              int Function(Pointer, int, Pointer<Uint32>,
                  Pointer<Bool>)>()(ptr.ref.lpVtbl, value, index, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  bool _indexOf_Uint8(int value, Pointer<Uint32> index) {
    final retValuePtr = calloc<Bool>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(8)
          .cast<
              Pointer<
                  NativeFunction<
                      HRESULT Function(
                          Pointer, Uint8, Pointer<Uint32>, Pointer<Bool>)>>>()
          .value
          .asFunction<
              int Function(Pointer, int, Pointer<Uint32>,
                  Pointer<Bool>)>()(ptr.ref.lpVtbl, value, index, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  bool _indexOf_Uint16(int value, Pointer<Uint32> index) {
    final retValuePtr = calloc<Bool>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(8)
          .cast<
              Pointer<
                  NativeFunction<
                      HRESULT Function(
                          Pointer, Uint16, Pointer<Uint32>, Pointer<Bool>)>>>()
          .value
          .asFunction<
              int Function(Pointer, int, Pointer<Uint32>,
                  Pointer<Bool>)>()(ptr.ref.lpVtbl, value, index, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  bool _indexOf_Uint32(int value, Pointer<Uint32> index) {
    final retValuePtr = calloc<Bool>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(8)
          .cast<
              Pointer<
                  NativeFunction<
                      HRESULT Function(
                          Pointer, Uint32, Pointer<Uint32>, Pointer<Bool>)>>>()
          .value
          .asFunction<
              int Function(Pointer, int, Pointer<Uint32>,
                  Pointer<Bool>)>()(ptr.ref.lpVtbl, value, index, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  bool _indexOf_Uint64(int value, Pointer<Uint32> index) {
    final retValuePtr = calloc<Bool>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(8)
          .cast<
              Pointer<
                  NativeFunction<
                      HRESULT Function(
                          Pointer, Uint64, Pointer<Uint32>, Pointer<Bool>)>>>()
          .value
          .asFunction<
              int Function(Pointer, int, Pointer<Uint32>,
                  Pointer<Bool>)>()(ptr.ref.lpVtbl, value, index, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  bool _indexOf_Uri(Uri value, Pointer<Uint32> index) {
    final retValuePtr = calloc<Bool>();
    final winrtUri = winrt_uri.Uri.createUri(value.toString());

    try {
      final hr = ptr.ref.vtable
              .elementAt(8)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(Pointer, COMObject, Pointer<Uint32>,
                              Pointer<Bool>)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer, COMObject, Pointer<Uint32>, Pointer<Bool>)>()(
          ptr.ref.lpVtbl, winrtUri.ptr.ref, index, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(winrtUri.ptr);
      free(retValuePtr);
    }
  }

  bool _indexOf_String(String value, Pointer<Uint32> index) {
    final retValuePtr = calloc<Bool>();
    final hValue = convertToHString(value);

    try {
      final hr = ptr.ref.vtable
          .elementAt(8)
          .cast<
              Pointer<
                  NativeFunction<
                      HRESULT Function(
                          Pointer, Int32, Pointer<Uint32>, Pointer<Bool>)>>>()
          .value
          .asFunction<
              int Function(Pointer, int, Pointer<Uint32>,
                  Pointer<Bool>)>()(ptr.ref.lpVtbl, hValue, index, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
      WindowsDeleteString(hValue);
    }
  }

  /// Retrieves multiple items from the vector view beginning at the given
  /// index.
  int getMany(int startIndex, int capacity, Pointer<NativeType> value) {
    if (isSameType<T, int>() || isSubtypeOfWinRTEnum<T>()) {
      return _getMany_int(startIndex, capacity, value.cast());
    }

    if (isSameType<T, String>()) {
      return _getMany_String(startIndex, capacity, value.cast());
    }

    return _getMany_COMObject(startIndex, capacity, value.cast());
  }

  int _getMany_COMObject(
      int startIndex, int capacity, Pointer<COMObject> value) {
    final retValuePtr = calloc<Uint32>();

    try {
      final hr = ptr.ref.vtable
              .elementAt(9)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(Pointer, Uint32, Uint32,
                              Pointer<COMObject>, Pointer<Uint32>)>>>()
              .value
              .asFunction<
                  int Function(Pointer, int, int, Pointer<COMObject>,
                      Pointer<Uint32>)>()(
          ptr.ref.lpVtbl, startIndex, capacity, value, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  int _getMany_int(int startIndex, int capacity, Pointer<NativeType> value) {
    switch (_intType) {
      case Int16:
        return _getMany_Int16(startIndex, capacity, value.cast());
      case Int64:
        return _getMany_Int64(startIndex, capacity, value.cast());
      case Uint8:
        return _getMany_Uint8(startIndex, capacity, value.cast());
      case Uint16:
        return _getMany_Uint16(startIndex, capacity, value.cast());
      case Uint32:
        return _getMany_Uint32(startIndex, capacity, value.cast());
      case Uint64:
        return _getMany_Uint64(startIndex, capacity, value.cast());
      default:
        return _getMany_Int32(startIndex, capacity, value.cast());
    }
  }

  int _getMany_Int16(int startIndex, int capacity, Pointer<Int16> value) {
    final retValuePtr = calloc<Uint32>();

    try {
      final hr =
          ptr.ref.lpVtbl.value
                  .elementAt(9)
                  .cast<
                      Pointer<
                          NativeFunction<
                              HRESULT Function(Pointer, Uint32, Uint32,
                                  Pointer<Int16>, Pointer<Uint32>)>>>()
                  .value
                  .asFunction<
                      int Function(Pointer, int, int, Pointer<Int16>,
                          Pointer<Uint32>)>()(
              ptr.ref.lpVtbl, startIndex, capacity, value, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  int _getMany_Int32(int startIndex, int capacity, Pointer<Int32> value) {
    final retValuePtr = calloc<Uint32>();

    try {
      final hr =
          ptr.ref.lpVtbl.value
                  .elementAt(9)
                  .cast<
                      Pointer<
                          NativeFunction<
                              HRESULT Function(Pointer, Uint32, Uint32,
                                  Pointer<Int32>, Pointer<Uint32>)>>>()
                  .value
                  .asFunction<
                      int Function(Pointer, int, int, Pointer<Int32>,
                          Pointer<Uint32>)>()(
              ptr.ref.lpVtbl, startIndex, capacity, value, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  int _getMany_Int64(int startIndex, int capacity, Pointer<Int64> value) {
    final retValuePtr = calloc<Uint32>();

    try {
      final hr =
          ptr.ref.lpVtbl.value
                  .elementAt(9)
                  .cast<
                      Pointer<
                          NativeFunction<
                              HRESULT Function(Pointer, Uint32, Uint32,
                                  Pointer<Int64>, Pointer<Uint32>)>>>()
                  .value
                  .asFunction<
                      int Function(Pointer, int, int, Pointer<Int64>,
                          Pointer<Uint32>)>()(
              ptr.ref.lpVtbl, startIndex, capacity, value, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  int _getMany_Uint8(int startIndex, int capacity, Pointer<Uint8> value) {
    final retValuePtr = calloc<Uint32>();

    try {
      final hr =
          ptr.ref.lpVtbl.value
                  .elementAt(9)
                  .cast<
                      Pointer<
                          NativeFunction<
                              HRESULT Function(Pointer, Uint32, Uint32,
                                  Pointer<Uint8>, Pointer<Uint32>)>>>()
                  .value
                  .asFunction<
                      int Function(Pointer, int, int, Pointer<Uint8>,
                          Pointer<Uint32>)>()(
              ptr.ref.lpVtbl, startIndex, capacity, value, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  int _getMany_Uint16(int startIndex, int capacity, Pointer<Uint16> value) {
    final retValuePtr = calloc<Uint32>();

    try {
      final hr =
          ptr.ref.lpVtbl.value
                  .elementAt(9)
                  .cast<
                      Pointer<
                          NativeFunction<
                              HRESULT Function(Pointer, Uint32, Uint32,
                                  Pointer<Uint16>, Pointer<Uint32>)>>>()
                  .value
                  .asFunction<
                      int Function(Pointer, int, int, Pointer<Uint16>,
                          Pointer<Uint32>)>()(
              ptr.ref.lpVtbl, startIndex, capacity, value, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  int _getMany_Uint32(int startIndex, int capacity, Pointer<Uint32> value) {
    final retValuePtr = calloc<Uint32>();

    try {
      final hr =
          ptr.ref.lpVtbl.value
                  .elementAt(9)
                  .cast<
                      Pointer<
                          NativeFunction<
                              HRESULT Function(Pointer, Uint32, Uint32,
                                  Pointer<Uint32>, Pointer<Uint32>)>>>()
                  .value
                  .asFunction<
                      int Function(Pointer, int, int, Pointer<Uint32>,
                          Pointer<Uint32>)>()(
              ptr.ref.lpVtbl, startIndex, capacity, value, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  int _getMany_Uint64(int startIndex, int capacity, Pointer<Uint64> value) {
    final retValuePtr = calloc<Uint32>();

    try {
      final hr =
          ptr.ref.lpVtbl.value
                  .elementAt(9)
                  .cast<
                      Pointer<
                          NativeFunction<
                              HRESULT Function(Pointer, Uint32, Uint32,
                                  Pointer<Uint64>, Pointer<Uint32>)>>>()
                  .value
                  .asFunction<
                      int Function(Pointer, int, int, Pointer<Uint64>,
                          Pointer<Uint32>)>()(
              ptr.ref.lpVtbl, startIndex, capacity, value, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  int _getMany_String(int startIndex, int capacity, Pointer<Int32> value) {
    final retValuePtr = calloc<Uint32>();

    try {
      final hr =
          ptr.ref.vtable
                  .elementAt(9)
                  .cast<
                      Pointer<
                          NativeFunction<
                              HRESULT Function(Pointer, Uint32, Uint32,
                                  Pointer<Int32>, Pointer<Uint32>)>>>()
                  .value
                  .asFunction<
                      int Function(Pointer, int, int, Pointer<Int32>,
                          Pointer<Uint32>)>()(
              ptr.ref.lpVtbl, startIndex, capacity, value, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  /// Creates an unmodifiable [List] from the current [IVectorView] instance.
  List<T> toList() {
    if (size == 0) return List.unmodifiable(<T>[]);
    return VectorHelper(
      _creator,
      _enumCreator,
      _intType,
      getMany,
      size,
    ).toList();
  }

  late final _iIterable = IIterable<T>.fromRawPointer(
    toInterface(iterableIidFromIids(iids)),
    creator: _creator,
    enumCreator: _enumCreator,
    intType: _intType,
  );

  @override
  IIterator<T> first() => _iIterable.first();
}
