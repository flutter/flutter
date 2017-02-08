package com.example.flutter;

import android.graphics.Bitmap;
import android.support.test.InstrumentationRegistry;
import android.support.test.rule.ActivityTestRule;
import android.support.test.runner.AndroidJUnit4;

import io.flutter.view.FlutterView;

import android.app.Instrumentation;
import android.support.test.InstrumentationRegistry;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import org.json.JSONException;
import org.json.JSONObject;
import org.junit.Rule;
import org.junit.Test;
import org.junit.runner.RunWith;

import static org.junit.Assert.*;

@RunWith(AndroidJUnit4.class)
public class ExampleInstrumentedTest {
    @Rule
    public ActivityTestRule<ExampleActivity> activityRule =
        new ActivityTestRule<>(ExampleActivity.class);

    @Test
    public void testFlutterMessage() {
        final Instrumentation instr = InstrumentationRegistry.getInstrumentation();

        final JSONObject message = new JSONObject();
        final int RANDOM_MIN = 1;
        final int RANDOM_MAX = 1000;
        try {
            message.put("min", RANDOM_MIN);
            message.put("max", RANDOM_MAX);
        } catch (JSONException e) {
            fail(e.getMessage());
        }

        final CountDownLatch latch = new CountDownLatch(1);
        final AtomicInteger random = new AtomicInteger();

        instr.runOnMainSync(new Runnable() {
            public void run() {
                final FlutterView flutterView = (FlutterView) activityRule.getActivity().findViewById(
                    R.id.flutter_view);
                flutterView.sendToFlutter("getRandom", message.toString(), new FlutterView.MessageReplyCallback() {
                    public void onReply(String json) {
                        try {
                            JSONObject reply = new JSONObject(json);
                            random.set(reply.getInt("value"));
                        } catch (JSONException e) {
                            fail(e.getMessage());
                        } finally {
                            latch.countDown();
                        }
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
