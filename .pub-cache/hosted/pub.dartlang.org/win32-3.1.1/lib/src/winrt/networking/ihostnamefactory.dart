// ihostnamefactory.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import, directives_ordering
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../combase.dart';
import '../../exceptions.dart';
import '../../macros.dart';
import '../../utils.dart';
import '../../types.dart';
import '../../win32/api_ms_win_core_winrt_string_l1_1_0.g.dart';
import '../../winrt_callbacks.dart';
import '../../winrt_helpers.dart';

import '../internal/hstring_array.dart';

import 'hostname.dart';
import '../../com/iinspectable.dart';

/// @nodoc
const IID_IHostNameFactory = '{458C23ED-712F-4576-ADF1-C20B2C643558}';

/// {@category Interface}
/// {@category winrt}
class IHostNameFactory extends IInspectable {
  // vtable begins at 6, is 1 entries long.
  IHostNameFactory.fromRawPointer(super.ptr);

  factory IHostNameFactory.from(IInspectable interface) =>
      IHostNameFactory.fromRawPointer(
          interface.toInterface(IID_IHostNameFactory));

  HostName createHostName(String hostName) {
    final retValuePtr = calloc<COMObject>();
    final hostNameHstring = convertToHString(hostName);
    final hr = ptr.ref.vtable
            .elementAt(6)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(
                            Pointer, IntPtr hostName, Pointer<COMObject>)>>>()
            .value
            .asFunction<
                int Function(Pointer, int hostName, Pointer<COMObject>)>()(
        ptr.ref.lpVtbl, hostNameHstring, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }
    WindowsDeleteString(hostNameHstring);
    return HostName.fromRawPointer(retValuePtr);
  }
}
