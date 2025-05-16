// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.platform;

import android.view.View;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.view.AccessibilityBridge;

public class PlatformViewsControllerDelegator implements PlatformViewsAccessibilityDelegate {

  PlatformViewsController platformViewsController;
  PlatformViewsController2 platformViewsController2;

  public PlatformViewsControllerDelegator(
      PlatformViewsController platformViewsController,
      PlatformViewsController2 platformViewsController2) {
    this.platformViewsController = platformViewsController;
    this.platformViewsController2 = platformViewsController2;
  }

  @Nullable
  @Override
  public View getPlatformViewById(int viewId) {
    return platformViewsController2.getPlatformViewById(viewId) != null
        ? platformViewsController2.getPlatformViewById(viewId)
        : platformViewsController.getPlatformViewById(viewId);
  }

  @Override
  public boolean usesVirtualDisplay(int id) {
    return platformViewsController2.getPlatformViewById(id) != null
        ? platformViewsController2.usesVirtualDisplay(id)
        : platformViewsController.usesVirtualDisplay(id);
  }

  @Override
  public void attachAccessibilityBridge(@NonNull AccessibilityBridge accessibilityBridge) {
    platformViewsController.attachAccessibilityBridge(accessibilityBridge);
    platformViewsController2.attachAccessibilityBridge(accessibilityBridge);
  }

  @Override
  public void detachAccessibilityBridge() {
    platformViewsController.detachAccessibilityBridge();
    platformViewsController2.detachAccessibilityBridge();
  }
}
