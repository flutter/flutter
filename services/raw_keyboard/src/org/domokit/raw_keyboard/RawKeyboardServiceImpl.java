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
    private RawKeyboardServiceState mViewState;

    public RawKeyboardServiceImpl(RawKeyboardServiceState state) {
        mViewState = state;
    }

    @Override
    public void addListener(RawKeyboardListener listener) {
        mViewState.addListener((RawKeyboardListener.Proxy) listener);
    }

    @Override
    public void onConnectionError(MojoException e) {}

    @Override
    public void close() {
        mViewState.close();
    }
}
