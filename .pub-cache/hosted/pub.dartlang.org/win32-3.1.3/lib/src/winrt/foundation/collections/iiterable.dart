// iiterable.dart

// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../../com/iinspectable.dart';
import '../../../combase.dart';
import '../../../exceptions.dart';
import '../../../macros.dart';
import '../../../types.dart';
import '../../../utils.dart';
import '../../../winrt_helpers.dart';
import '../../internal/vector_helper.dart';
import 'iiterator.dart';

/// Exposes an iterator that supports simple iteration over a collection of a
/// specified type.
///
/// {@category Interface}
/// {@category winrt}
class IIterable<T> extends IInspectable {
  // vtable begins at 6, is 1 entries long.
  final T Function(Pointer<COMObject>)? _creator;
  final T Function(int)? _enumCreator;
  final Type? _intType;

  /// Creates an instance of [IIterable] using the given [ptr].
  ///
  /// [T] must be of type `int`, `String`, `Uri`, `WinRT` (e.g. `IHostName`,
  /// `IStorageFile`) or `WinRTEnum` (e.g. `DeviceClass`).
  ///
  /// [intType] must be specified if [T] is `int`. Supported types are: [Int16],
  /// [Int32], [Int64], [Uint8], [Uint16], [Uint32], [Uint64].
  /// ```dart
  /// final iterable = IIterable<int>.fromRawPointer(ptr, intType: Uint64);
  /// ```
  ///
  /// [creator] must be specified if [T] is a `WinRT` type.
  /// ```dart
  /// final iterable = IIterable<StorageFile>.fromRawPointer(ptr,
  ///    creator: StorageFile.fromRawPointer);
  /// ```
  ///
  /// [enumCreator] and [intType] must be specified if [T] is a `WinRTEnum`.
  /// ```dart
  /// final iterable = IIterable<DeviceClass>.fromRawPointer(ptr,
  ///     enumCreator: DeviceClass.from, intType: Int32);
  /// ```
  IIterable.fromRawPointer(
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

  /// Returns an iterator for the items in the collection.
  IIterator<T> first() {
    final retValuePtr = calloc<COMObject>();

    final hr = ptr.ref.lpVtbl.value
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

    return IIterator.fromRawPointer(
      retValuePtr,
      creator: _creator,
      enumCreator: _enumCreator,
      intType: _intType,
    );
  }
}
