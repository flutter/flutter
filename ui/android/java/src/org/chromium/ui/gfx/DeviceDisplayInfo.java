// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.ui.gfx;

import android.content.Context;
import android.graphics.PixelFormat;
import android.graphics.Point;
import android.os.Build;
import android.util.DisplayMetrics;
import android.view.Display;
import android.view.Surface;
import android.view.WindowManager;

import org.chromium.base.CalledByNative;
import org.chromium.base.JNINamespace;

/**
 * This class facilitates access to android information typically only
 * available using the Java SDK, including {@link Display} properties.
 *
 * Currently the information consists of very raw display information (height, width, DPI scale)
 * regarding the main display.
 */
@JNINamespace("gfx")
public class DeviceDisplayInfo {

    private final Context mAppContext;
    private final WindowManager mWinManager;
    private Point mTempPoint = new Point();
    private DisplayMetrics mTempMetrics = new DisplayMetrics();

    private DeviceDisplayInfo(Context context) {
        mAppContext = context.getApplicationContext();
        mWinManager = (WindowManager) mAppContext.getSystemService(Context.WINDOW_SERVICE);
    }

    /**
     * @return Display height in physical pixels.
     */
    @CalledByNative
    public int getDisplayHeight() {
        getDisplay().getSize(mTempPoint);
        return mTempPoint.y;
    }

    /**
     * @return Display width in physical pixels.
     */
    @CalledByNative
    public int getDisplayWidth() {
        getDisplay().getSize(mTempPoint);
        return mTempPoint.x;
    }

    /**
     * @return Real physical display height in physical pixels.
     */
    @CalledByNative
    public int getPhysicalDisplayHeight() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.JELLY_BEAN_MR1) {
            return 0;
        }
        getDisplay().getRealSize(mTempPoint);
        return mTempPoint.y;
    }

    /**
     * @return Real physical display width in physical pixels.
     */
    @CalledByNative
    public int getPhysicalDisplayWidth() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.JELLY_BEAN_MR1) {
            return 0;
        }
        getDisplay().getRealSize(mTempPoint);
        return mTempPoint.x;
    }

    @SuppressWarnings("deprecation")
    private int getPixelFormat() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.JELLY_BEAN_MR1) {
            return getDisplay().getPixelFormat();
        }
        // JellyBean MR1 and later always uses RGBA_8888.
        return PixelFormat.RGBA_8888;
    }

    /**
     * @return Bits per pixel.
     */
    @CalledByNative
    public int getBitsPerPixel() {
        int format = getPixelFormat();
        PixelFormat info = new PixelFormat();
        PixelFormat.getPixelFormatInfo(format, info);
        return info.bitsPerPixel;
    }

    /**
     * @return Bits per component.
     */
    @SuppressWarnings("deprecation")
    @CalledByNative
    public int getBitsPerComponent() {
        int format = getPixelFormat();
        switch (format) {
            case PixelFormat.RGBA_4444:
                return 4;

            case PixelFormat.RGBA_5551:
                return 5;

            case PixelFormat.RGBA_8888:
            case PixelFormat.RGBX_8888:
            case PixelFormat.RGB_888:
                return 8;

            case PixelFormat.RGB_332:
                return 2;

            case PixelFormat.RGB_565:
                return 5;

            // Non-RGB formats.
            case PixelFormat.A_8:
            case PixelFormat.LA_88:
            case PixelFormat.L_8:
                return 0;

            // Unknown format. Use 8 as a sensible default.
            default:
                return 8;
        }
    }

    /**
     * @return A scaling factor for the Density Independent Pixel unit. 1.0 is
     *         160dpi, 0.75 is 120dpi, 2.0 is 320dpi.
     */
    @CalledByNative
    public double getDIPScale() {
        getDisplay().getMetrics(mTempMetrics);
        return mTempMetrics.density;
    }

    /**
     * @return Smallest screen size in density-independent pixels that the
     *         application will see, regardless of orientation.
     */
    @CalledByNative
    private int getSmallestDIPWidth() {
        return mAppContext.getResources().getConfiguration().smallestScreenWidthDp;
    }

    /**
     * @return the screen's rotation angle from its 'natural' orientation.
     * Expected values are one of { 0, 90, 180, 270 }.
     * See http://developer.android.com/reference/android/view/Display.html#getRotation()
     * for more information about Display.getRotation() behavior.
     */
    @CalledByNative
    public int getRotationDegrees() {
        switch (getDisplay().getRotation()) {
            case Surface.ROTATION_0:
                return 0;
            case Surface.ROTATION_90:
                return 90;
            case Surface.ROTATION_180:
                return 180;
            case Surface.ROTATION_270:
                return 270;
        }

        // This should not happen.
        assert false;
        return 0;
    }

    /**
     * Inform the native implementation to update its cached representation of
     * the DeviceDisplayInfo values.
     */
    public void updateNativeSharedDisplayInfo() {
        nativeUpdateSharedDeviceDisplayInfo(
                getDisplayHeight(), getDisplayWidth(),
                getPhysicalDisplayHeight(), getPhysicalDisplayWidth(),
                getBitsPerPixel(), getBitsPerComponent(),
                getDIPScale(), getSmallestDIPWidth(), getRotationDegrees());
    }

    private Display getDisplay() {
        return mWinManager.getDefaultDisplay();
    }

    /**
     * Creates DeviceDisplayInfo for a given Context.
     *
     * @param context A context to use.
     * @return DeviceDisplayInfo associated with a given Context.
     */
    @CalledByNative
    public static DeviceDisplayInfo create(Context context) {
        return new DeviceDisplayInfo(context);
    }

    private native void nativeUpdateSharedDeviceDisplayInfo(
            int displayHeight, int displayWidth,
            int physicalDisplayHeight, int physicalDisplayWidth,
            int bitsPerPixel, int bitsPerComponent, double dipScale,
            int smallestDIPWidth, int rotationDegrees);

}
