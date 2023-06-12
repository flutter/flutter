// itoastnotificationmanagerstatics.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import, directives_ordering
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../../win32/api_ms_win_core_winrt_string_l1_1_0.g.dart';

import '../../../combase.dart';
import '../../../exceptions.dart';
import '../../../macros.dart';
import '../../../utils.dart';
import '../../../types.dart';
import '../../../winrt_callbacks.dart';
import '../../../winrt_helpers.dart';

import '../../internal/hstring_array.dart';

import 'toastnotifier.dart';
import 'enums.g.dart';
import '../../data/xml/dom/xmldocument.dart';
import '../../../com/iinspectable.dart';

/// @nodoc
const IID_IToastNotificationManagerStatics =
    '{50AC103F-D235-4598-BBEF-98FE4D1A3AD4}';

/// {@category Interface}
/// {@category winrt}
class IToastNotificationManagerStatics extends IInspectable {
  // vtable begins at 6, is 3 entries long.
  IToastNotificationManagerStatics.fromRawPointer(super.ptr);

  factory IToastNotificationManagerStatics.from(IInspectable interface) =>
      IToastNotificationManagerStatics.fromRawPointer(
          interface.toInterface(IID_IToastNotificationManagerStatics));

  Pointer<COMObject> createToastNotifier() {
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

  Pointer<COMObject> createToastNotifierWithId(String applicationId) {
    final retValuePtr = calloc<COMObject>();
    final applicationIdHstring = convertToHString(applicationId);
    final hr = ptr.ref.vtable
            .elementAt(7)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, IntPtr applicationId,
                            Pointer<COMObject>)>>>()
            .value
            .asFunction<
                int Function(Pointer, int applicationId, Pointer<COMObject>)>()(
        ptr.ref.lpVtbl, applicationIdHstring, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }
    WindowsDeleteString(applicationIdHstring);
    return retValuePtr;
  }

  Pointer<COMObject> getTemplateContent(ToastTemplateType type) {
    final retValuePtr = calloc<COMObject>();

    final hr = ptr.ref.vtable
            .elementAt(8)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(
                            Pointer, Int32 type, Pointer<COMObject>)>>>()
            .value
            .asFunction<int Function(Pointer, int type, Pointer<COMObject>)>()(
        ptr.ref.lpVtbl, type.value, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }

    return retValuePtr;
  }
}
