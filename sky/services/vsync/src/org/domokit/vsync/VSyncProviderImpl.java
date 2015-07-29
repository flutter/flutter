// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.vsync;

import android.view.Choreographer;

import org.chromium.mojo.system.MessagePipeHandle;
import org.chromium.mojo.system.MojoException;
import org.chromium.mojom.vsync.VSyncProvider;

/**
 * Android implementation of VSyncProvider.
 */
public class VSyncProviderImpl implements VSyncProvider, Choreographer.FrameCallback {
    private Choreographer mChoreographer;
    private AwaitVSyncResponse mCallback;
    private MessagePipeHandle mPipe;

    public VSyncProviderImpl(MessagePipeHandle pipe) {
        mPipe = pipe;
        mChoreographer = Choreographer.getInstance();
    }

    @Override
    public void close() {}

    @Override
    public void onConnectionError(MojoException e) {}

    @Override
    public void awaitVSync(final AwaitVSyncResponse callback) {
        if (mCallback != null) {
            mPipe.close();
            return;
        }
        mCallback = callback;
        mChoreographer.postFrameCallback(this);
    }

    @Override
    public void doFrame(long frameTimeNanos) {
        mCallback.call(frameTimeNanos / 1000);
        mCallback = null;
    }
}
