// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

import org.chromium.testing.local.LocalRobolectricTestRunner;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.annotation.Config;
import org.robolectric.annotation.Implementation;
import org.robolectric.annotation.Implements;
import org.robolectric.shadows.ShadowLog;

import java.util.List;

/** Unit tests for {@link Log}. */
@RunWith(LocalRobolectricTestRunner.class)
@Config(manifest = Config.NONE, shadows = {LogTest.PermissiveShadowLog.class})
public class LogTest {
    /** Tests that the computed call origin is the correct one. */
    @Test
    public void callOriginTest() {
        Log.d("Foo", "Bar");

        List<ShadowLog.LogItem> logs = ShadowLog.getLogs();
        assertEquals("Only one log should be written", 1, logs.size());

        assertTrue("The origin of the log message (" + logs.get(0).msg + ") looks wrong.",
                logs.get(0).msg.matches("\\[LogTest.java:\\d+\\].*"));
    }

    /** Tests that exceptions provided to the log functions are properly recognized and printed. */
    @Test
    public void exceptionLoggingTest() {
        Throwable t = new Throwable() {
            @Override
            public String toString() {
                return "MyThrowable";
            }
        };

        Throwable t2 = new Throwable() {
            @Override
            public String toString() {
                return "MyOtherThrowable";
            }
        };

        List<ShadowLog.LogItem> logs = ShadowLog.getLogs();

        // The throwable gets printed out
        Log.i("Foo", "Bar", t);
        assertEquals(t, logs.get(logs.size() - 1).throwable);
        assertEquals("Bar", logs.get(logs.size() - 1).msg);

        // The throwable can be both added to the message itself and printed out
        Log.i("Foo", "Bar %s", t);
        assertEquals(t, logs.get(logs.size() - 1).throwable);
        assertEquals("Bar MyThrowable", logs.get(logs.size() - 1).msg);

        // Non throwable are properly identified
        Log.i("Foo", "Bar %s", t, "Baz");
        assertNull(logs.get(logs.size() - 1).throwable);
        assertEquals("Bar MyThrowable", logs.get(logs.size() - 1).msg);

        // The last throwable is the one used that is going to be printed out
        Log.i("Foo", "Bar %s %s", t, t2);
        assertEquals(t2, logs.get(logs.size() - 1).throwable);
        assertEquals("Bar MyThrowable MyOtherThrowable", logs.get(logs.size() - 1).msg);
    }

    public void verboseLoggingTest() {
        PermissiveShadowLog.setLevel(Log.VERBOSE);
        List<ShadowLog.LogItem> logs = ShadowLog.getLogs();

        Log.wtf("Foo", "Bar");
        Log.e("Foo", "Bar");
        Log.w("Foo", "Bar");
        Log.i("Foo", "Bar");
        Log.d("Foo", "Bar");
        Log.v("Foo", "Bar");

        assertEquals(Log.ASSERT, logs.get(0).type);
        assertEquals(Log.ERROR, logs.get(1).type);
        assertEquals(Log.WARN, logs.get(2).type);
        assertEquals(Log.INFO, logs.get(3).type);
        assertEquals(Log.DEBUG, logs.get(4).type);
        assertEquals(Log.VERBOSE, logs.get(5).type);
        assertEquals(6, logs.size());
    }

    @Test
    public void debugLoggingTest() {
        PermissiveShadowLog.setLevel(Log.DEBUG);
        List<ShadowLog.LogItem> logs = ShadowLog.getLogs();

        Log.wtf("Foo", "Bar");
        Log.e("Foo", "Bar");
        Log.w("Foo", "Bar");
        Log.i("Foo", "Bar");
        Log.d("Foo", "Bar");
        Log.v("Foo", "Bar");

        assertEquals(Log.ASSERT, logs.get(0).type);
        assertEquals(Log.ERROR, logs.get(1).type);
        assertEquals(Log.WARN, logs.get(2).type);
        assertEquals(Log.INFO, logs.get(3).type);
        assertEquals(Log.DEBUG, logs.get(4).type);
        assertEquals(5, logs.size());
    }

    @Test
    public void infoLoggingTest() {
        PermissiveShadowLog.setLevel(Log.INFO);
        List<ShadowLog.LogItem> logs = ShadowLog.getLogs();

        Log.wtf("Foo", "Bar");
        Log.e("Foo", "Bar");
        Log.w("Foo", "Bar");
        Log.i("Foo", "Bar");
        Log.d("Foo", "Bar");
        Log.v("Foo", "Bar");

        assertEquals(Log.ASSERT, logs.get(0).type);
        assertEquals(Log.ERROR, logs.get(1).type);
        assertEquals(Log.WARN, logs.get(2).type);
        assertEquals(Log.INFO, logs.get(3).type);
        assertEquals(4, logs.size());
    }

    @Test
    public void warnLoggingTest() {
        PermissiveShadowLog.setLevel(Log.WARN);
        List<ShadowLog.LogItem> logs = ShadowLog.getLogs();

        Log.wtf("Foo", "Bar");
        Log.e("Foo", "Bar");
        Log.w("Foo", "Bar");
        Log.i("Foo", "Bar");
        Log.d("Foo", "Bar");
        Log.v("Foo", "Bar");

        assertEquals(Log.ASSERT, logs.get(0).type);
        assertEquals(Log.ERROR, logs.get(1).type);
        assertEquals(Log.WARN, logs.get(2).type);
        assertEquals(3, logs.size());
    }

    @Test
    public void errorLoggingTest() {
        PermissiveShadowLog.setLevel(Log.ERROR);
        List<ShadowLog.LogItem> logs = ShadowLog.getLogs();

        Log.wtf("Foo", "Bar");
        Log.e("Foo", "Bar");
        Log.w("Foo", "Bar");
        Log.i("Foo", "Bar");
        Log.d("Foo", "Bar");
        Log.v("Foo", "Bar");

        assertEquals(Log.ASSERT, logs.get(0).type);
        assertEquals(Log.ERROR, logs.get(1).type);
        assertEquals(2, logs.size());
    }

    @Test
    public void assertLoggingTest() {
        PermissiveShadowLog.setLevel(Log.ASSERT);
        List<ShadowLog.LogItem> logs = ShadowLog.getLogs();

        Log.wtf("Foo", "Bar");
        Log.e("Foo", "Bar");
        Log.w("Foo", "Bar");
        Log.i("Foo", "Bar");
        Log.d("Foo", "Bar");
        Log.v("Foo", "Bar");

        assertEquals(Log.ASSERT, logs.get(0).type);
        assertEquals(1, logs.size());
    }

    @Before
    public void beforeTest() {
        PermissiveShadowLog.reset();
    }

    /** Needed to allow debug/verbose logging that is disabled by default. */
    @Implements(android.util.Log.class)
    public static class PermissiveShadowLog extends ShadowLog {
        private static int sLevel = Log.VERBOSE;

        /** Sets the log level for all tags. */
        public static void setLevel(int level) {
            sLevel = level;
        }

        @Implementation
        public static boolean isLoggable(String tag, int level) {
            return level >= sLevel;
        }

        public static void reset() {
            sLevel = Log.VERBOSE;
        }
    }
}
