// itoastnotificationfactory.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import, directives_ordering
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../api_ms_win_core_winrt_string_l1_1_0.dart';
import '../combase.dart';
import '../exceptions.dart';
import '../macros.dart';
import '../utils.dart';
import '../types.dart';
import '../winrt_helpers.dart';

import '../extensions/hstring_array.dart';
import 'ivector.dart';
import 'ivectorview.dart';

import '../com/iinspectable.dart';

/// @nodoc
const IID_IToastNotificationFactory = '{04124B20-82C6-4229-B109-FD9ED4662B53}';

/// {@category Interface}
/// {@category winrt}
class IToastNotificationFactory extends IInspectable {
  // vtable begins at 6, is 1 entries long.
  IToastNotificationFactory(super.ptr);

  late final Pointer<COMObject> _thisPtr =
      toInterface(IID_IToastNotificationFactory);

  Pointer<COMObject> CreateToastNotification(Pointer<COMObject> content) {
    final retValuePtr = calloc<COMObject>();

    final hr = _thisPtr.ref.vtable
            .elementAt(6)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<COMObject> content,
                            Pointer<COMObject>)>>>()
            .value
            .asFunction<
                int Function(
                    Pointer, Pointer<COMObject> content, Pointer<COMObject>)>()(
        _thisPtr.ref.lpVtbl,
        content.cast<Pointer<COMObject>>().value,
        retValuePtr);

    if (FAILED(hr)) throw WindowsException(hr);

    return retValuePtr;
  }
}
