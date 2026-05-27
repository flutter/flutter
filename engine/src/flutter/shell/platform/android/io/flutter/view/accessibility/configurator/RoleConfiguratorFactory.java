// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view.accessibility.configurator;

import io.flutter.view.AccessibilityBridge;

/**
 * Factory for creating {@link AccessibilityNodeConfigurator} instances based on {@link
 * AccessibilityBridge.Role}.
 */
public class RoleConfiguratorFactory {
  public static AccessibilityNodeConfigurator getConfigurator(AccessibilityBridge.Role role) {
    switch (role) {
      case PROGRESS_BAR:
        return new ProgressBarRoleConfigurator();
      case COMBO_BOX:
        return new ComboBoxRoleConfigurator();
      case MENU:
        return new MenuRoleConfigurator();
      case LIST:
        return new ClassNameRoleConfigurator("android.widget.ListView");
      case RADIO_GROUP:
        return new ClassNameRoleConfigurator("android.widget.RadioGroup");
      case MENU_ITEM:
      case MENU_ITEM_CHECKBOX:
      case MENU_ITEM_RADIO:
        return new ClassNameRoleConfigurator("android.view.MenuItem");
      case NONE:
      default:
        return new GenericRoleConfigurator();
    }
  }
}
