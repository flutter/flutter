package io.flutter.embedding.engine;

import static org.junit.Assert.assertEquals;

import io.flutter.embedding.engine.renderer.FlutterUiDisplayListener;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class FlutterJNITest {
  @Test
  public void itAllowsFirstFrameListenersToRemoveThemselvesInline() {
    // --- Test Setup ---
    FlutterJNI flutterJNI = new FlutterJNI();

    AtomicInteger callbackInvocationCount = new AtomicInteger(0);
    FlutterUiDisplayListener callback =
        new FlutterUiDisplayListener() {
          @Override
          public void onFlutterUiDisplayed() {
            callbackInvocationCount.incrementAndGet();
            flutterJNI.removeIsDisplayingFlutterUiListener(this);
          }

          @Override
          public void onFlutterUiNoLongerDisplayed() {}
        };
    flutterJNI.addIsDisplayingFlutterUiListener(callback);

    // --- Execute Test ---
    flutterJNI.onFirstFrame();

    // --- Verify Results ---
    assertEquals(1, callbackInvocationCount.get());

    // --- Execute Test ---
    // The callback removed itself from the listener list. A second call doesn't call the callback.
    flutterJNI.onFirstFrame();

    // --- Verify Results ---
    assertEquals(1, callbackInvocationCount.get());
  }
}
