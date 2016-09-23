// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.view;

import android.graphics.Rect;
import android.opengl.Matrix;
import android.os.Bundle;
import android.view.View;
import android.view.accessibility.AccessibilityEvent;
import android.view.accessibility.AccessibilityManager;
import android.view.accessibility.AccessibilityNodeInfo;
import android.view.accessibility.AccessibilityNodeProvider;

import org.chromium.mojo.system.MojoException;
import org.chromium.mojom.semantics.SemanticAction;
import org.chromium.mojom.semantics.SemanticsListener;
import org.chromium.mojom.semantics.SemanticsNode;
import org.chromium.mojom.semantics.SemanticsServer;
import org.chromium.mojom.sky.ViewportMetrics;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

class AccessibilityBridge extends AccessibilityNodeProvider implements SemanticsListener {
    private Map<Integer, SemanticObject> mObjects;
    private FlutterView mOwner;
    private SemanticsServer.Proxy mSemanticsServer;
    private boolean mAccessibilityEnabled = false;
    private SemanticObject mFocusedObject;
    private SemanticObject mHoveredObject;

    AccessibilityBridge(FlutterView owner, SemanticsServer.Proxy semanticsServer) {
        assert owner != null;
        assert semanticsServer != null;
        mOwner = owner;
        mObjects = new HashMap<Integer, SemanticObject>();
        mSemanticsServer = semanticsServer;
        mSemanticsServer.addSemanticsListener(this);
    }

    void setAccessibilityEnabled(boolean accessibilityEnabled) {
        mAccessibilityEnabled = accessibilityEnabled;
    }

    @Override
    public AccessibilityNodeInfo createAccessibilityNodeInfo(int virtualViewId) {
        if (virtualViewId == View.NO_ID) {
            AccessibilityNodeInfo result = AccessibilityNodeInfo.obtain(mOwner);
            mOwner.onInitializeAccessibilityNodeInfo(result);
            if (mObjects.containsKey(0))
                result.addChild(mOwner, 0);
            return result;
        }

        SemanticObject object = mObjects.get(virtualViewId);
        if (object == null)
            return null;

        AccessibilityNodeInfo result = AccessibilityNodeInfo.obtain(mOwner, virtualViewId);
        result.setPackageName(mOwner.getContext().getPackageName());
        result.setClassName("Flutter"); // Prettier than the more conventional node.getClass().getName()
        result.setSource(mOwner, virtualViewId);

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
        result.setEnabled(true); // TODO(ianh): Expose disabled subtrees

        if (object.canBeTapped) {
            result.addAction(AccessibilityNodeInfo.AccessibilityAction.ACTION_CLICK);
            result.setClickable(true);
        }
        if (object.canBeLongPressed) {
            result.addAction(AccessibilityNodeInfo.AccessibilityAction.ACTION_LONG_CLICK);
            result.setLongClickable(true);
        }
        if (object.canBeScrolledHorizontally || object.canBeScrolledVertically) {
            // TODO(ianh): Once we're on SDK v23+, call addAction to
            // expose AccessibilityAction.ACTION_SCROLL_LEFT, _RIGHT,
            // _UP, and _DOWN when appropriate.
            // TODO(ianh): Only include the actions if you can actually scroll that way.
            result.addAction(AccessibilityNodeInfo.AccessibilityAction.ACTION_SCROLL_FORWARD);
            result.addAction(AccessibilityNodeInfo.AccessibilityAction.ACTION_SCROLL_BACKWARD);
            result.setScrollable(true);
        }

        result.setCheckable(object.hasCheckedState);
        result.setChecked(object.isChecked);
        result.setText(object.label);

        // TODO(ianh): use setTraversalBefore/setTraversalAfter to set
        // the relative order of the views. For each set of siblings,
        // the views should be ordered top-to-bottom, tie-breaking
        // left-to-right (right-to-left in rtl environments), height,
        // width, and finally by list order.

        // Accessibility Focus
        if (mFocusedObject != null && mFocusedObject.id == virtualViewId) {
            result.addAction(AccessibilityNodeInfo.AccessibilityAction.ACTION_CLEAR_ACCESSIBILITY_FOCUS);
        } else {
            result.addAction(AccessibilityNodeInfo.AccessibilityAction.ACTION_ACCESSIBILITY_FOCUS);
        }

        if (object.children != null) {
            for (SemanticObject child : object.children) {
                result.addChild(mOwner, child.id);
            }
        }

        return result;
    }

    @Override
    public boolean performAction(int virtualViewId, int action, Bundle arguments) {
        SemanticObject object = mObjects.get(virtualViewId);
        if (object == null) {
            return false;
        }
        switch (action) {
            case AccessibilityNodeInfo.ACTION_CLICK: {
                mSemanticsServer.performAction(virtualViewId, SemanticAction.TAP);
                return true;
            }
            case AccessibilityNodeInfo.ACTION_LONG_CLICK: {
                mSemanticsServer.performAction(virtualViewId, SemanticAction.LONG_PRESS);
                return true;
            }
            case AccessibilityNodeInfo.ACTION_SCROLL_BACKWARD: {
                if (object.canBeScrolledVertically) {
                    mSemanticsServer.performAction(virtualViewId, SemanticAction.SCROLL_UP);
                } else if (object.canBeScrolledHorizontally) {
                    // TODO(ianh): bidi support
                    mSemanticsServer.performAction(virtualViewId, SemanticAction.SCROLL_LEFT);
                } else {
                    return false;
                }
                return true;
            }
            case AccessibilityNodeInfo.ACTION_SCROLL_FORWARD: {
                if (object.canBeScrolledVertically) {
                    mSemanticsServer.performAction(virtualViewId, SemanticAction.SCROLL_DOWN);
                } else if (object.canBeScrolledHorizontally) {
                    // TODO(ianh): bidi support
                    mSemanticsServer.performAction(virtualViewId, SemanticAction.SCROLL_RIGHT);
                } else {
                    return false;
                }
                return true;
            }
            case AccessibilityNodeInfo.ACTION_CLEAR_ACCESSIBILITY_FOCUS: {
                sendAccessibilityEvent(virtualViewId, AccessibilityEvent.TYPE_VIEW_ACCESSIBILITY_FOCUS_CLEARED);
                mFocusedObject = null;
                return true;
            }
            case AccessibilityNodeInfo.ACTION_ACCESSIBILITY_FOCUS: {
                sendAccessibilityEvent(virtualViewId, AccessibilityEvent.TYPE_VIEW_ACCESSIBILITY_FOCUSED);
                if (mFocusedObject == null) {
                    // When Android focuses a node, it doesn't invalidate the view.
                    // (It does when it sends ACTION_CLEAR_ACCESSIBILITY_FOCUS, so
                    // we only have to worry about this when the focused node is null.)
                    mOwner.invalidate();
                }
                mFocusedObject = object;
                return true;
            }
        }
        return false;
    }

    // TODO(ianh): implement findAccessibilityNodeInfosByText()
    // TODO(ianh): implement findFocus()

    private SemanticObject getRootObject() {
      return mObjects.get(0);
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
        assert mObjects.containsKey(0);
        SemanticObject newObject = getRootObject().hitTest(Math.round(x), Math.round(y));
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

    @Override
    public void updateSemanticsTree(SemanticsNode[] nodes) {
        Set<SemanticObject> updatedObjects = new HashSet<SemanticObject>();
        Set<SemanticObject> removedObjects = new HashSet<SemanticObject>();
        for (SemanticsNode node : nodes) {
            updateSemanticObject(node, updatedObjects, removedObjects);
            sendAccessibilityEvent(node.id, AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED);
        }
        for (SemanticObject object : removedObjects) {
            if (!updatedObjects.contains(object)) {
                removeSemanticObject(object, updatedObjects);
            }
        }
    }

    private SemanticObject updateSemanticObject(SemanticsNode node,
                                                Set<SemanticObject> updatedObjects,
                                                Set<SemanticObject> removedObjects) {
        SemanticObject object = mObjects.get(node.id);
        if (object == null) {
            object = new SemanticObject();
            mObjects.put(node.id, object);
        }
        object.updateWith(node);
        updatedObjects.add(object);
        if (node.children != null) {
            if (node.children.length == 0) {
                if (object.children != null) {
                    removedObjects.addAll(object.children);
                }
                object.children = null;
            } else {
                if (object.children == null) {
                    object.children = new ArrayList<SemanticObject>(node.children.length);
                } else {
                    removedObjects.addAll(object.children);
                    object.children.clear();
                }
                for (SemanticsNode childNode : node.children) {
                    SemanticObject childObject = updateSemanticObject(childNode, updatedObjects, removedObjects);
                    childObject.parent = object;
                    object.children.add(childObject);
                }
            }
        }
        if (node.geometry != null) {
            // has to be done after children are updated
            // since they also get marked dirty
            object.invalidateGlobalGeometry();
        }
        return object;
    }

    private void sendAccessibilityEvent(int virtualViewId, int eventType) {
        if (!mAccessibilityEnabled) {
            return;
        }
        if (virtualViewId == 0) {
            mOwner.sendAccessibilityEvent(eventType);
        } else {
            AccessibilityEvent event = AccessibilityEvent.obtain(eventType);
            event.setPackageName(mOwner.getContext().getPackageName());
            event.setSource(mOwner, virtualViewId);
            mOwner.getParent().requestSendAccessibilityEvent(mOwner, event);
        }
    }

    private void removeSemanticObject(SemanticObject object, Set<SemanticObject> updatedObjects) {
        assert mObjects.containsKey(object.id);
        assert mObjects.get(object.id) == object;
        object.parent = null;
        mObjects.remove(object.id);
        if (mFocusedObject == object) {
            sendAccessibilityEvent(mFocusedObject.id, AccessibilityEvent.TYPE_VIEW_ACCESSIBILITY_FOCUS_CLEARED);
            mFocusedObject = null;
        }
        if (mHoveredObject == object) {
            mHoveredObject = null;
        }
        if (object.children != null) {
            for (SemanticObject child : object.children) {
                if (!updatedObjects.contains(child)) {
                    assert child.parent == object;
                    removeSemanticObject(child, updatedObjects);
                }
            }
        }
    }

    void reset(SemanticsServer.Proxy newSemanticsServer) {
        mObjects.clear();
        sendAccessibilityEvent(mFocusedObject.id, AccessibilityEvent.TYPE_VIEW_ACCESSIBILITY_FOCUS_CLEARED);
        mFocusedObject = null;
        mHoveredObject = null;
        mSemanticsServer.close();
        sendAccessibilityEvent(0, AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED);
        mSemanticsServer = newSemanticsServer;
        mSemanticsServer.addSemanticsListener(this);
    }

    private class SemanticObject {
        SemanticObject() { }

        void updateWith(SemanticsNode node) {
            if (id == -1) {
                id = node.id;
                assert node.flags != null;
                assert node.strings != null;
                assert node.geometry != null;
                assert node.children != null;
            }
            assert id == node.id;
            if (node.flags != null) {
                hasCheckedState = node.flags.hasCheckedState;
                isChecked = node.flags.isChecked;
            }
            if (node.strings != null) {
                label = node.strings.label;
            }
            if (node.geometry != null) {
                transform = node.geometry.transform;
                left = node.geometry.left;
                top = node.geometry.top;
                width = node.geometry.width;
                height = node.geometry.height;
            }
            if (node.actions != null) {
                canBeTapped = false;
                canBeLongPressed = false;
                canBeScrolledHorizontally = false;
                canBeScrolledVertically = false;
                for (int action : node.actions) {
                    switch (action) {
                    case SemanticAction.TAP:
                        canBeTapped = true;
                        break;
                    case SemanticAction.LONG_PRESS:
                        canBeLongPressed = true;
                        break;
                    case SemanticAction.SCROLL_LEFT:
                        canBeScrolledHorizontally = true;
                        break;
                    case SemanticAction.SCROLL_RIGHT:
                        canBeScrolledHorizontally = true;
                        break;
                    case SemanticAction.SCROLL_UP:
                        canBeScrolledVertically = true;
                        break;
                    case SemanticAction.SCROLL_DOWN:
                        canBeScrolledVertically = true;
                        break;
                    case SemanticAction.INCREASE:
                        // Not implemented.
                        break;
                    case SemanticAction.DECREASE:
                        // Not implemented.
                        break;
                    }
                }
            }
        }

        // fields that we pass straight to the Android accessibility API
        int id = -1;
        SemanticObject parent;
        boolean canBeTapped;
        boolean canBeLongPressed;
        boolean canBeScrolledHorizontally;
        boolean canBeScrolledVertically;
        boolean hasCheckedState;
        boolean isChecked;
        String label;
        List<SemanticObject> children;

        // geometry, which we have to convert to global coordinates to send to Android
        private float[] transform; // can be null, meaning identity transform
        private float left;
        private float top;
        private float width;
        private float height;

        private boolean geometryDirty = true;
        private void invalidateGlobalGeometry() {
            if (geometryDirty) {
                return;
            }
            geometryDirty = true;
            // TODO(ianh): if we are the AccessibilityBridge.this.mFocusedObject
            // then we may have to unfocus and refocus ourselves to get Android to update the focus rect
            if (children != null) {
                for (SemanticObject child : children) {
                    child.invalidateGlobalGeometry();
                }
            }
        }

        private float[] globalTransform; // cached transform from the root node to this node
        private Rect globalRect; // cached Rect of bounds of this node in coordinate space of the root node

        private float[] getGlobalTransform() {
            if (geometryDirty) {
                if (parent == null) {
                    globalTransform = transform;
                } else {
                    float[] parentTransform = parent.getGlobalTransform();
                    if (transform == null) {
                        globalTransform = parentTransform;
                    } else if (parentTransform == null) {
                        globalTransform = transform;
                    } else {
                        globalTransform = new float[16];
                        Matrix.multiplyMM(globalTransform, 0, transform, 0, parentTransform, 0);
                    }
                }
            }
            return globalTransform;
        }

        private float[] transformPoint(float[] transform, float[] point) {
            if (transform == null)
                return point; // this is a 4-item array but the caller will ignore all but the first two items
            float[] transformedPoint = new float[4];
            Matrix.multiplyMV(transformedPoint, 0, transform, 0, point, 0);
            assert transformedPoint[2] == 0;
            return new float[]{transformedPoint[0] / transformedPoint[3],
                               transformedPoint[1] / transformedPoint[3]};
        }

        private float min(float a, float b, float c, float d) {
            return Math.min(a, Math.min(b, Math.min(c, d)));
        }

        private float max(float a, float b, float c, float d) {
            return Math.max(a, Math.max(b, Math.max(c, d)));
        }

        Rect getGlobalRect() {
            if (geometryDirty) {
                float[] transform = getGlobalTransform();
                float[] point1 = transformPoint(transform, new float[]{left,         top,          0, 1});
                float[] point2 = transformPoint(transform, new float[]{left + width, top,          0, 1});
                float[] point3 = transformPoint(transform, new float[]{left + width, top + height, 0, 1});
                float[] point4 = transformPoint(transform, new float[]{left,         top + height, 0, 1});
                // TODO(ianh): Scaling here is a hack to work around #1360.
                float scale = mOwner.getDevicePixelRatio();
                globalRect = new Rect(
                  Math.round(min(point1[0], point2[0], point3[0], point4[0]) * scale),
                  Math.round(min(point1[1], point2[1], point3[1], point4[1]) * scale),
                  Math.round(max(point1[0], point2[0], point3[0], point4[0]) * scale),
                  Math.round(max(point1[1], point2[1], point3[1], point4[1]) * scale)
                );
            }
            return globalRect;
        }

        SemanticObject hitTest(int x, int y) {
            Rect rect = getGlobalRect();
            if (!rect.contains(x, y))
                return null;
            if (children != null) {
                for (int index = children.size()-1; index >= 0; index -= 1) {
                    SemanticObject child = children.get(index);
                    SemanticObject result = child.hitTest(x, y);
                    if (result != null) {
                        return result;
                    }
                }
            }
            return this;
        }
    }

    @Override
    public void close() {}

    @Override
    public void onConnectionError(MojoException e) {}

}
