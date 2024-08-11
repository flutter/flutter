// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "common_patch.dart";

@patch
@pragma("vm:entry-point")
class _Platform {
  @patch
  @pragma("vm:external-name", "Platform_NumberOfProcessors")
  external static int _numberOfProcessors();
  @patch
  @pragma("vm:external-name", "Platform_PathSeparator")
  external static String _pathSeparator();
  @patch
  @pragma("vm:external-name", "Platform_OperatingSystem")
  external static String _operatingSystem();
  @patch
  @pragma("vm:external-name", "Platform_OperatingSystemVersion")
  external static _operatingSystemVersion();
  @patch
  @pragma("vm:external-name", "Platform_LocalHostname")
  external static _localHostname();
  @patch
  @pragma("vm:external-name", "Platform_ExecutableName")
  external static _executable();
  @patch
  @pragma("vm:external-name", "Platform_ResolvedExecutableName")
  external static _resolvedExecutable();
  @patch
  @pragma("vm:external-name", "Platform_Environment")
  external static _environment();
  @patch
  @pragma("vm:external-name", "Platform_ExecutableArguments")
  external static List<String> _executableArguments();
  @patch
  @pragma("vm:external-name", "Platform_GetVersion")
  external static String _version();

  @patch
  @pragma("vm:external-name", "Platform_LocaleName")
  external static String _localeName();

  @patch
  static String? _packageConfig() => VMLibraryHooks.packageConfigString;

  @patch
  static Uri _script() => VMLibraryHooks.platformScript!;

  // This script singleton is written to by the embedder if applicable.
  @pragma("vm:entry-point")
  static void set _nativeScript(String path) {
    VMLibraryHooks.platformScript = (() {
      if (path.startsWith('http:') ||
          path.startsWith('https:') ||
          path.startsWith('package:') ||
          path.startsWith('dart:') ||
          path.startsWith('data:') ||
          path.startsWith('file:')) {
        return Uri.parse(path);
      } else {
        return Uri.base.resolveUri(new Uri.file(path));
      }
    });
  }
}
