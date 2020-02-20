// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
part of engine;

abstract class RuntimeDelegate {
  String get defaultRouteName;
  void scheduleFrame({bool regenerateLayerTree = true});
  void render(LayerTree layerTree);
  void handlePlatformMessage(PlatformMessage message);
  FontCollection getFontCollection();
}
