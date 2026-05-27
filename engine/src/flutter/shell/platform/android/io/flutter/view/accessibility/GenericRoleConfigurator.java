// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view.accessibility;

import android.os.Build;
import android.view.View;
import android.view.accessibility.AccessibilityNodeInfo;
import io.flutter.Build.API_LEVELS;
import io.flutter.BuildConfig;
import io.flutter.Log;
import java.util.List;

/**
 * Configurator for the {@link AccessibilityBridge.Role#NONE} role. Implements the legacy behavior
 * of determining the class name based on semantics properties and flags.
 */
public class GenericRoleConfigurator implements AccessibilityNodeConfigurator {
  private static final String TAG = "GenericRoleConfigurator";

  @Override
  public void configure(AccessibilityNodeInfo result, AccessibilityBridge.SemanticsNode node) {
    configureTextField(result, node);

    if (node.shouldBeTreatedAsButton()) {
      result.setClassName("android.widget.Button");
    }
    if (node.hasFlag(AccessibilityBridge.Flag.IS_IMAGE)) {
      result.setClassName("android.widget.ImageView");
      // TODO(jonahwilliams): Figure out a way conform to the expected id from TalkBack's
      // CustomLabelManager. talkback/src/main/java/labeling/CustomLabelManager.java#L525
    }

    if (!node.hasAction(AccessibilityBridge.Action.TAP)
        && node.hasFlag(AccessibilityBridge.Flag.IS_SLIDER)) {
      // Prevent Slider to receive a regular tap which will change the value.
      //
      // This is needed because it causes slider to select to middle if it
      // doesn't have a semantics tap.
      result.addAction(AccessibilityNodeInfo.ACTION_CLICK);
      result.setClickable(true);
    }

    configureScrollable(result, node);

    // We should prefer setCollectionInfo to the class names, as this way we get "In List"
    // and "Out of list" announcements.  But we don't always know the counts, so we
    // can fallback to the generic scroll view class names.
    //
    // On older APIs, we always fall back to the generic scroll view class names here.
    //
    // TODO(dnfield): We should add semantics properties for rows and columns in 2 dimensional
    // lists, e.g.
    // GridView.  Right now, we're only supporting ListViews and only if they have scroll
    // children.
    if (node.accessibilityBridge.shouldSetCollectionInfo(node)) {
      if (node.hasAction(AccessibilityBridge.Action.SCROLL_LEFT)
          || node.hasAction(AccessibilityBridge.Action.SCROLL_RIGHT)) {
        // This code will only run on devices with API level 32 or lower.
        // The obtain method was deprecated in API 33.
        if (Build.VERSION.SDK_INT < API_LEVELS.API_33) {
          result.setCollectionInfo(
              AccessibilityNodeInfo.CollectionInfo.obtain(
                  1, // row count
                  node.scrollChildren, // column count
                  false // hierarchical
                  ));
        } else {
          result.setCollectionInfo(
              new AccessibilityNodeInfo.CollectionInfo(
                  1, // row count
                  node.scrollChildren, // column count
                  false // hierarchical
                  ));
        }
      } else {
        // This code will only run on devices with API level 32 or lower.
        // The obtain method was deprecated in API 33.
        if (Build.VERSION.SDK_INT < API_LEVELS.API_33) {
          result.setCollectionInfo(
              AccessibilityNodeInfo.CollectionInfo.obtain(
                  node.scrollChildren, // row count
                  1, // column count
                  false // hierarchical
                  ));
        } else {
          result.setCollectionInfo(
              new AccessibilityNodeInfo.CollectionInfo(
                  node.scrollChildren, // row count
                  1, // column count
                  false // hierarchical
                  ));
        }
      }
    }

    if (node.accessibilityBridge.shouldSetCollectionItemInfo(node)) {
      AccessibilityBridge.SemanticsNode parent = node.parent;
      List<AccessibilityBridge.SemanticsNode> scrollChildren = parent.childrenInTraversalOrder;
      boolean verticalScroll =
          !(parent.hasAction(AccessibilityBridge.Action.SCROLL_LEFT)
              || parent.hasAction(AccessibilityBridge.Action.SCROLL_RIGHT));
      int nodeIndex = scrollChildren.indexOf(node);
      if (verticalScroll) {
        // This code will only run on devices with API level 32 or lower.
        // The obtain method was deprecated in API 33.
        if (Build.VERSION.SDK_INT < 33) {
          result.setCollectionItemInfo(
              AccessibilityNodeInfo.CollectionItemInfo.obtain(
                  nodeIndex, // row index
                  1, // row span
                  0, // column index
                  1, // column span
                  node.hasFlag(AccessibilityBridge.Flag.IS_HEADER) // is heading
                  ));
        } else {
          result.setCollectionItemInfo(
              new AccessibilityNodeInfo.CollectionItemInfo(
                  nodeIndex, // row index
                  1, // row span
                  0, // column index
                  1, // column span
                  node.hasFlag(AccessibilityBridge.Flag.IS_HEADER) // is heading
                  ));
        }
      } else {
        // This code will only run on devices with API level 32 or lower.
        // The obtain method was deprecated in API 33.
        if (Build.VERSION.SDK_INT < 33) {
          result.setCollectionItemInfo(
              AccessibilityNodeInfo.CollectionItemInfo.obtain(
                  0, // row index
                  1, // row span
                  nodeIndex, // column index
                  1, // column span
                  node.hasFlag(AccessibilityBridge.Flag.IS_HEADER) // is heading
                  ));
        } else {
          result.setCollectionItemInfo(
              new AccessibilityNodeInfo.CollectionItemInfo(
                  0, // row index
                  1, // row span
                  nodeIndex, // column index
                  1, // column span
                  node.hasFlag(AccessibilityBridge.Flag.IS_HEADER) // is heading
                  ));
        }
      }
    }

    // TODO(ianh): Once we're on SDK v23+, call addAction to
    // expose AccessibilityAction.ACTION_SCROLL_LEFT, _RIGHT,
    // _UP, and _DOWN when appropriate.
    if (node.hasAction(AccessibilityBridge.Action.SCROLL_LEFT)
        || node.hasAction(AccessibilityBridge.Action.SCROLL_UP)) {
      result.addAction(AccessibilityNodeInfo.ACTION_SCROLL_FORWARD);
    }
    if (node.hasAction(AccessibilityBridge.Action.SCROLL_RIGHT)
        || node.hasAction(AccessibilityBridge.Action.SCROLL_DOWN)) {
      result.addAction(AccessibilityNodeInfo.ACTION_SCROLL_BACKWARD);
    }

    if (node.hasAction(AccessibilityBridge.Action.INCREASE)
        || node.hasAction(AccessibilityBridge.Action.DECREASE)) {
      // TODO(jonahwilliams): support AccessibilityAction.ACTION_SET_PROGRESS once SDK is
      // updated.
      result.setClassName("android.widget.SeekBar");
      if (node.hasAction(AccessibilityBridge.Action.INCREASE)) {
        result.addAction(AccessibilityNodeInfo.ACTION_SCROLL_FORWARD);
      }
      if (node.hasAction(AccessibilityBridge.Action.DECREASE)) {
        result.addAction(AccessibilityNodeInfo.ACTION_SCROLL_BACKWARD);
      }
    }

    // Scopes routes are not focusable, only need to set the content
    // for non-scopes-routes semantics nodes.
    if (node.hasFlag(AccessibilityBridge.Flag.IS_TEXT_FIELD)) {
      result.setText(node.getValue());
      if (Build.VERSION.SDK_INT >= API_LEVELS.API_28) {
        result.setHintText(node.getTextFieldHint());
      }
    } else if (!node.hasFlag(AccessibilityBridge.Flag.SCOPES_ROUTE)) {
      CharSequence content = node.getValueLabelHint();
      if (Build.VERSION.SDK_INT < API_LEVELS.API_28) {
        if (node.tooltip != null) {
          // For backward compatibility with Flutter SDK before Android API
          // level 28, the tooltip is appended at the end of content description.
          content = content != null ? content : "";
          content = content + "\n" + node.tooltip;
        }
      }
      if (content != null) {
        result.setContentDescription(content);
      }
    }

    if (Build.VERSION.SDK_INT >= API_LEVELS.API_28) {
      if (node.tooltip != null) {
        result.setTooltipText(node.tooltip);
        // Tooltips are not announced when a node is focused resulting in no
        // message. This is only announced after a long press and the tooltip
        // is shown.
        // To be consistent with platforms other than Android and prevent
        // TalkBack from announcing the node as unlabeled, a content
        // description is set.
        if (node.getValueLabelHint() == null) {
          result.setContentDescription(node.tooltip);
        }
      }
    }

    boolean hasCheckedState = node.hasFlag(AccessibilityBridge.Flag.HAS_CHECKED_STATE);
    boolean hasToggledState = node.hasFlag(AccessibilityBridge.Flag.HAS_TOGGLED_STATE);
    if (BuildConfig.DEBUG && (hasCheckedState && hasToggledState)) {
      Log.e(TAG, "Expected semanticsNode to have checked state and toggled state.");
    }
    result.setCheckable(hasCheckedState || hasToggledState);
    if (hasCheckedState) {
      if (node.hasFlag(AccessibilityBridge.Flag.IS_IN_MUTUALLY_EXCLUSIVE_GROUP)) {
        result.setClassName("android.widget.RadioButton");
      } else {
        result.setClassName("android.widget.CheckBox");
      }
      setChecked(
          result,
          node.hasFlag(AccessibilityBridge.Flag.IS_CHECKED),
          node.hasFlag(AccessibilityBridge.Flag.IS_CHECK_STATE_MIXED));
    } else if (hasToggledState) {
      result.setClassName("android.widget.Switch");
      setChecked(result, node.hasFlag(AccessibilityBridge.Flag.IS_TOGGLED), false);
    }

    // Starting on API level 36, setExpandedState is available on AccessibilityNodeInfo.
    if (Build.VERSION.SDK_INT >= API_LEVELS.API_36) {
      if (node.hasFlag(AccessibilityBridge.Flag.HAS_EXPANDED_STATE)) {
        final boolean isExpanded = node.hasFlag(AccessibilityBridge.Flag.IS_EXPANDED);
        result.setExpandedState(
            isExpanded
                ? AccessibilityNodeInfo.EXPANDED_STATE_FULL
                : AccessibilityNodeInfo.EXPANDED_STATE_COLLAPSED);
        if (node.hasAction(AccessibilityBridge.Action.EXPAND)) {
          result.addAction(AccessibilityNodeInfo.ACTION_EXPAND);
        }
        if (node.hasAction(AccessibilityBridge.Action.COLLAPSE)) {
          result.addAction(AccessibilityNodeInfo.ACTION_COLLAPSE);
        }
      }
    }
  }

  private void setChecked(AccessibilityNodeInfo result, boolean isChecked, boolean isMixed) {
    // Starting on API level 36, setChecked takes int instead.
    if (Build.VERSION.SDK_INT >= API_LEVELS.API_36) {
      result.setChecked(
          isMixed
              ? AccessibilityNodeInfo.CHECKED_STATE_PARTIAL
              : isChecked
                  ? AccessibilityNodeInfo.CHECKED_STATE_TRUE
                  : AccessibilityNodeInfo.CHECKED_STATE_FALSE);
    } else {
      result.setChecked(isChecked);
    }
  }

  private void configureTextField(
      AccessibilityNodeInfo result, AccessibilityBridge.SemanticsNode node) {
    if (node.hasFlag(AccessibilityBridge.Flag.IS_TEXT_FIELD)) {
      result.setPassword(node.hasFlag(AccessibilityBridge.Flag.IS_OBSCURED));
      if (!node.hasFlag(AccessibilityBridge.Flag.IS_READ_ONLY)) {
        result.setClassName("android.widget.EditText");
      }
      result.setEditable(!node.hasFlag(AccessibilityBridge.Flag.IS_READ_ONLY));
      if (node.textSelectionBase != -1 && node.textSelectionExtent != -1) {
        result.setTextSelection(node.textSelectionBase, node.textSelectionExtent);
      }
      if (node.accessibilityBridge.accessibilityFocusedSemanticsNode != null
          && node.accessibilityBridge.accessibilityFocusedSemanticsNode.id == node.id) {
        result.setLiveRegion(View.ACCESSIBILITY_LIVE_REGION_POLITE);
      }

      int granularities = 0;
      if (node.hasAction(AccessibilityBridge.Action.MOVE_CURSOR_FORWARD_BY_CHARACTER)) {
        result.addAction(AccessibilityNodeInfo.ACTION_NEXT_AT_MOVEMENT_GRANULARITY);
        granularities |= AccessibilityNodeInfo.MOVEMENT_GRANULARITY_CHARACTER;
      }
      if (node.hasAction(AccessibilityBridge.Action.MOVE_CURSOR_BACKWARD_BY_CHARACTER)) {
        result.addAction(AccessibilityNodeInfo.ACTION_PREVIOUS_AT_MOVEMENT_GRANULARITY);
        granularities |= AccessibilityNodeInfo.MOVEMENT_GRANULARITY_CHARACTER;
      }
      if (node.hasAction(AccessibilityBridge.Action.MOVE_CURSOR_FORWARD_BY_WORD)) {
        result.addAction(AccessibilityNodeInfo.ACTION_NEXT_AT_MOVEMENT_GRANULARITY);
        granularities |= AccessibilityNodeInfo.MOVEMENT_GRANULARITY_WORD;
      }
      if (node.hasAction(AccessibilityBridge.Action.MOVE_CURSOR_BACKWARD_BY_WORD)) {
        result.addAction(AccessibilityNodeInfo.ACTION_PREVIOUS_AT_MOVEMENT_GRANULARITY);
        granularities |= AccessibilityNodeInfo.MOVEMENT_GRANULARITY_WORD;
      }
      result.setMovementGranularities(granularities);
      if (node.maxValueLength >= 0) {
        final int length = node.value == null ? 0 : node.value.length();
        result.setMaxTextLength(length - node.currentValueLength + node.maxValueLength);
      }
    }
  }

  private void configureScrollable(
      AccessibilityNodeInfo result, AccessibilityBridge.SemanticsNode node) {
    if (node.hasAction(AccessibilityBridge.Action.SCROLL_LEFT)
        || node.hasAction(AccessibilityBridge.Action.SCROLL_UP)
        || node.hasAction(AccessibilityBridge.Action.SCROLL_RIGHT)
        || node.hasAction(AccessibilityBridge.Action.SCROLL_DOWN)) {
      result.setScrollable(true);
      if (node.hasFlag(AccessibilityBridge.Flag.HAS_IMPLICIT_SCROLLING)) {
        if (node.hasAction(AccessibilityBridge.Action.SCROLL_LEFT)
            || node.hasAction(AccessibilityBridge.Action.SCROLL_RIGHT)) {
          result.setClassName("android.widget.HorizontalScrollView");
        } else {
          result.setClassName("android.widget.ScrollView");
        }
      }
    }
  }
}
