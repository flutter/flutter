// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.platform;

import android.annotation.TargetApi;
import android.app.Presentation;
import android.content.Context;
import android.content.ContextWrapper;
import android.graphics.Rect;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.view.*;
import android.widget.FrameLayout;

import java.lang.reflect.*;

import static android.content.Context.WINDOW_SERVICE;

/*
 * A presentation used for hosting a single Android view in a virtual display.
 *
 * This presentation overrides the WindowManager's addView/removeView/updateViewLayout methods, such that views added
 * directly to the WindowManager are added as part of the presentation's view hierarchy (to mFakeWindowRootView).
 *
 * The view hierarchy for the presentation is as following:
 *
 *          mRootView
 *         /         \
 *        /           \
 *       /             \
 *   mContainer       mState.mFakeWindowRootView
 *      |
 *   EmbeddedView
 */
@TargetApi(Build.VERSION_CODES.JELLY_BEAN_MR1)
class SingleViewPresentation extends Presentation {

    /*
     * When an embedded view is resized in Flutterverse we move the Android view to a new virtual display
     * that has the new size. This class keeps the presentation state that moves with the view to the presentation of
     * the new virtual display.
     */
    static class PresentationState {
        // The Android view we are embedding in the Flutter app.
        private PlatformView mView;

        // The InvocationHandler for a WindowManager proxy. This is essentially the custom window manager for the
        // presentation.
        private WindowManagerHandler mWindowManagerHandler;

        // Contains views that were added directly to the window manager (e.g android.widget.PopupWindow).
        private FakeWindowViewGroup mFakeWindowRootView;
    }

    private final PlatformViewFactory mViewFactory;

    // This is the view id assigned by the Flutter framework to the embedded view, we keep it here
    // so when we create the platform view we can tell it its view id.
    private int mViewId;

    // This is the creation parameters for the platform view, we keep it here
    // so when we create the platform view we can tell it its view id.
    private Object mCreateParams;

    // The root view for the presentation, it has 2 childs: mContainer which contains the embedded view, and
    // mFakeWindowRootView which contains views that were added directly to the presentation's window manager.
    private FrameLayout mRootView;

    // Contains the embedded platform view (mView.getView()) when it is attached to the presentation.
    private FrameLayout mContainer;

    private PresentationState mState;

    /**
     * Creates a presentation that will use the view factory to create a new
     * platform view in the presentation's onCreate, and attach it.
     */
    public SingleViewPresentation(
            Context outerContext,
            Display display,
            PlatformViewFactory viewFactory,
            int viewId,
            Object createParams) {
        super(outerContext, display);
        mViewFactory = viewFactory;
        mViewId = viewId;
        mCreateParams = createParams;
        mState = new PresentationState();
        getWindow().setFlags(
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
        );
    }

    /**
     * Creates a presentation that will attach an already existing view as
     * its root view.
     *
     * <p>The display's density must match the density of the context used
     * when the view was created.
     */
    public SingleViewPresentation(Context outerContext, Display display, PresentationState state) {
        super(outerContext, display);
        mViewFactory = null;
        mState = state;
        getWindow().setFlags(
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
        );
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (mState.mFakeWindowRootView == null) {
            mState.mFakeWindowRootView = new FakeWindowViewGroup(getContext());
        }
        if (mState.mWindowManagerHandler == null) {
            WindowManager windowManagerDelegate = (WindowManager) getContext().getSystemService(WINDOW_SERVICE);
            mState.mWindowManagerHandler = new WindowManagerHandler(windowManagerDelegate, mState.mFakeWindowRootView);
        }

        mContainer = new FrameLayout(getContext());
        PresentationContext context = new PresentationContext(getContext(), mState.mWindowManagerHandler);

        if (mState.mView == null) {
            mState.mView = mViewFactory.create(context, mViewId, mCreateParams);
        }

        mContainer.addView(mState.mView.getView());
        mRootView = new FrameLayout(getContext());
        mRootView.addView(mContainer);
        mRootView.addView(mState.mFakeWindowRootView);
        setContentView(mRootView);
    }

    public PresentationState detachState() {
        mContainer.removeAllViews();
        mRootView.removeAllViews();
        return mState;
    }

    public PlatformView getView() {
        if (mState.mView == null)
            return null;
        return mState.mView;
    }

    /*
     * A view group that implements the same layout protocol that exist between the WindowManager and its direct
     * children.
     *
     * Currently only a subset of the protocol is supported (gravity, x, and y).
     */
    static class FakeWindowViewGroup extends ViewGroup {
        // Used in onLayout to keep the bounds of the current view.
        // We keep it as a member to avoid object allocations during onLayout which are discouraged.
        private final Rect mViewBounds;

        // Used in onLayout to keep the bounds of the child views.
        // We keep it as a member to avoid object allocations during onLayout which are discouraged.
        private final Rect mChildRect;

        public FakeWindowViewGroup(Context context) {
            super(context);
            mViewBounds = new Rect();
            mChildRect = new Rect();
        }

        @Override
        protected void onLayout(boolean changed, int l, int t, int r, int b) {
            for(int i = 0; i < getChildCount(); i++) {
                View child = getChildAt(i);
                WindowManager.LayoutParams params = (WindowManager.LayoutParams) child.getLayoutParams();
                mViewBounds.set(l, t, r, b);
                Gravity.apply(params.gravity, child.getMeasuredWidth(), child.getMeasuredHeight(), mViewBounds, params.x,
                        params.y, mChildRect);
                child.layout(mChildRect.left, mChildRect.top, mChildRect.right, mChildRect.bottom);
            }
        }

        @Override
        protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
            for(int i = 0; i < getChildCount(); i++) {
                View child = getChildAt(i);
                child.measure(atMost(widthMeasureSpec), atMost(heightMeasureSpec));
            }
            super.onMeasure(widthMeasureSpec, heightMeasureSpec);
        }

        private static int atMost(int measureSpec) {
            return MeasureSpec.makeMeasureSpec(MeasureSpec.getSize(measureSpec), MeasureSpec.AT_MOST);
        }
    }

    /**
     * Proxies a Context replacing the WindowManager with our custom instance.
     */
    static class PresentationContext extends ContextWrapper {
        private WindowManager mWindowManager;
        private final WindowManagerHandler mWindowManagerHandler;

        PresentationContext(Context base, WindowManagerHandler windowManagerHandler) {
            super(base);
            mWindowManagerHandler = windowManagerHandler;
        }

        @Override
        public Object getSystemService(String name) {
            if (WINDOW_SERVICE.equals(name)) {
                return getWindowManager();
            }
            return super.getSystemService(name);
        }

        private WindowManager getWindowManager() {
            if (mWindowManager == null) {
                mWindowManager = mWindowManagerHandler.getWindowManager();
            }
            return mWindowManager;
        }
    }

    /*
     * A dynamic proxy handler for a WindowManager with custom overrides.
     *
     * The presentation's window manager delegates all calls to the default window manager.
     * WindowManager#addView calls triggered by views that are attached to the virtual display are crashing
     * (see: https://github.com/flutter/flutter/issues/20714). This was triggered when selecting text in an embedded
     * WebView (as the selection handles are implemented as popup windows).
     *
     * This dynamic proxy overrides the addView, removeView, and updateViewLayout methods to prevent these crashes.
     *
     * This will be more efficient as a static proxy that's not using reflection, but as the engine is currently
     * not being built against the latest Android SDK we cannot override all relevant method.
     * Tracking issue for upgrading the engine's Android sdk: https://github.com/flutter/flutter/issues/20717
     */
    static class WindowManagerHandler implements InvocationHandler {
        private static final String TAG = "PlatformViewsController";

        private final WindowManager mDelegate;
        FakeWindowViewGroup mFakeWindowRootView;

        WindowManagerHandler(WindowManager delegate, FakeWindowViewGroup fakeWindowViewGroup) {
            mDelegate = delegate;
            mFakeWindowRootView = fakeWindowViewGroup;
        }

        public WindowManager getWindowManager() {
            return (WindowManager) Proxy.newProxyInstance(
                    WindowManager.class.getClassLoader(),
                    new Class[] { WindowManager.class },
                    this
            );
        }

        @Override
        public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
            switch (method.getName()) {
                case "addView":
                    addView(args);
                    return null;
                case "removeView":
                    removeView(args);
                    return null;
                case "updateViewLayout":
                    updateViewLayout(args);
                    return null;
            }
            try {
                return method.invoke(mDelegate, args);
            } catch (InvocationTargetException e) {
                throw e.getCause();
            }
        }

        private void addView(Object[] args) {
            if (mFakeWindowRootView == null) {
                Log.w(TAG, "Embedded view called addView while detached from presentation");
                return;
            }
            View view = (View) args[0];
            WindowManager.LayoutParams layoutParams = (WindowManager.LayoutParams) args[1];
            mFakeWindowRootView.addView(view, layoutParams);
        }

        private void removeView(Object[] args) {
            if (mFakeWindowRootView == null) {
                Log.w(TAG, "Embedded view called removeView while detached from presentation");
                return;
            }
            View view = (View) args[0];
            mFakeWindowRootView.removeView(view);
        }

        private void updateViewLayout(Object[] args) {
            if (mFakeWindowRootView == null) {
                Log.w(TAG, "Embedded view called updateViewLayout while detached from presentation");
                return;
            }
            View view = (View) args[0];
            WindowManager.LayoutParams layoutParams = (WindowManager.LayoutParams) args[1];
            mFakeWindowRootView.updateViewLayout(view, layoutParams);
        }
    }
}
