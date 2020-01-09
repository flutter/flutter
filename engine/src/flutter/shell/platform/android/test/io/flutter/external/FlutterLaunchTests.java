package io.flutter.external;

import android.content.Intent;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode;
import io.flutter.embedding.android.FlutterView;
import io.flutter.embedding.android.RobolectricFlutterActivity;

import static org.junit.Assert.assertArrayEquals;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

@Config(manifest=Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class FlutterLaunchTests {
  @Test
  public void launchFlutterActivity_with_defaultIntent_expect_defaultConfiguration() {
    Intent intent = FlutterActivity.createDefaultIntent(RuntimeEnvironment.application);
    FlutterActivity flutterActivity = RobolectricFlutterActivity.createFlutterActivity(intent);

    assertEquals("main", flutterActivity.getDartEntrypointFunctionName());
    assertEquals("/", flutterActivity.getInitialRoute());
    assertArrayEquals(new String[]{}, flutterActivity.getFlutterShellArgs().toArray());
    assertTrue(flutterActivity.shouldAttachEngineToActivity());
    assertNull(flutterActivity.getCachedEngineId());
    assertTrue(flutterActivity.shouldDestroyEngineWithHost());
    assertEquals(BackgroundMode.opaque, RobolectricFlutterActivity.getBackgroundMode(flutterActivity));
    assertEquals(FlutterView.RenderMode.surface, flutterActivity.getRenderMode());
    assertEquals(FlutterView.TransparencyMode.opaque, flutterActivity.getTransparencyMode());
  }
}
