// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view;

import android.os.Build;
import android.view.accessibility.AccessibilityNodeInfo;
import io.flutter.Build.API_LEVELS;

/**
 * Configurator for the {@link AccessibilityBridge.Role#TABLE} role. Sets the class name to
 * TableLayout and reports the table's dimensions as collection info.
 */
public class TableRoleConfigurator extends BaseRoleConfigurator {
  @Override
  protected void configureRole(
      AccessibilityNodeInfo result, AccessibilityBridge.SemanticsNode node) {
    result.setClassName("android.widget.TableLayout");

    int rowCount = 0;
    int columnCount = 0;
    for (AccessibilityBridge.SemanticsNode row : node.childrenInTraversalOrder) {
      if (!row.hasRole(AccessibilityBridge.Role.ROW)) {
        continue;
      }
      rowCount++;
      columnCount = Math.max(columnCount, row.childrenInTraversalOrder.size());
    }

    if (rowCount == 0 || columnCount == 0) {
      // TalkBack needs a row and column count greater than zero to announce entering and leaving
      // a collection, and reports nonsense for an empty one. An empty table is better described
      // by no collection info at all.
      return;
    }

    if (Build.VERSION.SDK_INT < API_LEVELS.API_33) {
      result.setCollectionInfo(
          AccessibilityNodeInfo.CollectionInfo.obtain(rowCount, columnCount, false));
    } else {
      result.setCollectionInfo(
          new AccessibilityNodeInfo.CollectionInfo(rowCount, columnCount, false));
    }
  }
}
