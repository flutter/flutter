// isupporterrorinfo.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import
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
const IID_ISupportErrorInfo = '{df0b3d60-548f-101b-8e65-08002b2bd119}';

/// Ensures that error information can be propagated up the call chain
/// correctly. Automation objects that use the error handling interfaces
/// must implement ISupportErrorInfo.
///
/// {@category Interface}
/// {@category com}
class ISupportErrorInfo extends IUnknown {
  // vtable begins at 3, is 1 entries long.
  ISupportErrorInfo(super.ptr);

  factory ISupportErrorInfo.from(IUnknown interface) =>
      ISupportErrorInfo(interface.toInterface(IID_ISupportErrorInfo));

  int interfaceSupportsErrorInfo(Pointer<GUID> riid) => ptr.ref.vtable
      .elementAt(3)
      .cast<
          Pointer<
              NativeFunction<Int32 Function(Pointer, Pointer<GUID> riid)>>>()
      .value
      .asFunction<
          int Function(Pointer, Pointer<GUID> riid)>()(ptr.ref.lpVtbl, riid);
}
