// iasyncoperation.dart

// ignore_for_file: non_constant_identifier_names

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../../win32.dart';
import '../../winrt_callbacks.dart';
import '../../winrt_helpers.dart';
import 'enums.g.dart';
import 'iasyncinfo.dart';
import 'uri.dart' as winrt_uri;

/// Represents an asynchronous operation, which returns a result upon
/// completion. This is the return type for many Windows Runtime asynchronous
/// methods that have results but don't report progress.
///
/// {@category Interface}
/// {@category winrt}
class IAsyncOperation<TResult> extends IInspectable implements IAsyncInfo {
  // vtable begins at 6, is 3 entries long.
  final TResult Function(Pointer<COMObject>)? _creator;
  final TResult Function(int)? _enumCreator;
  final Type? _intType;

  /// Creates an instance of `IAsyncOperation<TResult>` using the given `ptr`.
  ///
  /// [TResult] must be of type `bool`, `Guid`, `int`, `String`, `Uri`, `WinRT`
  /// (e.g. `IBuffer`, `StorageFile`) or `WinRTEnum` (e.g. `LaunchUriStatus`).
  ///
  /// [intType] must be specified if [TResult] is `int`. Supported types are:
  /// [Int32], [Int64], [Uint32], [Uint64].
  /// ```dart
  /// final asyncOperation = IAsyncOperation<int>.fromRawPointer(ptr,
  ///     intType: Uint64);
  /// ```
  ///
  /// [creator] must be specified if [TResult] is a `WinRT` type.
  /// ```dart
  /// ...
  /// final asyncOperation = IAsyncOperation<StorageFile?>(ptr,
  ///     creator: StorageFile.fromRawPointer);
  /// ```
  ///
  /// [enumCreator] and [intType] must be specified if [TResult] is a
  /// `WinRTEnum`.
  /// ```dart
  /// final asyncOperation = IAsyncOperation<LaunchUriStatus>.fromRawPointer
  ///     (ptr, enumCreator: LaunchUriStatus.from, intType: Int32);
  /// ```
  IAsyncOperation.fromRawPointer(
    super.ptr, {
    TResult Function(Pointer<COMObject>)? creator,
    TResult Function(int)? enumCreator,
    Type? intType,
  })  : _creator = creator,
        _enumCreator = enumCreator,
        _intType = intType {
    if (!isSameType<TResult, bool>() &&
        !isSameType<TResult, Guid>() &&
        !isSameType<TResult, int>() &&
        !isSameType<TResult, String>() &&
        !isSameType<TResult, Uri?>() &&
        !isSubtypeOfInspectable<TResult>() &&
        !isSubtypeOfWinRTEnum<TResult>()) {
      throw ArgumentError.value(TResult, 'TResult', 'Unsupported type');
    }

    if (isSameType<TResult, int>() && intType == null) {
      throw ArgumentError.notNull('intType');
    }

    if (isSubtypeOfInspectable<TResult>() && creator == null) {
      throw ArgumentError.notNull('creator');
    }

    if (isSubtypeOfWinRTEnum<TResult>()) {
      if (enumCreator == null) throw ArgumentError.notNull('enumCreator');
      if (intType == null) throw ArgumentError.notNull('intType');
    }

    if (intType != null && ![Int32, Int64, Uint32, Uint64].contains(intType)) {
      throw ArgumentError.value(intType, 'intType', 'Unsupported type');
    }
  }

  set completed(Pointer<NativeFunction<AsyncOperationCompletedHandler>> value) {
    final hr = ptr.ref.lpVtbl.value
        .elementAt(6)
        .cast<Pointer<NativeFunction<HRESULT Function(Pointer, Pointer)>>>()
        .value
        .asFunction<int Function(Pointer, Pointer)>()(ptr.ref.lpVtbl, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  Pointer<NativeFunction<AsyncOperationCompletedHandler>> get completed {
    final retValuePtr =
        calloc<Pointer<NativeFunction<AsyncOperationCompletedHandler>>>();

    try {
      final hr = ptr.ref.lpVtbl.value
          .elementAt(7)
          .cast<Pointer<NativeFunction<HRESULT Function(Pointer, Pointer)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  TResult getResults() {
    if (isSameType<TResult, bool>()) return _getResults_bool() as TResult;
    if (isSameType<TResult, Guid>()) return _getResults_Guid() as TResult;
    if (isSameType<TResult, int>()) return _getResults_int() as TResult;
    if (isSameType<TResult, String>()) return _getResults_String() as TResult;
    if (isSameType<TResult, Uri?>()) return _getResults_Uri() as TResult;
    if (isSubtypeOfWinRTEnum<TResult>()) {
      return _enumCreator!(_getResults_int());
    }

    final retValuePtr = _getResults_COMObject();
    return retValuePtr == null ? null as TResult : _creator!(retValuePtr);
  }

  bool _getResults_bool() {
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

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  Pointer<COMObject>? _getResults_COMObject() {
    final retValuePtr = calloc<COMObject>();

    final hr = ptr.ref.lpVtbl.value
            .elementAt(8)
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

    if (retValuePtr.ref.lpVtbl == nullptr) {
      free(retValuePtr);
      return null;
    }

    return retValuePtr;
  }

  Guid _getResults_Guid() {
    final retValuePtr = calloc<GUID>();

    try {
      final hr = ptr.ref.lpVtbl.value
          .elementAt(8)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<GUID>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<GUID>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.toDartGuid();
    } finally {
      free(retValuePtr);
    }
  }

  int _getResults_int() {
    switch (_intType) {
      case Int64:
        return _getResults_Int64();
      case Uint32:
        return _getResults_Uint32();
      case Uint64:
        return _getResults_Uint64();
      default:
        return _getResults_Int32();
    }
  }

  int _getResults_Int32() {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = ptr.ref.lpVtbl.value
          .elementAt(8)
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

  int _getResults_Int64() {
    final retValuePtr = calloc<Int64>();

    try {
      final hr = ptr.ref.lpVtbl.value
          .elementAt(8)
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

  int _getResults_Uint32() {
    final retValuePtr = calloc<Uint32>();

    try {
      final hr = ptr.ref.lpVtbl.value
          .elementAt(8)
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

  int _getResults_Uint64() {
    final retValuePtr = calloc<Uint64>();

    try {
      final hr = ptr.ref.lpVtbl.value
          .elementAt(8)
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

  String _getResults_String() {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = ptr.ref.lpVtbl.value
              .elementAt(8)
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

  Uri? _getResults_Uri() {
    final retValuePtr = calloc<COMObject>();

    final hr = ptr.ref.lpVtbl.value
            .elementAt(8)
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

    if (retValuePtr.ref.lpVtbl == nullptr) {
      free(retValuePtr);
      return null;
    }

    final winrtUri = winrt_uri.Uri.fromRawPointer(retValuePtr);
    final uriAsString = winrtUri.toString();
    winrtUri.release();

    return Uri.parse(uriAsString);
  }

  // IAsyncInfo methods
  late final _iAsyncInfo = IAsyncInfo.from(this);

  @override
  int get id => _iAsyncInfo.id;

  @override
  AsyncStatus get status => _iAsyncInfo.status;

  @override
  int get errorCode => _iAsyncInfo.errorCode;

  @override
  void cancel() => _iAsyncInfo.cancel();

  @override
  void close() => _iAsyncInfo.close();
}
