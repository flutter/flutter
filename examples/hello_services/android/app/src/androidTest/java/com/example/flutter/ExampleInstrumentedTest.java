package com.example.flutter;

import android.app.Instrumentation;
import android.graphics.Bitmap;
import android.support.test.InstrumentationRegistry;
import android.support.test.rule.ActivityTestRule;
import android.support.test.runner.AndroidJUnit4;

import org.junit.Rule;
import org.junit.Test;
import org.junit.runner.RunWith;

import java.util.Arrays;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

import io.flutter.plugin.common.FlutterMethodChannel;
import io.flutter.view.FlutterView;

import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;

@RunWith(AndroidJUnit4.class)
public class ExampleInstrumentedTest {
    @Rule
    public ActivityTestRule<ExampleActivity> activityRule =
            new ActivityTestRule<>(ExampleActivity.class);

    @Test
    public void testFlutterMessage() {
        final Instrumentation instr = InstrumentationRegistry.getInstrumentation();

        final int RANDOM_MIN = 1;
        final int RANDOM_MAX = 1000;

        final CountDownLatch latch = new CountDownLatch(1);
        final AtomicInteger random = new AtomicInteger();

        instr.runOnMainSync(new Runnable() {
            public void run() {
                final FlutterView flutterView = (FlutterView) activityRule.getActivity().findViewById(
                        R.id.flutter_view);
                final FlutterMethodChannel randomChannel = new FlutterMethodChannel(flutterView, "random");
                randomChannel.invokeMethod("getRandom", Arrays.asList(RANDOM_MIN, RANDOM_MAX), new FlutterMethodChannel.Response() {
                    @Override
                    public void success(Object o) {
                        random.set(((Number) o).intValue());
                        latch.countDown();
                    }

                    @Override
                    public void error(String code, String message, Object details) {

                    }
                });
            }
        });

        try {
            assertTrue(latch.await(2, TimeUnit.SECONDS));
        } catch (InterruptedException e) {
            fail(e.getMessage());
        }
        assertTrue(random.get() >= RANDOM_MIN);
        assertTrue(random.get() < RANDOM_MAX);
    }

    @Test
    public void testBitmap() {
        final Instrumentation instr = InstrumentationRegistry.getInstrumentation();
        final BitmapPoller poller = new BitmapPoller(5);
        instr.runOnMainSync(new Runnable() {
            public void run() {
                final FlutterView flutterView = (FlutterView) activityRule.getActivity().findViewById(
                        R.id.flutter_view);

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
        private final int delayMsec = 1000;
        private int triesPending;
        private int waitMsec;
        private FlutterView flutterView;
        private Bitmap bitmap;
        private CountDownLatch latch = new CountDownLatch(1);
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
    }
}
