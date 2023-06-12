// ------------------------------------------------------------------
// THIS FILE WAS DERIVED FROM SOURCE CODE UNDER THE FOLLOWING LICENSE
// ------------------------------------------------------------------
//
// Copyright 2012, the Dart project authors. All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
//       copyright notice, this list of conditions and the following
//       disclaimer in the documentation and/or other materials provided
//       with the distribution.
//     * Neither the name of Google Inc. nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ---------------------------------------------------------
// THIS, DERIVED FILE IS LICENSE UNDER THE FOLLOWING LICENSE
// ---------------------------------------------------------
// Copyright 2020 terrier989@gmail.com.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import '../internals_for_browser_or_node.dart' as browser_or_node;

/// Information about the environment in which the current program is running.
///
/// Platform provides information such as the operating system,
/// the hostname of the computer, the value of environment variables,
/// the path to the running program,
/// and so on.
///
/// ## Get the URI to the current Dart script
///
/// Use the [script] getter to get the URI to the currently running
/// Dart script.
///
///     import 'dart:io' show Platform;
///
///     void main() {
///       // Get the URI of the script being run.
///       var uri = Platform.script;
///       // Convert the URI to a path.
///       var path = uri.toFilePath();
///     }
///
/// ## Get the value of an environment variable
///
/// The [environment] getter returns a the names and values of environment
/// variables in a [Map] that contains key-value pairs of strings. The Map is
/// unmodifiable. This sample shows how to get the value of the `PATH`
/// environment variable.
///
///     import 'dart:io' show Platform;
///
///     void main() {
///       Map<String, String> envVars = Platform.environment;
///       print(envVars['PATH']);
///     }
///
/// ## Determine the OS
///
/// You can get the name of the operating system as a string with the
/// [operatingSystem] getter. You can also use one of the static boolean
/// getters: [isMacOS], [isLinux], and [isWindows].
///
///     import 'dart:io' show Platform, stdout;
///
///     void main() {
///       // Get the operating system as a string.
///       String os = Platform.operatingSystem;
///       // Or, use a predicate getter.
///       if (Platform.isMacOS) {
///         print('is a Mac');
///       } else {
///         print('is not a Mac');
///       }
///     }
class Platform {
  /// Whether the operating system is a version of
  /// [Linux](https://en.wikipedia.org/wiki/Linux).
  ///
  /// This value is `false` if the operating system is a specialized
  /// version of Linux that identifies itself by a different name,
  /// for example Android (see [isAndroid]).
  static final bool isLinux = (operatingSystem == 'linux');

  /// Whether the operating system is a version of
  /// [macOS](https://en.wikipedia.org/wiki/MacOS).
  static final bool isMacOS = (operatingSystem == 'macos');

  /// Whether the operating system is a version of
  /// [Microsoft Windows](https://en.wikipedia.org/wiki/Microsoft_Windows).
  static final bool isWindows = (operatingSystem == 'windows');

  /// Whether the operating system is a version of
  /// [Android](https://en.wikipedia.org/wiki/Android_%28operating_system%29).
  static final bool isAndroid = (operatingSystem == 'android');

  /// Whether the operating system is a version of
  /// [iOS](https://en.wikipedia.org/wiki/IOS).
  static final bool isIOS = (operatingSystem == 'ios');

  /// Whether the operating system is a version of
  /// [Fuchsia](https://en.wikipedia.org/wiki/Google_Fuchsia).
  static final bool isFuchsia = (operatingSystem == 'fuchsia');

  /// The environment for this process as a map from string key to string value.
  ///
  /// The map is unmodifiable,
  /// and its content is retrieved from the operating system on its first use.
  ///
  /// Environment variables on Windows are case-insensitive,
  /// so on Windows the map is case-insensitive and will convert
  /// all keys to upper case.
  /// On other platforms, keys can be distinguished by case.
  static Map<String, String> get environment => {};

  /// The path of the executable used to run the script in this isolate.
  ///
  /// The literal path used to identify the script.
  /// This path might be relative or just be a name from which the executable
  /// was found by searching the system path.
  ///
  /// Use [resolvedExecutable] to get an absolute path to the executable.
  static String get executable => '';

  /// The flags passed to the executable used to run the script in this isolate.
  ///
  /// These are the command-line flags to the executable that precedes
  /// the script name.
  /// Provides a new list every time the value is read.
  static List<String> get executableArguments => [];

  /// Get the name of the current locale.
  static String get localeName => browser_or_node.locale;

  /// The local hostname for the system.
  static String get localHostname => 'localhost';

  /// The number of individual execution units of the machine.
  static int get numberOfProcessors => 1;

  /// A string representing the operating system or platform.
  static String get operatingSystem => browser_or_node.operatingSystem;

  /// A string representing the version of the operating system or platform.
  static String get operatingSystemVersion => browser_or_node.operatingSystemVersion;

  /// The `--packages` flag passed to the executable used to run the script
  /// in this isolate.
  ///
  /// If present, it specifies a file describing how Dart packages are looked up.
  ///
  /// Is `null` if there is no `--packages` flag.
  static String? get packageConfig => null;

  /// This returns `null`, as `packages/` directories are no longer supported.
  ///
  @Deprecated('packages/ directory resolution is not supported in Dart 2')
  static String? get packageRoot => null;

  /// The path separator used by the operating system to separate
  /// components in file paths.
  static String get pathSeparator => '/';

  /// The path of the executable used to run the script in this
  /// isolate after it has been resolved by the OS.
  ///
  /// This is the absolute path, with all symlinks resolved, to the
  /// executable used to run the script.
  static String get resolvedExecutable => '';

  /// The absolute URI of the script being run in this isolate.
  ///
  /// If the script argument on the command line is relative,
  /// it is resolved to an absolute URI before fetching the script, and
  /// that absolute URI is returned.
  ///
  /// URI resolution only does string manipulation on the script path, and this
  /// may be different from the file system's path resolution behavior. For
  /// example, a symbolic link immediately followed by '..' will not be
  /// looked up.
  ///
  /// If the executable environment does not support [script],
  /// the URI is empty.
  static Uri get script => Uri();

  /// The version of the current Dart runtime.
  ///
  /// The value is a [semantic versioning](http://semver.org)
  /// string representing the version of the current Dart runtime,
  /// possibly followed by whitespace and other version and
  /// build details.
  static String get version => '';
}
