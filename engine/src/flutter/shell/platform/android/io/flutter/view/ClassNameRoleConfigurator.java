// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view;

import android.view.accessibility.AccessibilityNodeInfo;

/** Configurator that simply sets the class name of the accessibility node. */
public class ClassNameRoleConfigurator extends BaseRoleConfigurator {
  private final String className;

  public ClassNameRoleConfigurator(String className) {
    this.className = className;
  }

  @Override
  protected void configureRole(AccessibilityNodeInfo result, AccessibilityBridge.SemanticsNode node) {
    result.setClassName(className);
  }
}
