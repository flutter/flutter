// IGamepadStatics.dart

// ignore_for_file: unused_import, directives_ordering, camel_case_types
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../com/iinspectable.dart';
import '../combase.dart';
import '../constants.dart';
import '../exceptions.dart';
import '../macros.dart';
import '../ole32.dart';
import '../structs.dart';
import '../structs.g.dart';
import '../utils.dart';
import '../winrt_constants.dart';

/// @nodoc
const IID_IGamepadStatics = '{8BBCE529-D49C-39E9-9560-E47DDE96B7C8}';

typedef _add_GamepadAdded_Native = Int32 Function(
    Pointer obj, Pointer value, Pointer<Uint32> result);
typedef _add_GamepadAdded_Dart = int Function(
    Pointer obj, Pointer value, Pointer<Uint32> result);

typedef _remove_GamepadAdded_Native = Int32 Function(Pointer obj, Uint32 token);
typedef _remove_GamepadAdded_Dart = int Function(Pointer obj, int token);

typedef _add_GamepadRemoved_Native = Int32 Function(
    Pointer obj, Pointer value, Pointer<Uint32> result);
typedef _add_GamepadRemoved_Dart = int Function(
    Pointer obj, Pointer value, Pointer<Uint32> result);

typedef _remove_GamepadRemoved_Native = Int32 Function(
    Pointer obj, Uint32 token);
typedef _remove_GamepadRemoved_Dart = int Function(Pointer obj, int token);

typedef _get_Gamepads_Native = Int32 Function(
    Pointer obj, Pointer<Pointer> value);
typedef _get_Gamepads_Dart = int Function(Pointer obj, Pointer<Pointer> value);

/// {@category Interface}
/// {@category winrt}
class IGamepadStatics extends IInspectable {
  // vtable begins at 6, ends at 10

  IGamepadStatics(super.ptr);

  int add_GamepadAdded(Pointer value, Pointer<Uint32> result) => ptr.ref.vtable
      .elementAt(6)
      .cast<Pointer<NativeFunction<_add_GamepadAdded_Native>>>()
      .value
      .asFunction<_add_GamepadAdded_Dart>()(ptr.ref.lpVtbl, value, result);

  int remove_GamepadAdded(int token) => ptr.ref.vtable
      .elementAt(7)
      .cast<Pointer<NativeFunction<_remove_GamepadAdded_Native>>>()
      .value
      .asFunction<_remove_GamepadAdded_Dart>()(ptr.ref.lpVtbl, token);

  int add_GamepadRemoved(Pointer value, Pointer<Uint32> result) => ptr
      .ref.lpVtbl.value
      .elementAt(8)
      .cast<Pointer<NativeFunction<_add_GamepadRemoved_Native>>>()
      .value
      .asFunction<_add_GamepadRemoved_Dart>()(ptr.ref.lpVtbl, value, result);

  int remove_GamepadRemoved(int token) => ptr.ref.vtable
      .elementAt(9)
      .cast<Pointer<NativeFunction<_remove_GamepadRemoved_Native>>>()
      .value
      .asFunction<_remove_GamepadRemoved_Dart>()(ptr.ref.lpVtbl, token);

  Pointer get Gamepads {
    final retValuePtr = calloc<Pointer>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(10)
          .cast<Pointer<NativeFunction<_get_Gamepads_Native>>>()
          .value
          .asFunction<_get_Gamepads_Dart>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }
}
