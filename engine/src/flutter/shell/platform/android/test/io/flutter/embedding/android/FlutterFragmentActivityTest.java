package io.flutter.embedding.android;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import android.content.Context;
import android.content.Intent;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.embedding.engine.loader.FlutterLoader;
import io.flutter.plugins.GeneratedPluginRegistrant;
import java.util.List;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class FlutterFragmentActivityTest {
  @Before
  public void setUp() {
    GeneratedPluginRegistrant.clearRegisteredEngines();
  }

  @After
  public void tearDown() {
    GeneratedPluginRegistrant.clearRegisteredEngines();
  }

  @Test
  public void createFlutterFragment__defaultRenderModeSurface() {
    final FlutterFragmentActivity activity = new FakeFlutterFragmentActivity();
    assertEquals(activity.createFlutterFragment().getRenderMode(), RenderMode.surface);
  }

  @Test
  public void createFlutterFragment__defaultRenderModeTexture() {
    final FlutterFragmentActivity activity =
        new FakeFlutterFragmentActivity() {
          @Override
          protected BackgroundMode getBackgroundMode() {
            return BackgroundMode.transparent;
          }
        };
    assertEquals(activity.createFlutterFragment().getRenderMode(), RenderMode.texture);
  }

  @Test
  public void createFlutterFragment__customRenderMode() {
    final FlutterFragmentActivity activity =
        new FakeFlutterFragmentActivity() {
          @Override
          protected RenderMode getRenderMode() {
            return RenderMode.texture;
          }
        };
    assertEquals(activity.createFlutterFragment().getRenderMode(), RenderMode.texture);
  }

  @Test
  public void itRegistersPluginsAtConfigurationTime() {
    FlutterFragmentActivity activity =
        Robolectric.buildActivity(FlutterFragmentActivityWithProvidedEngine.class).get();
    assertTrue(GeneratedPluginRegistrant.getRegisteredEngines().isEmpty());

    // Calling onCreate on the FlutterFragmentActivity will create a FlutterFragment and
    // commit it to the fragment manager. This attaches the fragment to the FlutterFragmentActivity
    // creating and configuring the engine.
    activity.onCreate(null);

    List<FlutterEngine> registeredEngines = GeneratedPluginRegistrant.getRegisteredEngines();
    assertEquals(1, registeredEngines.size());
    assertEquals(activity.getFlutterEngine(), registeredEngines.get(0));
  }

  static class FlutterFragmentActivityWithProvidedEngine extends FlutterFragmentActivity {
    @Override
    protected FlutterFragment createFlutterFragment() {
      return FlutterFragment.createDefault();
    }

    @Nullable
    @Override
    public FlutterEngine provideFlutterEngine(@NonNull Context context) {
      FlutterJNI flutterJNI = mock(FlutterJNI.class);
      when(flutterJNI.isAttached()).thenReturn(true);

      return new FlutterEngine(
          context, mock(FlutterLoader.class), flutterJNI, new String[] {}, false);
    }
  }

  private static class FakeFlutterFragmentActivity extends FlutterFragmentActivity {
    @Override
    public Intent getIntent() {
      return new Intent();
    }

    @Override
    public String getDartEntrypointFunctionName() {
      return "";
    }

    @Override
    protected String getInitialRoute() {
      return "";
    }

    @Override
    protected String getAppBundlePath() {
      return "";
    }
  }

  // This is just a compile time check to ensure that it's possible for FlutterFragmentActivity
  // subclasses
  // to provide their own intent builders which builds their own runtime types.
  private static class FlutterFragmentActivityWithIntentBuilders extends FlutterFragmentActivity {
    public static NewEngineIntentBuilder withNewEngine() {
      return new NewEngineIntentBuilder(FlutterFragmentActivityWithIntentBuilders.class);
    }

    public static CachedEngineIntentBuilder withCachedEngine(@NonNull String cachedEngineId) {
      return new CachedEngineIntentBuilder(
          FlutterFragmentActivityWithIntentBuilders.class, cachedEngineId);
    }
  }
}
