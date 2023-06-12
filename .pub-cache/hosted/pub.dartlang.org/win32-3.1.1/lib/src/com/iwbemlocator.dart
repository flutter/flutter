// iwbemlocator.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import, directives_ordering
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../callbacks.dart';
import '../combase.dart';
import '../constants.dart';
import '../exceptions.dart';
import '../guid.dart';
import '../macros.dart';
import '../structs.g.dart';
import '../utils.dart';
import '../variant.dart';
import '../win32/ole32.g.dart';
import 'iunknown.dart';

/// @nodoc
const IID_IWbemLocator = '{DC12A687-737F-11CF-884D-00AA004B2E24}';

/// {@category Interface}
/// {@category com}
class IWbemLocator extends IUnknown {
  // vtable begins at 3, is 1 entries long.
  IWbemLocator(super.ptr);

  factory IWbemLocator.from(IUnknown interface) =>
      IWbemLocator(interface.toInterface(IID_IWbemLocator));

  int connectServer(
          Pointer<Utf16> strNetworkResource,
          Pointer<Utf16> strUser,
          Pointer<Utf16> strPassword,
          Pointer<Utf16> strLocale,
          int lSecurityFlags,
          Pointer<Utf16> strAuthority,
          Pointer<COMObject> pCtx,
          Pointer<Pointer<COMObject>> ppNamespace) =>
      ptr.ref.vtable
              .elementAt(3)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<Utf16> strNetworkResource,
                              Pointer<Utf16> strUser,
                              Pointer<Utf16> strPassword,
                              Pointer<Utf16> strLocale,
                              Int32 lSecurityFlags,
                              Pointer<Utf16> strAuthority,
                              Pointer<COMObject> pCtx,
                              Pointer<Pointer<COMObject>> ppNamespace)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<Utf16> strNetworkResource,
                      Pointer<Utf16> strUser,
                      Pointer<Utf16> strPassword,
                      Pointer<Utf16> strLocale,
                      int lSecurityFlags,
                      Pointer<Utf16> strAuthority,
                      Pointer<COMObject> pCtx,
                      Pointer<Pointer<COMObject>> ppNamespace)>()(
          ptr.ref.lpVtbl,
          strNetworkResource,
          strUser,
          strPassword,
          strLocale,
          lSecurityFlags,
          strAuthority,
          pCtx,
          ppNamespace);
}

/// @nodoc
const CLSID_WbemLocator = '{4590F811-1D3A-11D0-891F-00AA004B2E24}';

/// {@category com}
class WbemLocator extends IWbemLocator {
  WbemLocator(super.ptr);

  factory WbemLocator.createInstance() =>
      WbemLocator(COMObject.createFromID(CLSID_WbemLocator, IID_IWbemLocator));
}
