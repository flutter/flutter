// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:async';
import 'dart:io';

import 'browser.dart';
import 'common.dart';
import 'edge_installation.dart';

/// A class for running an instance of Edge.
///
/// Most of the communication with the browser is expected to happen via HTTP,
/// so this exposes a bare-bones API. The browser starts as soon as the class is
/// constructed, and is killed when [close] is called.
///
/// Any errors starting or running the process are reported through [onExit].
class Edge extends Browser {
  @override
  final name = 'Edge';

  static String version;

  /// Starts a new instance of Safari open to the given [url], which may be a
  /// [Uri] or a [String].
  factory Edge(Uri url, {bool debug = false}) {
    version = EdgeArgParser.instance.version;

    assert(version != null);
    return Edge._(() async {
      // TODO(nurhan): Configure info log for LUCI.
      final BrowserInstallation installation = await getEdgeInstallation(
        version,
        infoLog: DevNull(),
      );

      // Debug is not a valid option for Edge. Remove it.
      String pathToOpen = url.toString();
      if(pathToOpen.contains('debug')) {
        int index = pathToOpen.indexOf('debug');
        pathToOpen = pathToOpen.substring(0, index-1);
      }

      var process =
          await Process.start(installation.executable, ['$pathToOpen','-k']);

      return process;
    });
  }

  Edge._(Future<Process> startBrowser()) : super(startBrowser);
}
