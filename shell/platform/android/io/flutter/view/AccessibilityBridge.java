// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view;

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
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;

class AccessibilityBridge extends AccessibilityNodeProvider implements BasicMessageChannel.MessageHandler<Object> {
    private static final String TAG = "FlutterView";

    private Map<Integer, SemanticsObject> mObjects;
    private final FlutterView mOwner;
    private boolean mAccessibilityEnabled = false;
    private SemanticsObject mA11yFocusedObject;
    private SemanticsObject mInputFocusedObject;
    private SemanticsObject mHoveredObject;

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
        MOVE_CURSOR_BACKWARD_BY_CHARACTER(1 << 10);

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
        IS_IN_MUTUALLY_EXCLUSIVE_GROUP(1 << 8);

        Flag(int value) {
            this.value = value;
        }

        final int value;
    }

    AccessibilityBridge(FlutterView owner) {
        assert owner != null;
        mOwner = owner;
        mObjects = new HashMap<Integer, SemanticsObject>();
        mFlutterAccessibilityChannel = new BasicMessageChannel<>(owner, "flutter/accessibility",
            StandardMessageCodec.INSTANCE);
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
            if (mObjects.containsKey(0))
                result.addChild(mOwner, 0);
            return result;
        }

        SemanticsObject object = mObjects.get(virtualViewId);
        if (object == null)
            return null;

        AccessibilityNodeInfo result = AccessibilityNodeInfo.obtain(mOwner, virtualViewId);
        result.setPackageName(mOwner.getContext().getPackageName());
        result.setClassName("Flutter"); // TODO(goderbauer): Set proper class names
        result.setSource(mOwner, virtualViewId);
        result.setFocusable(object.isFocusable());
        if (mInputFocusedObject != null)
            result.setFocused(mInputFocusedObject.id == virtualViewId);

        if (mA11yFocusedObject != null)
            result.setAccessibilityFocused(mA11yFocusedObject.id == virtualViewId);

        if (object.hasFlag(Flag.IS_TEXT_FIELD)) {
            result.setClassName("android.widget.EditText");
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2)
                result.setEditable(true);

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
            result.setMovementGranularities(granularities);
        }

        if (object.hasFlag(Flag.IS_BUTTON)) {
          result.setClassName("android.widget.Button");
        }

        if (object.parent != null) {
            assert object.id > 0;
            result.setParent(mOwner, object.parent.id);
        } else {
            assert object.id == 0;
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
        result.setEnabled(!object.hasFlag(Flag.HAS_ENABLED_STATE) ||
                          object.hasFlag(Flag.IS_ENABLED));

        if (object.hasAction(Action.TAP)) {
            result.addAction(AccessibilityNodeInfo.ACTION_CLICK);
            result.setClickable(true);
        }
        if (object.hasAction(Action.LONG_PRESS)) {
            result.addAction(AccessibilityNodeInfo.ACTION_LONG_CLICK);
            result.setLongClickable(true);
        }
        if (object.hasAction(Action.SCROLL_LEFT) || object.hasAction(Action.SCROLL_UP)
                || object.hasAction(Action.SCROLL_RIGHT) || object.hasAction(Action.SCROLL_DOWN)) {
            result.setScrollable(true);
            // This tells Android's a11y to send scroll events when reaching the end of
            // the visible viewport of a scrollable.
            result.setClassName("android.widget.ScrollView");
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
            result.setClassName("android.widget.SeekBar");
            if (object.hasAction(Action.INCREASE)) {
                result.addAction(AccessibilityNodeInfo.ACTION_SCROLL_FORWARD);
            }
            if (object.hasAction(Action.DECREASE)) {
                result.addAction(AccessibilityNodeInfo.ACTION_SCROLL_BACKWARD);
            }
        }

        boolean hasCheckedState = object.hasFlag(Flag.HAS_CHECKED_STATE);
        result.setCheckable(hasCheckedState);
        if (hasCheckedState) {
            result.setChecked(object.hasFlag(Flag.IS_CHECKED));
            if (object.hasFlag(Flag.IS_IN_MUTUALLY_EXCLUSIVE_GROUP))
                result.setClassName("android.widget.RadioButton");
            else
                result.setClassName("android.widget.CheckBox");
        }

        result.setSelected(object.hasFlag(Flag.IS_SELECTED));
        result.setText(object.getValueLabelHint());

        // Accessibility Focus
        if (mA11yFocusedObject != null && mA11yFocusedObject.id == virtualViewId) {
            result.addAction(AccessibilityNodeInfo.ACTION_CLEAR_ACCESSIBILITY_FOCUS);
        } else {
            result.addAction(AccessibilityNodeInfo.ACTION_ACCESSIBILITY_FOCUS);
        }

        if (object.children != null) {
            List<SemanticsObject> childrenInTraversalOrder =
                new ArrayList<SemanticsObject>(object.children);
            Collections.sort(childrenInTraversalOrder, new Comparator<SemanticsObject>() {
                public int compare(SemanticsObject a, SemanticsObject b) {
                    final int top = Integer.compare(a.globalRect.top, b.globalRect.top);
                    // TODO(goderbauer): sort right-to-left in rtl environments.
                    return top == 0 ? Integer.compare(a.globalRect.left, b.globalRect.left) : top;
                }
            });
            for (SemanticsObject child : childrenInTraversalOrder) {
                result.addChild(mOwner, child.id);
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
                mOwner.dispatchSemanticsAction(virtualViewId, Action.TAP);
                return true;
            }
            case AccessibilityNodeInfo.ACTION_LONG_CLICK: {
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
                sendAccessibilityEvent(virtualViewId, AccessibilityEvent.TYPE_VIEW_ACCESSIBILITY_FOCUS_CLEARED);
                mA11yFocusedObject = null;
                return true;
            }
            case AccessibilityNodeInfo.ACTION_ACCESSIBILITY_FOCUS: {
                sendAccessibilityEvent(virtualViewId, AccessibilityEvent.TYPE_VIEW_ACCESSIBILITY_FOCUSED);

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
            // TODO(goderbauer): Use ACTION_SHOW_ON_SCREEN from Android Support Library after
            //     https://github.com/flutter/flutter/issues/11099 is resolved.
            case 16908342: { // ACTION_SHOW_ON_SCREEN, added in API level 23
                mOwner.dispatchSemanticsAction(virtualViewId, Action.SHOW_ON_SCREEN);
                return true;
            }
        }
        return false;
    }

    boolean performCursorMoveAction(SemanticsObject object, int virtualViewId, Bundle arguments, boolean forward) {
        final int granularity = arguments.getInt(
            AccessibilityNodeInfo.ACTION_ARGUMENT_MOVEMENT_GRANULARITY_INT);
        final boolean extendSelection = arguments.getBoolean(
            AccessibilityNodeInfo.ACTION_ARGUMENT_EXTEND_SELECTION_BOOLEAN);
        switch (granularity) {
            case AccessibilityNodeInfo.MOVEMENT_GRANULARITY_CHARACTER: {
                if (forward && object.hasAction(Action.MOVE_CURSOR_FORWARD_BY_CHARACTER)) {
                    mOwner.dispatchSemanticsAction(virtualViewId, Action.MOVE_CURSOR_FORWARD_BY_CHARACTER, extendSelection);
                    return true;
                }
                if (!forward && object.hasAction(Action.MOVE_CURSOR_BACKWARD_BY_CHARACTER)) {
                    mOwner.dispatchSemanticsAction(virtualViewId, Action.MOVE_CURSOR_BACKWARD_BY_CHARACTER, extendSelection);
                    return true;
                }
            }
            // TODO(goderbauer): support other granularities.
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
        SemanticsObject newObject = getRootObject().hitTest(new float[]{ x, y, 0, 1 });
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

    void updateSemantics(ByteBuffer buffer, String[] strings) {
        ArrayList<Integer> updated = new ArrayList<Integer>();
        while (buffer.hasRemaining()) {
            int id = buffer.getInt();
            SemanticsObject object = getOrCreateObject(id);
            object.updateWith(buffer, strings);
            if (object.hasFlag(Flag.IS_FOCUSED)) {
                mInputFocusedObject = object;
            }
            updated.add(id);
        }

        Set<SemanticsObject> visitedObjects = new HashSet<SemanticsObject>();
        SemanticsObject rootObject = getRootObject();
        if (rootObject != null) {
          final float[] identity = new float[16];
          Matrix.setIdentityM(identity, 0);
          rootObject.updateRecursively(identity, visitedObjects, false);
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

        for (Integer id : updated) {
            sendAccessibilityEvent(id, AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED);
        }
    }

    private AccessibilityEvent obtainAccessibilityEvent(int virtualViewId, int eventType) {
        assert virtualViewId != 0;
        AccessibilityEvent event = AccessibilityEvent.obtain(eventType);
        event.setPackageName(mOwner.getContext().getPackageName());
        event.setSource(mOwner, virtualViewId);
        return event;
    }

    private void sendAccessibilityEvent(int virtualViewId, int eventType) {
        if (!mAccessibilityEnabled) {
            return;
        }
        if (virtualViewId == 0) {
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
        final HashMap<String, Object> annotatedEvent = (HashMap<String, Object>)message;
        final String type = (String)annotatedEvent.get("type");
        @SuppressWarnings("unchecked")
        final HashMap<String, Object> data = (HashMap<String, Object>)annotatedEvent.get("data");

        switch (type) {
            case "scroll":
                final int nodeId = (int)annotatedEvent.get("nodeId");
                AccessibilityEvent event =
                    obtainAccessibilityEvent(nodeId, AccessibilityEvent.TYPE_VIEW_SCROLLED);
                char axis = ((String)data.get("axis")).charAt(0);
                double minPosition = (double)data.get("minScrollExtent");
                double maxPosition = (double)data.get("maxScrollExtent") - minPosition;
                double position = (double)data.get("pixels") - minPosition;
                if (axis == 'v') {
                    event.setScrollY((int)position);
                    event.setMaxScrollY((int)maxPosition);
                } else {
                    assert axis == 'h';
                    event.setScrollX((int)position);
                    event.setMaxScrollX((int)maxPosition);
                }
                sendAccessibilityEvent(event);
                break;
            case "announce":
                mOwner.announceForAccessibility((String) data.get("message"));
                break;
            default:
                assert false;
        }
    }

    private void willRemoveSemanticsObject(SemanticsObject object) {
        assert mObjects.containsKey(object.id);
        assert mObjects.get(object.id) == object;
        object.parent = null;
        if (mA11yFocusedObject == object) {
            sendAccessibilityEvent(mA11yFocusedObject.id, AccessibilityEvent.TYPE_VIEW_ACCESSIBILITY_FOCUS_CLEARED);
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
            sendAccessibilityEvent(mA11yFocusedObject.id, AccessibilityEvent.TYPE_VIEW_ACCESSIBILITY_FOCUS_CLEARED);
        mA11yFocusedObject = null;
        mHoveredObject = null;
        sendAccessibilityEvent(0, AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED);
    }

    private enum TextDirection {
        UNKNOWN, LTR, RTL;

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

    private class SemanticsObject {
        SemanticsObject() { }

        int id = -1;

        int flags;
        int actions;
        String label;
        String value;
        String increasedValue;
        String decreasedValue;
        String hint;
        TextDirection textDirection;

        private float left;
        private float top;
        private float right;
        private float bottom;
        private float[] transform;

        SemanticsObject parent;
        List<SemanticsObject> children;  // In inverse hit test order (i.e. paint order).

        private boolean inverseTransformDirty = true;
        private float[] inverseTransform;

        private boolean globalGeometryDirty = true;
        private float[] globalTransform;
        private Rect globalRect;

        boolean hasAction(Action action) {
            return (actions & action.value) != 0;
        }

        boolean hasFlag(Flag flag) {
            return (flags & flag.value) != 0;
        }

        void log(String indent) {
          Log.i(TAG, indent + "SemanticsObject id=" + id + " label=" + label + " actions=" +  actions + " flags=" + flags + "\n" +
                     indent + "  +-- rect.ltrb=(" + left + ", " + top + ", " + right + ", " + bottom + ")\n" +
                     indent + "  +-- transform=" + Arrays.toString(transform) + "\n");
          if (children != null) {
              String childIndent = indent + "  ";
              for (SemanticsObject child : children) {
                  child.log(childIndent);
              }
          }
        }

        void updateWith(ByteBuffer buffer, String[] strings) {
            flags = buffer.getInt();
            actions = buffer.getInt();

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

            if (transform == null)
                transform = new float[16];
            for (int i = 0; i < 16; ++i)
                transform[i] = buffer.getFloat();
            inverseTransformDirty = true;
            globalGeometryDirty = true;

            final int childCount = buffer.getInt();
            if (childCount == 0) {
                children = null;
            } else {
                if (children == null)
                    children = new ArrayList<SemanticsObject>(childCount);
                else
                    children.clear();

                for (int i = 0; i < childCount; ++i) {
                    SemanticsObject child = getOrCreateObject(buffer.getInt());
                    child.parent = this;
                    children.add(child);
                }
            }
        }

        private void ensureInverseTransform() {
            if (!inverseTransformDirty)
                return;
            inverseTransformDirty = false;
            if (inverseTransform == null)
                inverseTransform = new float[16];
            if (!Matrix.invertM(inverseTransform, 0, transform, 0))
                Arrays.fill(inverseTransform, 0);
        }

        Rect getGlobalRect() {
            assert !globalGeometryDirty;
            return globalRect;
        }

        SemanticsObject hitTest(float[] point) {
            final float w = point[3];
            final float x = point[0] / w;
            final float y = point[1] / w;
            if (x < left || x >= right || y < top || y >= bottom)
                return null;
            if (children != null) {
                final float[] transformedPoint = new float[4];
                for (int i = children.size() - 1; i >= 0; i -= 1) {
                    final SemanticsObject child = children.get(i);
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
            int scrollableActions = Action.SCROLL_RIGHT.value | Action.SCROLL_LEFT.value
                    | Action.SCROLL_UP.value | Action.SCROLL_DOWN.value;
            return (actions & ~scrollableActions) != 0
                || flags != 0
                || (label != null && !label.isEmpty())
                || (value != null && !value.isEmpty())
                || (hint != null && !hint.isEmpty());
        }

        void updateRecursively(float[] ancestorTransform, Set<SemanticsObject> visitedObjects, boolean forceUpdate) {
            visitedObjects.add(this);

            if (globalGeometryDirty)
                forceUpdate = true;

            if (forceUpdate) {
                if (globalTransform == null)
                    globalTransform = new float[16];
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

                if (globalRect == null)
                    globalRect = new Rect();

                globalRect.set(
                    Math.round(min(point1[0], point2[0], point3[0], point4[0])),
                    Math.round(min(point1[1], point2[1], point3[1], point4[1])),
                    Math.round(max(point1[0], point2[0], point3[0], point4[0])),
                    Math.round(max(point1[1], point2[1], point3[1], point4[1]))
                );

                globalGeometryDirty = false;
            }

            assert globalTransform != null;
            assert globalRect != null;

            if (children != null) {
                for (int i = 0; i < children.size(); ++i) {
                    children.get(i).updateRecursively(globalTransform, visitedObjects, forceUpdate);
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
            String[] array = { value, label, hint };
            for (String word: array) {
                if (word != null && (word = word.trim()).length() > 0) {
                    if (sb.length() > 0)
                        sb.append(", ");
                    sb.append(word);
                }
            }
            return sb.length() > 0 ? sb.toString() : null;
        }
    }
}
