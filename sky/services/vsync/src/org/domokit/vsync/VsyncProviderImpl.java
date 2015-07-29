// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.vsync;

import android.view.Choreographer;

import org.chromium.mojo.system.MojoException;
import org.chromium.mojom.vsync.VsyncProvider;

/**
 * Android implementation of VsyncProvider.
 */
public class VsyncProviderImpl implements VsyncProvider {
    private static final String TAG = "VsyncProviderImpl";

    public VsyncProviderImpl() {
    }

    @Override
    public void close() {}

    @Override
    public void onConnectionError(MojoException e) {}

    @Override
    public void awaitVsync(final AwaitVsyncResponse callback) {
        Choreographer.getInstance().postFrameCallback(new Choreographer.FrameCallback() {
            @Override
            public void doFrame(long frameTimeNanos) {
                callback.call(frameTimeNanos);
            }
        });
    }
}
