// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base;

import android.content.ContentResolver;
import android.content.Context;
import android.database.Cursor;
import android.net.Uri;
import android.os.ParcelFileDescriptor;
import android.util.Log;

import java.io.File;
import java.io.FileNotFoundException;

/**
 * This class provides methods to access content URI schemes.
 */
public abstract class ContentUriUtils {
    private static final String TAG = "ContentUriUtils";
    private static FileProviderUtil sFileProviderUtil;

    /**
     * Provides functionality to translate a file into a content URI for use
     * with a content provider.
     */
    public interface FileProviderUtil {
        /**
         * Generate a content URI from the given file.
         * @param context Application context.
         * @param file The file to be translated.
         */
        Uri getContentUriFromFile(Context context, File file);
    }

    // Prevent instantiation.
    private ContentUriUtils() {}

    public static void setFileProviderUtil(FileProviderUtil util) {
        sFileProviderUtil = util;
    }

    public static Uri getContentUriFromFile(Context context, File file) {
        ThreadUtils.assertOnUiThread();
        if (sFileProviderUtil != null) {
            return sFileProviderUtil.getContentUriFromFile(context, file);
        }
        return null;
    }

    /**
     * Opens the content URI for reading, and returns the file descriptor to
     * the caller. The caller is responsible for closing the file desciptor.
     *
     * @param context {@link Context} in interest
     * @param uriString the content URI to open
     * @return file desciptor upon sucess, or -1 otherwise.
     */
    @CalledByNative
    public static int openContentUriForRead(Context context, String uriString) {
        ParcelFileDescriptor pfd = getParcelFileDescriptor(context, uriString);
        if (pfd != null) {
            return pfd.detachFd();
        }
        return -1;
    }

    /**
     * Check whether a content URI exists.
     *
     * @param context {@link Context} in interest.
     * @param uriString the content URI to query.
     * @return true if the URI exists, or false otherwise.
     */
    @CalledByNative
    public static boolean contentUriExists(Context context, String uriString) {
        return getParcelFileDescriptor(context, uriString) != null;
    }

    /**
     * Retrieve the MIME type for the content URI.
     *
     * @param context {@link Context} in interest.
     * @param uriString the content URI to look up.
     * @return MIME type or null if the input params are empty or invalid.
     */
    @CalledByNative
    public static String getMimeType(Context context, String uriString) {
        ContentResolver resolver = context.getContentResolver();
        if (resolver == null) return null;
        Uri uri = Uri.parse(uriString);
        return resolver.getType(uri);
    }

    /**
     * Helper method to open a content URI and returns the ParcelFileDescriptor.
     *
     * @param context {@link Context} in interest.
     * @param uriString the content URI to open.
     * @return ParcelFileDescriptor of the content URI, or NULL if the file does not exist.
     */
    private static ParcelFileDescriptor getParcelFileDescriptor(Context context, String uriString) {
        ContentResolver resolver = context.getContentResolver();
        Uri uri = Uri.parse(uriString);

        ParcelFileDescriptor pfd = null;
        try {
            pfd = resolver.openFileDescriptor(uri, "r");
        } catch (FileNotFoundException e) {
            Log.w(TAG, "Cannot find content uri: " + uriString, e);
        } catch (SecurityException e) {
            Log.w(TAG, "Cannot open content uri: " + uriString, e);
        } catch (IllegalArgumentException e) {
            Log.w(TAG, "Unknown content uri: " + uriString, e);
        }
        return pfd;
    }

    /**
     * Method to resolve the display name of a content URI.
     *
     * @param uri the content URI to be resolved.
     * @param contentResolver the content resolver to query.
     * @param columnField the column field to query.
     * @return the display name of the @code uri if present in the database
     *  or an empty string otherwise.
     */
    public static String getDisplayName(
            Uri uri, ContentResolver contentResolver, String columnField) {
        if (contentResolver == null || uri == null) return "";
        Cursor cursor = null;
        try {
            cursor = contentResolver.query(uri, null, null, null, null);

            if (cursor != null && cursor.getCount() >= 1) {
                cursor.moveToFirst();
                int index = cursor.getColumnIndex(columnField);
                if (index > -1) return cursor.getString(index);
            }
        } catch (NullPointerException e) {
            // Some android models don't handle the provider call correctly.
            // see crbug.com/345393
            return "";
        } finally {
            if (cursor != null) cursor.close();
        }
        return "";
    }
}
