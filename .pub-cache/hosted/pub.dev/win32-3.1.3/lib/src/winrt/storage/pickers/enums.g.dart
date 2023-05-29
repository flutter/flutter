// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart representations of common enumerations used in the Windows Runtime APIs.

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: constant_identifier_names

import '../../foundation/winrt_enum.dart';

/// Identifies the storage location that the file picker presents to the
/// user.
///
/// {@category Enum}
enum PickerLocationId implements WinRTEnum {
  documentsLibrary(0),
  computerFolder(1),
  desktop(2),
  downloads(3),
  homeGroup(4),
  musicLibrary(5),
  picturesLibrary(6),
  videosLibrary(7),
  objects3D(8),
  unspecified(9);

  @override
  final int value;

  const PickerLocationId(this.value);

  factory PickerLocationId.from(int value) =>
      PickerLocationId.values.firstWhere((e) => e.value == value,
          orElse: () => throw ArgumentError.value(
              value, 'value', 'No enum value with that value'));
}

/// Indicates the view mode that the file picker is using to present items.
///
/// {@category Enum}
enum PickerViewMode implements WinRTEnum {
  list(0),
  thumbnail(1);

  @override
  final int value;

  const PickerViewMode(this.value);

  factory PickerViewMode.from(int value) =>
      PickerViewMode.values.firstWhere((e) => e.value == value,
          orElse: () => throw ArgumentError.value(
              value, 'value', 'No enum value with that value'));
}
