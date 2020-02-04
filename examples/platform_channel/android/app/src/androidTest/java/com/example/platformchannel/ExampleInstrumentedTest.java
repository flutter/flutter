package com.example.platformchannel;

import android.graphics.Bitmap;
import android.support.test.InstrumentationRegistry;
import android.support.test.rule.ActivityTestRule;
import android.support.test.runner.AndroidJUnit4;

import io.flutter.view.FlutterView;

import android.app.Instrumentation;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import org.junit.Rule;
import org.junit.Test;
import org.junit.runner.RunWith;

import static org.junit.Assert.*;

@RunWith(AndroidJUnit4.class)
public class ExampleInstrumentedTest {
    @Rule
    public ActivityTestRule<MainActivity> activityRule =
        new ActivityTestRule<>(MainActivity.class);


    @Test
    public void testBitmap() {
        final Instrumentation instr = InstrumentationRegistry.getInstrumentation();
        final BitmapPoller poller = new BitmapPoller(5);
        instr.runOnMainSync(new Runnable() {
            public void run() {
                final FlutterView flutterView = activityRule.getActivity().getFlutterView();

                // Call onPostResume to start the engine's renderer even if the activity
                // is paused in the test environment.
                flutterView.onPostResume();

                poller.start(flutterView);
            }
        });

        Bitmap bitmap = null;
        try {
            bitmap = poller.waitForBitmap();
        } catch (InterruptedException e) {
            fail(e.getMessage());
        }

        assertNotNull(bitmap);
        assertTrue(bitmap.getWidth() > 0);
        assertTrue(bitmap.getHeight() > 0);

        // Check that a pixel matches the default Material background color.
        assertTrue(bitmap.getPixel(bitmap.getWidth() - 1, bitmap.getHeight() - 1) == 0xFFFAFAFA);
    }

    // Waits on a FlutterView until it is able to produce a bitmap.
    private class BitmapPoller {
        private int triesPending;
        private int waitMsec;
        private FlutterView flutterView;
        private Bitmap bitmap;
        private CountDownLatch latch = new CountDownLatch(1);

        private final int delayMsec = 1000;

        BitmapPoller(int tries) {
            triesPending = tries;
            waitMsec = delayMsec * tries + 100;
        }

        void start(FlutterView flutterView) {
            this.flutterView = flutterView;
            flutterView.postDelayed(checkBitmap, delayMsec);
        }

        Bitmap waitForBitmap() throws InterruptedException {
            latch.await(waitMsec, TimeUnit.MILLISECONDS);
            return bitmap;
        }

        private Runnable checkBitmap = new Runnable() {
            public void run() {
                bitmap = flutterView.getBitmap();
                triesPending--;
                if (bitmap != null || triesPending == 0) {
                    latch.countDown();
                } else {
                    flutterView.postDelayed(checkBitmap, delayMsec);
                }
            }
        };
    }
}
