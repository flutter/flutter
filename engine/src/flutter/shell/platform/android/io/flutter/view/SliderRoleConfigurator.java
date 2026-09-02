// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view;

import android.os.Build;
import android.view.accessibility.AccessibilityNodeInfo;
import io.flutter.Build.API_LEVELS;

/**
 * Configurator for the {@link AccessibilityBridge.Role#SLIDER} role. Sets the class name to
 * SeekBar, adds progress action, and handles range info.
 */
public class SliderRoleConfigurator extends BaseRoleConfigurator {
  @Override
  protected void configureRole(
      AccessibilityNodeInfo result, AccessibilityBridge.SemanticsNode node) {
    result.setClassName("android.widget.SeekBar");
    if (Build.VERSION.SDK_INT >= API_LEVELS.API_24) {
      result.addAction(AccessibilityNodeInfo.AccessibilityAction.ACTION_SET_PROGRESS);
    }
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
        String valueString = node.value;
        boolean isPercentage = valueString != null && valueString.endsWith("%");
        if (isPercentage) {
          valueString = valueString.substring(0, valueString.length() - 1);
        }
        float parsedValue = Float.parseFloat(valueString);
        if (isPercentage) {
          // Convert the percentage to a value between min and max.
          if (max != Float.POSITIVE_INFINITY && min != Float.NEGATIVE_INFINITY) {
            parsedValue = (parsedValue / 100.0f) * (max - min) + min;
          }
        }
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
