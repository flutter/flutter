// ierrorinfo.dart

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
const IID_IErrorInfo = '{1CF2B120-547D-101B-8E65-08002B2BD119}';

/// {@category Interface}
/// {@category com}
class IErrorInfo extends IUnknown {
  // vtable begins at 3, is 5 entries long.
  IErrorInfo(super.ptr);

  factory IErrorInfo.from(IUnknown interface) =>
      IErrorInfo(interface.toInterface(IID_IErrorInfo));

  int getGUID(Pointer<GUID> pGUID) => ptr.ref.vtable
      .elementAt(3)
      .cast<
          Pointer<
              NativeFunction<Int32 Function(Pointer, Pointer<GUID> pGUID)>>>()
      .value
      .asFunction<
          int Function(Pointer, Pointer<GUID> pGUID)>()(ptr.ref.lpVtbl, pGUID);

  int getSource(Pointer<Pointer<Utf16>> pBstrSource) => ptr.ref.vtable
          .elementAt(4)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Pointer<Pointer<Utf16>> pBstrSource)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<Pointer<Utf16>> pBstrSource)>()(
      ptr.ref.lpVtbl, pBstrSource);

  int getDescription(Pointer<Pointer<Utf16>> pBstrDescription) => ptr.ref.vtable
          .elementAt(5)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer,
                          Pointer<Pointer<Utf16>> pBstrDescription)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Pointer<Utf16>> pBstrDescription)>()(
      ptr.ref.lpVtbl, pBstrDescription);

  int getHelpFile(Pointer<Pointer<Utf16>> pBstrHelpFile) => ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Pointer<Pointer<Utf16>> pBstrHelpFile)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<Pointer<Utf16>> pBstrHelpFile)>()(
      ptr.ref.lpVtbl, pBstrHelpFile);

  int getHelpContext(Pointer<Uint32> pdwHelpContext) =>
      ptr.ref.vtable
              .elementAt(7)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer, Pointer<Uint32> pdwHelpContext)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<Uint32> pdwHelpContext)>()(
          ptr.ref.lpVtbl, pdwHelpContext);
}
