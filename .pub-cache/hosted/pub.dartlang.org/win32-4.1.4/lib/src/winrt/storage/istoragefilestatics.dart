// istoragefilestatics.dart

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
import '../foundation/iasyncoperation.dart';
import '../foundation/uri.dart' as winrt_uri;
import '../internal/async_helpers.dart';
import '../internal/hstring_array.dart';
import 'storagefile.dart';

/// @nodoc
const IID_IStorageFileStatics = '{5984c710-daf2-43c8-8bb4-a4d3eacfd03f}';

/// {@category Interface}
/// {@category winrt}
class IStorageFileStatics extends IInspectable {
  // vtable begins at 6, is 6 entries long.
  IStorageFileStatics.fromRawPointer(super.ptr);

  factory IStorageFileStatics.from(IInspectable interface) =>
      IStorageFileStatics.fromRawPointer(
          interface.toInterface(IID_IStorageFileStatics));

  Future<StorageFile?> getFileFromPathAsync(String path) {
    final retValuePtr = calloc<COMObject>();
    final completer = Completer<StorageFile?>();
    final pathHstring = convertToHString(path);

    final hr = ptr.ref.vtable
            .elementAt(6)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(
                            Pointer, IntPtr path, Pointer<COMObject>)>>>()
            .value
            .asFunction<int Function(Pointer, int path, Pointer<COMObject>)>()(
        ptr.ref.lpVtbl, pathHstring, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }

    WindowsDeleteString(pathHstring);

    final asyncOperation = IAsyncOperation<StorageFile?>.fromRawPointer(
        retValuePtr,
        creator: StorageFile.fromRawPointer);
    completeAsyncOperation(
        asyncOperation, completer, asyncOperation.getResults);

    return completer.future;
  }

  Future<StorageFile?> getFileFromApplicationUriAsync(Uri uri) {
    final retValuePtr = calloc<COMObject>();
    final completer = Completer<StorageFile?>();
    final uriUri = winrt_uri.Uri.createUri(uri.toString());

    final hr = ptr.ref.vtable
            .elementAt(7)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<COMObject> uri,
                            Pointer<COMObject>)>>>()
            .value
            .asFunction<
                int Function(
                    Pointer, Pointer<COMObject> uri, Pointer<COMObject>)>()(
        ptr.ref.lpVtbl,
        uriUri.ptr.cast<Pointer<COMObject>>().value,
        retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }

    uriUri.release();

    final asyncOperation = IAsyncOperation<StorageFile?>.fromRawPointer(
        retValuePtr,
        creator: StorageFile.fromRawPointer);
    completeAsyncOperation(
        asyncOperation, completer, asyncOperation.getResults);

    return completer.future;
  }
}
