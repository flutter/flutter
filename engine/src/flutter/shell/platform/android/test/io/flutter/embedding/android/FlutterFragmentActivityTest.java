package io.flutter.embedding.android;

import static io.flutter.embedding.android.FlutterActivityLaunchConfigs.HANDLE_DEEPLINKING_META_DATA_KEY;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.when;
import static org.robolectric.Shadows.shadowOf;

import android.annotation.TargetApi;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.test.core.app.ActivityScenario;
import androidx.test.core.app.ApplicationProvider;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.FlutterInjector;
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
import org.robolectric.android.controller.ActivityController;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(AndroidJUnit4.class)
public class FlutterFragmentActivityTest {
  private final Context ctx = ApplicationProvider.getApplicationContext();

  @Before
  public void setUp() {
    FlutterInjector.reset();
    GeneratedPluginRegistrant.clearRegisteredEngines();
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    when(mockFlutterJNI.isAttached()).thenReturn(true);
    FlutterJNI.Factory mockFlutterJNIFactory = mock(FlutterJNI.Factory.class);
    when(mockFlutterJNIFactory.provideFlutterJNI()).thenReturn(mockFlutterJNI);
    FlutterInjector.setInstance(
        new FlutterInjector.Builder().setFlutterJNIFactory(mockFlutterJNIFactory).build());
  }

  @After
  public void tearDown() {
    GeneratedPluginRegistrant.clearRegisteredEngines();
    FlutterInjector.reset();
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
  public void createFlutterFragment__customDartEntrypointLibraryUri() {
    final FlutterFragmentActivity activity =
        new FakeFlutterFragmentActivity() {
          @Override
          public String getDartEntrypointLibraryUri() {
            return "package:foo/bar.dart";
          }
        };
    assertEquals(
        activity.createFlutterFragment().getDartEntrypointLibraryUri(), "package:foo/bar.dart");
  }

  @Test
  public void hasRootLayoutId() {
    FlutterFragmentActivityWithRootLayout activity =
        Robolectric.buildActivity(FlutterFragmentActivityWithRootLayout.class).get();
    activity.onCreate(null);
    assertNotNull(activity.FRAGMENT_CONTAINER_ID);
    assertTrue(activity.FRAGMENT_CONTAINER_ID != View.NO_ID);
  }

  @Test
  public void itRegistersPluginsAtConfigurationTime() {
    try (ActivityScenario<FlutterFragmentActivity> scenario =
        ActivityScenario.launch(FlutterFragmentActivity.class)) {
      scenario.onActivity(
          activity -> {
            List<FlutterEngine> registeredEngines =
                GeneratedPluginRegistrant.getRegisteredEngines();
            assertEquals(1, registeredEngines.size());
            assertEquals(activity.getFlutterEngine(), registeredEngines.get(0));
          });
    }
  }

  @Test
  public void itDoesNotRegisterPluginsTwiceWhenUsingACachedEngine() {
    try (ActivityScenario<FlutterFragmentActivity> scenario =
        ActivityScenario.launch(FlutterFragmentActivity.class)) {
      scenario.onActivity(
          activity -> {
            List<FlutterEngine> registeredEngines =
                GeneratedPluginRegistrant.getRegisteredEngines();
            assertEquals(1, registeredEngines.size());
            assertEquals(activity.getFlutterEngine(), registeredEngines.get(0));
          });
    }

    List<FlutterEngine> registeredEngines = GeneratedPluginRegistrant.getRegisteredEngines();
    // This might cause the plugins to be registered twice, once by the FlutterEngine constructor,
    // and once by the default FlutterFragmentActivity.configureFlutterEngine implementation.
    // Test that it doesn't happen.
    assertEquals(1, registeredEngines.size());
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

  @Test
  public void itAllowsRootLayoutOverride() {
    FlutterFragmentActivityWithRootLayout activity =
        Robolectric.buildActivity(FlutterFragmentActivityWithRootLayout.class).get();

    activity.onCreate(null);
    ViewGroup contentView = (ViewGroup) activity.findViewById(android.R.id.content);
    boolean foundCustomView = false;
    for (int i = 0; i < contentView.getChildCount(); i++) {
      foundCustomView =
          contentView.getChildAt(i) instanceof FlutterFragmentActivityWithRootLayout.CustomLayout;
      if (foundCustomView) {
        break;
      }
    }
    assertTrue(foundCustomView);
  }

  @Test
  public void itCreatesAValidFlutterFragment() {
    try (ActivityScenario<FlutterFragmentActivityWithProvidedEngine> scenario =
        ActivityScenario.launch(FlutterFragmentActivityWithProvidedEngine.class)) {
      scenario.onActivity(
          activity -> {
            assertNotNull(activity.getFlutterEngine());
            assertEquals(1, activity.numberOfEnginesCreated);
          });
    }
  }

  @Test
  public void itRetrievesExistingFlutterFragmentWhenRecreated() {
    FlutterFragmentActivityWithProvidedEngine activity =
        spy(Robolectric.buildActivity(FlutterFragmentActivityWithProvidedEngine.class).get());

    FlutterFragment fragment = mock(FlutterFragment.class);
    when(activity.retrieveExistingFlutterFragmentIfPossible()).thenReturn(fragment);

    FlutterEngine engine = mock(FlutterEngine.class);
    when(fragment.getFlutterEngine()).thenReturn(engine);

    activity.onCreate(null);
    assertEquals(engine, activity.getFlutterEngine());
    assertEquals(0, activity.numberOfEnginesCreated);
  }

  @Test
  public void itHandlesNewFragmentRecreationDuringRestoreWhenActivityIsRecreated() {
    FlutterFragmentActivityWithProvidedEngine activity =
        spy(Robolectric.buildActivity(FlutterFragmentActivityWithProvidedEngine.class).get());

    FlutterFragment fragment = mock(FlutterFragment.class);
    // Similar to the above case, except here, it's not just the activity that was destroyed and
    // could have its fragment restored in the fragment manager. Here, both activity and fragment
    // are destroyed. And the fragment manager recreated the fragment on activity recreate.
    when(activity.retrieveExistingFlutterFragmentIfPossible()).thenReturn(null, fragment);

    FlutterEngine engine = mock(FlutterEngine.class);
    when(fragment.getFlutterEngine()).thenReturn(engine);

    activity.onCreate(null);
    // The framework would have recreated a new fragment but the fragment activity wouldn't have
    // created a new one again.
    assertEquals(0, activity.numberOfEnginesCreated);
  }

  @Test
  public void itDoesNotCrashWhenSplashScreenMetadataIsNotDefined() {
    Intent intent = FlutterFragmentActivity.createDefaultIntent(ctx);
    ActivityController<FlutterFragmentActivity> activityController =
        Robolectric.buildActivity(FlutterFragmentActivity.class, intent);
    FlutterFragmentActivity fragmentActivity = activityController.get();

    // We never supplied the resource key to robolectric so it doesn't exist.
    SplashScreen splashScreen = fragmentActivity.provideSplashScreen();
    // It should quietly return a null and not crash.
    assertNull(splashScreen);
  }

  @Test
  @Config(
      sdk = Build.VERSION_CODES.KITKAT,
      shadows = {SplashShadowResources.class})
  public void itLoadsSplashScreenDrawable() throws PackageManager.NameNotFoundException {
    Intent intent = FlutterFragmentActivity.createDefaultIntent(ctx);
    ActivityController<FlutterFragmentActivity> activityController =
        Robolectric.buildActivity(FlutterFragmentActivity.class, intent);
    FlutterFragmentActivity activity = activityController.get();

    // Inject splash screen drawable resource id in the metadata
    PackageManager pm = ctx.getPackageManager();
    ActivityInfo activityInfo =
        pm.getActivityInfo(activity.getComponentName(), PackageManager.GET_META_DATA);
    activityInfo.metaData = new Bundle();
    activityInfo.metaData.putInt(
        FlutterActivityLaunchConfigs.SPLASH_SCREEN_META_DATA_KEY,
        SplashShadowResources.SPLASH_DRAWABLE_ID);
    shadowOf(ctx.getPackageManager()).addOrUpdateActivity(activityInfo);

    // It should load the drawable.
    SplashScreen splashScreen = activity.provideSplashScreen();
    assertNotNull(splashScreen);
  }

  @Test
  @Config(
      sdk = Build.VERSION_CODES.LOLLIPOP,
      shadows = {SplashShadowResources.class})
  @TargetApi(21) // Theme references in drawables requires API 21+
  public void itLoadsThemedSplashScreenDrawable() throws PackageManager.NameNotFoundException {
    // A drawable with theme references can be parsed only if the app theme is supplied
    // in getDrawable methods. This test verifies it by fetching a (fake) themed drawable.
    // On failure, a Resource.NotFoundException will ocurr.
    Intent intent = FlutterFragmentActivity.createDefaultIntent(ctx);
    ActivityController<FlutterFragmentActivity> activityController =
        Robolectric.buildActivity(FlutterFragmentActivity.class, intent);
    FlutterFragmentActivity activity = activityController.get();

    // Inject themed splash screen drawable resource id in the metadata.
    PackageManager pm = ctx.getPackageManager();
    ActivityInfo activityInfo =
        pm.getActivityInfo(activity.getComponentName(), PackageManager.GET_META_DATA);
    activityInfo.metaData = new Bundle();
    activityInfo.metaData.putInt(
        FlutterActivityLaunchConfigs.SPLASH_SCREEN_META_DATA_KEY,
        SplashShadowResources.THEMED_SPLASH_DRAWABLE_ID);
    shadowOf(ctx.getPackageManager()).addOrUpdateActivity(activityInfo);

    // It should load the drawable.
    SplashScreen splashScreen = activity.provideSplashScreen();
    assertNotNull(splashScreen);
  }

  @Test
  public void itWithMetadataWithoutSplashScreenResourceKeyDoesNotProvideSplashScreen()
      throws PackageManager.NameNotFoundException {
    Intent intent = FlutterFragmentActivity.createDefaultIntent(ctx);
    ActivityController<FlutterFragmentActivity> activityController =
        Robolectric.buildActivity(FlutterFragmentActivity.class, intent);
    FlutterFragmentActivity activity = activityController.get();

    // Setup an empty metadata file.
    PackageManager pm = ctx.getPackageManager();
    ActivityInfo activityInfo =
        pm.getActivityInfo(activity.getComponentName(), PackageManager.GET_META_DATA);
    activityInfo.metaData = new Bundle();
    shadowOf(ctx.getPackageManager()).addOrUpdateActivity(activityInfo);

    // It should not load the drawable.
    SplashScreen splashScreen = activity.provideSplashScreen();
    assertNull(splashScreen);
  }

  static class FlutterFragmentActivityWithProvidedEngine extends FlutterFragmentActivity {
    int numberOfEnginesCreated = 0;

    @Override
    protected FlutterFragment createFlutterFragment() {
      return FlutterFragment.createDefault();
    }

    @Nullable
    @Override
    public FlutterEngine provideFlutterEngine(@NonNull Context context) {
      FlutterJNI flutterJNI = mock(FlutterJNI.class);
      FlutterLoader flutterLoader = mock(FlutterLoader.class);
      when(flutterJNI.isAttached()).thenReturn(true);
      when(flutterLoader.automaticallyRegisterPlugins()).thenReturn(true);

      numberOfEnginesCreated++;
      return new FlutterEngine(context, flutterLoader, flutterJNI, new String[] {}, true);
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

    @Nullable
    public String getDartEntrypointLibraryUri() {
      return null;
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

  private static class FlutterFragmentActivityWithRootLayout
      extends FlutterFragmentActivityWithProvidedEngine {
    public static class CustomLayout extends FrameLayout {
      public CustomLayout(Context context) {
        super(context);
      }
    }

    @Override
    protected FrameLayout provideRootLayout(Context context) {
      return new CustomLayout(context);
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
