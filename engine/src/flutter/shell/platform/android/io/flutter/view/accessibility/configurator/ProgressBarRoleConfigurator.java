// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view.accessibility.configurator;

import android.os.Build;
import android.view.accessibility.AccessibilityNodeInfo;
import io.flutter.Build.API_LEVELS;
import io.flutter.view.AccessibilityBridge;

/**
 * Configurator for the {@link AccessibilityBridge.Role#PROGRESS_BAR} role. Sets the class name to
 * ProgressBar and handles range info.
 */
public class ProgressBarRoleConfigurator implements AccessibilityNodeConfigurator {
  @Override
  public void configure(AccessibilityNodeInfo result, AccessibilityBridge.SemanticsNode node) {
    result.setClassName("android.widget.ProgressBar");
    if (node.value != null) {
      float min = Float.NEGATIVE_INFINITY;
      float max = Float.POSITIVE_INFINITY;
      if (node.minValue != null) {
        try {
          min = Float.parseFloat(node.minValue);
        } catch (NumberFormatException e) {
          // Fallback to default min.
        }
      }
      if (node.maxValue != null) {
        try {
          max = Float.parseFloat(node.maxValue);
        } catch (NumberFormatException e) {
          // Fallback to default max.
        }
      }
      try {
        float parsedValue = Float.parseFloat(node.value);
        result.setRangeInfo(
            AccessibilityNodeInfo.RangeInfo.obtain(
                AccessibilityNodeInfo.RangeInfo.RANGE_TYPE_FLOAT, min, max, parsedValue));
      } catch (NumberFormatException e) {
        if (Build.VERSION.SDK_INT >= API_LEVELS.API_36) {
          result.setRangeInfo(
              AccessibilityNodeInfo.RangeInfo.obtain(
                  AccessibilityNodeInfo.RangeInfo.RANGE_TYPE_INDETERMINATE, 0.0f, 0.0f, 0.0f));
        } else {
          // Fallback to RANGE_TYPE_FLOAT with 0.0.
          result.setRangeInfo(
              AccessibilityNodeInfo.RangeInfo.obtain(
                  AccessibilityNodeInfo.RangeInfo.RANGE_TYPE_FLOAT, 0.0f, 0.0f, 0.0f));
        }
      }
    }
  }
}
