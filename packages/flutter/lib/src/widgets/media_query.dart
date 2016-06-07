// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:meta/meta.dart';

import 'basic.dart';
import 'framework.dart';

/// Whether in portrait or landscape.
enum Orientation {
  /// Taller than wide.
  portrait,

  /// Wider than tall.
  landscape
}

/// The result of a media query.
class MediaQueryData {
  /// Creates data for a media query with explicit values.
  ///
  /// Consider using [MediaQueryData.fromWindow] to create data based on a
  /// [ui.Window].
  const MediaQueryData({ this.size, this.devicePixelRatio, this.padding });

  /// Creates data for a media query based on the given window.
  MediaQueryData.fromWindow(ui.Window window)
    : size = window.size,
      devicePixelRatio = window.devicePixelRatio,
      padding = new EdgeInsets.fromWindowPadding(window.padding);

  /// The size of the media in logical pixel (e.g, the size of the screen).
  ///
  /// Logical pixels are roughly the same visual size across devices. Physical
  /// pixels are the size of the actual hardware pixels on the device. The
  /// number of physical pixels per logical pixel is described by the
  /// [devicePixelRatio].
  final Size size;

  /// The number of device pixels for each logical pixel. This number might not
  /// be a power of two. Indeed, it might not even be an integer. For example,
  /// the Nexus 6 has a device pixel ratio of 3.5.
  final double devicePixelRatio;

  /// The padding around the edges of the media (e.g., the screen).
  final EdgeInsets padding;

  /// The orientation of the media (e.g., whether the device is in landscape or portrait mode).
  Orientation get orientation {
    return size.width > size.height ? Orientation.landscape : Orientation.portrait;
  }

  @override
  bool operator==(Object other) {
    if (other.runtimeType != runtimeType)
      return false;
    MediaQueryData typedOther = other;
    return typedOther.size == size
        && typedOther.padding == padding
        && typedOther.devicePixelRatio == devicePixelRatio;
  }

  @override
  int get hashCode => hashValues(
    size.hashCode,
    padding.hashCode,
    devicePixelRatio.hashCode
  );

  @override
  String toString() => '$runtimeType(size: $size, devicePixelRatio: $devicePixelRatio, padding: $padding)';
}

/// Establishes a subtree in which media queries resolve to the given data.
class MediaQuery extends InheritedWidget {
  /// Creates a widget that provides [MediaQueryData] to its descendants.
  ///
  /// The [data] and [child] arguments must not be null.
  MediaQuery({
    Key key,
    @required this.data,
    @required Widget child
  }) : super(key: key, child: child) {
    assert(child != null);
    assert(data != null);
  }

  /// The result of media queries in this subtree.
  final MediaQueryData data;

  /// The data from the closest instance of this class that encloses the given context.
  ///
  /// You can use this function to query the size an orientation of the screen.
  /// When that information changes, your widget will be scheduled to be rebuilt,
  /// keeping your widget up-to-date.
  static MediaQueryData of(BuildContext context) {
    MediaQuery query = context.inheritFromWidgetOfExactType(MediaQuery);
    return query?.data ?? new MediaQueryData.fromWindow(ui.window);
  }

  @override
  bool updateShouldNotify(MediaQuery old) => data != old.data;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('$data');
  }
}
