// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base.library_loader;

/**
 * These are the possible failures from the LibraryLoader
 */
public class LoaderErrors {
    public static final int LOADER_ERROR_NORMAL_COMPLETION = 0;
    public static final int LOADER_ERROR_FAILED_TO_REGISTER_JNI = 1;
    public static final int LOADER_ERROR_NATIVE_LIBRARY_LOAD_FAILED = 2;
    public static final int LOADER_ERROR_NATIVE_LIBRARY_WRONG_VERSION = 3;
    public static final int LOADER_ERROR_NATIVE_STARTUP_FAILED = 4;
}
