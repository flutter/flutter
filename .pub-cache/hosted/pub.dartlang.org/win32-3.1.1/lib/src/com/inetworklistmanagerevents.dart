// inetworklistmanagerevents.dart

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
const IID_INetworkListManagerEvents = '{DCB00001-570F-4A9B-8D69-199FDBA5723B}';

/// {@category Interface}
/// {@category com}
class INetworkListManagerEvents extends IUnknown {
  // vtable begins at 3, is 1 entries long.
  INetworkListManagerEvents(super.ptr);

  factory INetworkListManagerEvents.from(IUnknown interface) =>
      INetworkListManagerEvents(
          interface.toInterface(IID_INetworkListManagerEvents));

  int connectivityChanged(int newConnectivity) => ptr.ref.vtable
      .elementAt(3)
      .cast<
          Pointer<
              NativeFunction<Int32 Function(Pointer, Int32 newConnectivity)>>>()
      .value
      .asFunction<
          int Function(
              Pointer, int newConnectivity)>()(ptr.ref.lpVtbl, newConnectivity);
}
