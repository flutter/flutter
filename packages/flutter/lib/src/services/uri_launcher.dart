// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:sky_services/flutter/platform/uri_launcher.mojom.dart' as mojo;
import 'shell.dart';

mojo.UriLauncherProxy _initURILauncherProxy() {
  return shell.connectToApplicationService(
      mojo.UriLauncher.serviceName,
      mojo.UriLauncher.connectToService);
}

final mojo.UriLauncherProxy _connectedURILauncherService = _initURILauncherProxy();

/// Allows applications to delegate responsbility of handling certain URIs to
/// the underlying platform.
class URILauncher {
  URILauncher._();

  /// Parse the specified URI string and delegate handling of the same to the
  /// underlying platform.
  ///
  /// Arguments:
  ///
  /// * [uriString]: The URI string to be parsed by the underlying platform and
  ///   before it attempts to launch the same.
  ///
  /// Return Value:
  ///
  ///   boolean indicating if the intent to handle the URI was successfully
  ///   conveyed to the to underlying platform and the platform could
  ///   successfully handle the same. The platform is responsible for URI
  ///   parsing.
  static Future<bool> launch(String uriString) async {
    return await _connectedURILauncherService.launch(uriString);
  }
}
