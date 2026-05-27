// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view.accessibility.configurator;

import android.view.accessibility.AccessibilityNodeInfo;
import io.flutter.view.AccessibilityBridge;

/**
 * Configurator for the {@link AccessibilityBridge.Role#MENU} role. Sets the class name to Spinner
 * and indicates it can open a popup.
 */
public class MenuRoleConfigurator implements AccessibilityNodeConfigurator {
  @Override
  public void configure(AccessibilityNodeInfo result, AccessibilityBridge.SemanticsNode node) {
    result.setClassName("android.widget.Spinner");
    result.setCanOpenPopup(true);
  }
}
