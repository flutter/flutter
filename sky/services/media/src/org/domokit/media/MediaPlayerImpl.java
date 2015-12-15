// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.media;

import android.content.Context;
import android.util.Log;

import org.chromium.mojo.common.DataPipeUtils;
import org.chromium.mojo.system.Core;
import org.chromium.mojo.system.DataPipe;
import org.chromium.mojo.system.MojoException;
import org.chromium.mojom.media.MediaPlayer;

import java.io.File;
import java.io.IOException;
import java.util.concurrent.Executor;

/**
 * Android implementation of MediaPlayer.
 */
public class MediaPlayerImpl implements MediaPlayer, android.media.MediaPlayer.OnPreparedListener {
    private static final String TAG = "MediaPlayerImpl";
    private final Core mCore;
    private final Context mContext;
    private final Executor mExecutor;
    private final android.media.MediaPlayer mPlayer;
    private PrepareResponse mPrepareResponse;
    private File mTempFile;

    public MediaPlayerImpl(Core core, Context context, Executor executor) {
        mCore = core;
        mContext = context;
        mExecutor = executor;
        mPlayer = new android.media.MediaPlayer();
        mTempFile = null;
        mPrepareResponse = null;
    }

    @Override
    public void close() {
        mPlayer.release();
        if (mTempFile != null) {
            mTempFile.delete();
        }
    }

    @Override
    public void onConnectionError(MojoException e) {
    }

    @Override
    public void onPrepared(android.media.MediaPlayer mp) {
        assert mPlayer == mp;
        assert mPrepareResponse != null;
        // ignored argument due to https://github.com/domokit/mojo/issues/282
        boolean ignored = true;
        mPrepareResponse.call(ignored);
    }

    public void copyComplete() {
        try {
            mPlayer.setOnPreparedListener(this);
            mPlayer.setDataSource(mTempFile.getCanonicalPath());
            mPlayer.prepare();
        } catch (java.io.IOException e) {
            Log.e(TAG, "Exception", e);
            mPrepareResponse.call(false);
            mPrepareResponse = null;
        }
    }

    @Override
    public void prepare(DataPipe.ConsumerHandle consumerHandle, PrepareResponse callback) {
        // TODO(eseidel): Ideally we'll find a way to hand the data straight
        // to Android's audio system w/o first having to dump it to a file.
        File outputDir = mContext.getCacheDir();
        mPrepareResponse = callback;
        try {
            mTempFile = File.createTempFile("sky_media_player", "temp", outputDir);
        } catch (IOException e) {
            Log.e(TAG, "Failed to create temporary file", e);
            callback.call(false);
            return; // TODO(eseidel): We should close the pipe?
        }

        DataPipeUtils.copyToFile(mCore, consumerHandle, mTempFile, mExecutor, new Runnable() {
            @Override
            public void run() {
                copyComplete();
            }
        });
    }

    @Override
    public void start() {
        mPlayer.start();
    }

    @Override
    public void seekTo(int msec) {
        mPlayer.seekTo(msec);
    }

    @Override
    public void pause() {
        mPlayer.pause();
    }

    @Override
    public void setLooping(boolean looping) {
        mPlayer.setLooping(looping);
    }

    @Override
    public void setVolume(float volume) {
        mPlayer.setVolume(volume, volume);
    }
}
