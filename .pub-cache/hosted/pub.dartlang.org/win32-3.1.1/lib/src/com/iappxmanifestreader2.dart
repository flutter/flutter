// iappxmanifestreader2.dart

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
import 'iappxmanifestreader.dart';
import 'iunknown.dart';

/// @nodoc
const IID_IAppxManifestReader2 = '{D06F67BC-B31D-4EBA-A8AF-638E73E77B4D}';

/// {@category Interface}
/// {@category com}
class IAppxManifestReader2 extends IAppxManifestReader {
  // vtable begins at 12, is 1 entries long.
  IAppxManifestReader2(super.ptr);

  factory IAppxManifestReader2.from(IUnknown interface) =>
      IAppxManifestReader2(interface.toInterface(IID_IAppxManifestReader2));

  int getQualifiedResources(Pointer<Pointer<COMObject>> resources) => ptr
          .ref.vtable
          .elementAt(12)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Pointer<Pointer<COMObject>> resources)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<Pointer<COMObject>> resources)>()(
      ptr.ref.lpVtbl, resources);
}
