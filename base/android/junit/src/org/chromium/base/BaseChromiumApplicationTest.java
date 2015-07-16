// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

import android.app.Activity;
import android.view.KeyEvent;

import junit.framework.Assert;

import org.chromium.base.BaseChromiumApplication.WindowFocusChangedListener;
import org.chromium.testing.local.LocalRobolectricTestRunner;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.annotation.Config;
import org.robolectric.annotation.Implementation;
import org.robolectric.annotation.Implements;
import org.robolectric.shadows.ShadowActivity;
import org.robolectric.util.ActivityController;

/** Unit tests for {@link BaseChromiumApplication}. */
@RunWith(LocalRobolectricTestRunner.class)
@Config(manifest = Config.NONE, application = BaseChromiumApplication.class,
        shadows = {BaseChromiumApplicationTest.TrackingShadowActivity.class})
public class BaseChromiumApplicationTest {

    @Implements(Activity.class)
    public static class TrackingShadowActivity extends ShadowActivity {
        private int mWindowFocusCalls;
        private int mDispatchKeyEventCalls;
        private boolean mReturnValueForKeyDispatch;

        @Implementation
        public void onWindowFocusChanged(@SuppressWarnings("unused") boolean hasFocus) {
            mWindowFocusCalls++;
        }

        @Implementation
        public boolean dispatchKeyEvent(@SuppressWarnings("unused") KeyEvent event) {
            mDispatchKeyEventCalls++;
            return mReturnValueForKeyDispatch;
        }
    }

    @Test
    public void testWindowsFocusChanged() throws Exception {
        BaseChromiumApplication app = (BaseChromiumApplication) Robolectric.application;

        WindowFocusChangedListener mock = mock(WindowFocusChangedListener.class);
        app.registerWindowFocusChangedListener(mock);

        ActivityController<Activity> controller =
                Robolectric.buildActivity(Activity.class).create().start().visible();
        TrackingShadowActivity shadow =
                (TrackingShadowActivity) Robolectric.shadowOf(controller.get());

        controller.get().getWindow().getCallback().onWindowFocusChanged(true);
        // Assert that listeners were notified.
        verify(mock).onWindowFocusChanged(controller.get(), true);
        // Also ensure that the original activity is forwarded the notification.
        Assert.assertEquals(1, shadow.mWindowFocusCalls);
    }

    @Test
    public void testDispatchKeyEvent() throws Exception {
        ActivityController<Activity> controller =
                Robolectric.buildActivity(Activity.class).create().start().visible();
        TrackingShadowActivity shadow =
                (TrackingShadowActivity) Robolectric.shadowOf(controller.get());

        final KeyEvent menuKey = new KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_MENU);

        // Ensure that key events are forwarded.
        Assert.assertFalse(controller.get().getWindow().getCallback().dispatchKeyEvent(menuKey));
        // This gets called twice - once to see if the activity is swallowing it, and again to
        // dispatch it.
        Assert.assertEquals(2, shadow.mDispatchKeyEventCalls);

        // Ensure that our activity can swallow the event.
        shadow.mReturnValueForKeyDispatch = true;
        Assert.assertTrue(controller.get().getWindow().getCallback().dispatchKeyEvent(menuKey));
        Assert.assertEquals(3, shadow.mDispatchKeyEventCalls);

        // A non-enter key only dispatches once.
        Assert.assertTrue(controller.get().getWindow().getCallback().dispatchKeyEvent(
                new KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_SPACE)));
        Assert.assertEquals(4, shadow.mDispatchKeyEventCalls);
    }
}
