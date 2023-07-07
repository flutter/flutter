// iwbemcontext.dart

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
import '../ole32.dart';
import '../structs.dart';
import '../structs.g.dart';
import '../utils.dart';

import 'iunknown.dart';

/// @nodoc
const IID_IWbemContext = '{44ACA674-E8FC-11D0-A07C-00C04FB68820}';

/// {@category Interface}
/// {@category com}
class IWbemContext extends IUnknown {
  // vtable begins at 3, is 9 entries long.
  IWbemContext(super.ptr);

  int Clone(Pointer<Pointer<COMObject>> ppNewCopy) => ptr.ref.vtable
          .elementAt(3)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Pointer<Pointer<COMObject>> ppNewCopy)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<Pointer<COMObject>> ppNewCopy)>()(
      ptr.ref.lpVtbl, ppNewCopy);

  int GetNames(int lFlags, Pointer<Pointer<SAFEARRAY>> pNames) => ptr.ref.vtable
          .elementAt(4)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Int32 lFlags,
                          Pointer<Pointer<SAFEARRAY>> pNames)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, int lFlags, Pointer<Pointer<SAFEARRAY>> pNames)>()(
      ptr.ref.lpVtbl, lFlags, pNames);

  int BeginEnumeration(int lFlags) => ptr.ref.vtable
      .elementAt(5)
      .cast<Pointer<NativeFunction<Int32 Function(Pointer, Int32 lFlags)>>>()
      .value
      .asFunction<int Function(Pointer, int lFlags)>()(ptr.ref.lpVtbl, lFlags);

  int Next(int lFlags, Pointer<Pointer<Utf16>> pstrName,
          Pointer<VARIANT> pValue) =>
      ptr.ref.vtable
              .elementAt(6)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Int32 lFlags,
                              Pointer<Pointer<Utf16>> pstrName,
                              Pointer<VARIANT> pValue)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      int lFlags,
                      Pointer<Pointer<Utf16>> pstrName,
                      Pointer<VARIANT> pValue)>()(
          ptr.ref.lpVtbl, lFlags, pstrName, pValue);

  int EndEnumeration() => ptr.ref.vtable
      .elementAt(7)
      .cast<Pointer<NativeFunction<Int32 Function(Pointer)>>>()
      .value
      .asFunction<int Function(Pointer)>()(ptr.ref.lpVtbl);

  int SetValue(Pointer<Utf16> wszName, int lFlags, Pointer<VARIANT> pValue) =>
      ptr.ref.vtable
              .elementAt(8)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, Pointer<Utf16> wszName,
                              Int32 lFlags, Pointer<VARIANT> pValue)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<Utf16> wszName, int lFlags,
                      Pointer<VARIANT> pValue)>()(
          ptr.ref.lpVtbl, wszName, lFlags, pValue);

  int GetValue(Pointer<Utf16> wszName, int lFlags, Pointer<VARIANT> pValue) =>
      ptr.ref.vtable
              .elementAt(9)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, Pointer<Utf16> wszName,
                              Int32 lFlags, Pointer<VARIANT> pValue)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<Utf16> wszName, int lFlags,
                      Pointer<VARIANT> pValue)>()(
          ptr.ref.lpVtbl, wszName, lFlags, pValue);

  int DeleteValue(Pointer<Utf16> wszName, int lFlags) => ptr.ref.vtable
          .elementAt(10)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Pointer<Utf16> wszName, Int32 lFlags)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<Utf16> wszName, int lFlags)>()(
      ptr.ref.lpVtbl, wszName, lFlags);

  int DeleteAll() => ptr.ref.vtable
      .elementAt(11)
      .cast<Pointer<NativeFunction<Int32 Function(Pointer)>>>()
      .value
      .asFunction<int Function(Pointer)>()(ptr.ref.lpVtbl);
}

/// @nodoc
const CLSID_WbemContext = '{674B6698-EE92-11D0-AD71-00C04FD8FDFF}';

/// {@category com}
class WbemContext extends IWbemContext {
  WbemContext(super.ptr);

  factory WbemContext.createInstance() =>
      WbemContext(COMObject.createFromID(CLSID_WbemContext, IID_IWbemContext));
}
