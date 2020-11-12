// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.platform;

import android.view.View;
import io.flutter.view.AccessibilityBridge;

/** Facilitates interaction between the accessibility bridge and embedded platform views. */
public interface PlatformViewsAccessibilityDelegate {
  /**
   * Returns the root of the view hierarchy for the platform view with the requested id, or null if
   * there is no corresponding view.
   */
  View getPlatformViewById(Integer id);

  /**
   * Returns true if the platform view uses virtual displays.
   *
   * @hide
   */
  boolean usesVirtualDisplay(Integer id);

  /**
   * Attaches an accessibility bridge for this platform views accessibility delegate.
   *
   * <p>Accessibility events originating in platform views belonging to this delegate will be
   * delegated to this accessibility bridge.
   */
  void attachAccessibilityBridge(AccessibilityBridge accessibilityBridge);

  /**
   * Detaches the current accessibility bridge.
   *
   * <p>Any accessibility events sent by platform views belonging to this delegate will be ignored
   * until a new accessibility bridge is attached.
   */
  void detachAccessibiltyBridge();
}
