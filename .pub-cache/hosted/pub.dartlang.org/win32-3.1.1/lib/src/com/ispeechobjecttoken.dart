// ispeechobjecttoken.dart

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
import 'idispatch.dart';
import 'iunknown.dart';

/// @nodoc
const IID_ISpeechObjectToken = '{C74A3ADC-B727-4500-A84A-B526721C8B8C}';

/// {@category Interface}
/// {@category com}
class ISpeechObjectToken extends IDispatch {
  // vtable begins at 7, is 13 entries long.
  ISpeechObjectToken(super.ptr);

  factory ISpeechObjectToken.from(IUnknown interface) =>
      ISpeechObjectToken(interface.toInterface(IID_ISpeechObjectToken));

  Pointer<Utf16> get id {
    final retValuePtr = calloc<Pointer<Utf16>>();

    try {
      final hr = ptr.ref.vtable
              .elementAt(7)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer, Pointer<Pointer<Utf16>> ObjectId)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<Pointer<Utf16>> ObjectId)>()(
          ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  Pointer<COMObject> get dataKey {
    final retValuePtr = calloc<Pointer<COMObject>>();

    try {
      final hr = ptr.ref.vtable
              .elementAt(8)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer, Pointer<Pointer<COMObject>> DataKey)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<Pointer<COMObject>> DataKey)>()(
          ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  Pointer<COMObject> get category {
    final retValuePtr = calloc<Pointer<COMObject>>();

    try {
      final hr = ptr.ref.vtable
              .elementAt(9)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer,
                              Pointer<Pointer<COMObject>> Category)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer, Pointer<Pointer<COMObject>> Category)>()(
          ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int getDescription(int Locale, Pointer<Pointer<Utf16>> Description) => ptr
          .ref.vtable
          .elementAt(10)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Int32 Locale,
                          Pointer<Pointer<Utf16>> Description)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, int Locale, Pointer<Pointer<Utf16>> Description)>()(
      ptr.ref.lpVtbl, Locale, Description);

  int setId(
          Pointer<Utf16> Id, Pointer<Utf16> CategoryID, int CreateIfNotExist) =>
      ptr.ref.vtable
              .elementAt(11)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<Utf16> Id,
                              Pointer<Utf16> CategoryID,
                              Int16 CreateIfNotExist)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<Utf16> Id,
                      Pointer<Utf16> CategoryID, int CreateIfNotExist)>()(
          ptr.ref.lpVtbl, Id, CategoryID, CreateIfNotExist);

  int getAttribute(Pointer<Utf16> AttributeName,
          Pointer<Pointer<Utf16>> AttributeValue) =>
      ptr.ref.vtable
              .elementAt(12)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, Pointer<Utf16> AttributeName,
                              Pointer<Pointer<Utf16>> AttributeValue)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<Utf16> AttributeName,
                      Pointer<Pointer<Utf16>> AttributeValue)>()(
          ptr.ref.lpVtbl, AttributeName, AttributeValue);

  int createInstance(Pointer<COMObject> pUnkOuter, int ClsContext,
          Pointer<Pointer<COMObject>> Object) =>
      ptr.ref.vtable
              .elementAt(13)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<COMObject> pUnkOuter,
                              Uint32 ClsContext,
                              Pointer<Pointer<COMObject>> Object)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<COMObject> pUnkOuter,
                      int ClsContext, Pointer<Pointer<COMObject>> Object)>()(
          ptr.ref.lpVtbl, pUnkOuter, ClsContext, Object);

  int remove(Pointer<Utf16> ObjectStorageCLSID) => ptr.ref.vtable
          .elementAt(14)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Pointer<Utf16> ObjectStorageCLSID)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<Utf16> ObjectStorageCLSID)>()(
      ptr.ref.lpVtbl, ObjectStorageCLSID);

  int getStorageFileName(
          Pointer<Utf16> ObjectStorageCLSID,
          Pointer<Utf16> KeyName,
          Pointer<Utf16> FileName,
          int Folder,
          Pointer<Pointer<Utf16>> FilePath) =>
      ptr.ref.vtable
              .elementAt(15)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<Utf16> ObjectStorageCLSID,
                              Pointer<Utf16> KeyName,
                              Pointer<Utf16> FileName,
                              Int32 Folder,
                              Pointer<Pointer<Utf16>> FilePath)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<Utf16> ObjectStorageCLSID,
                      Pointer<Utf16> KeyName,
                      Pointer<Utf16> FileName,
                      int Folder,
                      Pointer<Pointer<Utf16>> FilePath)>()(ptr.ref.lpVtbl,
          ObjectStorageCLSID, KeyName, FileName, Folder, FilePath);

  int
      removeStorageFileName(Pointer<Utf16> ObjectStorageCLSID,
              Pointer<Utf16> KeyName, int DeleteFile) =>
          ptr.ref.vtable
                  .elementAt(16)
                  .cast<
                      Pointer<
                          NativeFunction<
                              Int32 Function(
                                  Pointer,
                                  Pointer<Utf16> ObjectStorageCLSID,
                                  Pointer<Utf16> KeyName,
                                  Int16 DeleteFile)>>>()
                  .value
                  .asFunction<
                      int Function(Pointer, Pointer<Utf16> ObjectStorageCLSID,
                          Pointer<Utf16> KeyName, int DeleteFile)>()(
              ptr.ref.lpVtbl, ObjectStorageCLSID, KeyName, DeleteFile);

  int isUISupported(Pointer<Utf16> TypeOfUI, Pointer<VARIANT> ExtraData,
          Pointer<COMObject> Object, Pointer<Int16> Supported) =>
      ptr.ref.vtable
              .elementAt(17)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<Utf16> TypeOfUI,
                              Pointer<VARIANT> ExtraData,
                              Pointer<COMObject> Object,
                              Pointer<Int16> Supported)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<Utf16> TypeOfUI,
                      Pointer<VARIANT> ExtraData,
                      Pointer<COMObject> Object,
                      Pointer<Int16> Supported)>()(
          ptr.ref.lpVtbl, TypeOfUI, ExtraData, Object, Supported);

  int displayUI(int hWnd, Pointer<Utf16> Title, Pointer<Utf16> TypeOfUI,
          Pointer<VARIANT> ExtraData, Pointer<COMObject> Object) =>
      ptr.ref.vtable
              .elementAt(18)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Int32 hWnd,
                              Pointer<Utf16> Title,
                              Pointer<Utf16> TypeOfUI,
                              Pointer<VARIANT> ExtraData,
                              Pointer<COMObject> Object)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      int hWnd,
                      Pointer<Utf16> Title,
                      Pointer<Utf16> TypeOfUI,
                      Pointer<VARIANT> ExtraData,
                      Pointer<COMObject> Object)>()(
          ptr.ref.lpVtbl, hWnd, Title, TypeOfUI, ExtraData, Object);

  int matchesAttributes(Pointer<Utf16> Attributes, Pointer<Int16> Matches) =>
      ptr.ref.vtable
              .elementAt(19)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, Pointer<Utf16> Attributes,
                              Pointer<Int16> Matches)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<Utf16> Attributes,
                      Pointer<Int16> Matches)>()(
          ptr.ref.lpVtbl, Attributes, Matches);
}
