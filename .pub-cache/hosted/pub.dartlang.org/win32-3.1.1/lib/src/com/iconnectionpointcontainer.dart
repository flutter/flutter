// iconnectionpointcontainer.dart

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
const IID_IConnectionPointContainer = '{B196B284-BAB4-101A-B69C-00AA00341D07}';

/// {@category Interface}
/// {@category com}
class IConnectionPointContainer extends IUnknown {
  // vtable begins at 3, is 2 entries long.
  IConnectionPointContainer(super.ptr);

  factory IConnectionPointContainer.from(IUnknown interface) =>
      IConnectionPointContainer(
          interface.toInterface(IID_IConnectionPointContainer));

  int enumConnectionPoints(Pointer<Pointer<COMObject>> ppEnum) => ptr.ref.vtable
          .elementAt(3)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Pointer<Pointer<COMObject>> ppEnum)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<Pointer<COMObject>> ppEnum)>()(
      ptr.ref.lpVtbl, ppEnum);

  int findConnectionPoint(
          Pointer<GUID> riid, Pointer<Pointer<COMObject>> ppCP) =>
      ptr.ref.vtable
              .elementAt(4)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, Pointer<GUID> riid,
                              Pointer<Pointer<COMObject>> ppCP)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<GUID> riid,
                      Pointer<Pointer<COMObject>> ppCP)>()(
          ptr.ref.lpVtbl, riid, ppCP);
}
