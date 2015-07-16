// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo;

import android.content.Context;
import android.test.InstrumentationTestCase;

import org.chromium.base.JNINamespace;
import org.chromium.base.library_loader.LibraryLoader;
import org.chromium.base.library_loader.LibraryProcessType;

/**
 * Base class to test mojo. Setup the environment.
 */
@JNINamespace("mojo::android")
public class MojoTestCase extends InstrumentationTestCase {

    private long mTestEnvironmentPointer;

    /**
     * @see junit.framework.TestCase#setUp()
     */
    @Override
    protected void setUp() throws Exception {
        super.setUp();
        LibraryLoader.get(LibraryProcessType.PROCESS_BROWSER).ensureInitialized();
        nativeInitApplicationContext(getInstrumentation().getTargetContext());
        mTestEnvironmentPointer = nativeSetupTestEnvironment();
    }

    /**
     * @see android.test.InstrumentationTestCase#tearDown()
     */
    @Override
    protected void tearDown() throws Exception {
        nativeTearDownTestEnvironment(mTestEnvironmentPointer);
        super.tearDown();
    }

    /**
     * Runs the run loop for the given time.
     */
    protected void runLoop(long timeoutMS) {
        nativeRunLoop(timeoutMS);
    }

    /**
     * Runs the run loop until no handle or task are immediately available.
     */
    protected void runLoopUntilIdle() {
        nativeRunLoop(0);
    }

    private native void nativeInitApplicationContext(Context context);

    private native long nativeSetupTestEnvironment();

    private native void nativeTearDownTestEnvironment(long testEnvironment);

    private native void nativeRunLoop(long timeoutMS);

}
