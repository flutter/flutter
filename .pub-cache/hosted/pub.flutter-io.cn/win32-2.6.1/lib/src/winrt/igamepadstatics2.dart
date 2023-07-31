// IGamepadStatics2.dart

// ignore_for_file: unused_import, directives_ordering, camel_case_types
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../combase.dart';
import '../constants.dart';
import '../exceptions.dart';
import '../macros.dart';
import '../ole32.dart';
import '../structs.dart';
import '../structs.g.dart';
import '../utils.dart';

import '../winrt_constants.dart';

import 'igamepadstatics.dart';

/// @nodoc
const IID_IGamepadStatics2 = '{42676DC5-0856-47C4-9213-B395504C3A3C}';

typedef _FromGameController_Native = Int32 Function(
    Pointer obj, Pointer gameController, Pointer<Pointer> result);
typedef _FromGameController_Dart = int Function(
    Pointer obj, Pointer gameController, Pointer<Pointer> result);

/// {@category Interface}
/// {@category winrt}
class IGamepadStatics2 extends IGamepadStatics {
  // vtable begins at 10, ends at 11

  IGamepadStatics2(Pointer<COMObject> ptr) : super(ptr);

  int FromGameController(Pointer gameController, Pointer<Pointer> result) =>
      Pointer<NativeFunction<_FromGameController_Native>>.fromAddress(
                  ptr.ref.vtable.elementAt(6).value)
              .asFunction<_FromGameController_Dart>()(
          ptr.ref.lpVtbl, gameController, result);
}
