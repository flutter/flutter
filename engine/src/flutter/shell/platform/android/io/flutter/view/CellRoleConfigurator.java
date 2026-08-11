// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view;

import android.os.Build;
import android.view.accessibility.AccessibilityNodeInfo;
import io.flutter.Build.API_LEVELS;

/**
 * Configurator for the {@link AccessibilityBridge.Role#CELL} and COLUMN_HEADER roles. Reports a
 * cell's position within its enclosing table as collection item info.
 */
public class CellRoleConfigurator extends BaseRoleConfigurator {
  @Override
  protected void configureRole(
      AccessibilityNodeInfo result, AccessibilityBridge.SemanticsNode node) {
    final AccessibilityBridge.SemanticsNode row = node.parent;
    if (row == null || !row.hasRole(AccessibilityBridge.Role.ROW)) {
      // Cells may also be nested inside another cell, in which case there is no position within
      // the table to report. Leave whatever BaseRoleConfigurator computed in place.
      return;
    }
    final AccessibilityBridge.SemanticsNode table = row.parent;
    if (table == null || !table.hasRole(AccessibilityBridge.Role.TABLE)) {
      return;
    }

    // Only rows are counted, so that a non-row child of the table does not offset the rows that
    // follow it. TableRoleConfigurator counts the row total the same way.
    int rowIndex = 0;
    for (AccessibilityBridge.SemanticsNode sibling : table.childrenInTraversalOrder) {
      if (sibling == row) {
        break;
      }
      if (sibling.hasRole(AccessibilityBridge.Role.ROW)) {
        rowIndex++;
      }
    }

    // TODO(gmackall): Report the cell's real column rather than its position among its siblings.
    // RenderTable drops cells whose contents produce no semantics node at all (an empty SizedBox,
    // for example) and cells with zero width, so a table with such a gap in it shifts every cell
    // to the right of the gap one column to the left. RenderTable knows the real column and
    // records it in SemanticsNode.indexInParent, but that field stays in the framework and is
    // never sent over the semantics wire, so it is not available here.
    final int columnIndex = row.childrenInTraversalOrder.indexOf(node);

    final boolean isHeading =
        node.hasRole(AccessibilityBridge.Role.COLUMN_HEADER)
            || node.hasFlag(AccessibilityBridge.Flag.IS_HEADER);

    if (Build.VERSION.SDK_INT < API_LEVELS.API_33) {
      result.setCollectionItemInfo(
          AccessibilityNodeInfo.CollectionItemInfo.obtain(
              rowIndex, // row index
              1, // row span
              columnIndex, // column index
              1, // column span
              isHeading // is heading
              ));
    } else {
      result.setCollectionItemInfo(
          new AccessibilityNodeInfo.CollectionItemInfo(
              rowIndex, // row index
              1, // row span
              columnIndex, // column index
              1, // column span
              isHeading // is heading
              ));
    }
  }
}
