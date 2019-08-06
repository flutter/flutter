package io.flutter.embedding.android;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

import static org.junit.Assert.assertArrayEquals;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

@Config(manifest=Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class FlutterFragmentTest {
  @Test
  public void itCreatesDefaultFragmentWithExpectedDefaults() {
    FlutterFragment fragment = FlutterFragment.createDefault();

    assertEquals("main", fragment.getDartEntrypointFunctionName());
    assertEquals("/", fragment.getInitialRoute());
    assertArrayEquals(new String[]{}, fragment.getFlutterShellArgs().toArray());
    assertTrue(fragment.shouldAttachEngineToActivity());
    assertNull(fragment.getCachedEngineId());
    assertTrue(fragment.shouldDestroyEngineWithHost());
    assertEquals(FlutterView.RenderMode.surface, fragment.getRenderMode());
    assertEquals(FlutterView.TransparencyMode.transparent, fragment.getTransparencyMode());
  }

  @Test
  public void itCreatesNewEngineFragmentWithRequestedSettings() {
    FlutterFragment fragment = FlutterFragment.withNewEngine()
        .dartEntrypoint("custom_entrypoint")
        .initialRoute("/custom/route")
        .shouldAttachEngineToActivity(false)
        .renderMode(FlutterView.RenderMode.texture)
        .transparencyMode(FlutterView.TransparencyMode.opaque)
        .build();

    assertEquals("custom_entrypoint", fragment.getDartEntrypointFunctionName());
    assertEquals("/custom/route", fragment.getInitialRoute());
    assertArrayEquals(new String[]{}, fragment.getFlutterShellArgs().toArray());
    assertFalse(fragment.shouldAttachEngineToActivity());
    assertNull(fragment.getCachedEngineId());
    assertTrue(fragment.shouldDestroyEngineWithHost());
    assertEquals(FlutterView.RenderMode.texture, fragment.getRenderMode());
    assertEquals(FlutterView.TransparencyMode.opaque, fragment.getTransparencyMode());
  }

  @Test
  public void itCreatesCachedEngineFragmentThatDoesNotDestroyTheEngine() {
    FlutterFragment fragment = FlutterFragment
        .withCachedEngine("my_cached_engine")
        .build();

    assertTrue(fragment.shouldAttachEngineToActivity());
    assertEquals("my_cached_engine", fragment.getCachedEngineId());
    assertFalse(fragment.shouldDestroyEngineWithHost());
  }

  @Test
  public void itCreatesCachedEngineFragmentThatDestroysTheEngine() {
    FlutterFragment fragment = FlutterFragment
        .withCachedEngine("my_cached_engine")
        .destroyEngineWithFragment(true)
        .build();

    assertTrue(fragment.shouldAttachEngineToActivity());
    assertEquals("my_cached_engine", fragment.getCachedEngineId());
    assertTrue(fragment.shouldDestroyEngineWithHost());
  }
}
