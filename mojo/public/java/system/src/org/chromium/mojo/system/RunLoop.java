// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.system;

import java.io.Closeable;

/**
 * Definition of a run loop.
 */
public interface RunLoop extends Closeable {
    /**
     * Start the run loop. It will continue until quit() is called.
     */
    public void run();

    /**
     * Start the run loop and stop it as soon as no task is present in the work queue.
     */
    public void runUntilIdle();

    /*
     * Quit the currently running run loop.
     */
    public void quit();

    /**
     * Add a runnable to the queue of tasks.
     * @param runnable Callback to be executed by the run loop.
     * @param delay Delay, in MojoTimeTicks (microseconds) before the callback should
     * be executed.
     */
    public void postDelayedTask(Runnable runnable, long delay);

    /**
     * Destroy the run loop and deregister it from Core.
     */
    @Override
    public abstract void close();
}
