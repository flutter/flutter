// ishelllinkdatalist.dart

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
const IID_IShellLinkDataList = '{45E2B4AE-B1C3-11D0-B92F-00A0C90312E1}';

/// {@category Interface}
/// {@category com}
class IShellLinkDataList extends IUnknown {
  // vtable begins at 3, is 5 entries long.
  IShellLinkDataList(super.ptr);

  int AddDataBlock(Pointer pDataBlock) => ptr.ref.vtable
      .elementAt(3)
      .cast<
          Pointer<
              NativeFunction<Int32 Function(Pointer, Pointer pDataBlock)>>>()
      .value
      .asFunction<
          int Function(
              Pointer, Pointer pDataBlock)>()(ptr.ref.lpVtbl, pDataBlock);

  int CopyDataBlock(int dwSig, Pointer<Pointer> ppDataBlock) => ptr.ref.vtable
          .elementAt(4)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Uint32 dwSig,
                          Pointer<Pointer> ppDataBlock)>>>()
          .value
          .asFunction<
              int Function(Pointer, int dwSig, Pointer<Pointer> ppDataBlock)>()(
      ptr.ref.lpVtbl, dwSig, ppDataBlock);

  int RemoveDataBlock(int dwSig) => ptr.ref.vtable
      .elementAt(5)
      .cast<Pointer<NativeFunction<Int32 Function(Pointer, Uint32 dwSig)>>>()
      .value
      .asFunction<int Function(Pointer, int dwSig)>()(ptr.ref.lpVtbl, dwSig);

  int GetFlags(Pointer<Uint32> pdwFlags) => ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Uint32> pdwFlags)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<Uint32> pdwFlags)>()(
      ptr.ref.lpVtbl, pdwFlags);

  int SetFlags(int dwFlags) => ptr.ref.vtable
      .elementAt(7)
      .cast<Pointer<NativeFunction<Int32 Function(Pointer, Uint32 dwFlags)>>>()
      .value
      .asFunction<
          int Function(Pointer, int dwFlags)>()(ptr.ref.lpVtbl, dwFlags);
}
