package io.flutter.embedding.engine;

import static org.junit.Assert.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

import io.flutter.embedding.engine.renderer.FlutterUiDisplayListener;
import io.flutter.plugin.platform.PlatformViewsController;
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

  @Test
  public void onDisplayPlatformView__callsPlatformViewsController() {
    PlatformViewsController platformViewsController = mock(PlatformViewsController.class);

    FlutterJNI flutterJNI = new FlutterJNI();
    flutterJNI.setPlatformViewsController(platformViewsController);

    // --- Execute Test ---
    flutterJNI.onDisplayPlatformView(
        /*viewId=*/ 1, /*x=*/ 10, /*y=*/ 20, /*width=*/ 100, /*height=*/ 200);

    // --- Verify Results ---
    verify(platformViewsController, times(1))
        .onDisplayPlatformView(
            /*viewId=*/ 1, /*x=*/ 10, /*y=*/ 20, /*width=*/ 100, /*height=*/ 200);
  }

  @Test
  public void onDisplayOverlaySurface__callsPlatformViewsController() {
    PlatformViewsController platformViewsController = mock(PlatformViewsController.class);

    FlutterJNI flutterJNI = new FlutterJNI();
    flutterJNI.setPlatformViewsController(platformViewsController);

    // --- Execute Test ---
    flutterJNI.onDisplayOverlaySurface(
        /*id=*/ 1, /*x=*/ 10, /*y=*/ 20, /*width=*/ 100, /*height=*/ 200);

    // --- Verify Results ---
    verify(platformViewsController, times(1))
        .onDisplayOverlaySurface(/*id=*/ 1, /*x=*/ 10, /*y=*/ 20, /*width=*/ 100, /*height=*/ 200);
  }

  @Test
  public void onBeginFrame__callsPlatformViewsController() {
    PlatformViewsController platformViewsController = mock(PlatformViewsController.class);

    // --- Test Setup ---
    FlutterJNI flutterJNI = new FlutterJNI();
    flutterJNI.setPlatformViewsController(platformViewsController);

    // --- Execute Test ---
    flutterJNI.onBeginFrame();

    // --- Verify Results ---
    verify(platformViewsController, times(1)).onBeginFrame();
  }
}
