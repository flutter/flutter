// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base;

/**
 * This class provides an interface to the native class for writing
 * important data files without risking data loss.
 */
@JNINamespace("base::android")
public class ImportantFileWriterAndroid {

    /**
     * Write a binary file atomically.
     *
     * This either writes all the data or leaves the file unchanged.
     *
     * @param fileName The complete path of the file to be written
     * @param data The data to be written to the file
     * @return true if the data was written to the file, false if not.
     */
    public static boolean writeFileAtomically(String fileName, byte[] data) {
        return nativeWriteFileAtomically(fileName, data);
    }

    private static native boolean nativeWriteFileAtomically(
            String fileName, byte[] data);
}
