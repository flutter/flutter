// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/messages.g.dart',
  swiftOut: 'macos/Classes/messages.g.swift',
  copyrightHeader: 'pigeons/copyright.txt',
))

/// Possible error conditions for [UrlLauncherApi] calls.
enum UrlLauncherError {
  /// The URL could not be parsed as an NSURL.
  invalidUrl,
}

/// Possible results for a [UrlLauncherApi] call with a boolean outcome.
class UrlLauncherBoolResult {
  UrlLauncherBoolResult(this.value, {this.error});
  final bool value;
  final UrlLauncherError? error;
}

@HostApi()
abstract class UrlLauncherApi {
  /// Returns a true result if the URL can definitely be launched.
  @SwiftFunction('canLaunch(url:)')
  UrlLauncherBoolResult canLaunchUrl(String url);

  /// Opens the URL externally, returning a true result if successful.
  @SwiftFunction('launch(url:)')
  UrlLauncherBoolResult launchUrl(String url);
}
