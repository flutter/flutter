// idispatch.dart

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
const IID_IDispatch = '{00020400-0000-0000-C000-000000000046}';

/// {@category Interface}
/// {@category com}
class IDispatch extends IUnknown {
  // vtable begins at 3, is 4 entries long.
  IDispatch(super.ptr);

  factory IDispatch.from(IUnknown interface) =>
      IDispatch(interface.toInterface(IID_IDispatch));

  int getTypeInfoCount(Pointer<Uint32> pctinfo) => ptr.ref.vtable
          .elementAt(3)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Uint32> pctinfo)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<Uint32> pctinfo)>()(
      ptr.ref.lpVtbl, pctinfo);

  int getTypeInfo(int iTInfo, int lcid, Pointer<Pointer<COMObject>> ppTInfo) =>
      ptr.ref.vtable
              .elementAt(4)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, Uint32 iTInfo, Uint32 lcid,
                              Pointer<Pointer<COMObject>> ppTInfo)>>>()
              .value
              .asFunction<
                  int Function(Pointer, int iTInfo, int lcid,
                      Pointer<Pointer<COMObject>> ppTInfo)>()(
          ptr.ref.lpVtbl, iTInfo, lcid, ppTInfo);

  int getIDsOfNames(Pointer<GUID> riid, Pointer<Pointer<Utf16>> rgszNames,
          int cNames, int lcid, Pointer<Int32> rgDispId) =>
      ptr.ref.vtable
              .elementAt(5)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<GUID> riid,
                              Pointer<Pointer<Utf16>> rgszNames,
                              Uint32 cNames,
                              Uint32 lcid,
                              Pointer<Int32> rgDispId)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<GUID> riid,
                      Pointer<Pointer<Utf16>> rgszNames,
                      int cNames,
                      int lcid,
                      Pointer<Int32> rgDispId)>()(
          ptr.ref.lpVtbl, riid, rgszNames, cNames, lcid, rgDispId);

  int invoke(
          int dispIdMember,
          Pointer<GUID> riid,
          int lcid,
          int wFlags,
          Pointer<DISPPARAMS> pDispParams,
          Pointer<VARIANT> pVarResult,
          Pointer<EXCEPINFO> pExcepInfo,
          Pointer<Uint32> puArgErr) =>
      ptr.ref.vtable
              .elementAt(6)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Int32 dispIdMember,
                              Pointer<GUID> riid,
                              Uint32 lcid,
                              Uint16 wFlags,
                              Pointer<DISPPARAMS> pDispParams,
                              Pointer<VARIANT> pVarResult,
                              Pointer<EXCEPINFO> pExcepInfo,
                              Pointer<Uint32> puArgErr)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      int dispIdMember,
                      Pointer<GUID> riid,
                      int lcid,
                      int wFlags,
                      Pointer<DISPPARAMS> pDispParams,
                      Pointer<VARIANT> pVarResult,
                      Pointer<EXCEPINFO> pExcepInfo,
                      Pointer<Uint32> puArgErr)>()(ptr.ref.lpVtbl, dispIdMember,
          riid, lcid, wFlags, pDispParams, pVarResult, pExcepInfo, puArgErr);
}
