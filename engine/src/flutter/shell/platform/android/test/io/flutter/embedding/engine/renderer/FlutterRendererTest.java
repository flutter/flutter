package io.flutter.embedding.engine.renderer;

import static android.content.ComponentCallbacks2.TRIM_MEMORY_COMPLETE;
import static org.junit.Assert.assertArrayEquals;
import static org.junit.Assert.assertEquals;
import static org.mockito.ArgumentMatchers.anyFloat;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.robolectric.Shadows.shadowOf;

import android.graphics.Rect;
import android.graphics.SurfaceTexture;
import android.os.Looper;
import android.view.Surface;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.view.TextureRegistry;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(AndroidJUnit4.class)
public class FlutterRendererTest {

  private FlutterJNI fakeFlutterJNI;
  private Surface fakeSurface;
  private Surface fakeSurface2;

  @Before
  public void setup() {
    fakeFlutterJNI = mock(FlutterJNI.class);
    fakeSurface = mock(Surface.class);
    fakeSurface2 = mock(Surface.class);
  }

  @Test
  public void itForwardsSurfaceCreationNotificationToFlutterJNI() {
    // Setup the test.
    Surface fakeSurface = mock(Surface.class);
    FlutterRenderer flutterRenderer = new FlutterRenderer(fakeFlutterJNI);

    // Execute the behavior under test.
    flutterRenderer.startRenderingToSurface(fakeSurface, false);

    // Verify the behavior under test.
    verify(fakeFlutterJNI, times(1)).onSurfaceCreated(eq(fakeSurface));
  }

  @Test
  public void itForwardsSurfaceChangeNotificationToFlutterJNI() {
    // Setup the test.
    Surface fakeSurface = mock(Surface.class);
    FlutterRenderer flutterRenderer = new FlutterRenderer(fakeFlutterJNI);

    flutterRenderer.startRenderingToSurface(fakeSurface, false);

    // Execute the behavior under test.
    flutterRenderer.surfaceChanged(100, 50);

    // Verify the behavior under test.
    verify(fakeFlutterJNI, times(1)).onSurfaceChanged(eq(100), eq(50));
  }

  @Test
  public void itForwardsSurfaceDestructionNotificationToFlutterJNI() {
    // Setup the test.
    Surface fakeSurface = mock(Surface.class);
    FlutterRenderer flutterRenderer = new FlutterRenderer(fakeFlutterJNI);

    flutterRenderer.startRenderingToSurface(fakeSurface, false);

    // Execute the behavior under test.
    flutterRenderer.stopRenderingToSurface();

    // Verify the behavior under test.
    verify(fakeFlutterJNI, times(1)).onSurfaceDestroyed();
  }

  @Test
  public void itStopsRenderingToOneSurfaceBeforeRenderingToANewSurface() {
    // Setup the test.
    Surface fakeSurface2 = mock(Surface.class);
    FlutterRenderer flutterRenderer = new FlutterRenderer(fakeFlutterJNI);

    flutterRenderer.startRenderingToSurface(fakeSurface, false);

    // Execute behavior under test.
    flutterRenderer.startRenderingToSurface(fakeSurface2, false);

    // Verify behavior under test.
    verify(fakeFlutterJNI, times(1)).onSurfaceDestroyed(); // notification of 1st surface's removal.
  }

  @Test
  public void itStopsRenderingToSurfaceWhenRequested() {
    // Setup the test.
    FlutterRenderer flutterRenderer = new FlutterRenderer(fakeFlutterJNI);

    flutterRenderer.startRenderingToSurface(fakeSurface, false);

    // Execute the behavior under test.
    flutterRenderer.stopRenderingToSurface();

    // Verify behavior under test.
    verify(fakeFlutterJNI, times(1)).onSurfaceDestroyed();
  }

  @Test
  public void iStopsRenderingToSurfaceWhenSurfaceAlreadySet() {
    // Setup the test.
    FlutterRenderer flutterRenderer = new FlutterRenderer(fakeFlutterJNI);

    flutterRenderer.startRenderingToSurface(fakeSurface, false);

    flutterRenderer.startRenderingToSurface(fakeSurface, false);

    // Verify behavior under test.
    verify(fakeFlutterJNI, times(1)).onSurfaceDestroyed();
  }

  @Test
  public void itNeverStopsRenderingToSurfaceWhenRequested() {
    // Setup the test.
    FlutterRenderer flutterRenderer = new FlutterRenderer(fakeFlutterJNI);

    flutterRenderer.startRenderingToSurface(fakeSurface, false);

    flutterRenderer.startRenderingToSurface(fakeSurface, true);

    // Verify behavior under test.
    verify(fakeFlutterJNI, never()).onSurfaceDestroyed();
  }

  @Test
  public void itStopsSurfaceTextureCallbackWhenDetached() {
    // Setup the test.
    FlutterRenderer flutterRenderer = new FlutterRenderer(fakeFlutterJNI);

    fakeFlutterJNI.detachFromNativeAndReleaseResources();

    FlutterRenderer.SurfaceTextureRegistryEntry entry =
        (FlutterRenderer.SurfaceTextureRegistryEntry) flutterRenderer.createSurfaceTexture();

    flutterRenderer.startRenderingToSurface(fakeSurface, false);

    // Execute the behavior under test.
    flutterRenderer.stopRenderingToSurface();

    // Verify behavior under test.
    verify(fakeFlutterJNI, times(0)).markTextureFrameAvailable(eq(entry.id()));
  }

  @Test
  public void itRegistersExistingSurfaceTexture() {
    // Setup the test.
    FlutterRenderer flutterRenderer = new FlutterRenderer(fakeFlutterJNI);

    fakeFlutterJNI.detachFromNativeAndReleaseResources();

    SurfaceTexture surfaceTexture = new SurfaceTexture(0);

    // Execute the behavior under test.
    FlutterRenderer.SurfaceTextureRegistryEntry entry =
        (FlutterRenderer.SurfaceTextureRegistryEntry)
            flutterRenderer.registerSurfaceTexture(surfaceTexture);

    flutterRenderer.startRenderingToSurface(fakeSurface, false);

    // Verify behavior under test.
    assertEquals(surfaceTexture, entry.surfaceTexture());

    verify(fakeFlutterJNI, times(1)).registerTexture(eq(entry.id()), eq(entry.textureWrapper()));
  }

  @Test
  public void itUnregistersTextureWhenSurfaceTextureFinalized() {
    // Setup the test.
    FlutterJNI fakeFlutterJNI = mock(FlutterJNI.class);
    when(fakeFlutterJNI.isAttached()).thenReturn(true);
    FlutterRenderer flutterRenderer = new FlutterRenderer(fakeFlutterJNI);

    fakeFlutterJNI.detachFromNativeAndReleaseResources();

    FlutterRenderer.SurfaceTextureRegistryEntry entry =
        (FlutterRenderer.SurfaceTextureRegistryEntry) flutterRenderer.createSurfaceTexture();
    long id = entry.id();

    flutterRenderer.startRenderingToSurface(fakeSurface, false);

    // Execute the behavior under test.
    runFinalization(entry);

    shadowOf(Looper.getMainLooper()).idle();

    flutterRenderer.stopRenderingToSurface();

    // Verify behavior under test.
    verify(fakeFlutterJNI, times(1)).unregisterTexture(eq(id));
  }

  @Test
  public void itStopsUnregisteringTextureWhenDetached() {
    // Setup the test.
    FlutterJNI fakeFlutterJNI = mock(FlutterJNI.class);
    when(fakeFlutterJNI.isAttached()).thenReturn(false);
    FlutterRenderer flutterRenderer = new FlutterRenderer(fakeFlutterJNI);

    fakeFlutterJNI.detachFromNativeAndReleaseResources();

    FlutterRenderer.SurfaceTextureRegistryEntry entry =
        (FlutterRenderer.SurfaceTextureRegistryEntry) flutterRenderer.createSurfaceTexture();
    long id = entry.id();

    flutterRenderer.startRenderingToSurface(fakeSurface, false);

    flutterRenderer.stopRenderingToSurface();

    // Execute the behavior under test.
    runFinalization(entry);

    shadowOf(Looper.getMainLooper()).idle();

    // Verify behavior under test.
    verify(fakeFlutterJNI, times(0)).unregisterTexture(eq(id));
  }

  void runFinalization(FlutterRenderer.SurfaceTextureRegistryEntry entry) {
    CountDownLatch latch = new CountDownLatch(1);
    Thread fakeFinalizer =
        new Thread(
            new Runnable() {
              public void run() {
                try {
                  entry.finalize();
                  latch.countDown();
                } catch (Throwable e) {
                  // do nothing
                }
              }
            });
    fakeFinalizer.start();
    try {
      latch.await(5L, TimeUnit.SECONDS);
    } catch (Throwable e) {
      // do nothing
    }
  }

  @Test
  public void itConvertsDisplayFeatureArrayToPrimitiveArrays() {
    // Setup the test.
    FlutterRenderer flutterRenderer = new FlutterRenderer(fakeFlutterJNI);
    FlutterRenderer.ViewportMetrics metrics = new FlutterRenderer.ViewportMetrics();
    metrics.width = 1000;
    metrics.height = 1000;
    metrics.devicePixelRatio = 2;
    metrics.displayFeatures.add(
        new FlutterRenderer.DisplayFeature(
            new Rect(10, 20, 30, 40),
            FlutterRenderer.DisplayFeatureType.FOLD,
            FlutterRenderer.DisplayFeatureState.POSTURE_HALF_OPENED));
    metrics.displayFeatures.add(
        new FlutterRenderer.DisplayFeature(
            new Rect(50, 60, 70, 80), FlutterRenderer.DisplayFeatureType.CUTOUT));

    // Execute the behavior under test.
    flutterRenderer.setViewportMetrics(metrics);

    // Verify behavior under test.
    ArgumentCaptor<int[]> boundsCaptor = ArgumentCaptor.forClass(int[].class);
    ArgumentCaptor<int[]> typeCaptor = ArgumentCaptor.forClass(int[].class);
    ArgumentCaptor<int[]> stateCaptor = ArgumentCaptor.forClass(int[].class);
    verify(fakeFlutterJNI)
        .setViewportMetrics(
            anyFloat(),
            anyInt(),
            anyInt(),
            anyInt(),
            anyInt(),
            anyInt(),
            anyInt(),
            anyInt(),
            anyInt(),
            anyInt(),
            anyInt(),
            anyInt(),
            anyInt(),
            anyInt(),
            anyInt(),
            anyInt(),
            boundsCaptor.capture(),
            typeCaptor.capture(),
            stateCaptor.capture());

    assertArrayEquals(new int[] {10, 20, 30, 40, 50, 60, 70, 80}, boundsCaptor.getValue());
    assertArrayEquals(
        new int[] {
          FlutterRenderer.DisplayFeatureType.FOLD.encodedValue,
          FlutterRenderer.DisplayFeatureType.CUTOUT.encodedValue
        },
        typeCaptor.getValue());
    assertArrayEquals(
        new int[] {
          FlutterRenderer.DisplayFeatureState.POSTURE_HALF_OPENED.encodedValue,
          FlutterRenderer.DisplayFeatureState.UNKNOWN.encodedValue
        },
        stateCaptor.getValue());
  }

  @Test
  public void itNotifyImageFrameListener() {
    // Setup the test.
    FlutterRenderer flutterRenderer = new FlutterRenderer(fakeFlutterJNI);

    AtomicInteger invocationCount = new AtomicInteger(0);
    final TextureRegistry.OnFrameConsumedListener listener =
        new TextureRegistry.OnFrameConsumedListener() {
          @Override
          public void onFrameConsumed() {
            invocationCount.incrementAndGet();
          }
        };

    FlutterRenderer.SurfaceTextureRegistryEntry entry =
        (FlutterRenderer.SurfaceTextureRegistryEntry) flutterRenderer.createSurfaceTexture();
    entry.setOnFrameConsumedListener(listener);

    // Execute the behavior under test.
    entry.textureWrapper().updateTexImage();

    // Verify behavior under test.
    assertEquals(1, invocationCount.get());
  }

  @Test
  public void itAddsListenerWhenSurfaceTextureEntryCreated() {
    // Setup the test.
    FlutterRenderer flutterRenderer = spy(new FlutterRenderer(fakeFlutterJNI));

    // Execute the behavior under test.
    FlutterRenderer.SurfaceTextureRegistryEntry entry =
        (FlutterRenderer.SurfaceTextureRegistryEntry) flutterRenderer.createSurfaceTexture();

    // Verify behavior under test.
    verify(flutterRenderer, times(1)).addOnTrimMemoryListener(entry);
  }

  @Test
  public void itRemovesListenerWhenSurfaceTextureEntryReleased() {
    // Setup the test.
    FlutterRenderer flutterRenderer = spy(new FlutterRenderer(fakeFlutterJNI));
    FlutterRenderer.SurfaceTextureRegistryEntry entry =
        (FlutterRenderer.SurfaceTextureRegistryEntry) flutterRenderer.createSurfaceTexture();

    // Execute the behavior under test.
    entry.release();

    // Verify behavior under test.
    verify(flutterRenderer, times(1)).removeOnTrimMemoryListener(entry);
  }

  @Test
  public void itNotifySurfaceTextureEntryWhenMemoryPressureWarning() {
    // Setup the test.
    FlutterRenderer flutterRenderer = new FlutterRenderer(fakeFlutterJNI);

    AtomicInteger invocationCount = new AtomicInteger(0);
    final TextureRegistry.OnTrimMemoryListener listener =
        new TextureRegistry.OnTrimMemoryListener() {
          @Override
          public void onTrimMemory(int level) {
            invocationCount.incrementAndGet();
          }
        };

    FlutterRenderer.SurfaceTextureRegistryEntry entry =
        (FlutterRenderer.SurfaceTextureRegistryEntry) flutterRenderer.createSurfaceTexture();
    entry.setOnTrimMemoryListener(listener);

    // Execute the behavior under test.
    flutterRenderer.onTrimMemory(TRIM_MEMORY_COMPLETE);

    // Verify behavior under test.
    assertEquals(1, invocationCount.get());
  }

  @Test
  public void itDoesDispatchSurfaceDestructionNotificationOnlyOnce() {
    // Setup the test.
    FlutterRenderer flutterRenderer = new FlutterRenderer(fakeFlutterJNI);

    flutterRenderer.startRenderingToSurface(fakeSurface, false);

    // Execute the behavior under test.
    // Simulate calling |FlutterRenderer#stopRenderingToSurface| twice with different code paths.
    flutterRenderer.stopRenderingToSurface();
    flutterRenderer.stopRenderingToSurface();

    // Verify behavior under test.
    verify(fakeFlutterJNI, times(1)).onSurfaceDestroyed();
  }

  @Test
  public void itInvokesCreatesSurfaceWhenStartingRendering() {
    FlutterRenderer flutterRenderer = new FlutterRenderer(fakeFlutterJNI);

    flutterRenderer.startRenderingToSurface(fakeSurface, false);
    verify(fakeFlutterJNI, times(1)).onSurfaceCreated(eq(fakeSurface));
  }

  @Test
  public void itDoesNotInvokeCreatesSurfaceWhenResumingRendering() {
    FlutterRenderer flutterRenderer = new FlutterRenderer(fakeFlutterJNI);

    // The following call sequence mimics the behaviour of FlutterView when it exits from hybrid
    // composition mode.

    // Install initial rendering surface.
    flutterRenderer.startRenderingToSurface(fakeSurface, false);
    verify(fakeFlutterJNI, times(1)).onSurfaceCreated(eq(fakeSurface));
    verify(fakeFlutterJNI, times(0)).onSurfaceWindowChanged(eq(fakeSurface));

    // Install the image view.
    flutterRenderer.startRenderingToSurface(fakeSurface2, true);
    verify(fakeFlutterJNI, times(1)).onSurfaceCreated(eq(fakeSurface));
    verify(fakeFlutterJNI, times(0)).onSurfaceWindowChanged(eq(fakeSurface));
    verify(fakeFlutterJNI, times(0)).onSurfaceCreated(eq(fakeSurface2));
    verify(fakeFlutterJNI, times(1)).onSurfaceWindowChanged(eq(fakeSurface2));

    flutterRenderer.startRenderingToSurface(fakeSurface, true);
    verify(fakeFlutterJNI, times(1)).onSurfaceCreated(eq(fakeSurface));
    verify(fakeFlutterJNI, times(1)).onSurfaceWindowChanged(eq(fakeSurface));
    verify(fakeFlutterJNI, times(0)).onSurfaceCreated(eq(fakeSurface2));
    verify(fakeFlutterJNI, times(1)).onSurfaceWindowChanged(eq(fakeSurface2));
  }
}
