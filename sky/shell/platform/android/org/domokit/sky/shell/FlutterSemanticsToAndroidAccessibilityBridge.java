// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.sky.shell;

import android.graphics.Rect;
import android.opengl.Matrix;
import android.os.Bundle;
import android.view.View;
import android.view.accessibility.AccessibilityManager;
import android.view.accessibility.AccessibilityNodeInfo;
import android.view.accessibility.AccessibilityNodeProvider;

import org.chromium.mojo.system.MojoException;
import org.chromium.mojom.semantics.SemanticsListener;
import org.chromium.mojom.semantics.SemanticsNode;
import org.chromium.mojom.semantics.SemanticsServer;
import org.chromium.mojom.sky.ViewportMetrics;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class FlutterSemanticsToAndroidAccessibilityBridge extends AccessibilityNodeProvider
                                                          implements SemanticsListener {
    private Map<Integer, PersistentAccessibilityNode> mTreeNodes;
    private PlatformViewAndroid mOwner;
    private SemanticsServer.Proxy mSemanticsServer;

    FlutterSemanticsToAndroidAccessibilityBridge(PlatformViewAndroid owner, SemanticsServer.Proxy semanticsServer) {
        assert owner != null;
        assert semanticsServer != null;
        mOwner = owner;
        mTreeNodes = new HashMap<Integer, PersistentAccessibilityNode>();
        mSemanticsServer = semanticsServer;
        mSemanticsServer.addSemanticsListener(this);
    }

    @Override
    public AccessibilityNodeInfo createAccessibilityNodeInfo(int virtualViewId) {

        if (virtualViewId == View.NO_ID) {
            AccessibilityNodeInfo result = AccessibilityNodeInfo.obtain(mOwner);
            mOwner.onInitializeAccessibilityNodeInfo(result);
            if (mTreeNodes.containsKey(0))
                result.addChild(mOwner, 0);
            return result;
        }

        PersistentAccessibilityNode node = mTreeNodes.get(virtualViewId);
        if (node == null)
            return null;

        AccessibilityNodeInfo result = AccessibilityNodeInfo.obtain(mOwner, virtualViewId);
        result.setPackageName(mOwner.getContext().getPackageName());
        result.setClassName("Flutter"); // Prettier than the more conventional node.getClass().getName()
        result.setSource(mOwner, virtualViewId);

        if (node.parent != null) {
            assert node.id > 0;
            result.setParent(mOwner, node.parent.id);
        } else {
            assert node.id == 0;
            result.setParent(mOwner);
        }

        Rect bounds = node.getGlobalRect();
        if (node.parent != null) {
            Rect parentBounds = node.parent.getGlobalRect();
            Rect boundsInParent = new Rect(bounds);
            boundsInParent.offset(-parentBounds.left, -parentBounds.top);
            result.setBoundsInParent(boundsInParent);
        } else {
            result.setBoundsInParent(bounds);
        }
        result.setBoundsInScreen(bounds);
        result.setVisibleToUser(true);
        result.setEnabled(true); // TODO(ianh): Expose disabled subtrees

        if (node.canBeTapped) {
            result.addAction(AccessibilityNodeInfo.ACTION_CLICK);
            result.setClickable(true);
        }
        if (node.canBeLongPressed) {
            result.addAction(AccessibilityNodeInfo.ACTION_LONG_CLICK);
            result.setLongClickable(true);
        }
        if ((node.canBeScrolledHorizontally && !node.canBeScrolledVertically) ||
            (!node.canBeScrolledHorizontally && node.canBeScrolledVertically)) {
            result.addAction(AccessibilityNodeInfo.ACTION_SCROLL_FORWARD);
            result.addAction(AccessibilityNodeInfo.ACTION_SCROLL_BACKWARD);
        }
        if (node.canBeScrolledHorizontally || node.canBeScrolledVertically) {
            // TODO(ianh): Figure out how to enable panning. SDK v23
            // has AccessibilityAction.ACTION_SCROLL_LEFT and company,
            // but earlier versions do not. Right now we only forward
            // scroll actions if it's unidirectional.
            result.setScrollable(true);
        }

        result.setCheckable(node.hasCheckedState);
        result.setChecked(node.isChecked);
        result.setText(node.label);

        // TODO(ianh): use setTraversalBefore/setTraversalAfter to set
        // the relative order of the views. For each set of siblings,
        // the views should be ordered top-to-bottom, tie-breaking
        // left-to-right (right-to-left in rtl environments), height,
        // width, and finally by list order.

        for (PersistentAccessibilityNode child : node.children) {
            result.addChild(mOwner, child.id);
        }

        return result;
    }

    @Override
    public boolean performAction(int virtualViewId, int action, Bundle arguments) {
        if (!mTreeNodes.containsKey(virtualViewId))
            return false;
        switch (action) {
            case AccessibilityNodeInfo.ACTION_CLICK: {
                mSemanticsServer.tap(virtualViewId);
                return true;
            }
            case AccessibilityNodeInfo.ACTION_LONG_CLICK: {
                mSemanticsServer.longPress(virtualViewId);
                return true;
            }
            case AccessibilityNodeInfo.ACTION_SCROLL_BACKWARD: {
                PersistentAccessibilityNode node = mTreeNodes.get(virtualViewId);
                if (node.canBeScrolledHorizontally && !node.canBeScrolledVertically) {
                    // TODO(ianh): bidi support
                    mSemanticsServer.scrollLeft(virtualViewId);
                } else if (node.canBeScrolledHorizontally && !node.canBeScrolledVertically) {
                    mSemanticsServer.scrollUp(virtualViewId);
                } else {
                    return false;
                }
                return true;
            }
            case AccessibilityNodeInfo.ACTION_SCROLL_FORWARD: {
                PersistentAccessibilityNode node = mTreeNodes.get(virtualViewId);
                if (node.canBeScrolledHorizontally && !node.canBeScrolledVertically) {
                    // TODO(ianh): bidi support
                    mSemanticsServer.scrollRight(virtualViewId);
                } else if (node.canBeScrolledHorizontally && !node.canBeScrolledVertically) {
                    mSemanticsServer.scrollDown(virtualViewId);
                } else {
                    return false;
                }
                return true;
            }
        }
        // TODO(ianh): Implement left/right/up/down scrolling
        return false;
    }

    @Override
    public void updateSemanticsTree(SemanticsNode[] nodes) {
        for (SemanticsNode node : nodes) {
            updateSemanticsNode(node);
        }
    }

    private PersistentAccessibilityNode updateSemanticsNode(SemanticsNode node) {
        PersistentAccessibilityNode persistentNode = mTreeNodes.get(node.id);
        if (persistentNode != null) {
            persistentNode.update(node);
        } else {
            persistentNode = new PersistentAccessibilityNode(node);
            mTreeNodes.put(node.id, persistentNode);
        }
        assert persistentNode != null;
        return persistentNode;
    }

    public void removePersistentNode(PersistentAccessibilityNode node) {
        assert mTreeNodes.containsKey(node.id);
        assert mTreeNodes.get(node.id).parent == null;
        mTreeNodes.remove(node.id);
    }

    public void reset(SemanticsServer.Proxy newSemanticsServer) {
        mTreeNodes.clear();
        mSemanticsServer.close();
        mSemanticsServer = newSemanticsServer;
        mSemanticsServer.addSemanticsListener(this);
    }

    private class PersistentAccessibilityNode {
        PersistentAccessibilityNode(SemanticsNode node) {
            update(node);
        }
        void update(SemanticsNode node) {
            if (id == -1) {
                id = node.id;
                assert node.flags != null;
                assert node.strings != null;
                assert node.geometry != null;
                assert node.children != null;
            }
            assert id == node.id;
            if (node.flags != null) {
                canBeTapped = node.flags.canBeTapped;
                canBeLongPressed = node.flags.canBeLongPressed;
                canBeScrolledHorizontally = node.flags.canBeScrolledHorizontally;
                canBeScrolledVertically = node.flags.canBeScrolledVertically;
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
            if (node.children != null) {
                List<PersistentAccessibilityNode> oldChildren = children;
                children = new ArrayList<PersistentAccessibilityNode>(node.children.length);
                if (oldChildren != null) {
                    for (PersistentAccessibilityNode child : oldChildren) {
                        assert child.parent != null;
                        child.parent = null;
                    }
                }
                for (SemanticsNode childNode : node.children) {
                    PersistentAccessibilityNode child = FlutterSemanticsToAndroidAccessibilityBridge.this.updateSemanticsNode(childNode);
                    assert child != null;
                    child.parent = this;
                    children.add(child);
                }
                if (oldChildren != null) {
                    for (PersistentAccessibilityNode child : oldChildren) {
                        if (child.parent == null) {
                            FlutterSemanticsToAndroidAccessibilityBridge.this.removePersistentNode(child);
                        }
                    }
                }
            }
            if (node.geometry != null) {
                // has to be done after children are updated
                // since they also get marked dirty
                invalidateGlobalGeometry();
            }
            // TODO(ianh): Notify Android that our tree is dirty
        }

        // fields that we pass straight to the Android accessibility API
        public int id = -1;
        public PersistentAccessibilityNode parent;
        public boolean canBeTapped;
        public boolean canBeLongPressed;
        public boolean canBeScrolledHorizontally;
        public boolean canBeScrolledVertically;
        public boolean hasCheckedState;
        public boolean isChecked;
        public String label;
        public List<PersistentAccessibilityNode> children;

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
            for (PersistentAccessibilityNode child : children) {
                child.invalidateGlobalGeometry();
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

        public Rect getGlobalRect() {
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
    }

    @Override
    public void close() {}

    @Override
    public void onConnectionError(MojoException e) {}

}
