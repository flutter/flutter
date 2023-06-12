// iwbemconfigurerefresher.dart

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
const IID_IWbemConfigureRefresher = '{49353C92-516B-11D1-AEA6-00C04FB68820}';

/// {@category Interface}
/// {@category com}
class IWbemConfigureRefresher extends IUnknown {
  // vtable begins at 3, is 5 entries long.
  IWbemConfigureRefresher(super.ptr);

  factory IWbemConfigureRefresher.from(IUnknown interface) =>
      IWbemConfigureRefresher(
          interface.toInterface(IID_IWbemConfigureRefresher));

  int addObjectByPath(
          Pointer<COMObject> pNamespace,
          Pointer<Utf16> wszPath,
          int lFlags,
          Pointer<COMObject> pContext,
          Pointer<Pointer<COMObject>> ppRefreshable,
          Pointer<Int32> plId) =>
      ptr.ref.vtable
              .elementAt(3)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<COMObject> pNamespace,
                              Pointer<Utf16> wszPath,
                              Int32 lFlags,
                              Pointer<COMObject> pContext,
                              Pointer<Pointer<COMObject>> ppRefreshable,
                              Pointer<Int32> plId)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<COMObject> pNamespace,
                      Pointer<Utf16> wszPath,
                      int lFlags,
                      Pointer<COMObject> pContext,
                      Pointer<Pointer<COMObject>> ppRefreshable,
                      Pointer<Int32> plId)>()(ptr.ref.lpVtbl, pNamespace,
          wszPath, lFlags, pContext, ppRefreshable, plId);

  int addObjectByTemplate(
          Pointer<COMObject> pNamespace,
          Pointer<COMObject> pTemplate,
          int lFlags,
          Pointer<COMObject> pContext,
          Pointer<Pointer<COMObject>> ppRefreshable,
          Pointer<Int32> plId) =>
      ptr.ref.vtable
              .elementAt(4)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<COMObject> pNamespace,
                              Pointer<COMObject> pTemplate,
                              Int32 lFlags,
                              Pointer<COMObject> pContext,
                              Pointer<Pointer<COMObject>> ppRefreshable,
                              Pointer<Int32> plId)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<COMObject> pNamespace,
                      Pointer<COMObject> pTemplate,
                      int lFlags,
                      Pointer<COMObject> pContext,
                      Pointer<Pointer<COMObject>> ppRefreshable,
                      Pointer<Int32> plId)>()(ptr.ref.lpVtbl, pNamespace,
          pTemplate, lFlags, pContext, ppRefreshable, plId);

  int addRefresher(
          Pointer<COMObject> pRefresher, int lFlags, Pointer<Int32> plId) =>
      ptr.ref.vtable
              .elementAt(5)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, Pointer<COMObject> pRefresher,
                              Int32 lFlags, Pointer<Int32> plId)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<COMObject> pRefresher,
                      int lFlags, Pointer<Int32> plId)>()(
          ptr.ref.lpVtbl, pRefresher, lFlags, plId);

  int remove(int lId, int lFlags) => ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Int32 lId, Int32 lFlags)>>>()
          .value
          .asFunction<int Function(Pointer, int lId, int lFlags)>()(
      ptr.ref.lpVtbl, lId, lFlags);

  int addEnum(
          Pointer<COMObject> pNamespace,
          Pointer<Utf16> wszClassName,
          int lFlags,
          Pointer<COMObject> pContext,
          Pointer<Pointer<COMObject>> ppEnum,
          Pointer<Int32> plId) =>
      ptr.ref.vtable
              .elementAt(7)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<COMObject> pNamespace,
                              Pointer<Utf16> wszClassName,
                              Int32 lFlags,
                              Pointer<COMObject> pContext,
                              Pointer<Pointer<COMObject>> ppEnum,
                              Pointer<Int32> plId)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<COMObject> pNamespace,
                      Pointer<Utf16> wszClassName,
                      int lFlags,
                      Pointer<COMObject> pContext,
                      Pointer<Pointer<COMObject>> ppEnum,
                      Pointer<Int32> plId)>()(ptr.ref.lpVtbl, pNamespace,
          wszClassName, lFlags, pContext, ppEnum, plId);
}
