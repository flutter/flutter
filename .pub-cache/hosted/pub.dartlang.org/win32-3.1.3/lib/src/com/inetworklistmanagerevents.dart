// inetworklistmanagerevents.dart

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
const IID_INetworkListManagerEvents = '{dcb00001-570f-4a9b-8d69-199fdba5723b}';

/// INetworkListManagerEvents is a message sink interface that a client
/// implements to get overall machine state related events. Applications
/// that are interested on higher-level events, for example internet
/// connectivity, implement this interface.
///
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
