// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

/// Provides API parity with the `Platform` class in `dart:io`, but using
/// instance properties rather than static properties. This difference enables
/// the use of these APIs in tests, where you can provide mock implementations.
abstract class Platform {
  /// Creates a new [Platform].
  const Platform();

  /// A string constant to compare with [operatingSystem] to see if the platform
  /// is Linux.
  ///
  /// Useful in case statements when switching on [operatingSystem].
  ///
  /// To just check if the platform is Linux, use [isLinux].
  static const String linux = 'linux';

  /// A string constant to compare with [operatingSystem] to see if the platform
  /// is Windows.
  ///
  /// Useful in case statements when switching on [operatingSystem].
  ///
  /// To just check if the platform is Windows, use [isWindows].
  static const String windows = 'windows';

  /// A string constant to compare with [operatingSystem] to see if the platform
  /// is macOS.
  ///
  /// Useful in case statements when switching on [operatingSystem].
  ///
  /// To just check if the platform is macOS, use [isMacOS].
  static const String macOS = 'macos';

  /// A string constant to compare with [operatingSystem] to see if the platform
  /// is Android.
  ///
  /// Useful in case statements when switching on [operatingSystem].
  ///
  /// To just check if the platform is Android, use [isAndroid].
  static const String android = 'android';

  /// A string constant to compare with [operatingSystem] to see if the platform
  /// is iOS.
  ///
  /// Useful in case statements when switching on [operatingSystem].
  ///
  /// To just check if the platform is iOS, use [isIOS].
  static const String iOS = 'ios';

  /// A string constant to compare with [operatingSystem] to see if the platform
  /// is Fuchsia.
  ///
  /// Useful in case statements when switching on [operatingSystem].
  ///
  /// To just check if the platform is Fuchsia, use [isFuchsia].
  static const String fuchsia = 'fuchsia';

  /// A list of the possible values that [operatingSystem] can return.
  static const List<String> operatingSystemValues = <String>[
    linux,
    macOS,
    windows,
    android,
    iOS,
    fuchsia,
  ];

  /// The number of processors of the machine.
  int get numberOfProcessors;

  /// The path separator used by the operating system to separate
  /// components in file paths.
  String get pathSeparator;

  /// A string (`linux`, `macos`, `windows`, `android`, `ios`, or `fuchsia`)
  /// representing the operating system.
  ///
  /// The possible return values are available from [operatingSystemValues], and
  /// there are constants for each of the platforms to use in switch statements
  /// or conditionals (See [linux], [macOS], [windows], [android], [iOS], and
  /// [fuchsia]).
  String get operatingSystem;

  /// A string representing the version of the operating system or platform.
  String get operatingSystemVersion;

  /// Get the local hostname for the system.
  String get localHostname;

  /// True if the operating system is Linux.
  bool get isLinux => operatingSystem == linux;

  /// True if the operating system is OS X.
  bool get isMacOS => operatingSystem == macOS;

  /// True if the operating system is Windows.
  bool get isWindows => operatingSystem == windows;

  /// True if the operating system is Android.
  bool get isAndroid => operatingSystem == android;

  /// True if the operating system is iOS.
  bool get isIOS => operatingSystem == iOS;

  /// True if the operating system is Fuchsia
  bool get isFuchsia => operatingSystem == fuchsia;

  /// The environment for this process.
  ///
  /// The returned environment is an unmodifiable map whose content is
  /// retrieved from the operating system on its first use.
  ///
  /// Environment variables on Windows are case-insensitive. The map
  /// returned on Windows is therefore case-insensitive and will convert
  /// all keys to upper case. On other platforms the returned map is
  /// a standard case-sensitive map.
  Map<String, String> get environment;

  /// The path of the executable used to run the script in this isolate.
  ///
  /// The path returned is the literal path used to run the script. This
  /// path might be relative or just be a name from which the executable
  /// was found by searching the `PATH`.
  ///
  /// To get the absolute path to the resolved executable use
  /// [resolvedExecutable].
  String get executable;

  /// The path of the executable used to run the script in this
  /// isolate after it has been resolved by the OS.
  ///
  /// This is the absolute path, with all symlinks resolved, to the
  /// executable used to run the script.
  String get resolvedExecutable;

  /// The absolute URI of the script being run in this
  /// isolate.
  ///
  /// If the script argument on the command line is relative,
  /// it is resolved to an absolute URI before fetching the script, and
  /// this absolute URI is returned.
  ///
  /// URI resolution only does string manipulation on the script path, and this
  /// may be different from the file system's path resolution behavior. For
  /// example, a symbolic link immediately followed by '..' will not be
  /// looked up.
  ///
  /// If the executable environment does not support [script] an empty
  /// [Uri] is returned.
  Uri get script;

  /// The flags passed to the executable used to run the script in this
  /// isolate. These are the command-line flags between the executable name
  /// and the script name. Each fetch of `executableArguments` returns a new
  /// list containing the flags passed to the executable.
  List<String> get executableArguments;

  /// The value of the `--packages` flag passed to the executable
  /// used to run the script in this isolate. This is the configuration which
  /// specifies how Dart packages are looked up.
  ///
  /// If there is no `--packages` flag, `null` is returned.
  String? get packageConfig;

  /// The version of the current Dart runtime.
  ///
  /// The returned `String` is formatted as the [semver](http://semver.org)
  /// version string of the current dart runtime, possibly followed by
  /// whitespace and other version and build details.
  String get version;

  /// When stdin is connected to a terminal, whether ANSI codes are supported.
  bool get stdinSupportsAnsi;

  /// When stdout is connected to a terminal, whether ANSI codes are supported.
  bool get stdoutSupportsAnsi;

  /// Get the name of the current locale.
  String get localeName;

  /// Returns a JSON-encoded representation of this platform.
  String toJson() {
    return const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      'numberOfProcessors': numberOfProcessors,
      'pathSeparator': pathSeparator,
      'operatingSystem': operatingSystem,
      'operatingSystemVersion': operatingSystemVersion,
      'localHostname': localHostname,
      'environment': environment,
      'executable': executable,
      'resolvedExecutable': resolvedExecutable,
      'script': script.toString(),
      'executableArguments': executableArguments,
      'packageConfig': packageConfig,
      'version': version,
      'stdinSupportsAnsi': stdinSupportsAnsi,
      'stdoutSupportsAnsi': stdoutSupportsAnsi,
      'localeName': localeName,
    });
  }
}
