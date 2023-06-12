// iasyncaction.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import, directives_ordering
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../win32/api_ms_win_core_winrt_string_l1_1_0.g.dart';
import '../../combase.dart';
import '../../exceptions.dart';
import '../../macros.dart';
import '../../utils.dart';
import '../../types.dart';
import '../../winrt_callbacks.dart';
import '../../winrt_helpers.dart';

import '../../winrt/internal/hstring_array.dart';

import '../../winrt/foundation/iasyncinfo.dart';
import '../../com/iinspectable.dart';
import 'enums.g.dart';

/// @nodoc
const IID_IAsyncAction = '{5A648006-843A-4DA9-865B-9D26E5DFAD7B}';

/// {@category Interface}
/// {@category winrt}
class IAsyncAction extends IInspectable implements IAsyncInfo {
  // vtable begins at 6, is 3 entries long.
  IAsyncAction.fromRawPointer(super.ptr);

  factory IAsyncAction.from(IInspectable interface) =>
      IAsyncAction.fromRawPointer(interface.toInterface(IID_IAsyncAction));

  set Completed(Pointer<NativeFunction<AsyncActionCompletedHandler>> value) {
    final hr =
        ptr.ref.vtable
                .elementAt(6)
                .cast<
                    Pointer<
                        NativeFunction<
                            HRESULT Function(
                                Pointer,
                                Pointer<
                                    NativeFunction<
                                        AsyncActionCompletedHandler>>)>>>()
                .value
                .asFunction<
                    int Function(
                        Pointer,
                        Pointer<
                            NativeFunction<AsyncActionCompletedHandler>>)>()(
            ptr.ref.lpVtbl, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  Pointer<NativeFunction<AsyncActionCompletedHandler>> get Completed {
    final retValuePtr =
        calloc<Pointer<NativeFunction<AsyncActionCompletedHandler>>>();

    try {
      final hr = ptr.ref.vtable
              .elementAt(7)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(
                              Pointer,
                              Pointer<
                                  Pointer<
                                      NativeFunction<
                                          AsyncActionCompletedHandler>>>)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<
                          Pointer<
                              NativeFunction<AsyncActionCompletedHandler>>>)>()(
          ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  void GetResults() {
    final hr = ptr.ref.vtable
        .elementAt(8)
        .cast<Pointer<NativeFunction<HRESULT Function(Pointer)>>>()
        .value
        .asFunction<int Function(Pointer)>()(ptr.ref.lpVtbl);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  // IAsyncInfo methods
  late final _iAsyncInfo =
      IAsyncInfo.fromRawPointer(toInterface(IID_IAsyncInfo));

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
