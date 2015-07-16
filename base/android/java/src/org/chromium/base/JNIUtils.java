// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base;

/**
 * This class provides JNI-related methods to the native library.
 */
public class JNIUtils {
    /**
     * This returns a ClassLoader that is capable of loading Chromium Java code. Such a ClassLoader
     * is needed for the few cases where the JNI mechanism is unable to automatically determine the
     * appropriate ClassLoader instance.
     */
    @CalledByNative
    public static Object getClassLoader() {
        return JNIUtils.class.getClassLoader();
    }
}
