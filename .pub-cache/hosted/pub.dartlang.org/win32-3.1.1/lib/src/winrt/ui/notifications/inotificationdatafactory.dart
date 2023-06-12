// inotificationdatafactory.dart

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

import '../../foundation/collections/iiterable.dart';
import '../../foundation/collections/ikeyvaluepair.dart';
import 'notificationdata.dart';
import '../../../com/iinspectable.dart';

/// @nodoc
const IID_INotificationDataFactory = '{23C1E33A-1C10-46FB-8040-DEC384621CF8}';

/// {@category Interface}
/// {@category winrt}
class INotificationDataFactory extends IInspectable {
  // vtable begins at 6, is 2 entries long.
  INotificationDataFactory.fromRawPointer(super.ptr);

  factory INotificationDataFactory.from(IInspectable interface) =>
      INotificationDataFactory.fromRawPointer(
          interface.toInterface(IID_INotificationDataFactory));

  NotificationData createNotificationDataWithValuesAndSequenceNumber(
      IIterable<IKeyValuePair<String, String?>> initialValues,
      int sequenceNumber) {
    final retValuePtr = calloc<COMObject>();

    final hr =
        ptr.ref.vtable
                .elementAt(6)
                .cast<
                    Pointer<
                        NativeFunction<
                            HRESULT Function(
                                Pointer,
                                Pointer<COMObject> initialValues,
                                Uint32 sequenceNumber,
                                Pointer<COMObject>)>>>()
                .value
                .asFunction<
                    int Function(Pointer, Pointer<COMObject> initialValues,
                        int sequenceNumber, Pointer<COMObject>)>()(
            ptr.ref.lpVtbl,
            initialValues.ptr.cast<Pointer<COMObject>>().value,
            sequenceNumber,
            retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }

    return NotificationData.fromRawPointer(retValuePtr);
  }

  NotificationData createNotificationDataWithValues(
      IIterable<IKeyValuePair<String, String?>> initialValues) {
    final retValuePtr = calloc<COMObject>();

    final hr =
        ptr.ref.vtable
                .elementAt(7)
                .cast<
                    Pointer<
                        NativeFunction<
                            HRESULT Function(
                                Pointer,
                                Pointer<COMObject> initialValues,
                                Pointer<COMObject>)>>>()
                .value
                .asFunction<
                    int Function(Pointer, Pointer<COMObject> initialValues,
                        Pointer<COMObject>)>()(ptr.ref.lpVtbl,
            initialValues.ptr.cast<Pointer<COMObject>>().value, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }

    return NotificationData.fromRawPointer(retValuePtr);
  }
}
