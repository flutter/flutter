// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.platform;

import android.view.View;

/**
 * A handle to an Android view to be embedded in the Flutter hierarchy.
 */
public interface PlatformView {
    /**
     * Returns the Android view to be embedded in the Flutter hierarchy.
     */
    View getView();
}
