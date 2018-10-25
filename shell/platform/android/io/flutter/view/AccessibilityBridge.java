// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view;

import android.app.Activity;
import android.graphics.Rect;
import android.opengl.Matrix;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.view.accessibility.AccessibilityEvent;
import android.view.accessibility.AccessibilityNodeInfo;
import android.view.accessibility.AccessibilityNodeProvider;
import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.StandardMessageCodec;

import java.nio.ByteBuffer;
import java.util.*;

class AccessibilityBridge
        extends AccessibilityNodeProvider implements BasicMessageChannel.MessageHandler<Object> {
    private static final String TAG = "FlutterView";

    // Constants from higher API levels.
    // TODO(goderbauer): Get these from Android Support Library when
    // https://github.com/flutter/flutter/issues/11099 is resolved.
    private static final int ACTION_SHOW_ON_SCREEN = 16908342; // API level 23

    private static final float SCROLL_EXTENT_FOR_INFINITY = 100000.0f;
    private static final float SCROLL_POSITION_CAP_FOR_INFINITY = 70000.0f;
    private static final int ROOT_NODE_ID = 0;

    private Map<Integer, SemanticsObject> mObjects;
    private Map<Integer, CustomAccessibilityAction> mCustomAccessibilityActions;
    private final FlutterView mOwner;
    private boolean mAccessibilityEnabled = false;
    private SemanticsObject mA11yFocusedObject;
    private SemanticsObject mInputFocusedObject;
    private SemanticsObject mHoveredObject;
    private int previousRouteId = ROOT_NODE_ID;
    private List<Integer> previousRoutes;
    private final View mDecorView;
    private Integer mLastLeftFrameInset = 0;

    private final BasicMessageChannel<Object> mFlutterAccessibilityChannel;

    enum Action {
        TAP(1 << 0),
        LONG_PRESS(1 << 1),
        SCROLL_LEFT(1 << 2),
        SCROLL_RIGHT(1 << 3),
        SCROLL_UP(1 << 4),
        SCROLL_DOWN(1 << 5),
        INCREASE(1 << 6),
        DECREASE(1 << 7),
        SHOW_ON_SCREEN(1 << 8),
        MOVE_CURSOR_FORWARD_BY_CHARACTER(1 << 9),
        MOVE_CURSOR_BACKWARD_BY_CHARACTER(1 << 10),
        SET_SELECTION(1 << 11),
        COPY(1 << 12),
        CUT(1 << 13),
        PASTE(1 << 14),
        DID_GAIN_ACCESSIBILITY_FOCUS(1 << 15),
        DID_LOSE_ACCESSIBILITY_FOCUS(1 << 16),
        CUSTOM_ACTION(1 << 17),
        DISMISS(1 << 18),
        MOVE_CURSOR_FORWARD_BY_WORD(1 << 19),
        MOVE_CURSOR_BACKWARD_BY_WORD(1 << 20);

        Action(int value) {
            this.value = value;
        }

        final int value;
    }

    enum Flag {
        HAS_CHECKED_STATE(1 << 0),
        IS_CHECKED(1 << 1),
        IS_SELECTED(1 << 2),
        IS_BUTTON(1 << 3),
        IS_TEXT_FIELD(1 << 4),
        IS_FOCUSED(1 << 5),
        HAS_ENABLED_STATE(1 << 6),
        IS_ENABLED(1 << 7),
        IS_IN_MUTUALLY_EXCLUSIVE_GROUP(1 << 8),
        IS_HEADER(1 << 9),
        IS_OBSCURED(1 << 10),
        SCOPES_ROUTE(1 << 11),
        NAMES_ROUTE(1 << 12),
        IS_HIDDEN(1 << 13),
        IS_IMAGE(1 << 14),
        IS_LIVE_REGION(1 << 15),
        HAS_TOGGLED_STATE(1 << 16),
        IS_TOGGLED(1 << 17),
        HAS_IMPLICIT_SCROLLING(1 << 18);

        Flag(int value) {
            this.value = value;
        }

        final int value;
    }

    AccessibilityBridge(FlutterView owner) {
        assert owner != null;
        mOwner = owner;
        mObjects = new HashMap<Integer, SemanticsObject>();
        mCustomAccessibilityActions = new HashMap<Integer, CustomAccessibilityAction>();
        previousRoutes = new ArrayList<>();
        mFlutterAccessibilityChannel = new BasicMessageChannel<>(
                owner, "flutter/accessibility", StandardMessageCodec.INSTANCE);
        mDecorView = ((Activity) owner.getContext()).getWindow().getDecorView();
    }

    void setAccessibilityEnabled(boolean accessibilityEnabled) {
        mAccessibilityEnabled = accessibilityEnabled;
        if (accessibilityEnabled) {
            mFlutterAccessibilityChannel.setMessageHandler(this);
        } else {
            mFlutterAccessibilityChannel.setMessageHandler(null);
        }
    }

    @Override
    @SuppressWarnings("deprecation")
    public AccessibilityNodeInfo createAccessibilityNodeInfo(int virtualViewId) {
        if (virtualViewId == View.NO_ID) {
            AccessibilityNodeInfo result = AccessibilityNodeInfo.obtain(mOwner);
            mOwner.onInitializeAccessibilityNodeInfo(result);
            if (mObjects.containsKey(ROOT_NODE_ID)) {
                result.addChild(mOwner, ROOT_NODE_ID);
            }
            return result;
        }

        SemanticsObject object = mObjects.get(virtualViewId);
        if (object == null) {
            return null;
        }

        AccessibilityNodeInfo result = AccessibilityNodeInfo.obtain(mOwner, virtualViewId);
        // Work around for https://github.com/flutter/flutter/issues/2101
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
            result.setViewIdResourceName("");
        }
        result.setPackageName(mOwner.getContext().getPackageName());
        result.setClassName("android.view.View");
        result.setSource(mOwner, virtualViewId);
        result.setFocusable(object.isFocusable());
        if (mInputFocusedObject != null) {
            result.setFocused(mInputFocusedObject.id == virtualViewId);
        }

        if (mA11yFocusedObject != null) {
            result.setAccessibilityFocused(mA11yFocusedObject.id == virtualViewId);
        }

        if (object.hasFlag(Flag.IS_TEXT_FIELD)) {
            result.setPassword(object.hasFlag(Flag.IS_OBSCURED));
            result.setClassName("android.widget.EditText");
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
                result.setEditable(true);
                if (object.textSelectionBase != -1 && object.textSelectionExtent != -1) {
                    result.setTextSelection(object.textSelectionBase, object.textSelectionExtent);
                }
                // Text fields will always be created as a live region when they have input focus,
                // so that updates to the label trigger polite announcements. This makes it easy to
                // follow a11y guidelines for text fields on Android.
                if (Build.VERSION.SDK_INT > Build.VERSION_CODES.JELLY_BEAN_MR2 && mA11yFocusedObject != null && mA11yFocusedObject.id == virtualViewId) {
                    result.setLiveRegion(View.ACCESSIBILITY_LIVE_REGION_POLITE);
                }
            }

            // Cursor movements
            int granularities = 0;
            if (object.hasAction(Action.MOVE_CURSOR_FORWARD_BY_CHARACTER)) {
                result.addAction(AccessibilityNodeInfo.ACTION_NEXT_AT_MOVEMENT_GRANULARITY);
                granularities |= AccessibilityNodeInfo.MOVEMENT_GRANULARITY_CHARACTER;
            }
            if (object.hasAction(Action.MOVE_CURSOR_BACKWARD_BY_CHARACTER)) {
                result.addAction(AccessibilityNodeInfo.ACTION_PREVIOUS_AT_MOVEMENT_GRANULARITY);
                granularities |= AccessibilityNodeInfo.MOVEMENT_GRANULARITY_CHARACTER;
            }
            if (object.hasAction(Action.MOVE_CURSOR_FORWARD_BY_WORD)) {
                result.addAction(AccessibilityNodeInfo.ACTION_NEXT_AT_MOVEMENT_GRANULARITY);
                granularities |= AccessibilityNodeInfo.MOVEMENT_GRANULARITY_WORD;
            }
            if (object.hasAction(Action.MOVE_CURSOR_BACKWARD_BY_WORD)) {
                result.addAction(AccessibilityNodeInfo.ACTION_PREVIOUS_AT_MOVEMENT_GRANULARITY);
                granularities |= AccessibilityNodeInfo.MOVEMENT_GRANULARITY_WORD;
            }
            result.setMovementGranularities(granularities);
        }
        if (object.hasAction(Action.SET_SELECTION)) {
            result.addAction(AccessibilityNodeInfo.ACTION_SET_SELECTION);
        }
        if (object.hasAction(Action.COPY)) {
            result.addAction(AccessibilityNodeInfo.ACTION_COPY);
        }
        if (object.hasAction(Action.CUT)) {
            result.addAction(AccessibilityNodeInfo.ACTION_CUT);
        }
        if (object.hasAction(Action.PASTE)) {
            result.addAction(AccessibilityNodeInfo.ACTION_PASTE);
        }

        if (object.hasFlag(Flag.IS_BUTTON)) {
            result.setClassName("android.widget.Button");
        }
        if (object.hasFlag(Flag.IS_IMAGE)) {
            result.setClassName("android.widget.ImageView");
            // TODO(jonahwilliams): Figure out a way conform to the expected id from TalkBack's
            // CustomLabelManager. talkback/src/main/java/labeling/CustomLabelManager.java#L525
        }
        if (Build.VERSION.SDK_INT > Build.VERSION_CODES.JELLY_BEAN_MR2 && object.hasAction(Action.DISMISS)) {
            result.setDismissable(true);
            result.addAction(AccessibilityNodeInfo.ACTION_DISMISS);
        }

        if (object.parent != null) {
            assert object.id > ROOT_NODE_ID;
            result.setParent(mOwner, object.parent.id);
        } else {
            assert object.id == ROOT_NODE_ID;
            result.setParent(mOwner);
        }

        Rect bounds = object.getGlobalRect();
        if (object.parent != null) {
            Rect parentBounds = object.parent.getGlobalRect();
            Rect boundsInParent = new Rect(bounds);
            boundsInParent.offset(-parentBounds.left, -parentBounds.top);
            result.setBoundsInParent(boundsInParent);
        } else {
            result.setBoundsInParent(bounds);
        }
        result.setBoundsInScreen(bounds);
        result.setVisibleToUser(true);
        result.setEnabled(
                !object.hasFlag(Flag.HAS_ENABLED_STATE) || object.hasFlag(Flag.IS_ENABLED));

        if (object.hasAction(Action.TAP)) {
            if (Build.VERSION.SDK_INT >= 21 && object.onTapOverride != null) {
                result.addAction(new AccessibilityNodeInfo.AccessibilityAction(
                    AccessibilityNodeInfo.ACTION_CLICK, object.onTapOverride.hint));
                result.setClickable(true);
            } else {
                result.addAction(AccessibilityNodeInfo.ACTION_CLICK);
                result.setClickable(true);
            }
        }
        if (object.hasAction(Action.LONG_PRESS)) {
            if (Build.VERSION.SDK_INT >= 21 && object.onLongPressOverride != null) {
                result.addAction(new AccessibilityNodeInfo.AccessibilityAction(AccessibilityNodeInfo.ACTION_LONG_CLICK,
                    object.onLongPressOverride.hint));
                result.setLongClickable(true);
            } else {
                result.addAction(AccessibilityNodeInfo.ACTION_LONG_CLICK);
                result.setLongClickable(true);
            }
        }
        if (object.hasAction(Action.SCROLL_LEFT) || object.hasAction(Action.SCROLL_UP)
                || object.hasAction(Action.SCROLL_RIGHT) || object.hasAction(Action.SCROLL_DOWN)) {
            result.setScrollable(true);
            // This tells Android's a11y to send scroll events when reaching the end of
            // the visible viewport of a scrollable, unless the node itself does not
            // allow implicit scrolling - then we leave the className as view.View.
            if (object.hasFlag(Flag.HAS_IMPLICIT_SCROLLING)) {
                if (object.hasAction(Action.SCROLL_LEFT) || object.hasAction(Action.SCROLL_RIGHT)) {
                    result.setClassName("android.widget.HorizontalScrollView");
                } else {
                    result.setClassName("android.widget.ScrollView");
                }
            }
            // TODO(ianh): Once we're on SDK v23+, call addAction to
            // expose AccessibilityAction.ACTION_SCROLL_LEFT, _RIGHT,
            // _UP, and _DOWN when appropriate.
            if (object.hasAction(Action.SCROLL_LEFT) || object.hasAction(Action.SCROLL_UP)) {
                result.addAction(AccessibilityNodeInfo.ACTION_SCROLL_FORWARD);
            }
            if (object.hasAction(Action.SCROLL_RIGHT) || object.hasAction(Action.SCROLL_DOWN)) {
                result.addAction(AccessibilityNodeInfo.ACTION_SCROLL_BACKWARD);
            }
        }
        if (object.hasAction(Action.INCREASE) || object.hasAction(Action.DECREASE)) {
            // TODO(jonahwilliams): support AccessibilityAction.ACTION_SET_PROGRESS once SDK is
            // updated.
            result.setClassName("android.widget.SeekBar");
            if (object.hasAction(Action.INCREASE)) {
                result.addAction(AccessibilityNodeInfo.ACTION_SCROLL_FORWARD);
            }
            if (object.hasAction(Action.DECREASE)) {
                result.addAction(AccessibilityNodeInfo.ACTION_SCROLL_BACKWARD);
            }
        }
        if (object.hasFlag(Flag.IS_LIVE_REGION) && Build.VERSION.SDK_INT > Build.VERSION_CODES.JELLY_BEAN_MR2) {
            result.setLiveRegion(View.ACCESSIBILITY_LIVE_REGION_POLITE);
        }

        boolean hasCheckedState = object.hasFlag(Flag.HAS_CHECKED_STATE);
        boolean hasToggledState = object.hasFlag(Flag.HAS_TOGGLED_STATE);
        assert !(hasCheckedState && hasToggledState);
        result.setCheckable(hasCheckedState || hasToggledState);
        if (hasCheckedState) {
            result.setChecked(object.hasFlag(Flag.IS_CHECKED));
            result.setContentDescription(object.getValueLabelHint());
            if (object.hasFlag(Flag.IS_IN_MUTUALLY_EXCLUSIVE_GROUP))
                result.setClassName("android.widget.RadioButton");
            else
                result.setClassName("android.widget.CheckBox");
        } else if (hasToggledState) {
            result.setChecked(object.hasFlag(Flag.IS_TOGGLED));
            result.setClassName("android.widget.Switch");
            result.setContentDescription(object.getValueLabelHint());
        } else {
            // Setting the text directly instead of the content description
            // will replace the "checked" or "not-checked" label.
            result.setText(object.getValueLabelHint());
        }

        result.setSelected(object.hasFlag(Flag.IS_SELECTED));

        // Accessibility Focus
        if (mA11yFocusedObject != null && mA11yFocusedObject.id == virtualViewId) {
            result.addAction(AccessibilityNodeInfo.ACTION_CLEAR_ACCESSIBILITY_FOCUS);
        } else {
            result.addAction(AccessibilityNodeInfo.ACTION_ACCESSIBILITY_FOCUS);
        }

        // Actions on the local context menu
        if (Build.VERSION.SDK_INT >= 21) {
            if (object.customAccessibilityActions != null) {
                for (CustomAccessibilityAction action : object.customAccessibilityActions) {
                    result.addAction(new AccessibilityNodeInfo.AccessibilityAction(
                            action.resourceId, action.label));
                }
            }
        }

        if (object.childrenInTraversalOrder != null) {
            for (SemanticsObject child : object.childrenInTraversalOrder) {
                if (!child.hasFlag(Flag.IS_HIDDEN)) {
                    result.addChild(mOwner, child.id);
                }
            }
        }

        return result;
    }

    @Override
    public boolean performAction(int virtualViewId, int action, Bundle arguments) {
        SemanticsObject object = mObjects.get(virtualViewId);
        if (object == null) {
            return false;
        }
        switch (action) {
            case AccessibilityNodeInfo.ACTION_CLICK: {
                // Note: TalkBack prior to Oreo doesn't use this handler and instead simulates a
                //     click event at the center of the SemanticsNode. Other a11y services might go
                //     through this handler though.
                mOwner.dispatchSemanticsAction(virtualViewId, Action.TAP);
                return true;
            }
            case AccessibilityNodeInfo.ACTION_LONG_CLICK: {
                // Note: TalkBack doesn't use this handler and instead simulates a long click event
                //     at the center of the SemanticsNode. Other a11y services might go through this
                //     handler though.
                mOwner.dispatchSemanticsAction(virtualViewId, Action.LONG_PRESS);
                return true;
            }
            case AccessibilityNodeInfo.ACTION_SCROLL_FORWARD: {
                if (object.hasAction(Action.SCROLL_UP)) {
                    mOwner.dispatchSemanticsAction(virtualViewId, Action.SCROLL_UP);
                } else if (object.hasAction(Action.SCROLL_LEFT)) {
                    // TODO(ianh): bidi support using textDirection
                    mOwner.dispatchSemanticsAction(virtualViewId, Action.SCROLL_LEFT);
                } else if (object.hasAction(Action.INCREASE)) {
                    object.value = object.increasedValue;
                    // Event causes Android to read out the updated value.
                    sendAccessibilityEvent(virtualViewId, AccessibilityEvent.TYPE_VIEW_SELECTED);
                    mOwner.dispatchSemanticsAction(virtualViewId, Action.INCREASE);
                } else {
                    return false;
                }
                return true;
            }
            case AccessibilityNodeInfo.ACTION_SCROLL_BACKWARD: {
                if (object.hasAction(Action.SCROLL_DOWN)) {
                    mOwner.dispatchSemanticsAction(virtualViewId, Action.SCROLL_DOWN);
                } else if (object.hasAction(Action.SCROLL_RIGHT)) {
                    // TODO(ianh): bidi support using textDirection
                    mOwner.dispatchSemanticsAction(virtualViewId, Action.SCROLL_RIGHT);
                } else if (object.hasAction(Action.DECREASE)) {
                    object.value = object.decreasedValue;
                    // Event causes Android to read out the updated value.
                    sendAccessibilityEvent(virtualViewId, AccessibilityEvent.TYPE_VIEW_SELECTED);
                    mOwner.dispatchSemanticsAction(virtualViewId, Action.DECREASE);
                } else {
                    return false;
                }
                return true;
            }
            case AccessibilityNodeInfo.ACTION_PREVIOUS_AT_MOVEMENT_GRANULARITY: {
                return performCursorMoveAction(object, virtualViewId, arguments, false);
            }
            case AccessibilityNodeInfo.ACTION_NEXT_AT_MOVEMENT_GRANULARITY: {
                return performCursorMoveAction(object, virtualViewId, arguments, true);
            }
            case AccessibilityNodeInfo.ACTION_CLEAR_ACCESSIBILITY_FOCUS: {
                mOwner.dispatchSemanticsAction(virtualViewId, Action.DID_LOSE_ACCESSIBILITY_FOCUS);
                sendAccessibilityEvent(
                        virtualViewId, AccessibilityEvent.TYPE_VIEW_ACCESSIBILITY_FOCUS_CLEARED);
                mA11yFocusedObject = null;
                return true;
            }
            case AccessibilityNodeInfo.ACTION_ACCESSIBILITY_FOCUS: {
                mOwner.dispatchSemanticsAction(virtualViewId, Action.DID_GAIN_ACCESSIBILITY_FOCUS);
                sendAccessibilityEvent(
                        virtualViewId, AccessibilityEvent.TYPE_VIEW_ACCESSIBILITY_FOCUSED);

                if (mA11yFocusedObject == null) {
                    // When Android focuses a node, it doesn't invalidate the view.
                    // (It does when it sends ACTION_CLEAR_ACCESSIBILITY_FOCUS, so
                    // we only have to worry about this when the focused node is null.)
                    mOwner.invalidate();
                }
                mA11yFocusedObject = object;

                if (object.hasAction(Action.INCREASE) || object.hasAction(Action.DECREASE)) {
                    // SeekBars only announce themselves after this event.
                    sendAccessibilityEvent(virtualViewId, AccessibilityEvent.TYPE_VIEW_SELECTED);
                }

                return true;
            }
            case ACTION_SHOW_ON_SCREEN: {
                mOwner.dispatchSemanticsAction(virtualViewId, Action.SHOW_ON_SCREEN);
                return true;
            }
            case AccessibilityNodeInfo.ACTION_SET_SELECTION: {
                final Map<String, Integer> selection = new HashMap<String, Integer>();
                final boolean hasSelection = arguments != null
                        && arguments.containsKey(
                                   AccessibilityNodeInfo.ACTION_ARGUMENT_SELECTION_START_INT)
                        && arguments.containsKey(
                                   AccessibilityNodeInfo.ACTION_ARGUMENT_SELECTION_END_INT);
                if (hasSelection) {
                    selection.put("base",
                            arguments.getInt(
                                    AccessibilityNodeInfo.ACTION_ARGUMENT_SELECTION_START_INT));
                    selection.put("extent",
                            arguments.getInt(
                                    AccessibilityNodeInfo.ACTION_ARGUMENT_SELECTION_END_INT));
                } else {
                    // Clear the selection
                    selection.put("base", object.textSelectionExtent);
                    selection.put("extent", object.textSelectionExtent);
                }
                mOwner.dispatchSemanticsAction(virtualViewId, Action.SET_SELECTION, selection);
                return true;
            }
            case AccessibilityNodeInfo.ACTION_COPY: {
                mOwner.dispatchSemanticsAction(virtualViewId, Action.COPY);
                return true;
            }
            case AccessibilityNodeInfo.ACTION_CUT: {
                mOwner.dispatchSemanticsAction(virtualViewId, Action.CUT);
                return true;
            }
            case AccessibilityNodeInfo.ACTION_PASTE: {
                mOwner.dispatchSemanticsAction(virtualViewId, Action.PASTE);
                return true;
            }
            case AccessibilityNodeInfo.ACTION_DISMISS: {
                mOwner.dispatchSemanticsAction(virtualViewId, Action.DISMISS);
                return true;
            }
            default:
                // might be a custom accessibility action.
                final int flutterId = action - firstResourceId;
                CustomAccessibilityAction contextAction =
                        mCustomAccessibilityActions.get(flutterId);
                if (contextAction != null) {
                    mOwner.dispatchSemanticsAction(
                            virtualViewId, Action.CUSTOM_ACTION, contextAction.id);
                    return true;
                }
        }
        return false;
    }

    boolean performCursorMoveAction(
            SemanticsObject object, int virtualViewId, Bundle arguments, boolean forward) {
        final int granularity =
                arguments.getInt(AccessibilityNodeInfo.ACTION_ARGUMENT_MOVEMENT_GRANULARITY_INT);
        final boolean extendSelection = arguments.getBoolean(
                AccessibilityNodeInfo.ACTION_ARGUMENT_EXTEND_SELECTION_BOOLEAN);
        switch (granularity) {
            case AccessibilityNodeInfo.MOVEMENT_GRANULARITY_CHARACTER: {
                if (forward && object.hasAction(Action.MOVE_CURSOR_FORWARD_BY_CHARACTER)) {
                    mOwner.dispatchSemanticsAction(virtualViewId,
                            Action.MOVE_CURSOR_FORWARD_BY_CHARACTER, extendSelection);
                    return true;
                }
                if (!forward && object.hasAction(Action.MOVE_CURSOR_BACKWARD_BY_CHARACTER)) {
                    mOwner.dispatchSemanticsAction(virtualViewId,
                            Action.MOVE_CURSOR_BACKWARD_BY_CHARACTER, extendSelection);
                    return true;
                }
                break;
            }
            case AccessibilityNodeInfo.MOVEMENT_GRANULARITY_WORD:
                if (forward && object.hasAction(Action.MOVE_CURSOR_FORWARD_BY_WORD)) {
                    mOwner.dispatchSemanticsAction(virtualViewId,
                            Action.MOVE_CURSOR_FORWARD_BY_WORD, extendSelection);
                    return true;
                }
                if (!forward && object.hasAction(Action.MOVE_CURSOR_BACKWARD_BY_WORD)) {
                    mOwner.dispatchSemanticsAction(virtualViewId,
                            Action.MOVE_CURSOR_BACKWARD_BY_WORD, extendSelection);
                    return true;
                }
                break;
        }
        return false;
    }

    // TODO(ianh): implement findAccessibilityNodeInfosByText()

    @Override
    public AccessibilityNodeInfo findFocus(int focus) {
        switch (focus) {
            case AccessibilityNodeInfo.FOCUS_INPUT: {
                if (mInputFocusedObject != null)
                    return createAccessibilityNodeInfo(mInputFocusedObject.id);
            }
            // Fall through to check FOCUS_ACCESSIBILITY
            case AccessibilityNodeInfo.FOCUS_ACCESSIBILITY: {
                if (mA11yFocusedObject != null)
                    return createAccessibilityNodeInfo(mA11yFocusedObject.id);
            }
        }
        return null;
    }

    private SemanticsObject getRootObject() {
        assert mObjects.containsKey(0);
        return mObjects.get(0);
    }

    private SemanticsObject getOrCreateObject(int id) {
        SemanticsObject object = mObjects.get(id);
        if (object == null) {
            object = new SemanticsObject();
            object.id = id;
            mObjects.put(id, object);
        }
        return object;
    }

    private CustomAccessibilityAction getOrCreateAction(int id) {
        CustomAccessibilityAction action = mCustomAccessibilityActions.get(id);
        if (action == null) {
            action = new CustomAccessibilityAction();
            action.id = id;
            action.resourceId = id + firstResourceId;
            mCustomAccessibilityActions.put(id, action);
        }
        return action;
    }

    void handleTouchExplorationExit() {
        if (mHoveredObject != null) {
            sendAccessibilityEvent(mHoveredObject.id, AccessibilityEvent.TYPE_VIEW_HOVER_EXIT);
            mHoveredObject = null;
        }
    }

    void handleTouchExploration(float x, float y) {
        if (mObjects.isEmpty()) {
            return;
        }
        SemanticsObject newObject = getRootObject().hitTest(new float[] {x, y, 0, 1});
        if (newObject != mHoveredObject) {
            // sending ENTER before EXIT is how Android wants it
            if (newObject != null) {
                sendAccessibilityEvent(newObject.id, AccessibilityEvent.TYPE_VIEW_HOVER_ENTER);
            }
            if (mHoveredObject != null) {
                sendAccessibilityEvent(mHoveredObject.id, AccessibilityEvent.TYPE_VIEW_HOVER_EXIT);
            }
            mHoveredObject = newObject;
        }
    }

    void updateCustomAccessibilityActions(ByteBuffer buffer, String[] strings) {
        while (buffer.hasRemaining()) {
            int id = buffer.getInt();
            CustomAccessibilityAction action = getOrCreateAction(id);
            action.overrideId = buffer.getInt();
            int stringIndex = buffer.getInt();
            action.label = stringIndex == -1 ? null : strings[stringIndex];
            stringIndex = buffer.getInt();
            action.hint = stringIndex == -1 ? null : strings[stringIndex];
        }
    }

    void updateSemantics(ByteBuffer buffer, String[] strings) {
        ArrayList<SemanticsObject> updated = new ArrayList<SemanticsObject>();
        while (buffer.hasRemaining()) {
            int id = buffer.getInt();
            SemanticsObject object = getOrCreateObject(id);
            object.updateWith(buffer, strings);
            if (object.hasFlag(Flag.IS_HIDDEN)) {
                continue;
            }
            if (object.hasFlag(Flag.IS_FOCUSED)) {
                mInputFocusedObject = object;
            }
            if (object.hadPreviousConfig) {
                updated.add(object);
            }
        }

        Set<SemanticsObject> visitedObjects = new HashSet<SemanticsObject>();
        SemanticsObject rootObject = getRootObject();
        List<SemanticsObject> newRoutes = new ArrayList<>();
        if (rootObject != null) {
            final float[] identity = new float[16];
            Matrix.setIdentityM(identity, 0);
            // in android devices API 23 and above, the system nav bar can be placed on the left side
            // of the screen in landscape mode. We must handle the translation ourselves for the
            // a11y nodes.
            if (Build.VERSION.SDK_INT >= 23) {
                Rect visibleFrame = new Rect();
                mDecorView.getWindowVisibleDisplayFrame(visibleFrame);
                if (!mLastLeftFrameInset.equals(visibleFrame.left)) {
                    rootObject.globalGeometryDirty = true;
                    rootObject.inverseTransformDirty = true;
                }
                mLastLeftFrameInset = visibleFrame.left;
                Matrix.translateM(identity, 0, visibleFrame.left, 0, 0);
            }
            rootObject.updateRecursively(identity, visitedObjects, false);
            rootObject.collectRoutes(newRoutes);
        }

        // Dispatch a TYPE_WINDOW_STATE_CHANGED event if the most recent route id changed from the
        // previously cached route id.
        SemanticsObject lastAdded = null;
        for (SemanticsObject semanticsObject : newRoutes) {
            if (!previousRoutes.contains(semanticsObject.id)) {
                lastAdded = semanticsObject;
            }
        }
        if (lastAdded == null && newRoutes.size() > 0) {
            lastAdded = newRoutes.get(newRoutes.size() - 1);
        }
        if (lastAdded != null && lastAdded.id != previousRouteId) {
            previousRouteId = lastAdded.id;
            createWindowChangeEvent(lastAdded);
        }
        previousRoutes.clear();
        for (SemanticsObject semanticsObject : newRoutes) {
            previousRoutes.add(semanticsObject.id);
        }

        Iterator<Map.Entry<Integer, SemanticsObject>> it = mObjects.entrySet().iterator();
        while (it.hasNext()) {
            Map.Entry<Integer, SemanticsObject> entry = it.next();
            SemanticsObject object = entry.getValue();
            if (!visitedObjects.contains(object)) {
                willRemoveSemanticsObject(object);
                it.remove();
            }
        }

        // TODO(goderbauer): Send this event only once (!) for changed subtrees,
        //     see https://github.com/flutter/flutter/issues/14534
        sendAccessibilityEvent(0, AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED);

        for (SemanticsObject object : updated) {
            if (object.didScroll()) {
                AccessibilityEvent event =
                        obtainAccessibilityEvent(object.id, AccessibilityEvent.TYPE_VIEW_SCROLLED);

                // Android doesn't support unbound scrolling. So we pretend there is a large
                // bound (SCROLL_EXTENT_FOR_INFINITY), which you can never reach.
                float position = object.scrollPosition;
                float max = object.scrollExtentMax;
                if (Float.isInfinite(object.scrollExtentMax)) {
                    max = SCROLL_EXTENT_FOR_INFINITY;
                    if (position > SCROLL_POSITION_CAP_FOR_INFINITY) {
                        position = SCROLL_POSITION_CAP_FOR_INFINITY;
                    }
                }
                if (Float.isInfinite(object.scrollExtentMin)) {
                    max += SCROLL_EXTENT_FOR_INFINITY;
                    if (position < -SCROLL_POSITION_CAP_FOR_INFINITY) {
                        position = -SCROLL_POSITION_CAP_FOR_INFINITY;
                    }
                    position += SCROLL_EXTENT_FOR_INFINITY;
                } else {
                    max -= object.scrollExtentMin;
                    position -= object.scrollExtentMin;
                }

                if (object.hadAction(Action.SCROLL_UP) || object.hadAction(Action.SCROLL_DOWN)) {
                    event.setScrollY((int) position);
                    event.setMaxScrollY((int) max);
                } else if (object.hadAction(Action.SCROLL_LEFT)
                        || object.hadAction(Action.SCROLL_RIGHT)) {
                    event.setScrollX((int) position);
                    event.setMaxScrollX((int) max);
                }
                if (object.scrollChildren > 0) {
                    // We don't need to add 1 to the scroll index because TalkBack does this automagically.
                    event.setItemCount(object.scrollChildren);
                    event.setFromIndex(object.scrollIndex);
                    int visibleChildren = 0;
                    // handle hidden children at the beginning and end of the list.
                    for (SemanticsObject child : object.childrenInHitTestOrder) {
                        if (!child.hasFlag(Flag.IS_HIDDEN)) {
                            visibleChildren += 1;
                        }
                    }
                    assert(object.scrollIndex + visibleChildren <= object.scrollChildren);
                    assert(!object.childrenInHitTestOrder.get(object.scrollIndex).hasFlag(Flag.IS_HIDDEN));
                    // The setToIndex should be the index of the last visible child. Because we counted all
                    // children, including the first index we need to subtract one.
                    //
                    //   [0, 1, 2, 3, 4, 5]
                    //    ^     ^
                    // In the example above where 0 is the first visible index and 2 is the last, we will
                    // count 3 total visible children. We then subtract one to get the correct last visible
                    // index of 2.
                    event.setToIndex(object.scrollIndex + visibleChildren - 1);
                }
                sendAccessibilityEvent(event);
            }
            if (object.hasFlag(Flag.IS_LIVE_REGION)) {
                String label = object.label == null ? "" : object.label;
                String previousLabel = object.previousLabel == null ? "" : object.label;
                if (!label.equals(previousLabel) || !object.hadFlag(Flag.IS_LIVE_REGION)) {
                    sendAccessibilityEvent(object.id, AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED);
                }
            } else if (object.hasFlag(Flag.IS_TEXT_FIELD) && object.didChangeLabel()
                    && mInputFocusedObject != null && mInputFocusedObject.id == object.id) {
                // Text fields should announce when their label changes while focused. We use a live
                // region tag to do so, and this event triggers that update.
                sendAccessibilityEvent(object.id, AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED);
            }
            if (mA11yFocusedObject != null && mA11yFocusedObject.id == object.id
                    && !object.hadFlag(Flag.IS_SELECTED) && object.hasFlag(Flag.IS_SELECTED)) {
                AccessibilityEvent event =
                        obtainAccessibilityEvent(object.id, AccessibilityEvent.TYPE_VIEW_SELECTED);
                event.getText().add(object.label);
                sendAccessibilityEvent(event);
            }
            if (mInputFocusedObject != null && mInputFocusedObject.id == object.id
                    && object.hadFlag(Flag.IS_TEXT_FIELD) && object.hasFlag(Flag.IS_TEXT_FIELD)) {
                String oldValue = object.previousValue != null ? object.previousValue : "";
                String newValue = object.value != null ? object.value : "";
                AccessibilityEvent event = createTextChangedEvent(object.id, oldValue, newValue);
                if (event != null) {
                    sendAccessibilityEvent(event);
                }

                if (object.previousTextSelectionBase != object.textSelectionBase
                        || object.previousTextSelectionExtent != object.textSelectionExtent) {
                    AccessibilityEvent selectionEvent = obtainAccessibilityEvent(
                            object.id, AccessibilityEvent.TYPE_VIEW_TEXT_SELECTION_CHANGED);
                    selectionEvent.getText().add(newValue);
                    selectionEvent.setFromIndex(object.textSelectionBase);
                    selectionEvent.setToIndex(object.textSelectionExtent);
                    selectionEvent.setItemCount(newValue.length());
                    sendAccessibilityEvent(selectionEvent);
                }
            }
        }
    }

    private AccessibilityEvent createTextChangedEvent(int id, String oldValue, String newValue) {
        AccessibilityEvent e =
                obtainAccessibilityEvent(id, AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED);
        e.setBeforeText(oldValue);
        e.getText().add(newValue);

        int i;
        for (i = 0; i < oldValue.length() && i < newValue.length(); ++i) {
            if (oldValue.charAt(i) != newValue.charAt(i)) {
                break;
            }
        }
        if (i >= oldValue.length() && i >= newValue.length()) {
            return null; // Text did not change
        }
        int firstDifference = i;
        e.setFromIndex(firstDifference);

        int oldIndex = oldValue.length() - 1;
        int newIndex = newValue.length() - 1;
        while (oldIndex >= firstDifference && newIndex >= firstDifference) {
            if (oldValue.charAt(oldIndex) != newValue.charAt(newIndex)) {
                break;
            }
            --oldIndex;
            --newIndex;
        }
        e.setRemovedCount(oldIndex - firstDifference + 1);
        e.setAddedCount(newIndex - firstDifference + 1);

        return e;
    }

    private AccessibilityEvent obtainAccessibilityEvent(int virtualViewId, int eventType) {
        assert virtualViewId != ROOT_NODE_ID;
        AccessibilityEvent event = AccessibilityEvent.obtain(eventType);
        event.setPackageName(mOwner.getContext().getPackageName());
        event.setSource(mOwner, virtualViewId);
        return event;
    }

    private void sendAccessibilityEvent(int virtualViewId, int eventType) {
        if (!mAccessibilityEnabled) {
            return;
        }
        if (virtualViewId == ROOT_NODE_ID) {
            mOwner.sendAccessibilityEvent(eventType);
        } else {
            sendAccessibilityEvent(obtainAccessibilityEvent(virtualViewId, eventType));
        }
    }

    private void sendAccessibilityEvent(AccessibilityEvent event) {
        if (!mAccessibilityEnabled) {
            return;
        }
        mOwner.getParent().requestSendAccessibilityEvent(mOwner, event);
    }

    // Message Handler for [mFlutterAccessibilityChannel].
    public void onMessage(Object message, BasicMessageChannel.Reply<Object> reply) {
        @SuppressWarnings("unchecked")
        final HashMap<String, Object> annotatedEvent = (HashMap<String, Object>) message;
        final String type = (String) annotatedEvent.get("type");
        @SuppressWarnings("unchecked")
        final HashMap<String, Object> data = (HashMap<String, Object>) annotatedEvent.get("data");

        switch (type) {
            case "announce":
                mOwner.announceForAccessibility((String) data.get("message"));
                break;
            case "longPress": {
                Integer nodeId = (Integer) annotatedEvent.get("nodeId");
                if (nodeId == null) {
                    return;
                }
                sendAccessibilityEvent(nodeId, AccessibilityEvent.TYPE_VIEW_LONG_CLICKED);
                break;
            }
            case "tap": {
                Integer nodeId = (Integer) annotatedEvent.get("nodeId");
                if (nodeId == null) {
                    return;
                }
                sendAccessibilityEvent(nodeId, AccessibilityEvent.TYPE_VIEW_CLICKED);
                break;
            }
            case "tooltip": {
                AccessibilityEvent e = obtainAccessibilityEvent(
                        ROOT_NODE_ID, AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED);
                e.getText().add((String) data.get("message"));
                sendAccessibilityEvent(e);
                break;
            }
        }
    }

    private void createWindowChangeEvent(SemanticsObject route) {
        AccessibilityEvent e =
                obtainAccessibilityEvent(route.id, AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED);
        String routeName = route.getRouteName();
        e.getText().add(routeName);
        sendAccessibilityEvent(e);
    }

    private void willRemoveSemanticsObject(SemanticsObject object) {
        assert mObjects.containsKey(object.id);
        assert mObjects.get(object.id) == object;
        object.parent = null;
        if (mA11yFocusedObject == object) {
            sendAccessibilityEvent(mA11yFocusedObject.id,
                    AccessibilityEvent.TYPE_VIEW_ACCESSIBILITY_FOCUS_CLEARED);
            mA11yFocusedObject = null;
        }
        if (mInputFocusedObject == object) {
            mInputFocusedObject = null;
        }
        if (mHoveredObject == object) {
            mHoveredObject = null;
        }
    }

    void reset() {
        mObjects.clear();
        if (mA11yFocusedObject != null)
            sendAccessibilityEvent(mA11yFocusedObject.id,
                    AccessibilityEvent.TYPE_VIEW_ACCESSIBILITY_FOCUS_CLEARED);
        mA11yFocusedObject = null;
        mHoveredObject = null;
        sendAccessibilityEvent(0, AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED);
    }

    private enum TextDirection {
        UNKNOWN,
        LTR,
        RTL;

        public static TextDirection fromInt(int value) {
            switch (value) {
                case 1:
                    return RTL;
                case 2:
                    return LTR;
            }
            return UNKNOWN;
        }
    }

    private class CustomAccessibilityAction {
        CustomAccessibilityAction() {}

        /// Resource id is the id of the custom action plus a minimum value so that the identifier
        /// does not collide with existing Android accessibility actions.
        int resourceId = -1;
        int id = -1;
        int overrideId = -1;

        /// The label is the user presented value which is displayed in the local context menu.
        String label;

        /// The hint is the text used in overriden standard actions.
        String hint;

        boolean isStandardAction() {
            return overrideId != -1;
        }
    }
    /// Value is derived from ACTION_TYPE_MASK in AccessibilityNodeInfo.java
    static int firstResourceId = 267386881;

    private class SemanticsObject {
        SemanticsObject() {}

        int id = -1;

        int flags;
        int actions;
        int textSelectionBase;
        int textSelectionExtent;
        int scrollChildren;
        int scrollIndex;
        float scrollPosition;
        float scrollExtentMax;
        float scrollExtentMin;
        String label;
        String value;
        String increasedValue;
        String decreasedValue;
        String hint;
        TextDirection textDirection;

        boolean hadPreviousConfig = false;
        int previousFlags;
        int previousActions;
        int previousTextSelectionBase;
        int previousTextSelectionExtent;
        float previousScrollPosition;
        float previousScrollExtentMax;
        float previousScrollExtentMin;
        String previousValue;
        String previousLabel;

        private float left;
        private float top;
        private float right;
        private float bottom;
        private float[] transform;

        SemanticsObject parent;
        List<SemanticsObject> childrenInTraversalOrder;
        List<SemanticsObject> childrenInHitTestOrder;
        List<CustomAccessibilityAction> customAccessibilityActions;
        CustomAccessibilityAction onTapOverride;
        CustomAccessibilityAction onLongPressOverride;

        private boolean inverseTransformDirty = true;
        private float[] inverseTransform;

        private boolean globalGeometryDirty = true;
        private float[] globalTransform;
        private Rect globalRect;

        boolean hasAction(Action action) {
            return (actions & action.value) != 0;
        }

        boolean hadAction(Action action) {
            return (previousActions & action.value) != 0;
        }

        boolean hasFlag(Flag flag) {
            return (flags & flag.value) != 0;
        }

        boolean hadFlag(Flag flag) {
            assert hadPreviousConfig;
            return (previousFlags & flag.value) != 0;
        }

        boolean didScroll() {
            return !Float.isNaN(scrollPosition) && !Float.isNaN(previousScrollPosition)
                    && previousScrollPosition != scrollPosition;
        }

        boolean didChangeLabel() {
            if (label == null && previousLabel == null) {
                return false;
            }
            return label == null || previousLabel == null || !label.equals(previousLabel);
        }

        void log(String indent, boolean recursive) {
            Log.i(TAG,
                    indent + "SemanticsObject id=" + id + " label=" + label + " actions=" + actions
                            + " flags=" + flags + "\n" + indent + "  +-- textDirection="
                            + textDirection + "\n" + indent + "  +-- rect.ltrb=(" + left + ", "
                            + top + ", " + right + ", " + bottom + ")\n" + indent
                            + "  +-- transform=" + Arrays.toString(transform) + "\n");
            if (childrenInTraversalOrder != null && recursive) {
                String childIndent = indent + "  ";
                for (SemanticsObject child : childrenInTraversalOrder) {
                    child.log(childIndent, recursive);
                }
            }
        }

        void updateWith(ByteBuffer buffer, String[] strings) {
            hadPreviousConfig = true;
            previousValue = value;
            previousLabel = label;
            previousFlags = flags;
            previousActions = actions;
            previousTextSelectionBase = textSelectionBase;
            previousTextSelectionExtent = textSelectionExtent;
            previousScrollPosition = scrollPosition;
            previousScrollExtentMax = scrollExtentMax;
            previousScrollExtentMin = scrollExtentMin;

            flags = buffer.getInt();
            actions = buffer.getInt();
            textSelectionBase = buffer.getInt();
            textSelectionExtent = buffer.getInt();
            scrollChildren = buffer.getInt();
            scrollIndex = buffer.getInt();
            scrollPosition = buffer.getFloat();
            scrollExtentMax = buffer.getFloat();
            scrollExtentMin = buffer.getFloat();

            int stringIndex = buffer.getInt();
            label = stringIndex == -1 ? null : strings[stringIndex];

            stringIndex = buffer.getInt();
            value = stringIndex == -1 ? null : strings[stringIndex];

            stringIndex = buffer.getInt();
            increasedValue = stringIndex == -1 ? null : strings[stringIndex];

            stringIndex = buffer.getInt();
            decreasedValue = stringIndex == -1 ? null : strings[stringIndex];

            stringIndex = buffer.getInt();
            hint = stringIndex == -1 ? null : strings[stringIndex];

            textDirection = TextDirection.fromInt(buffer.getInt());

            left = buffer.getFloat();
            top = buffer.getFloat();
            right = buffer.getFloat();
            bottom = buffer.getFloat();

            if (transform == null) {
                transform = new float[16];
            }
            for (int i = 0; i < 16; ++i) {
                transform[i] = buffer.getFloat();
            }
            inverseTransformDirty = true;
            globalGeometryDirty = true;

            final int childCount = buffer.getInt();
            if (childCount == 0) {
                childrenInTraversalOrder = null;
                childrenInHitTestOrder = null;
            } else {
                if (childrenInTraversalOrder == null)
                    childrenInTraversalOrder = new ArrayList<SemanticsObject>(childCount);
                else
                    childrenInTraversalOrder.clear();

                for (int i = 0; i < childCount; ++i) {
                    SemanticsObject child = getOrCreateObject(buffer.getInt());
                    child.parent = this;
                    childrenInTraversalOrder.add(child);
                }

                if (childrenInHitTestOrder == null)
                    childrenInHitTestOrder = new ArrayList<SemanticsObject>(childCount);
                else
                    childrenInHitTestOrder.clear();

                for (int i = 0; i < childCount; ++i) {
                    SemanticsObject child = getOrCreateObject(buffer.getInt());
                    child.parent = this;
                    childrenInHitTestOrder.add(child);
                }
            }
            final int actionCount = buffer.getInt();
            if (actionCount == 0) {
                customAccessibilityActions = null;
            } else {
                if (customAccessibilityActions == null)
                    customAccessibilityActions =
                            new ArrayList<CustomAccessibilityAction>(actionCount);
                else
                    customAccessibilityActions.clear();

                for (int i = 0; i < actionCount; i++) {
                    CustomAccessibilityAction action = getOrCreateAction(buffer.getInt());
                    if (action.overrideId == Action.TAP.value) {
                        onTapOverride = action;
                    } else if (action.overrideId == Action.LONG_PRESS.value) {
                        onLongPressOverride = action;
                    } else {
                        // If we recieve a different overrideId it means that we were passed
                        // a standard action to override that we don't yet support.
                        assert action.overrideId == -1;
                        customAccessibilityActions.add(action);
                    }
                    customAccessibilityActions.add(action);
                }
            }
        }

        private void ensureInverseTransform() {
            if (!inverseTransformDirty) {
                return;
            }
            inverseTransformDirty = false;
            if (inverseTransform == null) {
                inverseTransform = new float[16];
            }
            if (!Matrix.invertM(inverseTransform, 0, transform, 0)) {
                Arrays.fill(inverseTransform, 0);
            }
        }

        Rect getGlobalRect() {
            assert !globalGeometryDirty;
            return globalRect;
        }

        SemanticsObject hitTest(float[] point) {
            final float w = point[3];
            final float x = point[0] / w;
            final float y = point[1] / w;
            if (x < left || x >= right || y < top || y >= bottom) return null;
            if (childrenInHitTestOrder != null) {
                final float[] transformedPoint = new float[4];
                for (int i = 0; i < childrenInHitTestOrder.size(); i += 1) {
                    final SemanticsObject child = childrenInHitTestOrder.get(i);
                    if (child.hasFlag(Flag.IS_HIDDEN)) {
                        continue;
                    }
                    child.ensureInverseTransform();
                    Matrix.multiplyMV(transformedPoint, 0, child.inverseTransform, 0, point, 0);
                    final SemanticsObject result = child.hitTest(transformedPoint);
                    if (result != null) {
                        return result;
                    }
                }
            }
            return this;
        }

        // TODO(goderbauer): This should be decided by the framework once we have more information
        //     about focusability there.
        boolean isFocusable() {
            // We enforce in the framework that no other useful semantics are merged with these
            // nodes.
            if (hasFlag(Flag.SCOPES_ROUTE)) {
                return false;
            }
            int scrollableActions = Action.SCROLL_RIGHT.value | Action.SCROLL_LEFT.value
                    | Action.SCROLL_UP.value | Action.SCROLL_DOWN.value;
            return (actions & ~scrollableActions) != 0 || flags != 0
                    || (label != null && !label.isEmpty()) || (value != null && !value.isEmpty())
                    || (hint != null && !hint.isEmpty());
        }

        void collectRoutes(List<SemanticsObject> edges) {
            if (hasFlag(Flag.SCOPES_ROUTE)) {
                edges.add(this);
            }
            if (childrenInTraversalOrder != null) {
                for (int i = 0; i < childrenInTraversalOrder.size(); ++i) {
                    childrenInTraversalOrder.get(i).collectRoutes(edges);
                }
            }
        }

        String getRouteName() {
            // Returns the first non-null and non-empty semantic label of a child
            // with an NamesRoute flag. Otherwise returns null.
            if (hasFlag(Flag.NAMES_ROUTE)) {
                if (label != null && !label.isEmpty()) {
                    return label;
                }
            }
            if (childrenInTraversalOrder != null) {
                for (int i = 0; i < childrenInTraversalOrder.size(); ++i) {
                    String newName = childrenInTraversalOrder.get(i).getRouteName();
                    if (newName != null && !newName.isEmpty()) {
                        return newName;
                    }
                }
            }
            return null;
        }

        void updateRecursively(float[] ancestorTransform, Set<SemanticsObject> visitedObjects,
                boolean forceUpdate) {
            visitedObjects.add(this);

            if (globalGeometryDirty) {
                forceUpdate = true;
            }

            if (forceUpdate) {
                if (globalTransform == null) {
                    globalTransform = new float[16];
                }
                Matrix.multiplyMM(globalTransform, 0, ancestorTransform, 0, transform, 0);

                final float[] sample = new float[4];
                sample[2] = 0;
                sample[3] = 1;

                final float[] point1 = new float[4];
                final float[] point2 = new float[4];
                final float[] point3 = new float[4];
                final float[] point4 = new float[4];

                sample[0] = left;
                sample[1] = top;
                transformPoint(point1, globalTransform, sample);

                sample[0] = right;
                sample[1] = top;
                transformPoint(point2, globalTransform, sample);

                sample[0] = right;
                sample[1] = bottom;
                transformPoint(point3, globalTransform, sample);

                sample[0] = left;
                sample[1] = bottom;
                transformPoint(point4, globalTransform, sample);

                if (globalRect == null) globalRect = new Rect();

                globalRect.set(Math.round(min(point1[0], point2[0], point3[0], point4[0])),
                        Math.round(min(point1[1], point2[1], point3[1], point4[1])),
                        Math.round(max(point1[0], point2[0], point3[0], point4[0])),
                        Math.round(max(point1[1], point2[1], point3[1], point4[1])));

                globalGeometryDirty = false;
            }

            assert globalTransform != null;
            assert globalRect != null;

            if (childrenInTraversalOrder != null) {
                for (int i = 0; i < childrenInTraversalOrder.size(); ++i) {
                    childrenInTraversalOrder.get(i).updateRecursively(
                            globalTransform, visitedObjects, forceUpdate);
                }
            }
        }

        private void transformPoint(float[] result, float[] transform, float[] point) {
            Matrix.multiplyMV(result, 0, transform, 0, point, 0);
            final float w = result[3];
            result[0] /= w;
            result[1] /= w;
            result[2] /= w;
            result[3] = 0;
        }

        private float min(float a, float b, float c, float d) {
            return Math.min(a, Math.min(b, Math.min(c, d)));
        }

        private float max(float a, float b, float c, float d) {
            return Math.max(a, Math.max(b, Math.max(c, d)));
        }

        private String getValueLabelHint() {
            StringBuilder sb = new StringBuilder();
            String[] array = {value, label, hint};
            for (String word : array) {
                if (word != null && word.length() > 0) {
                    if (sb.length() > 0) sb.append(", ");
                    sb.append(word);
                }
            }
            return sb.length() > 0 ? sb.toString() : null;
        }
    }
}
