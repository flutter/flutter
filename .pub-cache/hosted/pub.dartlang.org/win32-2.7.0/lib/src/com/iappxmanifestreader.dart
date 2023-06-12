// iappxmanifestreader.dart

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
const IID_IAppxManifestReader = '{4E1BD148-55A0-4480-A3D1-15544710637C}';

/// {@category Interface}
/// {@category com}
class IAppxManifestReader extends IUnknown {
  // vtable begins at 3, is 9 entries long.
  IAppxManifestReader(super.ptr);

  int GetPackageId(Pointer<Pointer<COMObject>> packageId) => ptr.ref.vtable
          .elementAt(3)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Pointer<Pointer<COMObject>> packageId)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<Pointer<COMObject>> packageId)>()(
      ptr.ref.lpVtbl, packageId);

  int GetProperties(Pointer<Pointer<COMObject>> packageProperties) => ptr
          .ref.vtable
          .elementAt(4)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer,
                          Pointer<Pointer<COMObject>> packageProperties)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Pointer<COMObject>> packageProperties)>()(
      ptr.ref.lpVtbl, packageProperties);

  int GetPackageDependencies(Pointer<Pointer<COMObject>> dependencies) => ptr
          .ref.vtable
          .elementAt(5)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer,
                          Pointer<Pointer<COMObject>> dependencies)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Pointer<COMObject>> dependencies)>()(
      ptr.ref.lpVtbl, dependencies);

  int GetCapabilities(Pointer<Uint32> capabilities) => ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Uint32> capabilities)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<Uint32> capabilities)>()(
      ptr.ref.lpVtbl, capabilities);

  int GetResources(Pointer<Pointer<COMObject>> resources) => ptr.ref.vtable
          .elementAt(7)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Pointer<Pointer<COMObject>> resources)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<Pointer<COMObject>> resources)>()(
      ptr.ref.lpVtbl, resources);

  int
      GetDeviceCapabilities(Pointer<Pointer<COMObject>> deviceCapabilities) =>
          ptr.ref.vtable
                  .elementAt(8)
                  .cast<
                      Pointer<
                          NativeFunction<
                              Int32 Function(
                                  Pointer,
                                  Pointer<Pointer<COMObject>>
                                      deviceCapabilities)>>>()
                  .value
                  .asFunction<
                      int Function(Pointer,
                          Pointer<Pointer<COMObject>> deviceCapabilities)>()(
              ptr.ref.lpVtbl, deviceCapabilities);

  int GetPrerequisite(Pointer<Utf16> name, Pointer<Uint64> value) => ptr
      .ref.vtable
      .elementAt(9)
      .cast<
          Pointer<
              NativeFunction<
                  Int32 Function(
                      Pointer, Pointer<Utf16> name, Pointer<Uint64> value)>>>()
      .value
      .asFunction<
          int Function(Pointer, Pointer<Utf16> name,
              Pointer<Uint64> value)>()(ptr.ref.lpVtbl, name, value);

  int GetApplications(Pointer<Pointer<COMObject>> applications) =>
      ptr.ref.vtable
              .elementAt(10)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer,
                              Pointer<Pointer<COMObject>> applications)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer, Pointer<Pointer<COMObject>> applications)>()(
          ptr.ref.lpVtbl, applications);

  int GetStream(Pointer<Pointer<COMObject>> manifestStream) => ptr.ref.vtable
          .elementAt(11)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer,
                          Pointer<Pointer<COMObject>> manifestStream)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Pointer<COMObject>> manifestStream)>()(
      ptr.ref.lpVtbl, manifestStream);
}
