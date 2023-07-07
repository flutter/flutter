// notificationdata.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import, directives_ordering
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../../api_ms_win_core_winrt_string_l1_1_0.dart';
import '../../../combase.dart';
import '../../../exceptions.dart';
import '../../../macros.dart';
import '../../../utils.dart';
import '../../../types.dart';
import '../../../winrt_callbacks.dart';
import '../../../winrt_helpers.dart';

import '../../../winrt/internal/hstring_array.dart';

import '../../../winrt/ui/notifications/inotificationdata.dart';
import 'inotificationdatafactory.dart';
import '../../../winrt/foundation/collections/iiterable.dart';
import '../../../winrt/foundation/collections/ikeyvaluepair.dart';
import '../../../winrt/foundation/collections/imap.dart';
import '../../../com/iinspectable.dart';

/// {@category Class}
/// {@category winrt}
class NotificationData extends IInspectable implements INotificationData {
  NotificationData({Allocator allocator = calloc})
      : super(ActivateClass(_className, allocator: allocator));
  NotificationData.fromRawPointer(super.ptr);

  static const _className = 'Windows.UI.Notifications.NotificationData';

  // INotificationDataFactory methods
  static NotificationData createNotificationDataWithValuesAndSequenceNumber(
      Pointer<COMObject> initialValues, int sequenceNumber) {
    final activationFactory =
        CreateActivationFactory(_className, IID_INotificationDataFactory);

    try {
      final result = INotificationDataFactory.fromRawPointer(activationFactory)
          .createNotificationDataWithValuesAndSequenceNumber(
              initialValues, sequenceNumber);
      return NotificationData.fromRawPointer(result);
    } finally {
      free(activationFactory);
    }
  }

  static NotificationData createNotificationDataWithValues(
      Pointer<COMObject> initialValues) {
    final activationFactory =
        CreateActivationFactory(_className, IID_INotificationDataFactory);

    try {
      final result = INotificationDataFactory.fromRawPointer(activationFactory)
          .createNotificationDataWithValues(initialValues);
      return NotificationData.fromRawPointer(result);
    } finally {
      free(activationFactory);
    }
  }

  // INotificationData methods
  late final _iNotificationData = INotificationData.from(this);

  @override
  IMap<String, String?> get values => _iNotificationData.values;

  @override
  int get sequenceNumber => _iNotificationData.sequenceNumber;

  @override
  set sequenceNumber(int value) => _iNotificationData.sequenceNumber = value;
}
