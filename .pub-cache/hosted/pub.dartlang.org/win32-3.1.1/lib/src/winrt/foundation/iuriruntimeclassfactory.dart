// iuriruntimeclassfactory.dart

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

import 'uri.dart';
import '../../com/iinspectable.dart';

/// @nodoc
const IID_IUriRuntimeClassFactory = '{44A9796F-723E-4FDF-A218-033E75B0C084}';

/// {@category Interface}
/// {@category winrt}
class IUriRuntimeClassFactory extends IInspectable {
  // vtable begins at 6, is 2 entries long.
  IUriRuntimeClassFactory.fromRawPointer(super.ptr);

  factory IUriRuntimeClassFactory.from(IInspectable interface) =>
      IUriRuntimeClassFactory.fromRawPointer(
          interface.toInterface(IID_IUriRuntimeClassFactory));

  Uri createUri(String uri) {
    final retValuePtr = calloc<COMObject>();
    final uriHstring = convertToHString(uri);
    final hr = ptr.ref.vtable
            .elementAt(6)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(
                            Pointer, IntPtr uri, Pointer<COMObject>)>>>()
            .value
            .asFunction<int Function(Pointer, int uri, Pointer<COMObject>)>()(
        ptr.ref.lpVtbl, uriHstring, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }
    WindowsDeleteString(uriHstring);
    return Uri.fromRawPointer(retValuePtr);
  }

  Uri createWithRelativeUri(String baseUri, String relativeUri) {
    final retValuePtr = calloc<COMObject>();
    final baseUriHstring = convertToHString(baseUri);
    final relativeUriHstring = convertToHString(relativeUri);
    final hr = ptr.ref.vtable
            .elementAt(7)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, IntPtr baseUri,
                            IntPtr relativeUri, Pointer<COMObject>)>>>()
            .value
            .asFunction<
                int Function(Pointer, int baseUri, int relativeUri,
                    Pointer<COMObject>)>()(
        ptr.ref.lpVtbl, baseUriHstring, relativeUriHstring, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }
    WindowsDeleteString(baseUriHstring);
    WindowsDeleteString(relativeUriHstring);
    return Uri.fromRawPointer(retValuePtr);
  }
}
