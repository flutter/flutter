// imoniker.dart

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
import 'ipersiststream.dart';
import 'iunknown.dart';

/// @nodoc
const IID_IMoniker = '{0000000F-0000-0000-C000-000000000046}';

/// {@category Interface}
/// {@category com}
class IMoniker extends IPersistStream {
  // vtable begins at 8, is 15 entries long.
  IMoniker(super.ptr);

  factory IMoniker.from(IUnknown interface) =>
      IMoniker(interface.toInterface(IID_IMoniker));

  int bindToObject(Pointer<COMObject> pbc, Pointer<COMObject> pmkToLeft,
          Pointer<GUID> riidResult, Pointer<Pointer> ppvResult) =>
      ptr.ref.vtable
              .elementAt(8)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<COMObject> pbc,
                              Pointer<COMObject> pmkToLeft,
                              Pointer<GUID> riidResult,
                              Pointer<Pointer> ppvResult)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<COMObject> pbc,
                      Pointer<COMObject> pmkToLeft,
                      Pointer<GUID> riidResult,
                      Pointer<Pointer> ppvResult)>()(
          ptr.ref.lpVtbl, pbc, pmkToLeft, riidResult, ppvResult);

  int bindToStorage(Pointer<COMObject> pbc, Pointer<COMObject> pmkToLeft,
          Pointer<GUID> riid, Pointer<Pointer> ppvObj) =>
      ptr.ref.vtable
              .elementAt(9)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<COMObject> pbc,
                              Pointer<COMObject> pmkToLeft,
                              Pointer<GUID> riid,
                              Pointer<Pointer> ppvObj)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<COMObject> pbc,
                      Pointer<COMObject> pmkToLeft,
                      Pointer<GUID> riid,
                      Pointer<Pointer> ppvObj)>()(
          ptr.ref.lpVtbl, pbc, pmkToLeft, riid, ppvObj);

  int reduce(
          Pointer<COMObject> pbc,
          int dwReduceHowFar,
          Pointer<Pointer<COMObject>> ppmkToLeft,
          Pointer<Pointer<COMObject>> ppmkReduced) =>
      ptr.ref.vtable
              .elementAt(10)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<COMObject> pbc,
                              Uint32 dwReduceHowFar,
                              Pointer<Pointer<COMObject>> ppmkToLeft,
                              Pointer<Pointer<COMObject>> ppmkReduced)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<COMObject> pbc,
                      int dwReduceHowFar,
                      Pointer<Pointer<COMObject>> ppmkToLeft,
                      Pointer<Pointer<COMObject>> ppmkReduced)>()(
          ptr.ref.lpVtbl, pbc, dwReduceHowFar, ppmkToLeft, ppmkReduced);

  int composeWith(Pointer<COMObject> pmkRight, int fOnlyIfNotGeneric,
          Pointer<Pointer<COMObject>> ppmkComposite) =>
      ptr.ref.vtable
              .elementAt(11)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<COMObject> pmkRight,
                              Int32 fOnlyIfNotGeneric,
                              Pointer<Pointer<COMObject>> ppmkComposite)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<COMObject> pmkRight,
                      int fOnlyIfNotGeneric,
                      Pointer<Pointer<COMObject>> ppmkComposite)>()(
          ptr.ref.lpVtbl, pmkRight, fOnlyIfNotGeneric, ppmkComposite);

  int enum_(int fForward, Pointer<Pointer<COMObject>> ppenumMoniker) =>
      ptr.ref.vtable
              .elementAt(12)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, Int32 fForward,
                              Pointer<Pointer<COMObject>> ppenumMoniker)>>>()
              .value
              .asFunction<
                  int Function(Pointer, int fForward,
                      Pointer<Pointer<COMObject>> ppenumMoniker)>()(
          ptr.ref.lpVtbl, fForward, ppenumMoniker);

  int isEqual(Pointer<COMObject> pmkOtherMoniker) => ptr.ref.vtable
          .elementAt(13)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Pointer<COMObject> pmkOtherMoniker)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<COMObject> pmkOtherMoniker)>()(
      ptr.ref.lpVtbl, pmkOtherMoniker);

  int hash(Pointer<Uint32> pdwHash) => ptr.ref.vtable
          .elementAt(14)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Uint32> pdwHash)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<Uint32> pdwHash)>()(
      ptr.ref.lpVtbl, pdwHash);

  int isRunning(Pointer<COMObject> pbc, Pointer<COMObject> pmkToLeft,
          Pointer<COMObject> pmkNewlyRunning) =>
      ptr.ref.vtable
              .elementAt(15)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<COMObject> pbc,
                              Pointer<COMObject> pmkToLeft,
                              Pointer<COMObject> pmkNewlyRunning)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<COMObject> pbc,
                      Pointer<COMObject> pmkToLeft,
                      Pointer<COMObject> pmkNewlyRunning)>()(
          ptr.ref.lpVtbl, pbc, pmkToLeft, pmkNewlyRunning);

  int getTimeOfLastChange(Pointer<COMObject> pbc, Pointer<COMObject> pmkToLeft,
          Pointer<FILETIME> pFileTime) =>
      ptr.ref.vtable
              .elementAt(16)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<COMObject> pbc,
                              Pointer<COMObject> pmkToLeft,
                              Pointer<FILETIME> pFileTime)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<COMObject> pbc,
                      Pointer<COMObject> pmkToLeft,
                      Pointer<FILETIME> pFileTime)>()(
          ptr.ref.lpVtbl, pbc, pmkToLeft, pFileTime);

  int inverse(Pointer<Pointer<COMObject>> ppmk) => ptr.ref.vtable
      .elementAt(17)
      .cast<
          Pointer<
              NativeFunction<
                  Int32 Function(Pointer, Pointer<Pointer<COMObject>> ppmk)>>>()
      .value
      .asFunction<
          int Function(Pointer,
              Pointer<Pointer<COMObject>> ppmk)>()(ptr.ref.lpVtbl, ppmk);

  int commonPrefixWith(Pointer<COMObject> pmkOther,
          Pointer<Pointer<COMObject>> ppmkPrefix) =>
      ptr.ref.vtable
              .elementAt(18)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, Pointer<COMObject> pmkOther,
                              Pointer<Pointer<COMObject>> ppmkPrefix)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<COMObject> pmkOther,
                      Pointer<Pointer<COMObject>> ppmkPrefix)>()(
          ptr.ref.lpVtbl, pmkOther, ppmkPrefix);

  int relativePathTo(Pointer<COMObject> pmkOther,
          Pointer<Pointer<COMObject>> ppmkRelPath) =>
      ptr.ref.vtable
              .elementAt(19)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, Pointer<COMObject> pmkOther,
                              Pointer<Pointer<COMObject>> ppmkRelPath)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<COMObject> pmkOther,
                      Pointer<Pointer<COMObject>> ppmkRelPath)>()(
          ptr.ref.lpVtbl, pmkOther, ppmkRelPath);

  int getDisplayName(Pointer<COMObject> pbc, Pointer<COMObject> pmkToLeft,
          Pointer<Pointer<Utf16>> ppszDisplayName) =>
      ptr.ref.vtable
              .elementAt(20)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<COMObject> pbc,
                              Pointer<COMObject> pmkToLeft,
                              Pointer<Pointer<Utf16>> ppszDisplayName)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<COMObject> pbc,
                      Pointer<COMObject> pmkToLeft,
                      Pointer<Pointer<Utf16>> ppszDisplayName)>()(
          ptr.ref.lpVtbl, pbc, pmkToLeft, ppszDisplayName);

  int parseDisplayName(
          Pointer<COMObject> pbc,
          Pointer<COMObject> pmkToLeft,
          Pointer<Utf16> pszDisplayName,
          Pointer<Uint32> pchEaten,
          Pointer<Pointer<COMObject>> ppmkOut) =>
      ptr.ref.vtable
              .elementAt(21)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<COMObject> pbc,
                              Pointer<COMObject> pmkToLeft,
                              Pointer<Utf16> pszDisplayName,
                              Pointer<Uint32> pchEaten,
                              Pointer<Pointer<COMObject>> ppmkOut)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<COMObject> pbc,
                      Pointer<COMObject> pmkToLeft,
                      Pointer<Utf16> pszDisplayName,
                      Pointer<Uint32> pchEaten,
                      Pointer<Pointer<COMObject>> ppmkOut)>()(
          ptr.ref.lpVtbl, pbc, pmkToLeft, pszDisplayName, pchEaten, ppmkOut);

  int isSystemMoniker(Pointer<Uint32> pdwMksys) => ptr.ref.vtable
          .elementAt(22)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Uint32> pdwMksys)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<Uint32> pdwMksys)>()(
      ptr.ref.lpVtbl, pdwMksys);
}
