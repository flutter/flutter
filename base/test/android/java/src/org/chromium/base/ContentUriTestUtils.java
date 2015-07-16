// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base;

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.net.Uri;
import android.provider.MediaStore;

/**
 * Utilities for testing operations on content URI.
 */
public class ContentUriTestUtils {
    /**
     * Insert an image into the MediaStore, and return the content URI. If the
     * image already exists in the MediaStore, just retrieve the URI.
     *
     * @param context Application context.
     * @param path Path to the image file.
     * @return Content URI of the image.
     */
    @CalledByNative
    private static String insertImageIntoMediaStore(Context context, String path) {
        // Check whether the content URI exists.
        Cursor c = context.getContentResolver().query(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                new String[] { MediaStore.Video.VideoColumns._ID },
                MediaStore.Images.Media.DATA + " LIKE ?",
                new String[] { path },
                null);
        if (c != null && c.getCount() > 0) {
            c.moveToFirst();
            int id = c.getInt(0);
            return Uri.withAppendedPath(
                    MediaStore.Images.Media.EXTERNAL_CONTENT_URI, "" + id).toString();
        }

        // Insert the content URI into MediaStore.
        ContentValues values = new ContentValues();
        values.put(MediaStore.MediaColumns.DATA, path);
        Uri uri = context.getContentResolver().insert(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values);
        return uri.toString();
    }
}
