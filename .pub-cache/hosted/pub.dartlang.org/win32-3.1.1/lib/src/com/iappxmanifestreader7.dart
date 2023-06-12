// iappxmanifestreader7.dart

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
const IID_IAppxManifestReader7 = '{8EFE6F27-0CE0-4988-B32D-738EB63DB3B7}';

/// {@category Interface}
/// {@category com}
class IAppxManifestReader7 extends IUnknown {
  // vtable begins at 3, is 3 entries long.
  IAppxManifestReader7(super.ptr);

  factory IAppxManifestReader7.from(IUnknown interface) =>
      IAppxManifestReader7(interface.toInterface(IID_IAppxManifestReader7));

  int
      getDriverDependencies(Pointer<Pointer<COMObject>> driverDependencies) =>
          ptr.ref.vtable
                  .elementAt(3)
                  .cast<
                      Pointer<
                          NativeFunction<
                              Int32 Function(
                                  Pointer,
                                  Pointer<Pointer<COMObject>>
                                      driverDependencies)>>>()
                  .value
                  .asFunction<
                      int Function(Pointer,
                          Pointer<Pointer<COMObject>> driverDependencies)>()(
              ptr.ref.lpVtbl, driverDependencies);

  int getOSPackageDependencies(
          Pointer<Pointer<COMObject>> osPackageDependencies) =>
      ptr
              .ref.vtable
              .elementAt(4)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<Pointer<COMObject>>
                                  osPackageDependencies)>>>()
              .value
              .asFunction<
                  int Function(Pointer,
                      Pointer<Pointer<COMObject>> osPackageDependencies)>()(
          ptr.ref.lpVtbl, osPackageDependencies);

  int getHostRuntimeDependencies(
          Pointer<Pointer<COMObject>> hostRuntimeDependencies) =>
      ptr.ref.vtable
              .elementAt(5)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<Pointer<COMObject>>
                                  hostRuntimeDependencies)>>>()
              .value
              .asFunction<
                  int Function(Pointer,
                      Pointer<Pointer<COMObject>> hostRuntimeDependencies)>()(
          ptr.ref.lpVtbl, hostRuntimeDependencies);
}
