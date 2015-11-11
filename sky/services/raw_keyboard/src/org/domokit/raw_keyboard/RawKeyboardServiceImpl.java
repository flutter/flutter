// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.raw_keyboard;

import org.chromium.mojo.system.MojoException;
import org.chromium.mojom.raw_keyboard.RawKeyboardListener;
import org.chromium.mojom.raw_keyboard.RawKeyboardService;

/**
 * Android implementation of Keyboard.
 */
public class RawKeyboardServiceImpl implements RawKeyboardService {
    // We have a unique ServiceImpl per connection.  However multiple views
    // can be sending us key events simultaneously.
    private static RawKeyboardServiceState sViewState;

    public RawKeyboardServiceImpl() {
    }

    public static void setViewState(RawKeyboardServiceState state) {
        if (sViewState != null) sViewState.close();
        sViewState = state;
    }

    @Override
    public void addListener(RawKeyboardListener listener) {
        sViewState.addListener(listener);
    }

    @Override
    public void removeListener(RawKeyboardListener listener) {
        sViewState.removeListener(listener);
    }

    @Override
    public void onConnectionError(MojoException e) {}

    @Override
    public void close() {
        if (sViewState == null) return;
        sViewState.close();
    }
}
