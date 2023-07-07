// toastnotification.dart

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

import '../../../winrt/ui/notifications/itoastnotification.dart';
import '../../../winrt/ui/notifications/itoastnotification2.dart';
import '../../../winrt/ui/notifications/itoastnotification3.dart';
import '../../../winrt/ui/notifications/itoastnotification4.dart';
import '../../../winrt/ui/notifications/itoastnotification6.dart';
import 'itoastnotificationfactory.dart';
import '../../../winrt/data/xml/dom/xmldocument.dart';
import '../../../winrt/foundation/ireference.dart';
import '../../../winrt/ui/notifications/toastdismissedeventargs.dart';
import '../../../winrt/ui/notifications/toastfailedeventargs.dart';
import '../../../winrt/ui/notifications/enums.g.dart';
import '../../../winrt/ui/notifications/notificationdata.dart';
import '../../../com/iinspectable.dart';

/// {@category Class}
/// {@category winrt}
class ToastNotification extends IInspectable
    implements
        IToastNotification,
        IToastNotification2,
        IToastNotification3,
        IToastNotification4,
        IToastNotification6 {
  ToastNotification.fromRawPointer(super.ptr);

  static const _className = 'Windows.UI.Notifications.ToastNotification';

  // IToastNotificationFactory methods
  static ToastNotification createToastNotification(Pointer<COMObject> content) {
    final activationFactory =
        CreateActivationFactory(_className, IID_IToastNotificationFactory);

    try {
      final result = IToastNotificationFactory.fromRawPointer(activationFactory)
          .createToastNotification(content);
      return ToastNotification.fromRawPointer(result);
    } finally {
      free(activationFactory);
    }
  }

  // IToastNotification methods
  late final _iToastNotification = IToastNotification.from(this);

  @override
  Pointer<COMObject> get content => _iToastNotification.content;

  @override
  set expirationTime(DateTime? value) =>
      _iToastNotification.expirationTime = value;

  @override
  DateTime? get expirationTime => _iToastNotification.expirationTime;

  @override
  int add_Dismissed(Pointer<NativeFunction<TypedEventHandler>> handler) =>
      _iToastNotification.add_Dismissed(handler);

  @override
  void remove_Dismissed(int token) =>
      _iToastNotification.remove_Dismissed(token);

  @override
  int add_Activated(Pointer<NativeFunction<TypedEventHandler>> handler) =>
      _iToastNotification.add_Activated(handler);

  @override
  void remove_Activated(int token) =>
      _iToastNotification.remove_Activated(token);

  @override
  int add_Failed(Pointer<NativeFunction<TypedEventHandler>> handler) =>
      _iToastNotification.add_Failed(handler);

  @override
  void remove_Failed(int token) => _iToastNotification.remove_Failed(token);
  // IToastNotification2 methods
  late final _iToastNotification2 = IToastNotification2.from(this);

  @override
  set tag(String value) => _iToastNotification2.tag = value;

  @override
  String get tag => _iToastNotification2.tag;

  @override
  set group(String value) => _iToastNotification2.group = value;

  @override
  String get group => _iToastNotification2.group;

  @override
  set suppressPopup(bool value) => _iToastNotification2.suppressPopup = value;

  @override
  bool get suppressPopup => _iToastNotification2.suppressPopup;
  // IToastNotification3 methods
  late final _iToastNotification3 = IToastNotification3.from(this);

  @override
  NotificationMirroring get notificationMirroring =>
      _iToastNotification3.notificationMirroring;

  @override
  set notificationMirroring(NotificationMirroring value) =>
      _iToastNotification3.notificationMirroring = value;

  @override
  String get remoteId => _iToastNotification3.remoteId;

  @override
  set remoteId(String value) => _iToastNotification3.remoteId = value;
  // IToastNotification4 methods
  late final _iToastNotification4 = IToastNotification4.from(this);

  @override
  Pointer<COMObject> get data => _iToastNotification4.data;

  @override
  set data(Pointer<COMObject> value) => _iToastNotification4.data = value;

  @override
  ToastNotificationPriority get priority => _iToastNotification4.priority;

  @override
  set priority(ToastNotificationPriority value) =>
      _iToastNotification4.priority = value;
  // IToastNotification6 methods
  late final _iToastNotification6 = IToastNotification6.from(this);

  @override
  bool get expiresOnReboot => _iToastNotification6.expiresOnReboot;

  @override
  set expiresOnReboot(bool value) =>
      _iToastNotification6.expiresOnReboot = value;
}
