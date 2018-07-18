// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.platform;

import android.annotation.TargetApi;
import android.app.Presentation;
import android.content.Context;
import android.os.Build;
import android.os.Bundle;
import android.view.Display;
import android.view.View;
import android.widget.FrameLayout;

@TargetApi(Build.VERSION_CODES.JELLY_BEAN_MR1)
class SingleViewPresentation extends Presentation {
    private final PlatformViewFactory mViewFactory;

    private PlatformView mView;
    private int mViewId;

    // As the root view of a display cannot be detached, we use this mContainer
    // as the root, and attach mView to it. This allows us to detach mView.
    private FrameLayout mContainer;

    /**
     * Creates a presentation that will use the view factory to create a new
     * platform view in the presentation's onCreate, and attach it.
     */
    public SingleViewPresentation(Context outerContext, Display display, PlatformViewFactory viewFactory, int viewId) {
        super(outerContext, display);
        mViewFactory = viewFactory;
        mViewId = viewId;
    }

    /**
     * Creates a presentation that will attach an already existing view as
     * its root view.
     *
     * <p>The display's density must match the density of the context used
     * when the view was created.
     */
    public SingleViewPresentation(Context outerContext, Display display, PlatformView view) {
        super(outerContext, display);
        mViewFactory = null;
        mView = view;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (mView == null) {
            mView = mViewFactory.create(getContext(), mViewId);
        }
        mContainer = new FrameLayout(getContext());
        mContainer.addView(mView.getView());
        setContentView(mContainer);
    }

    public PlatformView detachView() {
        mContainer.removeView(mView.getView());
        return mView;
    }

    public View getView() {
        if (mView == null)
            return null;
        return mView.getView();
    }
}
