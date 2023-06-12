// iprovideclassinfo.dart

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
const IID_IProvideClassInfo = '{B196B283-BAB4-101A-B69C-00AA00341D07}';

/// {@category Interface}
/// {@category com}
class IProvideClassInfo extends IUnknown {
  // vtable begins at 3, is 1 entries long.
  IProvideClassInfo(super.ptr);

  factory IProvideClassInfo.from(IUnknown interface) =>
      IProvideClassInfo(interface.toInterface(IID_IProvideClassInfo));

  int getClassInfo(Pointer<Pointer<COMObject>> ppTI) => ptr.ref.vtable
      .elementAt(3)
      .cast<
          Pointer<
              NativeFunction<
                  Int32 Function(Pointer, Pointer<Pointer<COMObject>> ppTI)>>>()
      .value
      .asFunction<
          int Function(Pointer,
              Pointer<Pointer<COMObject>> ppTI)>()(ptr.ref.lpVtbl, ppTI);
}
