// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:args/args.dart';

import 'common.dart';

class EdgeArgParser extends BrowserArgParser {
  static final EdgeArgParser _singletonInstance = EdgeArgParser._();

  /// The [EdgeArgParser] singleton.
  static EdgeArgParser get instance => _singletonInstance;

  String _version;

  EdgeArgParser._();

  @override
  void populateOptions(ArgParser argParser) {
    argParser
      ..addOption(
        'edge-version',
        defaultsTo: 'system',
        help: 'The Edge version to use while running tests. The Edge '
            'browser installed on the system is used as the only option now.',
      );
  }

  @override
  void parseOptions(ArgResults argResults) {
    _version = argResults['edge-version'];
    assert(_version == 'system');
  }

  @override
  String get version => _version;
}

/// Returns the installation of Edge.
///
/// Currently uses the Edge version installed on the operating system.
///
/// As explained on the Microsoft help page: `Microsoft Edge comes
/// exclusively with Windows 10 and cannot be downloaded or installed separately.`
/// See: https://support.microsoft.com/en-us/help/17171/microsoft-edge-get-to-know
///
// TODO(nurhan): Investigate running tests for the tech preview downloads
// from the beta channel.
Future<BrowserInstallation> getEdgeInstallation(
  String requestedVersion, {
  StringSink infoLog,
}) async {
  // For now these tests are aimed to run only on Windows machines local or on LUCI/CI.
  // In the future we can investigate to run them on Android or on MacOS.
  if (!io.Platform.isWindows) {
    throw UnimplementedError(
        'Tests for Edge on ${io.Platform.operatingSystem} is'
        ' not supported.');
  }

  infoLog ??= io.stdout;

  if (requestedVersion == 'system') {
    // Since Edge is included in Windows, always assume there will be one on the
    // system.
    infoLog.writeln('Using the system version that is already installed.');
    return BrowserInstallation(
      version: 'system',
      executable: PlatformBinding.instance.getCommandToRunEdge(),
    );
  } else {
    infoLog.writeln('Unsupported version $requestedVersion.');
    throw UnimplementedError();
  }
}
