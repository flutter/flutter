// IApplicationActivationManager.dart

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
const IID_IApplicationActivationManager =
    '{2E941141-7F97-4756-BA1D-9DECDE894A3D}';

/// {@category Interface}
/// {@category com}
class IApplicationActivationManager extends IUnknown {
  // vtable begins at 3, is 3 entries long.
  IApplicationActivationManager(Pointer<COMObject> ptr) : super(ptr);

  int ActivateApplication(
    Pointer<Utf16> appUserModelId,
    Pointer<Utf16> arguments,
    int options,
    Pointer<Uint32> processId,
  ) =>
      ptr.ref.lpVtbl.value
          .elementAt(3)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
            Pointer,
            Pointer<Utf16> appUserModelId,
            Pointer<Utf16> arguments,
            Int32 options,
            Pointer<Uint32> processId,
          )>>>()
          .value
          .asFunction<
              int Function(
            Pointer,
            Pointer<Utf16> appUserModelId,
            Pointer<Utf16> arguments,
            int options,
            Pointer<Uint32> processId,
          )>()(
        ptr.ref.lpVtbl,
        appUserModelId,
        arguments,
        options,
        processId,
      );

  int ActivateForFile(
    Pointer<Utf16> appUserModelId,
    Pointer<COMObject> itemArray,
    Pointer<Utf16> verb,
    Pointer<Uint32> processId,
  ) =>
      ptr.ref.lpVtbl.value
          .elementAt(4)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
            Pointer,
            Pointer<Utf16> appUserModelId,
            Pointer<COMObject> itemArray,
            Pointer<Utf16> verb,
            Pointer<Uint32> processId,
          )>>>()
          .value
          .asFunction<
              int Function(
            Pointer,
            Pointer<Utf16> appUserModelId,
            Pointer<COMObject> itemArray,
            Pointer<Utf16> verb,
            Pointer<Uint32> processId,
          )>()(
        ptr.ref.lpVtbl,
        appUserModelId,
        itemArray,
        verb,
        processId,
      );

  int ActivateForProtocol(
    Pointer<Utf16> appUserModelId,
    Pointer<COMObject> itemArray,
    Pointer<Uint32> processId,
  ) =>
      ptr.ref.lpVtbl.value
          .elementAt(5)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
            Pointer,
            Pointer<Utf16> appUserModelId,
            Pointer<COMObject> itemArray,
            Pointer<Uint32> processId,
          )>>>()
          .value
          .asFunction<
              int Function(
            Pointer,
            Pointer<Utf16> appUserModelId,
            Pointer<COMObject> itemArray,
            Pointer<Uint32> processId,
          )>()(
        ptr.ref.lpVtbl,
        appUserModelId,
        itemArray,
        processId,
      );
}

/// @nodoc
const CLSID_ApplicationActivationManager =
    '{45BA127D-10A8-46EA-8AB7-56EA9078943C}';

/// {@category com}
class ApplicationActivationManager extends IApplicationActivationManager {
  ApplicationActivationManager(Pointer<COMObject> ptr) : super(ptr);

  factory ApplicationActivationManager.createInstance() {
    final ptr = calloc<COMObject>();
    final clsid = calloc<GUID>()
      ..ref.setGUID(CLSID_ApplicationActivationManager);
    final iid = calloc<GUID>()..ref.setGUID(IID_IApplicationActivationManager);

    try {
      final hr = CoCreateInstance(clsid, nullptr, CLSCTX_ALL, iid, ptr.cast());

      if (FAILED(hr)) throw WindowsException(hr);

      return ApplicationActivationManager(ptr);
    } finally {
      free(clsid);
      free(iid);
    }
  }
}
