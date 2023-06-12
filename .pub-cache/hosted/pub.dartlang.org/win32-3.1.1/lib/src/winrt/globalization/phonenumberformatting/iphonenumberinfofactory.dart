// iphonenumberinfofactory.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import, directives_ordering
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../../combase.dart';
import '../../../exceptions.dart';
import '../../../macros.dart';
import '../../../utils.dart';
import '../../../types.dart';
import '../../../win32/api_ms_win_core_winrt_string_l1_1_0.g.dart';
import '../../../winrt_callbacks.dart';
import '../../../winrt_helpers.dart';

import '../../internal/hstring_array.dart';

import 'phonenumberinfo.dart';
import '../../../com/iinspectable.dart';

/// @nodoc
const IID_IPhoneNumberInfoFactory = '{8202B964-ADAA-4CFF-8FCF-17E7516A28FF}';

/// {@category Interface}
/// {@category winrt}
class IPhoneNumberInfoFactory extends IInspectable {
  // vtable begins at 6, is 1 entries long.
  IPhoneNumberInfoFactory.fromRawPointer(super.ptr);

  factory IPhoneNumberInfoFactory.from(IInspectable interface) =>
      IPhoneNumberInfoFactory.fromRawPointer(
          interface.toInterface(IID_IPhoneNumberInfoFactory));

  PhoneNumberInfo create(String number) {
    final retValuePtr = calloc<COMObject>();
    final numberHstring = convertToHString(number);
    final hr = ptr.ref.vtable
            .elementAt(6)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(
                            Pointer, IntPtr number, Pointer<COMObject>)>>>()
            .value
            .asFunction<
                int Function(Pointer, int number, Pointer<COMObject>)>()(
        ptr.ref.lpVtbl, numberHstring, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }
    WindowsDeleteString(numberHstring);
    return PhoneNumberInfo.fromRawPointer(retValuePtr);
  }
}
