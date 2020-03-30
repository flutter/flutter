// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:async';
import 'dart:io' as io;

import 'package:args/args.dart';

import 'common.dart';

class SafariArgParser extends BrowserArgParser {
  static final SafariArgParser _singletonInstance = SafariArgParser._();

  /// The [SafariArgParser] singleton.
  static SafariArgParser get instance => _singletonInstance;

  String _version;

  SafariArgParser._();

  @override
  void populateOptions(ArgParser argParser) {
    argParser
      ..addOption(
        'safari-version',
        defaultsTo: 'system',
        help: 'The Safari version to use while running tests. The Safari '
            'browser installed on the system is used as the only option now.'
            'Soon we will add support for using different versions using the '
            'tech previews.',
      );
  }

  @override
  void parseOptions(ArgResults argResults) {
    _version = argResults['safari-version'] as String;
    assert(_version == 'system');
  }

  @override
  String get version => _version;
}

/// Returns the installation of Safari.
///
/// Currently uses the Safari version installed on the operating system.
///
/// Latest Safari version for Catalina, Mojave, High Siera is 13.
///
/// Latest Safari version for Sierra is 12.
// TODO(nurhan): user latest version to download and install the latest
// technology preview.
Future<BrowserInstallation> getOrInstallSafari(
  String requestedVersion, {
  StringSink infoLog,
}) async {

  // These tests are aimed to run only on MacOs machines local or on LUCI.
  if (!io.Platform.isMacOS) {
    throw UnimplementedError('Safari on ${io.Platform.operatingSystem} is'
        ' not supported. Safari is only supported on MacOS.');
  }

  infoLog ??= io.stdout;

  if (requestedVersion == 'system') {
    // Since Safari is included in MacOS, always assume there will be one on the
    // system.
    infoLog.writeln('Using the system version that is already installed.');
    return BrowserInstallation(
      version: 'system',
      executable: PlatformBinding.instance.getMacApplicationLauncher(),
    );
  } else {
    infoLog.writeln('Unsupported version $requestedVersion.');
    throw UnimplementedError();
  }
}
