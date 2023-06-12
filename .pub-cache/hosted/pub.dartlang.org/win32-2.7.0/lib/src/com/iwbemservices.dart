// iwbemservices.dart

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
const IID_IWbemServices = '{9556DC99-828C-11CF-A37E-00AA003240C7}';

/// {@category Interface}
/// {@category com}
class IWbemServices extends IUnknown {
  // vtable begins at 3, is 23 entries long.
  IWbemServices(super.ptr);

  int OpenNamespace(
          Pointer<Utf16> strNamespace,
          int lFlags,
          Pointer<COMObject> pCtx,
          Pointer<Pointer<COMObject>> ppWorkingNamespace,
          Pointer<Pointer<COMObject>> ppResult) =>
      ptr.ref.vtable
              .elementAt(3)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<Utf16> strNamespace,
                              Int32 lFlags,
                              Pointer<COMObject> pCtx,
                              Pointer<Pointer<COMObject>> ppWorkingNamespace,
                              Pointer<Pointer<COMObject>> ppResult)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<Utf16> strNamespace,
                      int lFlags,
                      Pointer<COMObject> pCtx,
                      Pointer<Pointer<COMObject>> ppWorkingNamespace,
                      Pointer<Pointer<COMObject>> ppResult)>()(ptr.ref.lpVtbl,
          strNamespace, lFlags, pCtx, ppWorkingNamespace, ppResult);

  int CancelAsyncCall(Pointer<COMObject> pSink) => ptr.ref.vtable
          .elementAt(4)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<COMObject> pSink)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<COMObject> pSink)>()(
      ptr.ref.lpVtbl, pSink);

  int
      QueryObjectSink(
              int lFlags, Pointer<Pointer<COMObject>> ppResponseHandler) =>
          ptr.ref.vtable
                  .elementAt(5)
                  .cast<
                      Pointer<
                          NativeFunction<
                              Int32 Function(
                                  Pointer,
                                  Int32 lFlags,
                                  Pointer<Pointer<COMObject>>
                                      ppResponseHandler)>>>()
                  .value
                  .asFunction<
                      int Function(Pointer, int lFlags,
                          Pointer<Pointer<COMObject>> ppResponseHandler)>()(
              ptr.ref.lpVtbl, lFlags, ppResponseHandler);

  int GetObject(
          Pointer<Utf16> strObjectPath,
          int lFlags,
          Pointer<COMObject> pCtx,
          Pointer<Pointer<COMObject>> ppObject,
          Pointer<Pointer<COMObject>> ppCallResult) =>
      ptr.ref.vtable
              .elementAt(6)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<Utf16> strObjectPath,
                              Int32 lFlags,
                              Pointer<COMObject> pCtx,
                              Pointer<Pointer<COMObject>> ppObject,
                              Pointer<Pointer<COMObject>> ppCallResult)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<Utf16> strObjectPath,
                      int lFlags,
                      Pointer<COMObject> pCtx,
                      Pointer<Pointer<COMObject>> ppObject,
                      Pointer<Pointer<COMObject>> ppCallResult)>()(
          ptr.ref.lpVtbl, strObjectPath, lFlags, pCtx, ppObject, ppCallResult);

  int GetObjectAsync(Pointer<Utf16> strObjectPath, int lFlags,
          Pointer<COMObject> pCtx, Pointer<COMObject> pResponseHandler) =>
      ptr.ref.vtable
              .elementAt(7)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<Utf16> strObjectPath,
                              Int32 lFlags,
                              Pointer<COMObject> pCtx,
                              Pointer<COMObject> pResponseHandler)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<Utf16> strObjectPath,
                      int lFlags,
                      Pointer<COMObject> pCtx,
                      Pointer<COMObject> pResponseHandler)>()(
          ptr.ref.lpVtbl, strObjectPath, lFlags, pCtx, pResponseHandler);

  int PutClass(Pointer<COMObject> pObject, int lFlags, Pointer<COMObject> pCtx,
          Pointer<Pointer<COMObject>> ppCallResult) =>
      ptr.ref.vtable
              .elementAt(8)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<COMObject> pObject,
                              Int32 lFlags,
                              Pointer<COMObject> pCtx,
                              Pointer<Pointer<COMObject>> ppCallResult)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<COMObject> pObject,
                      int lFlags,
                      Pointer<COMObject> pCtx,
                      Pointer<Pointer<COMObject>> ppCallResult)>()(
          ptr.ref.lpVtbl, pObject, lFlags, pCtx, ppCallResult);

  int PutClassAsync(Pointer<COMObject> pObject, int lFlags,
          Pointer<COMObject> pCtx, Pointer<COMObject> pResponseHandler) =>
      ptr.ref.vtable
              .elementAt(9)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<COMObject> pObject,
                              Int32 lFlags,
                              Pointer<COMObject> pCtx,
                              Pointer<COMObject> pResponseHandler)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<COMObject> pObject,
                      int lFlags,
                      Pointer<COMObject> pCtx,
                      Pointer<COMObject> pResponseHandler)>()(
          ptr.ref.lpVtbl, pObject, lFlags, pCtx, pResponseHandler);

  int DeleteClass(Pointer<Utf16> strClass, int lFlags, Pointer<COMObject> pCtx,
          Pointer<Pointer<COMObject>> ppCallResult) =>
      ptr.ref.vtable
              .elementAt(10)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<Utf16> strClass,
                              Int32 lFlags,
                              Pointer<COMObject> pCtx,
                              Pointer<Pointer<COMObject>> ppCallResult)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<Utf16> strClass,
                      int lFlags,
                      Pointer<COMObject> pCtx,
                      Pointer<Pointer<COMObject>> ppCallResult)>()(
          ptr.ref.lpVtbl, strClass, lFlags, pCtx, ppCallResult);

  int DeleteClassAsync(Pointer<Utf16> strClass, int lFlags,
          Pointer<COMObject> pCtx, Pointer<COMObject> pResponseHandler) =>
      ptr.ref.vtable
              .elementAt(11)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<Utf16> strClass,
                              Int32 lFlags,
                              Pointer<COMObject> pCtx,
                              Pointer<COMObject> pResponseHandler)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<Utf16> strClass,
                      int lFlags,
                      Pointer<COMObject> pCtx,
                      Pointer<COMObject> pResponseHandler)>()(
          ptr.ref.lpVtbl, strClass, lFlags, pCtx, pResponseHandler);

  int CreateClassEnum(Pointer<Utf16> strSuperclass, int lFlags,
          Pointer<COMObject> pCtx, Pointer<Pointer<COMObject>> ppEnum) =>
      ptr.ref.vtable
              .elementAt(12)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<Utf16> strSuperclass,
                              Int32 lFlags,
                              Pointer<COMObject> pCtx,
                              Pointer<Pointer<COMObject>> ppEnum)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<Utf16> strSuperclass,
                      int lFlags,
                      Pointer<COMObject> pCtx,
                      Pointer<Pointer<COMObject>> ppEnum)>()(
          ptr.ref.lpVtbl, strSuperclass, lFlags, pCtx, ppEnum);

  int CreateClassEnumAsync(Pointer<Utf16> strSuperclass, int lFlags,
          Pointer<COMObject> pCtx, Pointer<COMObject> pResponseHandler) =>
      ptr.ref.vtable
              .elementAt(13)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<Utf16> strSuperclass,
                              Int32 lFlags,
                              Pointer<COMObject> pCtx,
                              Pointer<COMObject> pResponseHandler)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<Utf16> strSuperclass,
                      int lFlags,
                      Pointer<COMObject> pCtx,
                      Pointer<COMObject> pResponseHandler)>()(
          ptr.ref.lpVtbl, strSuperclass, lFlags, pCtx, pResponseHandler);

  int PutInstance(Pointer<COMObject> pInst, int lFlags, Pointer<COMObject> pCtx,
          Pointer<Pointer<COMObject>> ppCallResult) =>
      ptr.ref.vtable
              .elementAt(14)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<COMObject> pInst,
                              Int32 lFlags,
                              Pointer<COMObject> pCtx,
                              Pointer<Pointer<COMObject>> ppCallResult)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<COMObject> pInst,
                      int lFlags,
                      Pointer<COMObject> pCtx,
                      Pointer<Pointer<COMObject>> ppCallResult)>()(
          ptr.ref.lpVtbl, pInst, lFlags, pCtx, ppCallResult);

  int PutInstanceAsync(Pointer<COMObject> pInst, int lFlags,
          Pointer<COMObject> pCtx, Pointer<COMObject> pResponseHandler) =>
      ptr.ref.vtable
              .elementAt(15)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<COMObject> pInst,
                              Int32 lFlags,
                              Pointer<COMObject> pCtx,
                              Pointer<COMObject> pResponseHandler)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<COMObject> pInst,
                      int lFlags,
                      Pointer<COMObject> pCtx,
                      Pointer<COMObject> pResponseHandler)>()(
          ptr.ref.lpVtbl, pInst, lFlags, pCtx, pResponseHandler);

  int DeleteInstance(Pointer<Utf16> strObjectPath, int lFlags,
          Pointer<COMObject> pCtx, Pointer<Pointer<COMObject>> ppCallResult) =>
      ptr.ref.vtable
              .elementAt(16)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<Utf16> strObjectPath,
                              Int32 lFlags,
                              Pointer<COMObject> pCtx,
                              Pointer<Pointer<COMObject>> ppCallResult)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<Utf16> strObjectPath,
                      int lFlags,
                      Pointer<COMObject> pCtx,
                      Pointer<Pointer<COMObject>> ppCallResult)>()(
          ptr.ref.lpVtbl, strObjectPath, lFlags, pCtx, ppCallResult);

  int DeleteInstanceAsync(Pointer<Utf16> strObjectPath, int lFlags,
          Pointer<COMObject> pCtx, Pointer<COMObject> pResponseHandler) =>
      ptr.ref.vtable
              .elementAt(17)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<Utf16> strObjectPath,
                              Int32 lFlags,
                              Pointer<COMObject> pCtx,
                              Pointer<COMObject> pResponseHandler)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<Utf16> strObjectPath,
                      int lFlags,
                      Pointer<COMObject> pCtx,
                      Pointer<COMObject> pResponseHandler)>()(
          ptr.ref.lpVtbl, strObjectPath, lFlags, pCtx, pResponseHandler);

  int CreateInstanceEnum(Pointer<Utf16> strFilter, int lFlags,
          Pointer<COMObject> pCtx, Pointer<Pointer<COMObject>> ppEnum) =>
      ptr.ref.vtable
              .elementAt(18)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<Utf16> strFilter,
                              Int32 lFlags,
                              Pointer<COMObject> pCtx,
                              Pointer<Pointer<COMObject>> ppEnum)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<Utf16> strFilter,
                      int lFlags,
                      Pointer<COMObject> pCtx,
                      Pointer<Pointer<COMObject>> ppEnum)>()(
          ptr.ref.lpVtbl, strFilter, lFlags, pCtx, ppEnum);

  int CreateInstanceEnumAsync(Pointer<Utf16> strFilter, int lFlags,
          Pointer<COMObject> pCtx, Pointer<COMObject> pResponseHandler) =>
      ptr.ref.vtable
              .elementAt(19)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<Utf16> strFilter,
                              Int32 lFlags,
                              Pointer<COMObject> pCtx,
                              Pointer<COMObject> pResponseHandler)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<Utf16> strFilter,
                      int lFlags,
                      Pointer<COMObject> pCtx,
                      Pointer<COMObject> pResponseHandler)>()(
          ptr.ref.lpVtbl, strFilter, lFlags, pCtx, pResponseHandler);

  int ExecQuery(
          Pointer<Utf16> strQueryLanguage,
          Pointer<Utf16> strQuery,
          int lFlags,
          Pointer<COMObject> pCtx,
          Pointer<Pointer<COMObject>> ppEnum) =>
      ptr.ref.vtable
              .elementAt(20)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<Utf16> strQueryLanguage,
                              Pointer<Utf16> strQuery,
                              Int32 lFlags,
                              Pointer<COMObject> pCtx,
                              Pointer<Pointer<COMObject>> ppEnum)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<Utf16> strQueryLanguage,
                      Pointer<Utf16> strQuery,
                      int lFlags,
                      Pointer<COMObject> pCtx,
                      Pointer<Pointer<COMObject>> ppEnum)>()(
          ptr.ref.lpVtbl, strQueryLanguage, strQuery, lFlags, pCtx, ppEnum);

  int ExecQueryAsync(
          Pointer<Utf16> strQueryLanguage,
          Pointer<Utf16> strQuery,
          int lFlags,
          Pointer<COMObject> pCtx,
          Pointer<COMObject> pResponseHandler) =>
      ptr.ref.vtable
              .elementAt(21)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<Utf16> strQueryLanguage,
                              Pointer<Utf16> strQuery,
                              Int32 lFlags,
                              Pointer<COMObject> pCtx,
                              Pointer<COMObject> pResponseHandler)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<Utf16> strQueryLanguage,
                      Pointer<Utf16> strQuery,
                      int lFlags,
                      Pointer<COMObject> pCtx,
                      Pointer<COMObject> pResponseHandler)>()(ptr.ref.lpVtbl,
          strQueryLanguage, strQuery, lFlags, pCtx, pResponseHandler);

  int ExecNotificationQuery(
          Pointer<Utf16> strQueryLanguage,
          Pointer<Utf16> strQuery,
          int lFlags,
          Pointer<COMObject> pCtx,
          Pointer<Pointer<COMObject>> ppEnum) =>
      ptr.ref.vtable
              .elementAt(22)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<Utf16> strQueryLanguage,
                              Pointer<Utf16> strQuery,
                              Int32 lFlags,
                              Pointer<COMObject> pCtx,
                              Pointer<Pointer<COMObject>> ppEnum)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<Utf16> strQueryLanguage,
                      Pointer<Utf16> strQuery,
                      int lFlags,
                      Pointer<COMObject> pCtx,
                      Pointer<Pointer<COMObject>> ppEnum)>()(
          ptr.ref.lpVtbl, strQueryLanguage, strQuery, lFlags, pCtx, ppEnum);

  int ExecNotificationQueryAsync(
          Pointer<Utf16> strQueryLanguage,
          Pointer<Utf16> strQuery,
          int lFlags,
          Pointer<COMObject> pCtx,
          Pointer<COMObject> pResponseHandler) =>
      ptr.ref.vtable
              .elementAt(23)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<Utf16> strQueryLanguage,
                              Pointer<Utf16> strQuery,
                              Int32 lFlags,
                              Pointer<COMObject> pCtx,
                              Pointer<COMObject> pResponseHandler)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<Utf16> strQueryLanguage,
                      Pointer<Utf16> strQuery,
                      int lFlags,
                      Pointer<COMObject> pCtx,
                      Pointer<COMObject> pResponseHandler)>()(ptr.ref.lpVtbl,
          strQueryLanguage, strQuery, lFlags, pCtx, pResponseHandler);

  int ExecMethod(
          Pointer<Utf16> strObjectPath,
          Pointer<Utf16> strMethodName,
          int lFlags,
          Pointer<COMObject> pCtx,
          Pointer<COMObject> pInParams,
          Pointer<Pointer<COMObject>> ppOutParams,
          Pointer<Pointer<COMObject>> ppCallResult) =>
      ptr.ref.vtable
              .elementAt(24)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<Utf16> strObjectPath,
                              Pointer<Utf16> strMethodName,
                              Int32 lFlags,
                              Pointer<COMObject> pCtx,
                              Pointer<COMObject> pInParams,
                              Pointer<Pointer<COMObject>> ppOutParams,
                              Pointer<Pointer<COMObject>> ppCallResult)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<Utf16> strObjectPath,
                      Pointer<Utf16> strMethodName,
                      int lFlags,
                      Pointer<COMObject> pCtx,
                      Pointer<COMObject> pInParams,
                      Pointer<Pointer<COMObject>> ppOutParams,
                      Pointer<Pointer<COMObject>> ppCallResult)>()(
          ptr.ref.lpVtbl,
          strObjectPath,
          strMethodName,
          lFlags,
          pCtx,
          pInParams,
          ppOutParams,
          ppCallResult);

  int ExecMethodAsync(
          Pointer<Utf16> strObjectPath,
          Pointer<Utf16> strMethodName,
          int lFlags,
          Pointer<COMObject> pCtx,
          Pointer<COMObject> pInParams,
          Pointer<COMObject> pResponseHandler) =>
      ptr.ref.vtable
              .elementAt(25)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<Utf16> strObjectPath,
                              Pointer<Utf16> strMethodName,
                              Int32 lFlags,
                              Pointer<COMObject> pCtx,
                              Pointer<COMObject> pInParams,
                              Pointer<COMObject> pResponseHandler)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<Utf16> strObjectPath,
                      Pointer<Utf16> strMethodName,
                      int lFlags,
                      Pointer<COMObject> pCtx,
                      Pointer<COMObject> pInParams,
                      Pointer<COMObject> pResponseHandler)>()(
          ptr.ref.lpVtbl,
          strObjectPath,
          strMethodName,
          lFlags,
          pCtx,
          pInParams,
          pResponseHandler);
}
