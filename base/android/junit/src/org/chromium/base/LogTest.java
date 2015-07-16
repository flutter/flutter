// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

import org.chromium.testing.local.LocalRobolectricTestRunner;
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
    /** Test method for {@link Log#makeTag(String)} */
    @Test
    public void testMakeTag() {
        assertEquals("cr.Foo", Log.makeTag("Foo"));
        assertEquals("cr", Log.makeTag(null));
        assertEquals("cr", Log.makeTag(""));
    }

    /** Test method for {@link Log#makeTag(String)} */
    @Test(expected = IllegalArgumentException.class)
    public void testMakeTagFailure() {
        Log.makeTag("ThisIs21Char.....Long");
    }

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

    /** Needed to allow debug/verbose logging that is disabled by default. */
    @Implements(android.util.Log.class)
    public static class PermissiveShadowLog extends ShadowLog {
        @Implementation
        public static boolean isLoggable(String tag, int level) {
            return true;
        }
    }
}
