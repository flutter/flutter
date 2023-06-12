// iappxfactory.dart

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
const IID_IAppxFactory = '{beb94909-e451-438b-b5a7-d79e767b75d8}';

/// {@category Interface}
/// {@category com}
class IAppxFactory extends IUnknown {
  // vtable begins at 3, is 5 entries long.
  IAppxFactory(super.ptr);

  factory IAppxFactory.from(IUnknown interface) =>
      IAppxFactory(interface.toInterface(IID_IAppxFactory));

  int createPackageWriter(
          Pointer<COMObject> outputStream,
          Pointer<APPX_PACKAGE_SETTINGS> settings,
          Pointer<Pointer<COMObject>> packageWriter) =>
      ptr.ref.vtable
              .elementAt(3)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<COMObject> outputStream,
                              Pointer<APPX_PACKAGE_SETTINGS> settings,
                              Pointer<Pointer<COMObject>> packageWriter)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<COMObject> outputStream,
                      Pointer<APPX_PACKAGE_SETTINGS> settings,
                      Pointer<Pointer<COMObject>> packageWriter)>()(
          ptr.ref.lpVtbl, outputStream, settings, packageWriter);

  int createPackageReader(Pointer<COMObject> inputStream,
          Pointer<Pointer<COMObject>> packageReader) =>
      ptr.ref.vtable
              .elementAt(4)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, Pointer<COMObject> inputStream,
                              Pointer<Pointer<COMObject>> packageReader)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<COMObject> inputStream,
                      Pointer<Pointer<COMObject>> packageReader)>()(
          ptr.ref.lpVtbl, inputStream, packageReader);

  int createManifestReader(Pointer<COMObject> inputStream,
          Pointer<Pointer<COMObject>> manifestReader) =>
      ptr.ref.vtable
              .elementAt(5)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, Pointer<COMObject> inputStream,
                              Pointer<Pointer<COMObject>> manifestReader)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<COMObject> inputStream,
                      Pointer<Pointer<COMObject>> manifestReader)>()(
          ptr.ref.lpVtbl, inputStream, manifestReader);

  int createBlockMapReader(Pointer<COMObject> inputStream,
          Pointer<Pointer<COMObject>> blockMapReader) =>
      ptr.ref.vtable
              .elementAt(6)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, Pointer<COMObject> inputStream,
                              Pointer<Pointer<COMObject>> blockMapReader)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<COMObject> inputStream,
                      Pointer<Pointer<COMObject>> blockMapReader)>()(
          ptr.ref.lpVtbl, inputStream, blockMapReader);

  int createValidatedBlockMapReader(
          Pointer<COMObject> blockMapStream,
          Pointer<Utf16> signatureFileName,
          Pointer<Pointer<COMObject>> blockMapReader) =>
      ptr.ref.vtable
              .elementAt(7)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<COMObject> blockMapStream,
                              Pointer<Utf16> signatureFileName,
                              Pointer<Pointer<COMObject>> blockMapReader)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<COMObject> blockMapStream,
                      Pointer<Utf16> signatureFileName,
                      Pointer<Pointer<COMObject>> blockMapReader)>()(
          ptr.ref.lpVtbl, blockMapStream, signatureFileName, blockMapReader);
}

/// @nodoc
const CLSID_AppxFactory = '{5842a140-ff9f-4166-8f5c-62f5b7b0c781}';

/// {@category com}
class AppxFactory extends IAppxFactory {
  AppxFactory(super.ptr);

  factory AppxFactory.createInstance() =>
      AppxFactory(COMObject.createFromID(CLSID_AppxFactory, IID_IAppxFactory));
}
