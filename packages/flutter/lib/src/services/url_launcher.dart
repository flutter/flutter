// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_services/platform/url_launcher.dart' as mojom;
import 'shell.dart';

mojom.UrlLauncherProxy _initUrlLauncherProxy() {
  return shell.connectToApplicationService(
      mojom.UrlLauncher.serviceName,
      mojom.UrlLauncher.connectToService);
}

final mojom.UrlLauncherProxy _connectedUrlLauncherService = _initUrlLauncherProxy();

/// Allows applications to delegate responsbility of handling certain URLs to
/// the underlying platform.
class UrlLauncher {
  UrlLauncher._();

  /// Parse the specified URL string and delegate handling of the same to the
  /// underlying platform.
  ///
  /// Arguments:
  ///
  /// * [urlString]: The URL string to be parsed by the underlying platform and
  ///   before it attempts to launch the same.
  ///
  /// Return Value:
  ///
  ///   boolean indicating if the intent to handle the URL was successfully
  ///   conveyed to the to underlying platform and the platform could
  ///   successfully handle the same. The platform is responsible for URL
  ///   parsing.
  static Future<bool> launch(String urlString) {
    Completer<bool> completer = new Completer<bool>();
    _connectedUrlLauncherService.launch(urlString, (bool success) {
      completer.complete(success);
    });
    return completer.future;
  }
}
