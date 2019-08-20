package io.flutter.embedding.android;

import android.content.Intent;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.android.controller.ActivityController;
import org.robolectric.annotation.Config;

import static org.junit.Assert.assertArrayEquals;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

@Config(manifest=Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class FlutterActivityTest {
  @Test
  public void itCreatesDefaultIntentWithExpectedDefaults() {
    Intent intent = FlutterActivity.createDefaultIntent(RuntimeEnvironment.application);
    ActivityController<FlutterActivity> activityController = Robolectric.buildActivity(FlutterActivity.class, intent);
    FlutterActivity flutterActivity = activityController.get();

    assertEquals("main", flutterActivity.getDartEntrypointFunctionName());
    assertEquals("/", flutterActivity.getInitialRoute());
    assertArrayEquals(new String[]{}, flutterActivity.getFlutterShellArgs().toArray());
    assertTrue(flutterActivity.shouldAttachEngineToActivity());
    assertNull(flutterActivity.getCachedEngineId());
    assertTrue(flutterActivity.shouldDestroyEngineWithHost());
    assertEquals(FlutterActivity.BackgroundMode.opaque, flutterActivity.getBackgroundMode());
    assertEquals(FlutterView.RenderMode.surface, flutterActivity.getRenderMode());
    assertEquals(FlutterView.TransparencyMode.opaque, flutterActivity.getTransparencyMode());
  }

  @Test
  public void itCreatesNewEngineIntentWithRequestedSettings() {
    Intent intent = FlutterActivity.withNewEngine()
        .initialRoute("/custom/route")
        .backgroundMode(FlutterActivity.BackgroundMode.transparent)
        .build(RuntimeEnvironment.application);
    ActivityController<FlutterActivity> activityController = Robolectric.buildActivity(FlutterActivity.class, intent);
    FlutterActivity flutterActivity = activityController.get();

    assertEquals("/custom/route", flutterActivity.getInitialRoute());
    assertArrayEquals(new String[]{}, flutterActivity.getFlutterShellArgs().toArray());
    assertTrue(flutterActivity.shouldAttachEngineToActivity());
    assertNull(flutterActivity.getCachedEngineId());
    assertTrue(flutterActivity.shouldDestroyEngineWithHost());
    assertEquals(FlutterActivity.BackgroundMode.transparent, flutterActivity.getBackgroundMode());
    assertEquals(FlutterView.RenderMode.texture, flutterActivity.getRenderMode());
    assertEquals(FlutterView.TransparencyMode.transparent, flutterActivity.getTransparencyMode());
  }

  @Test
  public void itCreatesCachedEngineIntentThatDoesNotDestroyTheEngine() {
    Intent intent = FlutterActivity.withCachedEngine("my_cached_engine")
        .destroyEngineWithActivity(false)
        .build(RuntimeEnvironment.application);
    ActivityController<FlutterActivity> activityController = Robolectric.buildActivity(FlutterActivity.class, intent);
    FlutterActivity flutterActivity = activityController.get();

    assertArrayEquals(new String[]{}, flutterActivity.getFlutterShellArgs().toArray());
    assertTrue(flutterActivity.shouldAttachEngineToActivity());
    assertEquals("my_cached_engine", flutterActivity.getCachedEngineId());
    assertFalse(flutterActivity.shouldDestroyEngineWithHost());
  }

  @Test
  public void itCreatesCachedEngineIntentThatDestroysTheEngine() {
    Intent intent = FlutterActivity.withCachedEngine("my_cached_engine")
        .destroyEngineWithActivity(true)
        .build(RuntimeEnvironment.application);
    ActivityController<FlutterActivity> activityController = Robolectric.buildActivity(FlutterActivity.class, intent);
    FlutterActivity flutterActivity = activityController.get();

    assertArrayEquals(new String[]{}, flutterActivity.getFlutterShellArgs().toArray());
    assertTrue(flutterActivity.shouldAttachEngineToActivity());
    assertEquals("my_cached_engine", flutterActivity.getCachedEngineId());
    assertTrue(flutterActivity.shouldDestroyEngineWithHost());
  }
}
