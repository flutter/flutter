// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.ui.gfx;

import android.content.ComponentCallbacks;
import android.content.Context;
import android.content.res.Configuration;
import android.content.res.Resources;
import android.util.TypedValue;
import android.view.ViewConfiguration;

import org.chromium.base.CalledByNative;
import org.chromium.base.JNINamespace;
import org.chromium.ui.R;

/**
 * This class facilitates access to ViewConfiguration-related properties, also
 * providing native-code notifications when such properties have changed.
 *
 */
@JNINamespace("gfx")
public class ViewConfigurationHelper {

    // Fallback constants when resource lookup fails, see
    // ui/android/java/res/values/dimens.xml.
    private static final float MIN_SCALING_SPAN_MM = 27.0f;
    private static final float MIN_SCALING_TOUCH_MAJOR_DIP = 48.0f;

    private final Context mAppContext;
    private ViewConfiguration mViewConfiguration;

    private ViewConfigurationHelper(Context context) {
        mAppContext = context.getApplicationContext();
        mViewConfiguration = ViewConfiguration.get(mAppContext);
    }

    private void registerListener() {
        mAppContext.registerComponentCallbacks(
                new ComponentCallbacks() {
                    @Override
                    public void onConfigurationChanged(Configuration configuration) {
                        updateNativeViewConfigurationIfNecessary();
                    }

                    @Override
                    public void onLowMemory() {
                    }
                });
    }

    private void updateNativeViewConfigurationIfNecessary() {
        // The ViewConfiguration will differ only if the density has changed.
        ViewConfiguration configuration = ViewConfiguration.get(mAppContext);
        if (mViewConfiguration == configuration) return;

        mViewConfiguration = configuration;
        nativeUpdateSharedViewConfiguration(
                getScaledMaximumFlingVelocity(),
                getScaledMinimumFlingVelocity(),
                getScaledTouchSlop(),
                getScaledDoubleTapSlop(),
                getScaledMinScalingSpan(),
                getScaledMinScalingTouchMajor());
    }

    @CalledByNative
    private static int getDoubleTapTimeout() {
        return ViewConfiguration.getDoubleTapTimeout();
    }

    @CalledByNative
    private static int getLongPressTimeout() {
        return ViewConfiguration.getLongPressTimeout();
    }

    @CalledByNative
    private static int getTapTimeout() {
        return ViewConfiguration.getTapTimeout();
    }

    @CalledByNative
    private static float getScrollFriction() {
        return ViewConfiguration.getScrollFriction();
    }

    @CalledByNative
    private int getScaledMaximumFlingVelocity() {
        return mViewConfiguration.getScaledMaximumFlingVelocity();
    }

    @CalledByNative
    private int getScaledMinimumFlingVelocity() {
        return mViewConfiguration.getScaledMinimumFlingVelocity();
    }

    @CalledByNative
    private int getScaledTouchSlop() {
        return mViewConfiguration.getScaledTouchSlop();
    }

    @CalledByNative
    private int getScaledDoubleTapSlop() {
        return mViewConfiguration.getScaledDoubleTapSlop();
    }

    @CalledByNative
    private int getScaledMinScalingSpan() {
        final Resources res = mAppContext.getResources();
        int id = res.getIdentifier("config_minScalingSpan", "dimen", "android");
        // Fall back to a sensible default if the internal identifier does not exist.
        if (id == 0) id = R.dimen.config_min_scaling_span;
        try {
            return res.getDimensionPixelSize(id);
        } catch (Resources.NotFoundException e) {
            assert false : "MinScalingSpan resource lookup failed.";
            return (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_MM, MIN_SCALING_SPAN_MM,
                    res.getDisplayMetrics());
        }
    }

    @CalledByNative
    private int getScaledMinScalingTouchMajor() {
        final Resources res = mAppContext.getResources();
        int id = res.getIdentifier("config_minScalingTouchMajor", "dimen", "android");
        // Fall back to a sensible default if the internal identifier does not exist.
        if (id == 0) id = R.dimen.config_min_scaling_touch_major;
        try {
            return res.getDimensionPixelSize(id);
        } catch (Resources.NotFoundException e) {
            assert false : "MinScalingTouchMajor resource lookup failed.";
            return (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP,
                    MIN_SCALING_TOUCH_MAJOR_DIP, res.getDisplayMetrics());
        }
    }

    @CalledByNative
    private static ViewConfigurationHelper createWithListener(Context context) {
        ViewConfigurationHelper viewConfigurationHelper = new ViewConfigurationHelper(context);
        viewConfigurationHelper.registerListener();
        return viewConfigurationHelper;
    }

    private native void nativeUpdateSharedViewConfiguration(
            int scaledMaximumFlingVelocity, int scaledMinimumFlingVelocity,
            int scaledTouchSlop, int scaledDoubleTapSlop,
            int scaledMinScalingSpan, int scaledMinScalingTouchMajor);
}
