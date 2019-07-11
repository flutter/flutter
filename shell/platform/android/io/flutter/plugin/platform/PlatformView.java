// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.platform;

import android.annotation.SuppressLint;
import android.view.View;

/**
 * A handle to an Android view to be embedded in the Flutter hierarchy.
 */
public interface PlatformView {
    /**
     * Returns the Android view to be embedded in the Flutter hierarchy.
     */
    View getView();

    /**
     * Dispose this platform view.
     *
     * <p>The {@link PlatformView} object is unusable after this method is called.
     *
     * <p>Plugins implementing {@link PlatformView} must clear all references to the View object and the PlatformView
     * after this method is called. Failing to do so will result in a memory leak.
     */
    void dispose();

    /**
    * Callback fired when the platform's input connection is locked, or should be used. See also
    * {@link TextInputPlugin#lockPlatformViewInputConnection}.
    *
    * <p>This hook only exists for rare cases where the plugin relies on the state of the input
    * connection. This probably doesn't need to be implemented.
    */
    // Default interface methods are supported on all min SDK versions of Android.
    @SuppressLint("NewApi")
    default void onInputConnectionLocked() {};

    /**
    * Callback fired when the platform input connection has been unlocked. See also
    * {@link TextInputPlugin#lockPlatformViewInputConnection}.
    *
    * <p>This hook only exists for rare cases where the plugin relies on the state of the input
    * connection. This probably doesn't need to be implemented.
    */
    // Default interface methods are supported on all min SDK versions of Android.
    @SuppressLint("NewApi")
    default void onInputConnectionUnlocked() {};
}
