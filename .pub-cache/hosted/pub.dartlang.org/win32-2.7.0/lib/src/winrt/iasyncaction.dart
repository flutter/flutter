// IAsyncAction.dart

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
const IID_IAsyncAction = '{5A648006-843A-4DA9-865B-9D26E5DFAD7B}';

typedef _put_Completed_Native = Int32 Function(Pointer obj, Pointer handler);
typedef _put_Completed_Dart = int Function(Pointer obj, Pointer handler);

typedef _get_Completed_Native = Int32 Function(
    Pointer obj, Pointer<Pointer> value);
typedef _get_Completed_Dart = int Function(Pointer obj, Pointer<Pointer> value);

typedef _GetResults_Native = Int32 Function(Pointer obj);
typedef _GetResults_Dart = int Function(Pointer obj);

/// {@category Interface}
/// {@category winrt}
mixin IAsyncAction on IAsyncInfo {
  // vtable begins at 11, ends at 13
  late final Pointer<COMObject> _thisPtr = toInterface(IID_IAsyncAction);

  set Completed(Pointer value) {
    final hr = _thisPtr.ref.lpVtbl.value
        .elementAt(11)
        .cast<Pointer<NativeFunction<_put_Completed_Native>>>()
        .value
        .asFunction<_put_Completed_Dart>()(_thisPtr.ref.lpVtbl, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  Pointer get Completed {
    final retValuePtr = calloc<Pointer>();

    try {
      final hr = _thisPtr.ref.lpVtbl.value
          .elementAt(12)
          .cast<Pointer<NativeFunction<_get_Completed_Native>>>()
          .value
          .asFunction<_get_Completed_Dart>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int GetResults() => _thisPtr.ref.lpVtbl.value
      .elementAt(13)
      .cast<Pointer<NativeFunction<_GetResults_Native>>>()
      .value
      .asFunction<_GetResults_Dart>()(_thisPtr.ref.lpVtbl);
}
