// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A description of the kind of workflow the device supports.
class Category {
  const Category._(this.value);

  static const Category web = Category._('web');
  static const Category desktop = Category._('desktop');
  static const Category mobile = Category._('mobile');

  final String value;

  @override
  String toString() => value;
}

/// The platform sub-folder that a device type supports.
class PlatformType {
  const PlatformType._(this.value);

  static const PlatformType web = PlatformType._('web');
  static const PlatformType android = PlatformType._('android');
  static const PlatformType ios = PlatformType._('ios');
  static const PlatformType linux = PlatformType._('linux');
  static const PlatformType macos = PlatformType._('macos');
  static const PlatformType windows = PlatformType._('windows');
  static const PlatformType fuchsia = PlatformType._('fuchsia');
  static const PlatformType custom = PlatformType._('custom');

  final String value;

  @override
  String toString() => value;
}
