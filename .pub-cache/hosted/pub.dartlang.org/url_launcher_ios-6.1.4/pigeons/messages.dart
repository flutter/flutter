// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/messages.g.dart',
  objcOptions: ObjcOptions(prefix: 'FUL'),
  objcHeaderOut: 'ios/Classes/messages.g.h',
  objcSourceOut: 'ios/Classes/messages.g.m',
  copyrightHeader: 'pigeons/copyright.txt',
))
@HostApi()
abstract class UrlLauncherApi {
  /// Returns true if the URL can definitely be launched.
  @ObjCSelector('canLaunchURL:')
  bool canLaunchUrl(String url);

  /// Opens the URL externally, returning true if successful.
  @async
  @ObjCSelector('launchURL:universalLinksOnly:')
  bool launchUrl(String url, bool universalLinksOnly);

  /// Opens the URL in an in-app SFSafariViewController, returning true
  /// when it has loaded successfully.
  @async
  @ObjCSelector('openSafariViewControllerWithURL:')
  bool openUrlInSafariViewController(String url);

  /// Closes the view controller opened by [openUrlInSafariViewController].
  void closeSafariViewController();
}
