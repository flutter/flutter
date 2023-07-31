// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An enum of all operating systems supported by Dart.
///
/// This is used for selecting which operating systems a test can run on. Even
/// for browser tests, this indicates the operating system of the machine
/// running the test runner.
class OperatingSystem {
  /// Microsoft Windows.
  static const windows = OperatingSystem._('Windows', 'windows');

  /// Mac OS X.
  static const macOS = OperatingSystem._('OS X', 'mac-os');

  /// GNU/Linux.
  static const linux = OperatingSystem._('Linux', 'linux');

  /// Android.
  ///
  /// Since this is the operating system the test runner is running on, this
  /// won't be true when testing remotely on an Android browser.
  static const android = OperatingSystem._('Android', 'android');

  /// iOS.
  ///
  /// Since this is the operating system the test runner is running on, this
  /// won't be true when testing remotely on an iOS browser.
  static const iOS = OperatingSystem._('iOS', 'ios');

  /// No operating system.
  ///
  /// This is used when running in the browser, or if an unrecognized operating
  /// system is used. It can't be referenced by name in platform selectors.
  static const none = OperatingSystem._('none', 'none');

  /// A list of all instances of [OperatingSystem] other than [none].
  static const all = [windows, macOS, linux, android, iOS];

  /// Finds an operating system by its name.
  ///
  /// If no operating system is found, returns [none].
  static OperatingSystem find(String identifier) =>
      all.firstWhere((platform) => platform.identifier == identifier,
          orElse: () => none);

  /// Finds an operating system by the return value from `dart:io`'s
  /// `Platform.operatingSystem`.
  ///
  /// If no operating system is found, returns [none].
  static OperatingSystem findByIoName(String name) {
    switch (name) {
      case 'windows':
        return windows;
      case 'macos':
        return macOS;
      case 'linux':
        return linux;
      case 'android':
        return android;
      case 'ios':
        return iOS;
      default:
        return none;
    }
  }

  /// The human-friendly of the operating system.
  final String name;

  /// The identifier used to look up the operating system.
  final String identifier;

  /// Whether this is a POSIX-ish operating system.
  bool get isPosix => this != windows && this != none;

  const OperatingSystem._(this.name, this.identifier);

  @override
  String toString() => name;
}
