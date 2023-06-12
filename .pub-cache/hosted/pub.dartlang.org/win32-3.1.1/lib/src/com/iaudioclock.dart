// iaudioclock.dart

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
const IID_IAudioClock = '{CD63314F-3FBA-4A1B-812C-EF96358728E7}';

/// {@category Interface}
/// {@category com}
class IAudioClock extends IUnknown {
  // vtable begins at 3, is 3 entries long.
  IAudioClock(super.ptr);

  factory IAudioClock.from(IUnknown interface) =>
      IAudioClock(interface.toInterface(IID_IAudioClock));

  int getFrequency(Pointer<Uint64> pu64Frequency) => ptr.ref.vtable
      .elementAt(3)
      .cast<
          Pointer<
              NativeFunction<
                  Int32 Function(Pointer, Pointer<Uint64> pu64Frequency)>>>()
      .value
      .asFunction<
          int Function(Pointer,
              Pointer<Uint64> pu64Frequency)>()(ptr.ref.lpVtbl, pu64Frequency);

  int getPosition(
          Pointer<Uint64> pu64Position, Pointer<Uint64> pu64QPCPosition) =>
      ptr.ref.vtable
              .elementAt(4)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, Pointer<Uint64> pu64Position,
                              Pointer<Uint64> pu64QPCPosition)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<Uint64> pu64Position,
                      Pointer<Uint64> pu64QPCPosition)>()(
          ptr.ref.lpVtbl, pu64Position, pu64QPCPosition);

  int getCharacteristics(Pointer<Uint32> pdwCharacteristics) => ptr.ref.vtable
          .elementAt(5)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Pointer<Uint32> pdwCharacteristics)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<Uint32> pdwCharacteristics)>()(
      ptr.ref.lpVtbl, pdwCharacteristics);
}
