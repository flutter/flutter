// ifiledialog2.dart

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
import 'ifiledialog.dart';
import 'iunknown.dart';

/// @nodoc
const IID_IFileDialog2 = '{61744FC7-85B5-4791-A9B0-272276309B13}';

/// {@category Interface}
/// {@category com}
class IFileDialog2 extends IFileDialog {
  // vtable begins at 27, is 2 entries long.
  IFileDialog2(super.ptr);

  factory IFileDialog2.from(IUnknown interface) =>
      IFileDialog2(interface.toInterface(IID_IFileDialog2));

  int setCancelButtonLabel(Pointer<Utf16> pszLabel) => ptr.ref.vtable
          .elementAt(27)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Utf16> pszLabel)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<Utf16> pszLabel)>()(
      ptr.ref.lpVtbl, pszLabel);

  int setNavigationRoot(Pointer<COMObject> psi) => ptr.ref.vtable
          .elementAt(28)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<COMObject> psi)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<COMObject> psi)>()(
      ptr.ref.lpVtbl, psi);
}
