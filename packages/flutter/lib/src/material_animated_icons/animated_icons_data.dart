// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file serves as the interface between the public and private APIs for
// animated icons.
// The AnimatedIcons class is public and is used to specify available icons,
// while the _AnimatedIconData interface which used to deliver the icon data is
// kept private.

part of material_animated_icons;

class AnimatedIcons {
  static const AnimatedIconData menu_arrow = const _MenuArrowIconData();
}

abstract class AnimatedIconData {}

abstract class _AnimatedIconData extends AnimatedIconData {
  String get placeHolderIconData;
}
