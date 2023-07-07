// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Signature for a function provided by the [Link] widget that instructs it to
/// follow the link.
typedef FollowLink = Future<void> Function();

/// Signature for a builder function passed to the [Link] widget to construct
/// the widget tree under it.
typedef LinkWidgetBuilder = Widget Function(
  BuildContext context,
  FollowLink? followLink,
);

/// Signature for a delegate function to build the [Link] widget.
typedef LinkDelegate = Widget Function(LinkInfo linkWidget);

const MethodCodec _codec = JSONMethodCodec();

/// Defines where a Link URL should be open.
///
/// This is a class instead of an enum to allow future customizability e.g.
/// opening a link in a specific iframe.
class LinkTarget {
  /// Const private constructor with a [debugLabel] to allow the creation of
  /// multiple distinct const instances.
  const LinkTarget._({required this.debugLabel});

  /// Used to distinguish multiple const instances of [LinkTarget].
  final String debugLabel;

  /// Use the default target for each platform.
  ///
  /// On Android, the default is [blank]. On the web, the default is [self].
  ///
  /// iOS, on the other hand, defaults to [self] for web URLs, and [blank] for
  /// non-web URLs.
  static const LinkTarget defaultTarget =
      LinkTarget._(debugLabel: 'defaultTarget');

  /// On the web, this opens the link in the same tab where the flutter app is
  /// running.
  ///
  /// On Android and iOS, this opens the link in a webview within the app.
  static const LinkTarget self = LinkTarget._(debugLabel: 'self');

  /// On the web, this opens the link in a new tab or window (depending on the
  /// browser and user configuration).
  ///
  /// On Android and iOS, this opens the link in the browser or the relevant
  /// app.
  static const LinkTarget blank = LinkTarget._(debugLabel: 'blank');
}

/// Encapsulates all the information necessary to build a Link widget.
abstract class LinkInfo {
  /// Called at build time to construct the widget tree under the link.
  LinkWidgetBuilder get builder;

  /// The destination that this link leads to.
  Uri? get uri;

  /// The target indicating where to open the link.
  LinkTarget get target;

  /// Whether the link is disabled or not.
  bool get isDisabled;
}

typedef _SendMessage = Function(String, ByteData?, void Function(ByteData?));

/// Pushes the [routeName] into Flutter's navigation system via a platform
/// message.
///
/// The platform is notified using [SystemNavigator.routeInformationUpdated]. On
/// older versions of Flutter, this means it will not work unless the
/// application uses a [Router] (e.g. using [MaterialApp.router]).
///
/// Returns the raw data returned by the framework.
// TODO(ianh): Remove the first argument.
Future<ByteData> pushRouteNameToFramework(Object? _, String routeName) {
  final Completer<ByteData> completer = Completer<ByteData>();
  SystemNavigator.routeInformationUpdated(location: routeName);
  final _SendMessage sendMessage = _ambiguate(WidgetsBinding.instance)
          ?.platformDispatcher
          .onPlatformMessage ??
      ui.channelBuffers.push;
  sendMessage(
    'flutter/navigation',
    _codec.encodeMethodCall(
      MethodCall('pushRouteInformation', <dynamic, dynamic>{
        'location': routeName,
        'state': null,
      }),
    ),
    completer.complete,
  );
  return completer.future;
}

/// This allows a value of type T or T? to be treated as a value of type T?.
///
/// We use this so that APIs that have become non-nullable can still be used
/// with `!` and `?` on the stable branch.
// TODO(ianh): Remove this once we roll stable in late 2021.
T? _ambiguate<T>(T? value) => value;
