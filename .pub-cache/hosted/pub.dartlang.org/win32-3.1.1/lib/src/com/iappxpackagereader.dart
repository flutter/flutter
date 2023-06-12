// iappxpackagereader.dart

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
const IID_IAppxPackageReader = '{B5C49650-99BC-481C-9A34-3D53A4106708}';

/// {@category Interface}
/// {@category com}
class IAppxPackageReader extends IUnknown {
  // vtable begins at 3, is 5 entries long.
  IAppxPackageReader(super.ptr);

  factory IAppxPackageReader.from(IUnknown interface) =>
      IAppxPackageReader(interface.toInterface(IID_IAppxPackageReader));

  int getBlockMap(Pointer<Pointer<COMObject>> blockMapReader) => ptr.ref.vtable
          .elementAt(3)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer,
                          Pointer<Pointer<COMObject>> blockMapReader)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Pointer<COMObject>> blockMapReader)>()(
      ptr.ref.lpVtbl, blockMapReader);

  int getFootprintFile(int type, Pointer<Pointer<COMObject>> file) => ptr
      .ref.vtable
      .elementAt(4)
      .cast<
          Pointer<
              NativeFunction<
                  Int32 Function(Pointer, Int32 type,
                      Pointer<Pointer<COMObject>> file)>>>()
      .value
      .asFunction<
          int Function(Pointer, int type,
              Pointer<Pointer<COMObject>> file)>()(ptr.ref.lpVtbl, type, file);

  int getPayloadFile(
          Pointer<Utf16> fileName, Pointer<Pointer<COMObject>> file) =>
      ptr.ref.vtable
              .elementAt(5)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, Pointer<Utf16> fileName,
                              Pointer<Pointer<COMObject>> file)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<Utf16> fileName,
                      Pointer<Pointer<COMObject>> file)>()(
          ptr.ref.lpVtbl, fileName, file);

  int getPayloadFiles(Pointer<Pointer<COMObject>> filesEnumerator) => ptr
          .ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer,
                          Pointer<Pointer<COMObject>> filesEnumerator)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Pointer<COMObject>> filesEnumerator)>()(
      ptr.ref.lpVtbl, filesEnumerator);

  int getManifest(Pointer<Pointer<COMObject>> manifestReader) => ptr.ref.vtable
          .elementAt(7)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer,
                          Pointer<Pointer<COMObject>> manifestReader)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Pointer<COMObject>> manifestReader)>()(
      ptr.ref.lpVtbl, manifestReader);
}
