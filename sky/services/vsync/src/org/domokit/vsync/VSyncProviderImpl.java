// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.vsync;

import android.view.Choreographer;

import org.chromium.mojo.system.MessagePipeHandle;
import org.chromium.mojo.system.MojoException;
import org.chromium.mojom.vsync.VSyncProvider;

import java.util.ArrayList;

/**
 * Android implementation of VSyncProvider.
 */
public class VSyncProviderImpl implements VSyncProvider, Choreographer.FrameCallback {
    private Choreographer mChoreographer;
    private ArrayList<AwaitVSyncResponse> mCallbacks = new ArrayList<AwaitVSyncResponse>();
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
        mCallbacks.add(callback);
        if (mCallbacks.size() == 1) {
            mChoreographer.postFrameCallback(this);
        }
    }

    @Override
    public void doFrame(long frameTimeNanos) {
        long frameTimeMicros = frameTimeNanos / 1000;
        for (AwaitVSyncResponse callback : mCallbacks) {
            callback.call(frameTimeMicros);
        }
        mCallbacks.clear();
    }
}
