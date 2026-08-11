// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view;

import android.os.Build;
import android.view.accessibility.AccessibilityNodeInfo;
import io.flutter.Build.API_LEVELS;

/** Configures Android accessibility metadata for a Flutter semantic table. */
public class TableRoleConfigurator extends BaseRoleConfigurator {
  @Override
  protected void configureRole(
      AccessibilityNodeInfo result, AccessibilityBridge.SemanticsNode node) {
    result.setClassName("android.widget.TableLayout");

    int rowCount = 0;
    int columnCount = 0;
    if (node.childrenInTraversalOrder != null) {
      for (AccessibilityBridge.SemanticsNode row : node.childrenInTraversalOrder) {
        if (row == null || !row.hasRole(AccessibilityBridge.Role.ROW)) {
          continue;
        }
        rowCount++;
        int rowColumns =
            row.childrenInTraversalOrder != null ? row.childrenInTraversalOrder.size() : 0;
        columnCount = Math.max(columnCount, rowColumns);
      }
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
