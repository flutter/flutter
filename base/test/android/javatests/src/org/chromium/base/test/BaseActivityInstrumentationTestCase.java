// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base.test;

import android.app.Activity;
import android.content.Context;
import android.os.SystemClock;
import android.test.ActivityInstrumentationTestCase2;
import android.util.Log;

import org.chromium.base.BaseChromiumApplication;
import org.chromium.base.CommandLine;
import org.chromium.base.test.util.CommandLineFlags;

import java.lang.reflect.AnnotatedElement;
import java.lang.reflect.Method;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Base class for all Activity-based Instrumentation tests.
 *
 * @param <T> The Activity type.
 */
public class BaseActivityInstrumentationTestCase<T extends Activity>
        extends ActivityInstrumentationTestCase2<T> {

    private static final String TAG = "BaseActivityInstrumentationTestCase";

    private static final int SLEEP_INTERVAL = 50; // milliseconds
    private static final int WAIT_DURATION = 5000; // milliseconds

    /**
     * Creates a instance for running tests against an Activity of the given class.
     *
     * @param activityClass The type of activity that will be tested.
     */
    public BaseActivityInstrumentationTestCase(Class<T> activityClass) {
        super(activityClass);
    }

    /**
     * Sets up the CommandLine with the appropriate flags.
     *
     * This will add the difference of the sets of flags specified by {@link CommandLineFlags.Add}
     * and {@link CommandLineFlags.Remove} to the {@link org.chromium.base.CommandLine}. Note that
     * trying to remove a flag set externally, i.e. by the command-line flags file, will not work.
     */
    @Override
    protected void setUp() throws Exception {
        super.setUp();

        CommandLine.reset();
        Context targetContext = getTargetContext();
        assertNotNull("Unable to get a non-null target context.", targetContext);

        BaseChromiumApplication.initCommandLine(targetContext);
        Set<String> flags = getFlags(getClass().getMethod(getName()));
        for (String flag : flags) {
            CommandLine.getInstance().appendSwitch(flag);
        }
    }

    /**
     * Gets the target context.
     *
     * On older versions of Android, getTargetContext() may initially return null, so we have to
     * wait for it to become available.
     *
     * @return The target {@link android.content.Context} if available; null otherwise.
     */
    private Context getTargetContext() {
        Context targetContext = getInstrumentation().getTargetContext();
        try {
            long startTime = SystemClock.uptimeMillis();
            // TODO(jbudorick): Convert this to CriteriaHelper once that moves to base/.
            while (targetContext == null
                    && SystemClock.uptimeMillis() - startTime < WAIT_DURATION) {
                Thread.sleep(SLEEP_INTERVAL);
                targetContext = getInstrumentation().getTargetContext();
            }
        } catch (InterruptedException e) {
            Log.e(TAG, "Interrupted while attempting to initialize the command line.");
        }
        return targetContext;
    }

    private static Set<String> getFlags(AnnotatedElement element) {
        AnnotatedElement parent = (element instanceof Method)
                ? ((Method) element).getDeclaringClass()
                : ((Class) element).getSuperclass();
        Set<String> flags = (parent == null) ? new HashSet<String>() : getFlags(parent);

        if (element.isAnnotationPresent(CommandLineFlags.Add.class)) {
            flags.addAll(
                    Arrays.asList(element.getAnnotation(CommandLineFlags.Add.class).value()));
        }

        if (element.isAnnotationPresent(CommandLineFlags.Remove.class)) {
            List<String> flagsToRemove =
                    Arrays.asList(element.getAnnotation(CommandLineFlags.Remove.class).value());
            for (String flagToRemove : flagsToRemove) {
                // If your test fails here, you have tried to remove a command-line flag via
                // CommandLineFlags.Remove that was loaded into CommandLine via something other
                // than CommandLineFlags.Add (probably the command-line flag file).
                assertFalse("Unable to remove command-line flag \"" + flagToRemove + "\".",
                        CommandLine.getInstance().hasSwitch(flagToRemove));
            }
            flags.removeAll(flagsToRemove);
        }

        return flags;
    }
}
