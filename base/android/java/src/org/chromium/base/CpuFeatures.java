// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base;

// The only purpose of this class is to allow sending CPU properties
// from the browser process to sandboxed renderer processes. This is
// needed because sandboxed processes cannot, on ARM, query the kernel
// about the CPU's properties by parsing /proc, so this operation must
// be performed in the browser process, and the result passed to
// renderer ones.
//
// For more context, see http://crbug.com/164154
//
// Technically, this is a wrapper around the native NDK cpufeatures
// library. The exact CPU features bits are never used in Java so
// there is no point in duplicating their definitions here.
//
@JNINamespace("base::android")
public abstract class CpuFeatures {
    /**
     * Return the number of CPU Cores on the device.
     */
    public static int getCount() {
        return nativeGetCoreCount();
    }

    /**
     * Return the CPU feature mask.
     * This is a 64-bit integer that corresponds to the CPU's features.
     * The value comes directly from android_getCpuFeatures().
     */
    public static long getMask() {
        return nativeGetCpuFeatures();
    }

    private static native int nativeGetCoreCount();
    private static native long nativeGetCpuFeatures();
}
