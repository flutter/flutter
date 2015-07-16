// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base;

/**
 * Helper to get field trial information.
 */
public class FieldTrialList {

    private FieldTrialList() {}

    /**
     * @param trialName The name of the trial to get the group for.
     * @return The group name chosen for the named trial, or the empty string if the trial does
     *         not exist.
     */
    public static String findFullName(String trialName) {
        return nativeFindFullName(trialName);
    }

    /**
     * @param trialName The name of the trial to get the group for.
     * @return Whether the trial exists or not.
     */
    public static boolean trialExists(String trialName) {
        return nativeTrialExists(trialName);
    }

    private static native String nativeFindFullName(String trialName);
    private static native boolean nativeTrialExists(String trialName);
}
