// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.common;

import org.chromium.mojo.system.Core;
import org.chromium.mojo.system.DataPipe;
import org.chromium.mojo.system.MojoException;
import org.chromium.mojo.system.MojoResult;
import org.chromium.mojo.system.RunLoop;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;
import java.util.concurrent.Executor;

/**
 * Helper class for copyToFile.
 */
class CopyToFileJob implements Runnable {
    private final DataPipe.ConsumerHandle mSource;
    private final File mDest;
    private final Runnable mComplete;
    private final RunLoop mCaller;
    private final Core mCore;

    public CopyToFileJob(Core core, DataPipe.ConsumerHandle handle, File file, Runnable complete,
            RunLoop caller) {
        mCore = core;
        mSource = handle;
        mDest = file;
        mComplete = complete;
        mCaller = caller;
    }

    private void readLoop(FileChannel dest) throws IOException {
        do {
            try {
                ByteBuffer buffer = mSource.beginReadData(0, DataPipe.ReadFlags.NONE);
                if (buffer.capacity() == 0) break;
                dest.write(buffer);
                mSource.endReadData(buffer.capacity());
            } catch (MojoException e) {
                // No one read the pipe, they just closed it.
                if (e.getMojoResult() == MojoResult.FAILED_PRECONDITION) {
                    break;
                } else if (e.getMojoResult() == MojoResult.SHOULD_WAIT) {
                    mCore.wait(mSource, Core.HandleSignals.READABLE, -1);
                } else {
                    throw e;
                }
            }
        } while (true);
    }

    @Override
    public void run() {
        try (DataPipe.ConsumerHandle source = mSource;
                FileOutputStream stream = new FileOutputStream(mDest, false);
                FileChannel dest = stream.getChannel()) {
            readLoop(dest);
        } catch (java.io.IOException e) {
            throw new MojoException(e);
        }

        mCaller.postDelayedTask(mComplete, 0L);
    }
}

/**
 * Java helpers for dealing with DataPipes.
 */
public class DataPipeUtils {
    public static void copyToFile(Core core, DataPipe.ConsumerHandle source, File dest,
            Executor executor, Runnable complete) {
        executor.execute(new CopyToFileJob(core, source, dest, complete, core.getCurrentRunLoop()));
    }
}
