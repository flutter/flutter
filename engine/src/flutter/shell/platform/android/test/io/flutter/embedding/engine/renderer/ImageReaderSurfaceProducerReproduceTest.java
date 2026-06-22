// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.renderer;

import static org.junit.Assert.assertNotNull;
import static org.mockito.Mockito.doAnswer;
import static org.robolectric.Shadows.shadowOf;

import android.annotation.TargetApi;
import android.graphics.Canvas;
import android.media.Image;
import android.os.Looper;
import android.view.Surface;
import androidx.test.ext.junit.rules.ActivityScenarioRule;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.Build.API_LEVELS;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.view.TextureRegistry;
import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.shadows.ShadowLog;

@RunWith(AndroidJUnit4.class)
@TargetApi(API_LEVELS.API_29)
public class ImageReaderSurfaceProducerReproduceTest {
  @Rule(order = 1)
  public final FlutterEngineRule engineRule = new FlutterEngineRule();

  @Rule(order = 2)
  public final ActivityScenarioRule<FlutterActivity> scenarioRule =
      new ActivityScenarioRule<>(engineRule.makeIntent());

  private FlutterJNI fakeJNI;

  @Before
  public void setup() {
    ShadowLog.stream = System.out;
    fakeJNI = engineRule.getFlutterJNI();

    // Configure the mock FlutterJNI to throw when scheduleFrame is called
    // while JNI is detached, mimicking the real behavior of FlutterJNI.scheduleFrame().
    doAnswer(
            invocation -> {
              if (!fakeJNI.isAttached()) {
                throw new RuntimeException("FlutterJNI is not attached to native.");
              }
              return null;
            })
        .when(fakeJNI)
        .scheduleFrame();
  }

  @Test
  public void testCrashWhenJniDetachedDuringImageAvailable() {
    FlutterRenderer flutterRenderer = engineRule.getFlutterEngine().getRenderer();
    TextureRegistry.SurfaceProducer producer = flutterRenderer.createSurfaceProducer();
    FlutterRenderer.ImageReaderSurfaceProducer texture =
        (FlutterRenderer.ImageReaderSurfaceProducer) producer;
    texture.disableFenceForTest();

    // Give the texture an initial size.
    texture.setSize(1, 1);

    // Render a frame.
    Surface surface = texture.getSurface();
    assertNotNull(surface);
    Canvas canvas = surface.lockHardwareCanvas();
    canvas.drawARGB(255, 255, 0, 0);
    surface.unlockCanvasAndPost(canvas);

    // Detach JNI before running the callback.
    engineRule.setJniIsAttached(false);

    // Let callbacks run. Since the background thread posts to the main looper asynchronously,
    // we poll and pump the main looper until the image is produced and queued (or until we crash).
    long startTime = System.currentTimeMillis();
    Image image = null;
    while (image == null && (System.currentTimeMillis() - startTime) < 5000) {
      shadowOf(Looper.getMainLooper()).idle();
      image = texture.acquireLatestImage();
      if (image == null) {
        try {
          Thread.sleep(10);
        } catch (InterruptedException e) {
          // Ignore.
        }
      }
    }

    if (image != null) {
      image.close();
    }

    // Cleanup.
    texture.release();
  }
}
