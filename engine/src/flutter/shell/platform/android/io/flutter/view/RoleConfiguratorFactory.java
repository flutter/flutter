// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view;

/**
 * Factory for creating {@link AccessibilityNodeConfigurator} instances based on {@link
 * AccessibilityBridge.Role}.
 */
public class RoleConfiguratorFactory {
  private static final AccessibilityNodeConfigurator progressBarConfigurator =
      new ProgressBarRoleConfigurator();
  private static final AccessibilityNodeConfigurator comboBoxConfigurator =
      new ComboBoxRoleConfigurator();
  private static final AccessibilityNodeConfigurator menuConfigurator = new MenuRoleConfigurator();
  private static final AccessibilityNodeConfigurator listViewConfigurator =
      new ClassNameRoleConfigurator("android.widget.ListView");
  private static final AccessibilityNodeConfigurator radioGroupConfigurator =
      new ClassNameRoleConfigurator("android.widget.RadioGroup");
  private static final AccessibilityNodeConfigurator menuItemConfigurator =
      new ClassNameRoleConfigurator("android.view.MenuItem");
  private static final AccessibilityNodeConfigurator genericConfigurator =
      new BaseRoleConfigurator();

  public static AccessibilityNodeConfigurator getConfigurator(AccessibilityBridge.Role role) {
    switch (role) {
      case PROGRESS_BAR:
        return progressBarConfigurator;
      case COMBO_BOX:
        return comboBoxConfigurator;
      case MENU:
        return menuConfigurator;
      case LIST:
        return listViewConfigurator;
      case RADIO_GROUP:
        return radioGroupConfigurator;
      case MENU_ITEM:
      case MENU_ITEM_CHECKBOX:
      case MENU_ITEM_RADIO:
        return menuItemConfigurator;
      case NONE:
      default:
        return genericConfigurator;
    }
  }
}
