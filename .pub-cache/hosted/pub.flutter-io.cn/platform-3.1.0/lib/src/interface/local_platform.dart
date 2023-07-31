// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io show Platform, stdin, stdout;

import 'platform.dart';

/// `Platform` implementation that delegates directly to `dart:io`.
class LocalPlatform extends Platform {
  /// Creates a new [LocalPlatform].
  const LocalPlatform();

  @override
  int get numberOfProcessors => io.Platform.numberOfProcessors;

  @override
  String get pathSeparator => io.Platform.pathSeparator;

  @override
  String get operatingSystem => io.Platform.operatingSystem;

  @override
  String get operatingSystemVersion => io.Platform.operatingSystemVersion;

  @override
  String get localHostname => io.Platform.localHostname;

  @override
  Map<String, String> get environment => io.Platform.environment;

  @override
  String get executable => io.Platform.executable;

  @override
  String get resolvedExecutable => io.Platform.resolvedExecutable;

  @override
  Uri get script => io.Platform.script;

  @override
  List<String> get executableArguments => io.Platform.executableArguments;

  @override
  String? get packageConfig => io.Platform.packageConfig;

  @override
  String get version => io.Platform.version;

  @override
  bool get stdinSupportsAnsi => io.stdin.supportsAnsiEscapes;

  @override
  bool get stdoutSupportsAnsi => io.stdout.supportsAnsiEscapes;

  @override
  String get localeName => io.Platform.localeName;
}
