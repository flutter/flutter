// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.media;

import android.content.Context;

import org.chromium.mojo.bindings.InterfaceRequest;
import org.chromium.mojo.system.Core;
import org.chromium.mojo.system.MojoException;
import org.chromium.mojom.media.MediaPlayer;
import org.chromium.mojom.media.MediaService;
import org.chromium.mojom.media.SoundPool;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;


/**
 * Android implementation of MediaService.
 */
public class MediaServiceImpl implements MediaService {
    private final Core mCore;
    private final Context mContext;
    private static ExecutorService sThreadPool;

    public MediaServiceImpl(Context context, Core core) {
        assert context != null;
        mContext = context;
        assert core != null;
        mCore = core;

        if (sThreadPool == null) {
            sThreadPool = Executors.newCachedThreadPool();
        }
    }

    @Override
    public void close() {}

    @Override
    public void onConnectionError(MojoException e) {}

    @Override
    public void createPlayer(InterfaceRequest<MediaPlayer> player) {
        MediaPlayer.MANAGER.bind(new MediaPlayerImpl(mCore, mContext, sThreadPool), player);
    }

    @Override
    public void createSoundPool(InterfaceRequest<SoundPool> pool, int maxStreams) {
        SoundPool.MANAGER.bind(new SoundPoolImpl(mCore, mContext, sThreadPool, maxStreams), pool);
    }
}
