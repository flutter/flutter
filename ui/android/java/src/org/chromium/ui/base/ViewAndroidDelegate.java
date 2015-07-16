// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.ui.base;

import android.view.View;

/**
 * Interface to acquire and release anchor views from the implementing View.
 */
public interface ViewAndroidDelegate {

    /**
     * @return An anchor view that can be used to anchor decoration views like Autofill popup.
     */
    View acquireAnchorView();

    /**
     * Set the anchor view to specified position and width (all units in dp).
     * @param view The anchor view that needs to be positioned.
     * @param x X coordinate of the top left corner of the anchor view.
     * @param y Y coordinate of the top left corner of the anchor view.
     * @param width The width of the anchor view.
     * @param height The height of the anchor view.
     */
    void setAnchorViewPosition(View view, float x, float y, float width, float height);

    /**
     * Release given anchor view.
     * @param anchorView The anchor view that needs to be released.
     */
    void releaseAnchorView(View anchorView);
}
