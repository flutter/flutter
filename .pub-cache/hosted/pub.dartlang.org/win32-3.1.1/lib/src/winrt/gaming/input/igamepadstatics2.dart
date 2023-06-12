// igamepadstatics2.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import, directives_ordering
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../../combase.dart';
import '../../../exceptions.dart';
import '../../../macros.dart';
import '../../../utils.dart';
import '../../../types.dart';
import '../../../win32/api_ms_win_core_winrt_string_l1_1_0.g.dart';
import '../../../winrt_callbacks.dart';
import '../../../winrt_helpers.dart';

import '../../internal/hstring_array.dart';

import 'igamepadstatics.dart';
import 'igamecontroller.dart';
import 'gamepad.dart';
import '../../foundation/collections/ivectorview.dart';
import '../../../com/iinspectable.dart';

/// @nodoc
const IID_IGamepadStatics2 = '{42676DC5-0856-47C4-9213-B395504C3A3C}';

/// {@category Interface}
/// {@category winrt}
class IGamepadStatics2 extends IInspectable implements IGamepadStatics {
  // vtable begins at 6, is 1 entries long.
  IGamepadStatics2.fromRawPointer(super.ptr);

  factory IGamepadStatics2.from(IInspectable interface) =>
      IGamepadStatics2.fromRawPointer(
          interface.toInterface(IID_IGamepadStatics2));

  Gamepad fromGameController(IGameController gameController) {
    final retValuePtr = calloc<COMObject>();

    final hr =
        ptr.ref.vtable
                .elementAt(6)
                .cast<
                    Pointer<
                        NativeFunction<
                            HRESULT Function(
                                Pointer,
                                Pointer<COMObject> gameController,
                                Pointer<COMObject>)>>>()
                .value
                .asFunction<
                    int Function(Pointer, Pointer<COMObject> gameController,
                        Pointer<COMObject>)>()(ptr.ref.lpVtbl,
            gameController.ptr.cast<Pointer<COMObject>>().value, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }

    return Gamepad.fromRawPointer(retValuePtr);
  }

  // IGamepadStatics methods
  late final _iGamepadStatics = IGamepadStatics.from(this);

  @override
  int add_GamepadAdded(Pointer<NativeFunction<EventHandler>> value) =>
      _iGamepadStatics.add_GamepadAdded(value);

  @override
  void remove_GamepadAdded(int token) =>
      _iGamepadStatics.remove_GamepadAdded(token);

  @override
  int add_GamepadRemoved(Pointer<NativeFunction<EventHandler>> value) =>
      _iGamepadStatics.add_GamepadRemoved(value);

  @override
  void remove_GamepadRemoved(int token) =>
      _iGamepadStatics.remove_GamepadRemoved(token);

  @override
  List<Gamepad> get gamepads => _iGamepadStatics.gamepads;
}
