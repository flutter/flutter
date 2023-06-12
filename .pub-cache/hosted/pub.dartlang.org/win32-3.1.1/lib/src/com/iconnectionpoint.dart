// iconnectionpoint.dart

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
const IID_IConnectionPoint = '{B196B286-BAB4-101A-B69C-00AA00341D07}';

/// {@category Interface}
/// {@category com}
class IConnectionPoint extends IUnknown {
  // vtable begins at 3, is 5 entries long.
  IConnectionPoint(super.ptr);

  factory IConnectionPoint.from(IUnknown interface) =>
      IConnectionPoint(interface.toInterface(IID_IConnectionPoint));

  int getConnectionInterface(Pointer<GUID> pIID) => ptr.ref.vtable
      .elementAt(3)
      .cast<
          Pointer<
              NativeFunction<Int32 Function(Pointer, Pointer<GUID> pIID)>>>()
      .value
      .asFunction<
          int Function(Pointer, Pointer<GUID> pIID)>()(ptr.ref.lpVtbl, pIID);

  int getConnectionPointContainer(Pointer<Pointer<COMObject>> ppCPC) =>
      ptr.ref.vtable
              .elementAt(4)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer, Pointer<Pointer<COMObject>> ppCPC)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<Pointer<COMObject>> ppCPC)>()(
          ptr.ref.lpVtbl, ppCPC);

  int advise(Pointer<COMObject> pUnkSink, Pointer<Uint32> pdwCookie) =>
      ptr.ref.vtable
              .elementAt(5)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, Pointer<COMObject> pUnkSink,
                              Pointer<Uint32> pdwCookie)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<COMObject> pUnkSink,
                      Pointer<Uint32> pdwCookie)>()(
          ptr.ref.lpVtbl, pUnkSink, pdwCookie);

  int unadvise(int dwCookie) => ptr.ref.vtable
      .elementAt(6)
      .cast<Pointer<NativeFunction<Int32 Function(Pointer, Uint32 dwCookie)>>>()
      .value
      .asFunction<
          int Function(Pointer, int dwCookie)>()(ptr.ref.lpVtbl, dwCookie);

  int enumConnections(Pointer<Pointer<COMObject>> ppEnum) => ptr.ref.vtable
          .elementAt(7)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Pointer<Pointer<COMObject>> ppEnum)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<Pointer<COMObject>> ppEnum)>()(
      ptr.ref.lpVtbl, ppEnum);
}
