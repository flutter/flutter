// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view;

import android.os.Build;
import android.view.View;
import android.view.accessibility.AccessibilityNodeInfo;
import io.flutter.Build.API_LEVELS;
import io.flutter.BuildConfig;
import io.flutter.Log;
import java.util.List;

/**
 * Base class for {@link AccessibilityNodeConfigurator} implementations that compose common
 * semantics behaviors before applying role-specific configuration.
 *
 * This class also serves as the default configurator for nodes with no specific role (Role.NONE).
 */
public class BaseRoleConfigurator implements AccessibilityNodeConfigurator {
  private static final AccessibilityNodeConfigurator[] commonConfigurators =
      new AccessibilityNodeConfigurator[] {
        new FocusableConfigurator(),
        new ClipboardConfigurator(),
        new DismissableConfigurator(),
        new TappableConfigurator(),
        new LiveRegionConfigurator(),
        new SelectableConfigurator(),
        new HeadingConfigurator(),
        new CustomActionsConfigurator(),
        new TextFieldConfigurator(),
        new ButtonConfigurator(),
        new ImageConfigurator(),
        new SliderConfigurator(),
        new ScrollableConfigurator(),
        new CollectionConfigurator(),
        new CollectionItemConfigurator(),
        new LabelAndValueConfigurator(),
        new CheckableConfigurator(),
        new ExpandedConfigurator()
      };

  @Override
  public final void configure(AccessibilityNodeInfo result, AccessibilityBridge.SemanticsNode node) {
    for (AccessibilityNodeConfigurator configurator : commonConfigurators) {
      configurator.configure(result, node);
    }
    configureRole(result, node);
  }

  /**
   * Override this method to apply role-specific configuration.
   * The default implementation is a no-op, suitable for the generic role (Role.NONE).
   */
  protected void configureRole(
      AccessibilityNodeInfo result, AccessibilityBridge.SemanticsNode node) {
    // Default implementation is a no-op.
  }
}

// =============================================================================
// CONSOLIDATED BEHAVIOR CONFIGURATORS (PACKAGE-PRIVATE)
// =============================================================================

class FocusableConfigurator implements AccessibilityNodeConfigurator {
  @Override
  public void configure(AccessibilityNodeInfo result, AccessibilityBridge.SemanticsNode node) {
    result.setFocusable(node.isFocusable());
    if (node.accessibilityBridge.inputFocusedSemanticsNode != null) {
      result.setFocused(node.accessibilityBridge.inputFocusedSemanticsNode.id == node.id);
    }
    if (node.accessibilityBridge.accessibilityFocusedSemanticsNode != null) {
      result.setAccessibilityFocused(
          node.accessibilityBridge.accessibilityFocusedSemanticsNode.id == node.id);
    }
    if (node.accessibilityBridge.accessibilityFocusedSemanticsNode != null
        && node.accessibilityBridge.accessibilityFocusedSemanticsNode.id == node.id) {
      result.addAction(AccessibilityNodeInfo.ACTION_CLEAR_ACCESSIBILITY_FOCUS);
    } else {
      result.addAction(AccessibilityNodeInfo.ACTION_ACCESSIBILITY_FOCUS);
    }
  }
}

class ClipboardConfigurator implements AccessibilityNodeConfigurator {
  @Override
  public void configure(AccessibilityNodeInfo result, AccessibilityBridge.SemanticsNode node) {
    if (node.hasAction(AccessibilityBridge.Action.SET_SELECTION)) {
      result.addAction(AccessibilityNodeInfo.ACTION_SET_SELECTION);
    }
    if (node.hasAction(AccessibilityBridge.Action.COPY)) {
      result.addAction(AccessibilityNodeInfo.ACTION_COPY);
    }
    if (node.hasAction(AccessibilityBridge.Action.CUT)) {
      result.addAction(AccessibilityNodeInfo.ACTION_CUT);
    }
    if (node.hasAction(AccessibilityBridge.Action.PASTE)) {
      result.addAction(AccessibilityNodeInfo.ACTION_PASTE);
    }
    if (node.hasAction(AccessibilityBridge.Action.SET_TEXT)) {
      result.addAction(AccessibilityNodeInfo.ACTION_SET_TEXT);
    }
  }
}

class DismissableConfigurator implements AccessibilityNodeConfigurator {
  @Override
  public void configure(AccessibilityNodeInfo result, AccessibilityBridge.SemanticsNode node) {
    if (node.hasAction(AccessibilityBridge.Action.DISMISS)) {
      result.setDismissable(true);
      result.addAction(AccessibilityNodeInfo.ACTION_DISMISS);
    }
  }
}

class TappableConfigurator implements AccessibilityNodeConfigurator {
  @Override
  public void configure(AccessibilityNodeInfo result, AccessibilityBridge.SemanticsNode node) {
    if (node.hasAction(AccessibilityBridge.Action.TAP)) {
      if (node.onTapOverride != null) {
        result.addAction(
            new AccessibilityNodeInfo.AccessibilityAction(
                AccessibilityNodeInfo.ACTION_CLICK, node.onTapOverride.hint));
        result.setClickable(true);
      } else {
        result.addAction(AccessibilityNodeInfo.ACTION_CLICK);
        result.setClickable(true);
      }
    }
    if (node.hasAction(AccessibilityBridge.Action.LONG_PRESS)) {
      if (node.onLongPressOverride != null) {
        result.addAction(
            new AccessibilityNodeInfo.AccessibilityAction(
                AccessibilityNodeInfo.ACTION_LONG_CLICK, node.onLongPressOverride.hint));
        result.setLongClickable(true);
      } else {
        result.addAction(AccessibilityNodeInfo.ACTION_LONG_CLICK);
        result.setLongClickable(true);
      }
    }
  }
}

class LiveRegionConfigurator implements AccessibilityNodeConfigurator {
  @Override
  public void configure(AccessibilityNodeInfo result, AccessibilityBridge.SemanticsNode node) {
    if (node.hasFlag(AccessibilityBridge.Flag.IS_LIVE_REGION)) {
      result.setLiveRegion(View.ACCESSIBILITY_LIVE_REGION_POLITE);
    }
  }
}

class SelectableConfigurator implements AccessibilityNodeConfigurator {
  @Override
  public void configure(AccessibilityNodeInfo result, AccessibilityBridge.SemanticsNode node) {
    result.setSelected(node.hasFlag(AccessibilityBridge.Flag.IS_SELECTED));
  }
}

class HeadingConfigurator implements AccessibilityNodeConfigurator {
  @Override
  public void configure(AccessibilityNodeInfo result, AccessibilityBridge.SemanticsNode node) {
    if (Build.VERSION.SDK_INT >= API_LEVELS.API_28) {
      result.setHeading(node.headingLevel > 0);
    }
  }
}

class CustomActionsConfigurator implements AccessibilityNodeConfigurator {
  @Override
  public void configure(AccessibilityNodeInfo result, AccessibilityBridge.SemanticsNode node) {
    if (node.customAccessibilityActions != null) {
      for (AccessibilityBridge.CustomAccessibilityAction action : node.customAccessibilityActions) {
        result.addAction(
            new AccessibilityNodeInfo.AccessibilityAction(action.resourceId, action.label));
      }
    }
  }
}

class TextFieldConfigurator implements AccessibilityNodeConfigurator {
  @Override
  public void configure(AccessibilityNodeInfo result, AccessibilityBridge.SemanticsNode node) {
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
}

class ButtonConfigurator implements AccessibilityNodeConfigurator {
  @Override
  public void configure(AccessibilityNodeInfo result, AccessibilityBridge.SemanticsNode node) {
    if (node.shouldBeTreatedAsButton()) {
      result.setClassName("android.widget.Button");
    }
  }
}

class ImageConfigurator implements AccessibilityNodeConfigurator {
  @Override
  public void configure(AccessibilityNodeInfo result, AccessibilityBridge.SemanticsNode node) {
    if (node.hasFlag(AccessibilityBridge.Flag.IS_IMAGE)) {
      result.setClassName("android.widget.ImageView");
    }
  }
}

class SliderConfigurator implements AccessibilityNodeConfigurator {
  @Override
  public void configure(AccessibilityNodeInfo result, AccessibilityBridge.SemanticsNode node) {
    if (!node.hasAction(AccessibilityBridge.Action.TAP)
        && node.hasFlag(AccessibilityBridge.Flag.IS_SLIDER)) {
      result.addAction(AccessibilityNodeInfo.ACTION_CLICK);
      result.setClickable(true);
    }

    if (node.hasAction(AccessibilityBridge.Action.INCREASE)
        || node.hasAction(AccessibilityBridge.Action.DECREASE)) {
      result.setClassName("android.widget.SeekBar");
      if (node.hasAction(AccessibilityBridge.Action.INCREASE)) {
        result.addAction(AccessibilityNodeInfo.ACTION_SCROLL_FORWARD);
      }
      if (node.hasAction(AccessibilityBridge.Action.DECREASE)) {
        result.addAction(AccessibilityNodeInfo.ACTION_SCROLL_BACKWARD);
      }
    }
  }
}

class ScrollableConfigurator implements AccessibilityNodeConfigurator {
  @Override
  public void configure(AccessibilityNodeInfo result, AccessibilityBridge.SemanticsNode node) {
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

    if (node.hasAction(AccessibilityBridge.Action.SCROLL_LEFT)
        || node.hasAction(AccessibilityBridge.Action.SCROLL_UP)) {
      result.addAction(AccessibilityNodeInfo.ACTION_SCROLL_FORWARD);
    }
    if (node.hasAction(AccessibilityBridge.Action.SCROLL_RIGHT)
        || node.hasAction(AccessibilityBridge.Action.SCROLL_DOWN)) {
      result.addAction(AccessibilityNodeInfo.ACTION_SCROLL_BACKWARD);
    }
  }
}

class CollectionConfigurator implements AccessibilityNodeConfigurator {
  @Override
  public void configure(AccessibilityNodeInfo result, AccessibilityBridge.SemanticsNode node) {
    if (node.accessibilityBridge.shouldSetCollectionInfo(node)) {
      if (node.hasAction(AccessibilityBridge.Action.SCROLL_LEFT)
          || node.hasAction(AccessibilityBridge.Action.SCROLL_RIGHT)) {
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
  }
}

class CollectionItemConfigurator implements AccessibilityNodeConfigurator {
  @Override
  public void configure(AccessibilityNodeInfo result, AccessibilityBridge.SemanticsNode node) {
    if (node.accessibilityBridge.shouldSetCollectionItemInfo(node)) {
      AccessibilityBridge.SemanticsNode parent = node.parent;
      List<AccessibilityBridge.SemanticsNode> scrollChildren = parent.childrenInTraversalOrder;
      boolean verticalScroll =
          !(parent.hasAction(AccessibilityBridge.Action.SCROLL_LEFT)
              || parent.hasAction(AccessibilityBridge.Action.SCROLL_RIGHT));
      int nodeIndex = scrollChildren.indexOf(node);
      if (verticalScroll) {
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
  }
}

class LabelAndValueConfigurator implements AccessibilityNodeConfigurator {
  @Override
  public void configure(AccessibilityNodeInfo result, AccessibilityBridge.SemanticsNode node) {
    if (node.hasFlag(AccessibilityBridge.Flag.IS_TEXT_FIELD)) {
      result.setText(node.getValue());
      if (Build.VERSION.SDK_INT >= API_LEVELS.API_28) {
        result.setHintText(node.getTextFieldHint());
      }
    } else if (!node.hasFlag(AccessibilityBridge.Flag.SCOPES_ROUTE)) {
      CharSequence content = node.getValueLabelHint();
      if (Build.VERSION.SDK_INT < API_LEVELS.API_28) {
        if (node.tooltip != null) {
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
        if (node.getValueLabelHint() == null) {
          result.setContentDescription(node.tooltip);
        }
      }
    }
  }
}

class CheckableConfigurator implements AccessibilityNodeConfigurator {
  private static final String TAG = "CheckableConfigurator";

  @Override
  public void configure(AccessibilityNodeInfo result, AccessibilityBridge.SemanticsNode node) {
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
  }

  private void setChecked(AccessibilityNodeInfo result, boolean isChecked, boolean isMixed) {
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
}

class ExpandedConfigurator implements AccessibilityNodeConfigurator {
  @Override
  public void configure(AccessibilityNodeInfo result, AccessibilityBridge.SemanticsNode node) {
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
}
