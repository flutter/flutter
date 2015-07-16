// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base.library_loader;

/**
 * This is a complete dummy, required because base now requires a version of
 * NativeLibraries to build, but doesn't include it in its jar file.
 */
public class NativeLibraries {
    public static boolean sUseLinker = false;
    public static boolean sUseLibraryInZipFile = false;
    public static boolean sEnableLinkerTests = false;
    static final String[] LIBRARIES = {};
    static String sVersionNumber = "";
}
