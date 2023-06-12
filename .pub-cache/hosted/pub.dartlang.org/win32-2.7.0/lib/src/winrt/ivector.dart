// IVector.dart

// ignore_for_file: unused_import, directives_ordering
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../api_ms_win_core_winrt_string_l1_1_0.dart';
import '../callbacks.dart';
import '../combase.dart';
import '../constants.dart';
import '../exceptions.dart';
import '../extensions/comobject_pointer.dart';
import '../guid.dart';
import '../macros.dart';
import '../ole32.dart';
import '../structs.dart';
import '../structs.g.dart';
import '../types.dart';
import '../utils.dart';
import '../winrt/internal/winrt_vector_helper.dart';
import '../winrt_helpers.dart';
import '../com/iinspectable.dart';
import 'ivectorview.dart';

/// @nodoc
const IID_IVector = '{913337E9-11A1-4345-A3A2-4E7F956E222D}';

/// {@category Interface}
/// {@category winrt}
class IVector<T> extends IInspectable {
  T Function(Pointer<COMObject>)? creator;
  final Allocator allocator;

  // vtable begins at 6, is 12 entries long.
  /// Creates an instance of `IVector<T>` using the given `ptr`.
  ///
  /// `T` must be a either a `String` or a `WinRT` type. e.g. `IHostName`,
  /// `IStorageFile` etc.
  ///
  /// ```dart
  /// ...
  /// final vector = IVector<String>(ptr);
  /// ```
  ///
  /// `creator` must be specified if the `T` is a `WinRT` type.
  /// e.g. `IHostName.new`, `IStorageFile.new` etc.
  ///
  /// ```dart
  /// ...
  /// final allocator = Arena();
  /// final vector =
  ///     IVector<IHostName>(ptr, creator: IHostName.new, allocator: allocator);
  /// ```
  ///
  /// It is the caller's responsibility to deallocate the returned pointers
  /// from methods like `GetAt`, `GetView` and `toList` when they are finished
  /// with it. A FFI `Arena` may be passed as a  custom allocator for ease of
  /// memory management.
  ///
  /// {@category winrt}
  IVector(super.ptr, {this.creator, this.allocator = calloc}) {
    // TODO: Need to update this once we add support for types like `int`,
    // `bool`, `double`, `GUID`, `DateTime`, `Point`, `Size` etc.
    if (![String].contains(T) && creator == null) {
      throw ArgumentError(
          '`creator` parameter must be specified for WinRT types!');
    }
  }

  T GetAt(int index) {
    switch (T) {
      // TODO: Need to update this once we add support for types like `int`,
      // `bool`, `double`, `GUID`, `DateTime`, `Point`, `Size` etc.
      case String:
        return _GetAt_String(index) as T;
      // Handle WinRT types
      default:
        return creator!(_GetAt_COMObject(index));
    }
  }

  Pointer<COMObject> _GetAt_COMObject(int index) {
    final retValuePtr = allocator<COMObject>();

    final hr = ptr.ref.vtable
        .elementAt(6)
        .cast<
            Pointer<
                NativeFunction<
                    HRESULT Function(
          Pointer,
          Uint32,
          Pointer<COMObject>,
        )>>>()
        .value
        .asFunction<
            int Function(
          Pointer,
          int,
          Pointer<COMObject>,
        )>()(ptr.ref.lpVtbl, index, retValuePtr);

    if (FAILED(hr)) throw WindowsException(hr);

    return retValuePtr;
  }

  String _GetAt_String(int index) {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<
                      HRESULT Function(
            Pointer,
            Uint32,
            Pointer<HSTRING>,
          )>>>()
          .value
          .asFunction<
              int Function(
            Pointer,
            int,
            Pointer<HSTRING>,
          )>()(ptr.ref.lpVtbl, index, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  int get Size {
    final retValuePtr = calloc<Uint32>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(7)
          .cast<
              Pointer<
                  NativeFunction<
                      HRESULT Function(
            Pointer,
            Pointer<Uint32>,
          )>>>()
          .value
          .asFunction<
              int Function(
            Pointer,
            Pointer<Uint32>,
          )>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  List<T> get GetView {
    final retValuePtr = allocator<COMObject>();

    final hr = ptr.ref.vtable
        .elementAt(8)
        .cast<
            Pointer<
                NativeFunction<
                    HRESULT Function(
          Pointer,
          Pointer<COMObject>,
        )>>>()
        .value
        .asFunction<
            int Function(
          Pointer,
          Pointer<COMObject>,
        )>()(ptr.ref.lpVtbl, retValuePtr);

    if (FAILED(hr)) throw WindowsException(hr);

    return IVectorView(retValuePtr, creator: creator, allocator: allocator)
        .toList();
  }

  bool IndexOf(T value, Pointer<Uint32> index) {
    switch (T) {
      // TODO: Need to update this once we add support for types like `int`,
      // `bool`, `double`, `GUID`, `DateTime`, `Point`, `Size` etc.
      case String:
        return _IndexOf_String(value as String, index);
      // Handle WinRT types
      default:
        return _IndexOf_COMObject(value, index);
    }
  }

  bool _IndexOf_COMObject(T value, Pointer<Uint32> index) {
    final retValuePtr = calloc<Bool>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(9)
          .cast<
              Pointer<
                  NativeFunction<
                      HRESULT Function(
            Pointer,
            COMObject,
            Pointer<Uint32>,
            Pointer<Bool>,
          )>>>()
          .value
          .asFunction<
              int Function(
            Pointer,
            COMObject,
            Pointer<Uint32>,
            Pointer<Bool>,
          )>()(
        ptr.ref.lpVtbl,
        (value as IInspectable).ptr.ref,
        index,
        retValuePtr,
      );

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  bool _IndexOf_String(String value, Pointer<Uint32> index) {
    final retValuePtr = calloc<Bool>();
    final hValue = convertToHString(value);

    try {
      final hr = ptr.ref.vtable
          .elementAt(9)
          .cast<
              Pointer<
                  NativeFunction<
                      HRESULT Function(
            Pointer,
            HSTRING,
            Pointer<Uint32>,
            Pointer<Bool>,
          )>>>()
          .value
          .asFunction<
              int Function(
            Pointer,
            int,
            Pointer<Uint32>,
            Pointer<Bool>,
          )>()(ptr.ref.lpVtbl, hValue, index, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
      WindowsDeleteString(hValue);
    }
  }

  void SetAt(int index, T value) {
    switch (T) {
      // TODO: Need to update this once we add support for types like `int`,
      // `bool`, `double`, `GUID`, `DateTime`, `Point`, `Size` etc.
      case String:
        return _SetAt_String(index, value as String);
      // Handle WinRT types
      default:
        return _SetAt_COMObject(index, value);
    }
  }

  void _SetAt_COMObject(int index, T value) {
    final hr = ptr.ref.vtable
        .elementAt(10)
        .cast<
            Pointer<
                NativeFunction<
                    HRESULT Function(
          Pointer,
          Uint32,
          COMObject,
        )>>>()
        .value
        .asFunction<int Function(Pointer, int, COMObject)>()(
      ptr.ref.lpVtbl,
      index,
      (value as IInspectable).ptr.ref,
    );

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void _SetAt_String(int index, String value) {
    final hValue = convertToHString(value);

    try {
      final hr = ptr.ref.vtable
          .elementAt(10)
          .cast<
              Pointer<
                  NativeFunction<
                      HRESULT Function(
            Pointer,
            Uint32,
            HSTRING,
          )>>>()
          .value
          .asFunction<
              int Function(
            Pointer,
            int,
            int,
          )>()(
        ptr.ref.lpVtbl,
        index,
        hValue,
      );

      if (FAILED(hr)) throw WindowsException(hr);
    } finally {
      WindowsDeleteString(hValue);
    }
  }

  void InsertAt(int index, T value) {
    switch (T) {
      // TODO: Need to update this once we add support for types like `int`,
      // `bool`, `double`, `GUID`, `DateTime`, `Point`, `Size` etc.
      case String:
        return _InsertAt_String(index, value as String);
      // Handle WinRT types
      default:
        return _InsertAt_COMObject(index, value);
    }
  }

  void _InsertAt_COMObject(int index, T value) {
    final hr = ptr.ref.vtable
        .elementAt(11)
        .cast<
            Pointer<
                NativeFunction<
                    HRESULT Function(
          Pointer,
          Uint32,
          COMObject,
        )>>>()
        .value
        .asFunction<int Function(Pointer, int, COMObject)>()(
      ptr.ref.lpVtbl,
      index,
      (value as IInspectable).ptr.ref,
    );

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void _InsertAt_String(int index, String value) {
    final hValue = convertToHString(value);

    try {
      final hr = ptr.ref.vtable
          .elementAt(11)
          .cast<
              Pointer<
                  NativeFunction<
                      HRESULT Function(
            Pointer,
            Uint32,
            HSTRING,
          )>>>()
          .value
          .asFunction<int Function(Pointer, int, int)>()(
        ptr.ref.lpVtbl,
        index,
        hValue,
      );

      if (FAILED(hr)) throw WindowsException(hr);
    } finally {
      WindowsDeleteString(hValue);
    }
  }

  void RemoveAt(int index) {
    final hr = ptr.ref.vtable
        .elementAt(12)
        .cast<
            Pointer<
                NativeFunction<
                    HRESULT Function(
          Pointer,
          Uint32,
        )>>>()
        .value
        .asFunction<int Function(Pointer, int)>()(
      ptr.ref.lpVtbl,
      index,
    );

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void Append(T value) {
    switch (T) {
      // TODO: Need to update this once we add support for types like `int`,
      // `bool`, `double`, `GUID`, `DateTime`, `Point`, `Size` etc.
      case String:
        return _Append_String(value as String);
      // Handle WinRT types
      default:
        return _Append_COMObject(value);
    }
  }

  void _Append_COMObject(T value) {
    final hr = ptr.ref.vtable
            .elementAt(13)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(
              Pointer,
              COMObject,
            )>>>()
            .value
            .asFunction<int Function(Pointer, COMObject)>()(
        ptr.ref.lpVtbl, (value as IInspectable).ptr.ref);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void _Append_String(String value) {
    final hValue = convertToHString(value);

    try {
      final hr = ptr.ref.vtable
          .elementAt(13)
          .cast<
              Pointer<
                  NativeFunction<
                      HRESULT Function(
            Pointer,
            HSTRING,
          )>>>()
          .value
          .asFunction<int Function(Pointer, int)>()(ptr.ref.lpVtbl, hValue);

      if (FAILED(hr)) throw WindowsException(hr);
    } finally {
      WindowsDeleteString(hValue);
    }
  }

  void RemoveAtEnd() {
    final hr = ptr.ref.vtable
        .elementAt(14)
        .cast<Pointer<NativeFunction<HRESULT Function(Pointer)>>>()
        .value
        .asFunction<int Function(Pointer)>()(ptr.ref.lpVtbl);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void Clear() {
    final hr = ptr.ref.vtable
        .elementAt(15)
        .cast<Pointer<NativeFunction<HRESULT Function(Pointer)>>>()
        .value
        .asFunction<int Function(Pointer)>()(ptr.ref.lpVtbl);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  int GetMany(int startIndex, Pointer<NativeType> items) {
    switch (T) {
      // TODO: Need to update this once we add support for types like `int`,
      // `bool`, `double`, `GUID`, `DateTime`, `Point`, `Size` etc.
      case String:
        return _GetMany_String(startIndex, items.cast());
      // Handle WinRT types
      default:
        return _GetMany_COMObject(startIndex, items.cast());
    }
  }

  int _GetMany_COMObject(int startIndex, Pointer<COMObject> items) {
    final retValuePtr = calloc<Uint32>();

    try {
      final hr = ptr.ref.vtable
              .elementAt(16)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(
                Pointer,
                Uint32,
                Uint32,
                Pointer<COMObject>,
                Pointer<Uint32>,
              )>>>()
              .value
              .asFunction<
                  int Function(
                Pointer,
                int,
                int,
                Pointer<COMObject>,
                Pointer<Uint32>,
              )>()(
          ptr.ref.lpVtbl, startIndex, Size - startIndex, items, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int _GetMany_String(int startIndex, Pointer<HSTRING> items) {
    final retValuePtr = calloc<Uint32>();

    try {
      final hr = ptr.ref.vtable
              .elementAt(16)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(
                Pointer,
                Uint32,
                Uint32,
                Pointer<HSTRING>,
                Pointer<Uint32>,
              )>>>()
              .value
              .asFunction<
                  int Function(
                Pointer,
                int,
                int,
                Pointer<HSTRING>,
                Pointer<Uint32>,
              )>()(
          ptr.ref.lpVtbl, startIndex, Size - startIndex, items, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  void ReplaceAll(List<T> items) {
    switch (T) {
      // TODO: Need to update this once we add support for types like `int`,
      // `bool`, `double`, `GUID`, `DateTime`, `Point`, `Size` etc.
      case String:
        return _ReplaceAll_String(items as List<String>);
      // Handle WinRT types
      default:
        return _ReplaceAll_COMObject(items);
    }
  }

  void _ReplaceAll_COMObject(List<T> items) {
    final pArray = calloc<COMObject>(items.length);
    for (var i = 0; i < items.length; i++) {
      final pElement = (items.elementAt(i) as IInspectable).ptr;
      pArray[i] = pElement.ref.lpVtbl;
    }

    try {
      final hr = ptr.ref.vtable
          .elementAt(17)
          .cast<
              Pointer<
                  NativeFunction<
                      HRESULT Function(
            Pointer,
            Uint32,
            Pointer<COMObject>,
          )>>>()
          .value
          .asFunction<
              int Function(
            Pointer,
            int,
            Pointer<COMObject>,
          )>()(ptr.ref.lpVtbl, items.length, pArray);

      if (FAILED(hr)) throw WindowsException(hr);
    } finally {
      free(pArray);
    }
  }

  void _ReplaceAll_String(List<String> items) {
    final handles = <int>[];
    final pArray = calloc<HSTRING>(items.length);
    for (var i = 0; i < items.length; i++) {
      pArray[i] = convertToHString(items.elementAt(i));
      handles.add(pArray[i]);
    }

    try {
      final hr = ptr.ref.vtable
          .elementAt(17)
          .cast<
              Pointer<
                  NativeFunction<
                      HRESULT Function(
            Pointer,
            Uint32,
            Pointer<HSTRING>,
          )>>>()
          .value
          .asFunction<
              int Function(
            Pointer,
            int,
            Pointer<HSTRING>,
          )>()(ptr.ref.lpVtbl, items.length, pArray);

      if (FAILED(hr)) throw WindowsException(hr);
    } finally {
      free(pArray);
      for (final handle in handles) {
        WindowsDeleteString(handle);
      }
    }
  }

  /// Creates a `List<T>` from the `IVector<T>`.
  List<T> toList() {
    if (Size == 0) {
      return <T>[];
    }

    return VectorHelper(creator, GetMany, Size, allocator: allocator).toList();
  }
}
