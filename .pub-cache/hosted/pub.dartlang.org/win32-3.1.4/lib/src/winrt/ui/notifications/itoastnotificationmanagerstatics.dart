// itoastnotificationmanagerstatics.dart

// ignore_for_file: unused_import
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../../com/iinspectable.dart';
import '../../../combase.dart';
import '../../../exceptions.dart';
import '../../../macros.dart';
import '../../../types.dart';
import '../../../utils.dart';
import '../../../win32/api_ms_win_core_winrt_string_l1_1_0.g.dart';
import '../../../winrt_callbacks.dart';
import '../../../winrt_helpers.dart';
import '../../data/xml/dom/xmldocument.dart';
import '../../internal/hstring_array.dart';
import 'enums.g.dart';
import 'toastnotifier.dart';

/// @nodoc
const IID_IToastNotificationManagerStatics =
    '{50ac103f-d235-4598-bbef-98fe4d1a3ad4}';

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
