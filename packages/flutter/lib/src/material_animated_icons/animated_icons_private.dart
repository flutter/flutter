// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file contains the machinery used to draw animated icons.
// This code is deliberately private as we do not want to prematurely
// provide a public API for vector graphics.
// See: https://github.com/flutter/flutter/issues/1831 for the progress of
// generic vector graphics support in Flutter.

part of material_animated_icons;

class _AnimatedIcon extends StatelessWidget {
  const _AnimatedIcon({
    @required this.progress,
    @required this.color,
    @required this.icon,
  }) : assert (progress != null),
       assert (color != null),
       assert (icon != null);

  final Animation<double> progress;
  final Color color;
  final AnimatedIconData icon;

  @override
  Widget build(BuildContext context) {
    // TODO(amirh): implement this, starting with:
    // final _AnimatedIconData data = icon;
    return new Container();
  }
}
