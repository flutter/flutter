// notificationdata.dart

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

import 'inotificationdata.dart';
import 'inotificationdatafactory.dart';
import '../../foundation/collections/iiterable.dart';
import '../../foundation/collections/ikeyvaluepair.dart';
import '../../foundation/collections/imap.dart';
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
      IIterable<IKeyValuePair<String, String?>> initialValues,
      int sequenceNumber) {
    final activationFactory =
        CreateActivationFactory(_className, IID_INotificationDataFactory);

    try {
      return INotificationDataFactory.fromRawPointer(activationFactory)
          .createNotificationDataWithValuesAndSequenceNumber(
              initialValues, sequenceNumber);
    } finally {
      free(activationFactory);
    }
  }

  static NotificationData createNotificationDataWithValues(
      IIterable<IKeyValuePair<String, String?>> initialValues) {
    final activationFactory =
        CreateActivationFactory(_className, IID_INotificationDataFactory);

    try {
      return INotificationDataFactory.fromRawPointer(activationFactory)
          .createNotificationDataWithValues(initialValues);
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
