// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.media;

import android.content.Context;
import android.media.AudioManager;
import android.util.Log;

import org.chromium.mojo.common.DataPipeUtils;
import org.chromium.mojo.system.Core;
import org.chromium.mojo.system.DataPipe;
import org.chromium.mojo.system.MojoException;
import org.chromium.mojom.media.SoundPool;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.concurrent.Executor;

/**
 * Mojo service providing access to SoundPool.
 */
public class SoundPoolImpl implements SoundPool, android.media.SoundPool.OnLoadCompleteListener {
    private static final String TAG = "SoundPoolImpl";
    private final Core mCore;
    private final Context mContext;
    private final Executor mExecutor;
    private final android.media.SoundPool mSoundPool;
    private final ArrayList<File> mTempFiles;
    private final HashMap<Integer, LoadResponse> mPendingLoads;

    public SoundPoolImpl(Core core, Context context, Executor executor, int maxStreams) {
        mCore = core;
        mContext = context;
        mExecutor = executor;
        mTempFiles = new ArrayList<File>();
        mPendingLoads = new HashMap<Integer, LoadResponse>();

        android.media.SoundPool.Builder builder = new android.media.SoundPool.Builder();
        builder.setMaxStreams(maxStreams);
        mSoundPool = builder.build();
        mSoundPool.setOnLoadCompleteListener(this);
    }

    @Override
    public void close() {
        if (mSoundPool != null) {
            mSoundPool.release();
        }
        for (File tempFile : mTempFiles) {
            tempFile.delete();
        }
    }

    @Override
    public void onConnectionError(MojoException e) {
    }

    @Override
    public void load(DataPipe.ConsumerHandle consumerHandle, final LoadResponse callback) {
        File file;
        try {
            file = File.createTempFile("sky_sound_pool", "temp", mContext.getCacheDir());
        } catch (IOException e) {
            Log.e(TAG, "Failed to create temporary file", e);
            callback.call(false, 0);
            return;
        }
        final File tempFile = file;

        mTempFiles.add(tempFile);

        DataPipeUtils.copyToFile(mCore, consumerHandle, tempFile, mExecutor, new Runnable() {
            @Override
            public void run() {
                String path;
                try {
                    path = tempFile.getCanonicalPath();
                } catch (IOException e) {
                    callback.call(false, 0);
                    return;
                }
                int soundId = mSoundPool.load(path, 1);
                mPendingLoads.put(soundId, callback);
            }
        });
    }

    @Override
    public void onLoadComplete(android.media.SoundPool soundPool, int soundId, int status) {
        LoadResponse callback = mPendingLoads.remove(soundId);
        if (callback != null) {
            callback.call(true, soundId);
        }
    }

    @Override
    public void play(int soundId, float leftVolume, float rightVolume, boolean loop, float rate,
                     PlayResponse callback) {
        int streamId = mSoundPool.play(soundId, leftVolume, rightVolume, 0, loop ? -1 : 0, rate);
        callback.call(streamId != 0, streamId);
    }

    @Override
    public void stop(int streamId) {
        mSoundPool.stop(streamId);
    }

    @Override
    public void pause(int streamId) {
        mSoundPool.pause(streamId);
    }

    @Override
    public void resume(int streamId) {
        mSoundPool.resume(streamId);
    }    

    @Override
    public void setRate(int streamId, float rate) {
        mSoundPool.setRate(streamId, rate);
    }

    @Override
    public void setVolume(int streamId, float leftVolume, float rightVolume) {
        mSoundPool.setVolume(streamId, leftVolume, rightVolume);
    }

    @Override
    public void pauseAll() {
        mSoundPool.autoPause();
    }

    @Override
    public void resumeAll() {
        mSoundPool.autoResume();
    }
}
