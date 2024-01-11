package io.flutter.embedding.engine.renderer;

import static org.junit.Assert.assertEquals;
import static org.mockito.Mockito.mock;
import static org.robolectric.Shadows.shadowOf;

import android.annotation.TargetApi;
import android.graphics.Canvas;
import android.os.Handler;
import android.os.Looper;
import android.view.Surface;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.embedding.engine.FlutterJNI;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.Test;
import org.junit.runner.RunWith;

@RunWith(AndroidJUnit4.class)
@TargetApi(26)
public final class SurfaceTextureSurfaceProducerTest {
  private final FlutterJNI fakeJNI = mock(FlutterJNI.class);

  @Test
  public void createsSurfaceTextureOfGivenSizeAndResizesWhenRequested() {
    // Create a surface and set the initial size.
    final Handler handler = new Handler(Looper.getMainLooper());
    final SurfaceTextureSurfaceProducer producer =
        new SurfaceTextureSurfaceProducer(0, handler, fakeJNI);
    final Surface surface = producer.getSurface();
    AtomicInteger frames = new AtomicInteger();
    producer
        .getSurfaceTexture()
        .setOnFrameAvailableListener(
            (texture) -> {
              if (texture.isReleased()) {
                return;
              }
              frames.getAndIncrement();
            });
    producer.setSize(100, 200);

    // Draw.
    Canvas canvas = surface.lockHardwareCanvas();
    canvas.drawARGB(255, 255, 0, 0);
    surface.unlockCanvasAndPost(canvas);
    shadowOf(Looper.getMainLooper()).idle();
    assertEquals(frames.get(), 1);

    // Resize and redraw.
    producer.setSize(400, 800);
    canvas = surface.lockHardwareCanvas();
    canvas.drawARGB(255, 255, 0, 0);
    surface.unlockCanvasAndPost(canvas);
    shadowOf(Looper.getMainLooper()).idle();
    assertEquals(frames.get(), 2);

    // Done.
    fakeJNI.detachFromNativeAndReleaseResources();
    producer.release();
  }
}
