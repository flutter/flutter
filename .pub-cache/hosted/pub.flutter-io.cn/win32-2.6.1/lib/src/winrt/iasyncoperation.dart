// IAsyncOperation.dart

// ignore_for_file: unused_import, directives_ordering, camel_case_types
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../combase.dart';
import '../constants.dart';
import '../exceptions.dart';
import '../macros.dart';
import '../ole32.dart';
import '../structs.dart';
import '../structs.g.dart';
import '../utils.dart';

import '../winrt_constants.dart';

import 'iasyncinfo.dart';

/// @nodoc
const IID_IAsyncOperation = '{9FC2B0BB-E446-44E2-AA61-9CAB8F636AF2}';

typedef _put_Completed_Native = Int32 Function(Pointer obj, Pointer handler);
typedef _put_Completed_Dart = int Function(Pointer obj, Pointer handler);

typedef _get_Completed_Native = Int32 Function(
    Pointer obj, Pointer<Pointer> value);
typedef _get_Completed_Dart = int Function(Pointer obj, Pointer<Pointer> value);

typedef _GetResults_Native = Int32 Function(
    Pointer obj, Pointer<Pointer> result);
typedef _GetResults_Dart = int Function(Pointer obj, Pointer<Pointer> result);

/// {@category Interface}
/// {@category winrt}
class IAsyncOperation<TResult> extends IAsyncInfo {
  // vtable begins at 11, ends at 13

  IAsyncOperation(Pointer<COMObject> ptr) : super(ptr);

  set Completed(Pointer value) {
    final hr = ptr.ref.lpVtbl.value
        .elementAt(11)
        .cast<Pointer<NativeFunction<_put_Completed_Native>>>()
        .value
        .asFunction<_put_Completed_Dart>()(ptr.ref.lpVtbl, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  Pointer get Completed {
    final retValuePtr = calloc<Pointer>();

    try {
      final hr = ptr.ref.lpVtbl.value
          .elementAt(12)
          .cast<Pointer<NativeFunction<_get_Completed_Native>>>()
          .value
          .asFunction<_get_Completed_Dart>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int GetResults(Pointer<Pointer> result) => ptr.ref.lpVtbl.value
      .elementAt(13)
      .cast<Pointer<NativeFunction<_GetResults_Native>>>()
      .value
      .asFunction<_GetResults_Dart>()(ptr.ref.lpVtbl, result);
}
