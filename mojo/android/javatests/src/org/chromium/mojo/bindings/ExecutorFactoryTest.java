// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.bindings;

import android.test.suitebuilder.annotation.SmallTest;

import org.chromium.mojo.MojoTestCase;
import org.chromium.mojo.system.impl.CoreImpl;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.BrokenBarrierException;
import java.util.concurrent.CyclicBarrier;
import java.util.concurrent.Executor;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * Testing the executor factory.
 */
public class ExecutorFactoryTest extends MojoTestCase {

    private static final long RUN_LOOP_TIMEOUT_MS = 50;
    private static final int CONCURRENCY_LEVEL = 5;
    private static final ExecutorService WORKERS = Executors.newFixedThreadPool(CONCURRENCY_LEVEL);

    private Executor mExecutor;
    private List<Thread> mThreadContainer;

    /**
     * @see MojoTestCase#setUp()
     */
    @Override
    protected void setUp() throws Exception {
        super.setUp();
        mExecutor = ExecutorFactory.getExecutorForCurrentThread(CoreImpl.getInstance());
        mThreadContainer = new ArrayList<Thread>();
    }

    /**
     * Testing the {@link Executor} when called from the executor thread.
     */
    @SmallTest
    public void testExecutorOnCurrentThread() {
        Runnable action = new Runnable() {
            @Override
            public void run() {
                mThreadContainer.add(Thread.currentThread());
            }
        };
        mExecutor.execute(action);
        mExecutor.execute(action);
        assertEquals(0, mThreadContainer.size());
        runLoop(RUN_LOOP_TIMEOUT_MS);
        assertEquals(2, mThreadContainer.size());
        for (Thread thread : mThreadContainer) {
            assertEquals(Thread.currentThread(), thread);
        }
    }

    /**
     * Testing the {@link Executor} when called from another thread.
     */
    @SmallTest
    public void testExecutorOnOtherThread() {
        final CyclicBarrier barrier = new CyclicBarrier(CONCURRENCY_LEVEL + 1);
        for (int i = 0; i < CONCURRENCY_LEVEL; ++i) {
            WORKERS.execute(new Runnable() {
                @Override
                public void run() {
                    mExecutor.execute(new Runnable() {

                        @Override
                        public void run() {
                            mThreadContainer.add(Thread.currentThread());
                        }
                    });
                    try {
                        barrier.await();
                    } catch (InterruptedException e) {
                        fail("Unexpected exception: " + e.getMessage());
                    } catch (BrokenBarrierException e) {
                        fail("Unexpected exception: " + e.getMessage());
                    }
                }
            });
        }
        try {
            barrier.await();
        } catch (InterruptedException e) {
            fail("Unexpected exception: " + e.getMessage());
        } catch (BrokenBarrierException e) {
            fail("Unexpected exception: " + e.getMessage());
        }
        assertEquals(0, mThreadContainer.size());
        runLoop(RUN_LOOP_TIMEOUT_MS);
        assertEquals(CONCURRENCY_LEVEL, mThreadContainer.size());
        for (Thread thread : mThreadContainer) {
            assertEquals(Thread.currentThread(), thread);
        }
    }
}
