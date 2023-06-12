// imodalwindow.dart

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
const IID_IModalWindow = '{B4DB1657-70D7-485E-8E3E-6FCB5A5C1802}';

/// {@category Interface}
/// {@category com}
class IModalWindow extends IUnknown {
  // vtable begins at 3, is 1 entries long.
  IModalWindow(super.ptr);

  factory IModalWindow.from(IUnknown interface) =>
      IModalWindow(interface.toInterface(IID_IModalWindow));

  int show(int hwndOwner) => ptr.ref.vtable
      .elementAt(3)
      .cast<
          Pointer<NativeFunction<Int32 Function(Pointer, IntPtr hwndOwner)>>>()
      .value
      .asFunction<
          int Function(Pointer, int hwndOwner)>()(ptr.ref.lpVtbl, hwndOwner);
}
