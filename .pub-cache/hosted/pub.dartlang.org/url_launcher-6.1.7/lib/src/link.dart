// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'types.dart';
import 'url_launcher_uri.dart';

/// The function used to push routes to the Flutter framework.
@visibleForTesting
Future<ByteData> Function(Object?, String) pushRouteToFrameworkFunction =
    pushRouteNameToFramework;

/// A widget that renders a real link on the web, and uses WebViews in native
/// platforms to open links.
///
/// Example link to an external URL:
///
/// ```dart
/// Link(
///   uri: Uri.parse('https://flutter.dev'),
///   builder: (BuildContext context, FollowLink followLink) => ElevatedButton(
///     onPressed: followLink,
///     // ... other properties here ...
///   )},
/// );
/// ```
///
/// Example link to a route name within the app:
///
/// ```dart
/// Link(
///   uri: Uri.parse('/home'),
///   builder: (BuildContext context, FollowLink followLink) => ElevatedButton(
///     onPressed: followLink,
///     // ... other properties here ...
///   )},
/// );
/// ```
class Link extends StatelessWidget implements LinkInfo {
  /// Creates a widget that renders a real link on the web, and uses WebViews in
  /// native platforms to open links.
  const Link({
    Key? key,
    required this.uri,
    this.target = LinkTarget.defaultTarget,
    required this.builder,
  }) : super(key: key);

  /// Called at build time to construct the widget tree under the link.
  @override
  final LinkWidgetBuilder builder;

  /// The destination that this link leads to.
  @override
  final Uri? uri;

  /// The target indicating where to open the link.
  @override
  final LinkTarget target;

  /// Whether the link is disabled or not.
  @override
  bool get isDisabled => uri == null;

  LinkDelegate get _effectiveDelegate {
    return UrlLauncherPlatform.instance.linkDelegate ??
        DefaultLinkDelegate.create;
  }

  @override
  Widget build(BuildContext context) {
    return _effectiveDelegate(this);
  }
}

/// The default delegate used on non-web platforms.
///
/// For external URIs, it uses url_launche APIs. For app route names, it uses
/// event channel messages to instruct the framework to push the route name.
class DefaultLinkDelegate extends StatelessWidget {
  /// Creates a delegate for the given [link].
  const DefaultLinkDelegate(this.link, {Key? key}) : super(key: key);

  /// Given a [link], creates an instance of [DefaultLinkDelegate].
  ///
  /// This is a static method so it can be used as a tear-off.
  static DefaultLinkDelegate create(LinkInfo link) {
    return DefaultLinkDelegate(link);
  }

  /// Information about the link built by the app.
  final LinkInfo link;

  bool get _useWebView {
    if (link.target == LinkTarget.self) {
      return true;
    }
    if (link.target == LinkTarget.blank) {
      return false;
    }
    return false;
  }

  Future<void> _followLink(BuildContext context) async {
    final Uri url = link.uri!;
    if (!url.hasScheme) {
      // A uri that doesn't have a scheme is an internal route name. In this
      // case, we push it via Flutter's navigation system instead of letting the
      // browser handle it.
      final String routeName = link.uri.toString();
      await pushRouteToFrameworkFunction(context, routeName);
      return;
    }

    // At this point, we know that the link is external. So we use the
    // `launchUrl` API to open the link.
    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: _useWebView
            ? LaunchMode.inAppWebView
            : LaunchMode.externalApplication,
      );
    } else {
      FlutterError.reportError(FlutterErrorDetails(
        exception: 'Could not launch link $url',
        stack: StackTrace.current,
        library: 'url_launcher',
        context: ErrorDescription('during launching a link'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return link.builder(
      context,
      link.isDisabled ? null : () => _followLink(context),
    );
  }
}
