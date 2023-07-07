// iappxmanifestproperties.dart

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
const IID_IAppxManifestProperties = '{03FAF64D-F26F-4B2C-AAF7-8FE7789B8BCA}';

/// {@category Interface}
/// {@category com}
class IAppxManifestProperties extends IUnknown {
  // vtable begins at 3, is 2 entries long.
  IAppxManifestProperties(super.ptr);

  int GetBoolValue(Pointer<Utf16> name, Pointer<Int32> value) => ptr.ref.vtable
      .elementAt(3)
      .cast<
          Pointer<
              NativeFunction<
                  Int32 Function(
                      Pointer, Pointer<Utf16> name, Pointer<Int32> value)>>>()
      .value
      .asFunction<
          int Function(Pointer, Pointer<Utf16> name,
              Pointer<Int32> value)>()(ptr.ref.lpVtbl, name, value);

  int GetStringValue(Pointer<Utf16> name, Pointer<Pointer<Utf16>> value) => ptr
      .ref.vtable
      .elementAt(4)
      .cast<
          Pointer<
              NativeFunction<
                  Int32 Function(Pointer, Pointer<Utf16> name,
                      Pointer<Pointer<Utf16>> value)>>>()
      .value
      .asFunction<
          int Function(Pointer, Pointer<Utf16> name,
              Pointer<Pointer<Utf16>> value)>()(ptr.ref.lpVtbl, name, value);
}
