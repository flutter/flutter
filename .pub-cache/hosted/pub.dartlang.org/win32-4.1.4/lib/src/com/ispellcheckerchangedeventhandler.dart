// ispellcheckerchangedeventhandler.dart

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
const IID_ISpellCheckerChangedEventHandler =
    '{0b83a5b0-792f-4eab-9799-acf52c5ed08a}';

/// Allows the caller to create a handler for notifications that the state
/// of the speller has changed.
///
/// {@category Interface}
/// {@category com}
class ISpellCheckerChangedEventHandler extends IUnknown {
  // vtable begins at 3, is 1 entries long.
  ISpellCheckerChangedEventHandler(super.ptr);

  factory ISpellCheckerChangedEventHandler.from(IUnknown interface) =>
      ISpellCheckerChangedEventHandler(
          interface.toInterface(IID_ISpellCheckerChangedEventHandler));

  int invoke(Pointer<COMObject> sender) => ptr.ref.vtable
          .elementAt(3)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<COMObject> sender)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<COMObject> sender)>()(
      ptr.ref.lpVtbl, sender);
}
