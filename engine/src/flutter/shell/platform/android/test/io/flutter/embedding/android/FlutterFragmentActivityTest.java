package io.flutter.embedding.android;

import static io.flutter.embedding.android.FlutterActivityLaunchConfigs.HANDLE_DEEPLINKING_META_DATA_KEY;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.when;

import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Bundle;
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

  @Test
  public void itReturnsValueFromMetaDataWhenCallsShouldHandleDeepLinkingCase1()
      throws PackageManager.NameNotFoundException {
    FlutterFragmentActivity activity =
        Robolectric.buildActivity(FlutterFragmentActivityWithProvidedEngine.class).get();
    assertTrue(GeneratedPluginRegistrant.getRegisteredEngines().isEmpty());
    Bundle bundle = new Bundle();
    bundle.putBoolean(HANDLE_DEEPLINKING_META_DATA_KEY, true);
    FlutterFragmentActivity spyFlutterActivity = spy(activity);
    when(spyFlutterActivity.getMetaData()).thenReturn(bundle);
    assertTrue(spyFlutterActivity.shouldHandleDeeplinking());
  }

  @Test
  public void itReturnsValueFromMetaDataWhenCallsShouldHandleDeepLinkingCase2()
      throws PackageManager.NameNotFoundException {
    FlutterFragmentActivity activity =
        Robolectric.buildActivity(FlutterFragmentActivityWithProvidedEngine.class).get();
    assertTrue(GeneratedPluginRegistrant.getRegisteredEngines().isEmpty());
    Bundle bundle = new Bundle();
    bundle.putBoolean(HANDLE_DEEPLINKING_META_DATA_KEY, false);
    FlutterFragmentActivity spyFlutterActivity = spy(activity);
    when(spyFlutterActivity.getMetaData()).thenReturn(bundle);
    assertFalse(spyFlutterActivity.shouldHandleDeeplinking());
  }

  @Test
  public void itReturnsValueFromMetaDataWhenCallsShouldHandleDeepLinkingCase3()
      throws PackageManager.NameNotFoundException {
    FlutterFragmentActivity activity =
        Robolectric.buildActivity(FlutterFragmentActivityWithProvidedEngine.class).get();
    assertTrue(GeneratedPluginRegistrant.getRegisteredEngines().isEmpty());
    // Creates an empty bundle.
    Bundle bundle = new Bundle();
    FlutterFragmentActivity spyFlutterActivity = spy(activity);
    when(spyFlutterActivity.getMetaData()).thenReturn(bundle);
    // Empty bundle should return false.
    assertFalse(spyFlutterActivity.shouldHandleDeeplinking());
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

    @Override
    protected boolean shouldHandleDeeplinking() {
      return false;
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
