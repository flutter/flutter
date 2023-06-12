// iaudiorenderclient.dart

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
const IID_IAudioRenderClient = '{F294ACFC-3146-4483-A7BF-ADDCA7C260E2}';

/// {@category Interface}
/// {@category com}
class IAudioRenderClient extends IUnknown {
  // vtable begins at 3, is 2 entries long.
  IAudioRenderClient(super.ptr);

  factory IAudioRenderClient.from(IUnknown interface) =>
      IAudioRenderClient(interface.toInterface(IID_IAudioRenderClient));

  int getBuffer(int NumFramesRequested, Pointer<Pointer<Uint8>> ppData) =>
      ptr.ref.vtable
              .elementAt(3)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, Uint32 NumFramesRequested,
                              Pointer<Pointer<Uint8>> ppData)>>>()
              .value
              .asFunction<
                  int Function(Pointer, int NumFramesRequested,
                      Pointer<Pointer<Uint8>> ppData)>()(
          ptr.ref.lpVtbl, NumFramesRequested, ppData);

  int releaseBuffer(int NumFramesWritten, int dwFlags) => ptr.ref.vtable
          .elementAt(4)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Uint32 NumFramesWritten, Uint32 dwFlags)>>>()
          .value
          .asFunction<
              int Function(Pointer, int NumFramesWritten, int dwFlags)>()(
      ptr.ref.lpVtbl, NumFramesWritten, dwFlags);
}
