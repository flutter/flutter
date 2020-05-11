// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// Defines where a Link URL should be open.
enum LinkTarget {
  /// Use the default target for each platform.
  ///
  /// On Android, the default is [blank]. On the web, the default is [self].
  ///
  /// iOS, on the other hand, defaults to [self] for web URLs, and [blank] for
  /// non-web URLs.
  defaultTarget,

  /// On the web, this opens the link in the same tab where the flutter app is
  /// running.
  ///
  /// On Android and iOS, this opens the link in a webview within the app.
  self,

  /// On the web, this opens the link in a new tab or window (depending on the
  /// browser and user configuration).
  ///
  /// On Android and iOS, this opens the link in the browser or the relevant
  /// app.
  blank,
}

///
class RenderLink extends RenderProxyBox {
  ///
  RenderLink({
    @required String destination,
    @required String label,
    @required LinkTarget target,
  })  : _destination = destination,
        _label = label,
        _target = target;

  ///
  String get destination => _destination;
  String _destination;
  set destination(String value) {
    if (value != _destination) {
      _destination = value;
      markNeedsPaint();
      // TODO: markNeedsSemanticsUpdate();
    }
  }

  ///
  String get label => _label;
  String _label;
  set label(String value) {
    if (value != _label) {
      _label = value;
      markNeedsPaint();
      // TODO: markNeedsSemanticsUpdate();
    }
  }

  ///
  LinkTarget get target => _target;
  LinkTarget _target;
  set target(LinkTarget value) {
    if (value != _target) {
      _target = value;
      markNeedsPaint();
      // TODO: markNeedsSemanticsUpdate();
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final LinkLayer layer = LinkLayer(
      destination: destination,
      label: label,
      target: target,
      rect: offset & size,
    );
    context.pushLayer(layer, super.paint, offset);
  }
}
