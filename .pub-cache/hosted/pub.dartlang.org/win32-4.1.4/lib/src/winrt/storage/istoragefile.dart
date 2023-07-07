// istoragefile.dart

// ignore_for_file: unused_import
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:async';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../com/iinspectable.dart';
import '../../combase.dart';
import '../../exceptions.dart';
import '../../macros.dart';
import '../../types.dart';
import '../../utils.dart';
import '../../win32/api_ms_win_core_winrt_string_l1_1_0.g.dart';
import '../../winrt_callbacks.dart';
import '../../winrt_helpers.dart';
import '../foundation/iasyncaction.dart';
import '../foundation/iasyncoperation.dart';
import '../internal/async_helpers.dart';
import '../internal/hstring_array.dart';
import 'enums.g.dart';
import 'fileproperties/basicproperties.dart';
import 'istorageitem.dart';
import 'storagefile.dart';

/// @nodoc
const IID_IStorageFile = '{fa3f6186-4214-428c-a64c-14c9ac7315ea}';

/// {@category Interface}
/// {@category winrt}
class IStorageFile extends IInspectable implements IStorageItem {
  // vtable begins at 6, is 12 entries long.
  IStorageFile.fromRawPointer(super.ptr);

  factory IStorageFile.from(IInspectable interface) =>
      IStorageFile.fromRawPointer(interface.toInterface(IID_IStorageFile));

  String get fileType {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<IntPtr>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<IntPtr>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  String get contentType {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(7)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<IntPtr>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<IntPtr>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  Future<void> copyAndReplaceAsync(IStorageFile fileToReplace) {
    final retValuePtr = calloc<COMObject>();
    final completer = Completer<void>();

    final hr =
        ptr.ref.vtable
                .elementAt(13)
                .cast<
                    Pointer<
                        NativeFunction<
                            HRESULT Function(
                                Pointer,
                                Pointer<COMObject> fileToReplace,
                                Pointer<COMObject>)>>>()
                .value
                .asFunction<
                    int Function(Pointer, Pointer<COMObject> fileToReplace,
                        Pointer<COMObject>)>()(ptr.ref.lpVtbl,
            fileToReplace.ptr.cast<Pointer<COMObject>>().value, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }

    final asyncAction = IAsyncAction.fromRawPointer(retValuePtr);
    completeAsyncAction(asyncAction, completer);

    return completer.future;
  }

  Future<void> moveAndReplaceAsync(IStorageFile fileToReplace) {
    final retValuePtr = calloc<COMObject>();
    final completer = Completer<void>();

    final hr =
        ptr.ref.vtable
                .elementAt(17)
                .cast<
                    Pointer<
                        NativeFunction<
                            HRESULT Function(
                                Pointer,
                                Pointer<COMObject> fileToReplace,
                                Pointer<COMObject>)>>>()
                .value
                .asFunction<
                    int Function(Pointer, Pointer<COMObject> fileToReplace,
                        Pointer<COMObject>)>()(ptr.ref.lpVtbl,
            fileToReplace.ptr.cast<Pointer<COMObject>>().value, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }

    final asyncAction = IAsyncAction.fromRawPointer(retValuePtr);
    completeAsyncAction(asyncAction, completer);

    return completer.future;
  }

  // IStorageItem methods
  late final _iStorageItem = IStorageItem.from(this);

  @override
  Future<void> renameAsyncOverloadDefaultOptions(String desiredName) =>
      _iStorageItem.renameAsyncOverloadDefaultOptions(desiredName);

  @override
  Future<void> renameAsync(String desiredName, NameCollisionOption option) =>
      _iStorageItem.renameAsync(desiredName, option);

  @override
  Future<void> deleteAsyncOverloadDefaultOptions() =>
      _iStorageItem.deleteAsyncOverloadDefaultOptions();

  @override
  Future<void> deleteAsync(StorageDeleteOption option) =>
      _iStorageItem.deleteAsync(option);

  @override
  Future<BasicProperties?> getBasicPropertiesAsync() =>
      _iStorageItem.getBasicPropertiesAsync();

  @override
  String get name => _iStorageItem.name;

  @override
  String get path => _iStorageItem.path;

  @override
  FileAttributes get attributes => _iStorageItem.attributes;

  @override
  DateTime get dateCreated => _iStorageItem.dateCreated;

  @override
  bool isOfType(StorageItemTypes type) => _iStorageItem.isOfType(type);
}
