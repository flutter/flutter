// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart representations of common enumerations used in the Windows Runtime APIs.

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: constant_identifier_names

import '../../foundation/winrt_enum.dart';

/// Indicates the type of devices that the user wants to enumerate.
///
/// {@category Enum}
enum DeviceClass implements WinRTEnum {
  all(0),
  audioCapture(1),
  audioRender(2),
  portableStorageDevice(3),
  videoCapture(4),
  imageScanner(5),
  location(6);

  @override
  final int value;

  const DeviceClass(this.value);

  factory DeviceClass.from(int value) =>
      DeviceClass.values.firstWhere((e) => e.value == value,
          orElse: () => throw ArgumentError.value(
              value, 'value', 'No enum value with that value'));
}

/// Indicates what you'd like the device picker to show about a given
/// device. Used with the SetDisplayStatus method on the DevicePicker
/// object.
///
/// {@category Enum}
class DevicePickerDisplayStatusOptions extends WinRTEnum {
  const DevicePickerDisplayStatusOptions(super.value, {super.name});

  factory DevicePickerDisplayStatusOptions.from(int value) =>
      DevicePickerDisplayStatusOptions.values.firstWhere(
          (e) => e.value == value,
          orElse: () => DevicePickerDisplayStatusOptions(value));

  static const none = DevicePickerDisplayStatusOptions(0, name: 'none');
  static const showProgress =
      DevicePickerDisplayStatusOptions(1, name: 'showProgress');
  static const showDisconnectButton =
      DevicePickerDisplayStatusOptions(2, name: 'showDisconnectButton');
  static const showRetryButton =
      DevicePickerDisplayStatusOptions(4, name: 'showRetryButton');

  static const List<DevicePickerDisplayStatusOptions> values = [
    none,
    showProgress,
    showDisconnectButton,
    showRetryButton
  ];

  DevicePickerDisplayStatusOptions operator &(
          DevicePickerDisplayStatusOptions other) =>
      DevicePickerDisplayStatusOptions(value & other.value);

  DevicePickerDisplayStatusOptions operator |(
          DevicePickerDisplayStatusOptions other) =>
      DevicePickerDisplayStatusOptions(value | other.value);

  /// Determines whether one or more bit fields are set in the current enum
  /// value.
  ///
  /// ```dart
  /// final fileAttributes = FileAttributes.readOnly | FileAttributes.archive;
  /// fileAttributes.hasFlag(FileAttributes.readOnly)); // `true`
  /// fileAttributes.hasFlag(FileAttributes.temporary)); // `false`
  /// fileAttributes.hasFlag(
  ///     FileAttributes.readOnly | FileAttributes.archive)); // `true`
  /// ```
  bool hasFlag(DevicePickerDisplayStatusOptions flag) {
    if (value != 0 && flag.value == 0) return false;
    return value & flag.value == flag.value;
  }
}
