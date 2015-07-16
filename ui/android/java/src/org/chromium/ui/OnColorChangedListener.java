// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.ui;

/**
 * The callback used to indicate the user changed the color.
 */
public interface OnColorChangedListener {

    /**
     * Called upon a color change.
     *
     * @param color The color that was set.
     */
    void onColorChanged(int color);
}