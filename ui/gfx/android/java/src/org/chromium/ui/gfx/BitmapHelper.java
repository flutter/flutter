// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.ui.gfx;

import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;

import org.chromium.base.CalledByNative;
import org.chromium.base.JNINamespace;

/**
 * Helper class to decode and sample down bitmap resources.
 */
@JNINamespace("gfx")
public class BitmapHelper {
    @CalledByNative
    private static Bitmap createBitmap(int width,
                                      int height,
                                      int bitmapFormatValue) {
        Bitmap.Config bitmapConfig = getBitmapConfigForFormat(bitmapFormatValue);
        return Bitmap.createBitmap(width, height, bitmapConfig);
    }

    /**
     * Decode and sample down a bitmap resource to the requested width and height.
     *
     * @param name The resource name of the bitmap to decode.
     * @param reqWidth The requested width of the resulting bitmap.
     * @param reqHeight The requested height of the resulting bitmap.
     * @return A bitmap sampled down from the original with the same aspect ratio and dimensions.
     *         that are equal to or greater than the requested width and height.
     */
    @CalledByNative
    private static Bitmap decodeDrawableResource(String name,
                                                 int reqWidth,
                                                 int reqHeight) {
        Resources res = Resources.getSystem();
        int resId = res.getIdentifier(name, null, null);
        if (resId == 0) return null;

        final BitmapFactory.Options options = new BitmapFactory.Options();
        options.inJustDecodeBounds = true;
        BitmapFactory.decodeResource(res, resId, options);

        options.inSampleSize = calculateInSampleSize(options, reqWidth, reqHeight);
        options.inJustDecodeBounds = false;
        options.inPreferredConfig = Bitmap.Config.ARGB_8888;
        return BitmapFactory.decodeResource(res, resId, options);
    }

    // http://developer.android.com/training/displaying-bitmaps/load-bitmap.html
    private static int calculateInSampleSize(BitmapFactory.Options options,
                                             int reqWidth,
                                             int reqHeight) {
        // Raw height and width of image
        final int height = options.outHeight;
        final int width = options.outWidth;
        int inSampleSize = 1;

        if (height > reqHeight || width > reqWidth) {

            // Calculate ratios of height and width to requested height and width
            final int heightRatio = Math.round((float) height / (float) reqHeight);
            final int widthRatio = Math.round((float) width / (float) reqWidth);

            // Choose the smallest ratio as inSampleSize value, this will guarantee
            // a final image with both dimensions larger than or equal to the
            // requested height and width.
            inSampleSize = heightRatio < widthRatio ? heightRatio : widthRatio;
        }

        return inSampleSize;
    }

    /**
     * Provides a matching integer constant for the Bitmap.Config value passed.
     *
     * @param bitmapConfig The Bitmap Configuration value.
     * @return Matching integer constant for the Bitmap.Config value passed.
     */
    @CalledByNative
    private static int getBitmapFormatForConfig(Bitmap.Config bitmapConfig) {
        switch (bitmapConfig) {
            case ALPHA_8:
                return BitmapFormat.ALPHA_8;
            case ARGB_4444:
                return BitmapFormat.ARGB_4444;
            case ARGB_8888:
                return BitmapFormat.ARGB_8888;
            case RGB_565:
                return BitmapFormat.RGB_565;
            default:
                return BitmapFormat.NO_CONFIG;
        }
    }

     /**
     * Provides a matching Bitmap.Config for the enum config value passed.
     *
     * @param bitmapFormatValue The Bitmap Configuration enum value.
     * @return Matching Bitmap.Config  for the enum value passed.
     */
    private static Bitmap.Config getBitmapConfigForFormat(int bitmapFormatValue) {
        switch (bitmapFormatValue) {
            case BitmapFormat.ALPHA_8:
                return Bitmap.Config.ALPHA_8;
            case BitmapFormat.ARGB_4444:
                return Bitmap.Config.ARGB_4444;
            case BitmapFormat.RGB_565:
                return Bitmap.Config.RGB_565;
            case BitmapFormat.ARGB_8888:
            default:
                return Bitmap.Config.ARGB_8888;
        }
    }

}
