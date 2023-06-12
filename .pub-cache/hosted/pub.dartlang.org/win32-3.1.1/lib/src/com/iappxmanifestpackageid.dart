// iappxmanifestpackageid.dart

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
const IID_IAppxManifestPackageId = '{283CE2D7-7153-4A91-9649-7A0F7240945F}';

/// {@category Interface}
/// {@category com}
class IAppxManifestPackageId extends IUnknown {
  // vtable begins at 3, is 8 entries long.
  IAppxManifestPackageId(super.ptr);

  factory IAppxManifestPackageId.from(IUnknown interface) =>
      IAppxManifestPackageId(interface.toInterface(IID_IAppxManifestPackageId));

  int getName(Pointer<Pointer<Utf16>> name) => ptr.ref.vtable
          .elementAt(3)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Pointer<Utf16>> name)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<Pointer<Utf16>> name)>()(
      ptr.ref.lpVtbl, name);

  int getArchitecture(Pointer<Int32> architecture) => ptr.ref.vtable
          .elementAt(4)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Int32> architecture)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<Int32> architecture)>()(
      ptr.ref.lpVtbl, architecture);

  int getPublisher(Pointer<Pointer<Utf16>> publisher) => ptr.ref.vtable
          .elementAt(5)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Pointer<Pointer<Utf16>> publisher)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<Pointer<Utf16>> publisher)>()(
      ptr.ref.lpVtbl, publisher);

  int getVersion(Pointer<Uint64> packageVersion) =>
      ptr.ref.vtable
              .elementAt(6)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer, Pointer<Uint64> packageVersion)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<Uint64> packageVersion)>()(
          ptr.ref.lpVtbl, packageVersion);

  int getResourceId(Pointer<Pointer<Utf16>> resourceId) => ptr.ref.vtable
          .elementAt(7)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Pointer<Pointer<Utf16>> resourceId)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<Pointer<Utf16>> resourceId)>()(
      ptr.ref.lpVtbl, resourceId);

  int comparePublisher(Pointer<Utf16> other, Pointer<Int32> isSame) => ptr
      .ref.vtable
      .elementAt(8)
      .cast<
          Pointer<
              NativeFunction<
                  Int32 Function(
                      Pointer, Pointer<Utf16> other, Pointer<Int32> isSame)>>>()
      .value
      .asFunction<
          int Function(Pointer, Pointer<Utf16> other,
              Pointer<Int32> isSame)>()(ptr.ref.lpVtbl, other, isSame);

  int getPackageFullName(Pointer<Pointer<Utf16>> packageFullName) => ptr
          .ref.vtable
          .elementAt(9)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Pointer<Pointer<Utf16>> packageFullName)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<Pointer<Utf16>> packageFullName)>()(
      ptr.ref.lpVtbl, packageFullName);

  int getPackageFamilyName(Pointer<Pointer<Utf16>> packageFamilyName) =>
      ptr.ref.vtable
              .elementAt(10)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer,
                              Pointer<Pointer<Utf16>> packageFamilyName)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer, Pointer<Pointer<Utf16>> packageFamilyName)>()(
          ptr.ref.lpVtbl, packageFamilyName);
}
