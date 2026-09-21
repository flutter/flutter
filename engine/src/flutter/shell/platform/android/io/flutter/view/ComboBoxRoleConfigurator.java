// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view;

import android.view.accessibility.AccessibilityNodeInfo;

/**
 * Configurator for the {@link AccessibilityBridge.Role#COMBO_BOX} role. Sets the class name to
 * Spinner and indicates it can open a popup.
 */
public class ComboBoxRoleConfigurator extends BaseRoleConfigurator {
  @Override
  protected void configureRole(
      AccessibilityNodeInfo result, AccessibilityBridge.SemanticsNode node) {
    result.setClassName("android.widget.Spinner");
    result.setCanOpenPopup(true);
  }
}
