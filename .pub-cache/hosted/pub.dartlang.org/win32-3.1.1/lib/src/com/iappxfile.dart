// iappxfile.dart

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
const IID_IAppxFile = '{91DF827B-94FD-468F-827B-57F41B2F6F2E}';

/// {@category Interface}
/// {@category com}
class IAppxFile extends IUnknown {
  // vtable begins at 3, is 5 entries long.
  IAppxFile(super.ptr);

  factory IAppxFile.from(IUnknown interface) =>
      IAppxFile(interface.toInterface(IID_IAppxFile));

  int getCompressionOption(Pointer<Int32> compressionOption) =>
      ptr.ref.vtable
              .elementAt(3)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer, Pointer<Int32> compressionOption)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<Int32> compressionOption)>()(
          ptr.ref.lpVtbl, compressionOption);

  int getContentType(Pointer<Pointer<Utf16>> contentType) => ptr.ref.vtable
          .elementAt(4)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Pointer<Pointer<Utf16>> contentType)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<Pointer<Utf16>> contentType)>()(
      ptr.ref.lpVtbl, contentType);

  int getName(Pointer<Pointer<Utf16>> fileName) => ptr.ref.vtable
      .elementAt(5)
      .cast<
          Pointer<
              NativeFunction<
                  Int32 Function(Pointer, Pointer<Pointer<Utf16>> fileName)>>>()
      .value
      .asFunction<
          int Function(Pointer,
              Pointer<Pointer<Utf16>> fileName)>()(ptr.ref.lpVtbl, fileName);

  int getSize(Pointer<Uint64> size) => ptr.ref.vtable
      .elementAt(6)
      .cast<
          Pointer<
              NativeFunction<Int32 Function(Pointer, Pointer<Uint64> size)>>>()
      .value
      .asFunction<
          int Function(Pointer, Pointer<Uint64> size)>()(ptr.ref.lpVtbl, size);

  int getStream(Pointer<Pointer<COMObject>> stream) => ptr.ref.vtable
          .elementAt(7)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Pointer<Pointer<COMObject>> stream)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<Pointer<COMObject>> stream)>()(
      ptr.ref.lpVtbl, stream);
}
