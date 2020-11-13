package io.flutter.embedding.android;

import static io.flutter.embedding.android.FlutterActivityLaunchConfigs.HANDLE_DEEPLINKING_META_DATA_KEY;
import static org.junit.Assert.assertArrayEquals;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Bundle;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.lifecycle.DefaultLifecycleObserver;
import androidx.lifecycle.LifecycleOwner;
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterEngineCache;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.embedding.engine.loader.FlutterLoader;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding.OnSaveInstanceStateListener;
import io.flutter.plugins.GeneratedPluginRegistrant;
import java.util.List;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.android.controller.ActivityController;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class FlutterActivityTest {
  @Before
  public void setUp() {
    GeneratedPluginRegistrant.clearRegisteredEngines();
  }

  @After
  public void tearDown() {
    GeneratedPluginRegistrant.clearRegisteredEngines();
  }

  @Test
  public void itCreatesDefaultIntentWithExpectedDefaults() {
    Intent intent = FlutterActivity.createDefaultIntent(RuntimeEnvironment.application);
    ActivityController<FlutterActivity> activityController =
        Robolectric.buildActivity(FlutterActivity.class, intent);
    FlutterActivity flutterActivity = activityController.get();
    flutterActivity.setDelegate(new FlutterActivityAndFragmentDelegate(flutterActivity));

    assertEquals("main", flutterActivity.getDartEntrypointFunctionName());
    assertEquals("/", flutterActivity.getInitialRoute());
    assertArrayEquals(new String[] {}, flutterActivity.getFlutterShellArgs().toArray());
    assertTrue(flutterActivity.shouldAttachEngineToActivity());
    assertNull(flutterActivity.getCachedEngineId());
    assertTrue(flutterActivity.shouldDestroyEngineWithHost());
    assertEquals(BackgroundMode.opaque, flutterActivity.getBackgroundMode());
    assertEquals(RenderMode.surface, flutterActivity.getRenderMode());
    assertEquals(TransparencyMode.opaque, flutterActivity.getTransparencyMode());
  }

  @Test
  public void itDestroysNewEngineWhenIntentIsMissingParameter() {
    // All clients should use the static members of FlutterActivity to construct an
    // Intent. Missing extras is an error. However, Flutter has number of tests that
    // don't seem to use the static members of FlutterActivity to construct the
    // launching Intent, so this test explicitly verifies that even illegal Intents
    // result in the automatic destruction of a non-cached FlutterEngine, which prevents
    // the breakage of memory usage benchmark tests.
    Intent intent = new Intent(RuntimeEnvironment.application, FlutterActivity.class);
    ActivityController<FlutterActivity> activityController =
        Robolectric.buildActivity(FlutterActivity.class, intent);
    FlutterActivity flutterActivity = activityController.get();
    flutterActivity.setDelegate(new FlutterActivityAndFragmentDelegate(flutterActivity));

    assertTrue(flutterActivity.shouldDestroyEngineWithHost());
  }

  @Test
  public void itDoesNotDestroyFlutterEngineWhenProvidedByHost() {
    Intent intent =
        new Intent(RuntimeEnvironment.application, FlutterActivityWithProvidedEngine.class);
    ActivityController<FlutterActivityWithProvidedEngine> activityController =
        Robolectric.buildActivity(FlutterActivityWithProvidedEngine.class, intent);
    activityController.create();
    FlutterActivityWithProvidedEngine flutterActivity = activityController.get();

    assertFalse(flutterActivity.shouldDestroyEngineWithHost());
  }

  @Test
  public void itCreatesNewEngineIntentWithRequestedSettings() {
    Intent intent =
        FlutterActivity.withNewEngine()
            .initialRoute("/custom/route")
            .backgroundMode(BackgroundMode.transparent)
            .build(RuntimeEnvironment.application);
    ActivityController<FlutterActivity> activityController =
        Robolectric.buildActivity(FlutterActivity.class, intent);
    FlutterActivity flutterActivity = activityController.get();
    flutterActivity.setDelegate(new FlutterActivityAndFragmentDelegate(flutterActivity));

    assertEquals("/custom/route", flutterActivity.getInitialRoute());
    assertArrayEquals(new String[] {}, flutterActivity.getFlutterShellArgs().toArray());
    assertTrue(flutterActivity.shouldAttachEngineToActivity());
    assertNull(flutterActivity.getCachedEngineId());
    assertTrue(flutterActivity.shouldDestroyEngineWithHost());
    assertEquals(BackgroundMode.transparent, flutterActivity.getBackgroundMode());
    assertEquals(RenderMode.texture, flutterActivity.getRenderMode());
    assertEquals(TransparencyMode.transparent, flutterActivity.getTransparencyMode());
  }

  @Test
  public void itReturnsValueFromMetaDataWhenCallsShouldHandleDeepLinkingCase1()
      throws PackageManager.NameNotFoundException {
    Intent intent =
        FlutterActivity.withNewEngine()
            .backgroundMode(BackgroundMode.transparent)
            .build(RuntimeEnvironment.application);
    ActivityController<FlutterActivity> activityController =
        Robolectric.buildActivity(FlutterActivity.class, intent);
    FlutterActivity flutterActivity = activityController.get();
    Bundle bundle = new Bundle();
    bundle.putBoolean(HANDLE_DEEPLINKING_META_DATA_KEY, true);
    FlutterActivity spyFlutterActivity = spy(flutterActivity);
    when(spyFlutterActivity.getMetaData()).thenReturn(bundle);
    assertTrue(spyFlutterActivity.shouldHandleDeeplinking());
  }

  @Test
  public void itReturnsValueFromMetaDataWhenCallsShouldHandleDeepLinkingCase2()
      throws PackageManager.NameNotFoundException {
    Intent intent =
        FlutterActivity.withNewEngine()
            .backgroundMode(BackgroundMode.transparent)
            .build(RuntimeEnvironment.application);
    ActivityController<FlutterActivity> activityController =
        Robolectric.buildActivity(FlutterActivity.class, intent);
    FlutterActivity flutterActivity = activityController.get();
    Bundle bundle = new Bundle();
    bundle.putBoolean(HANDLE_DEEPLINKING_META_DATA_KEY, false);
    FlutterActivity spyFlutterActivity = spy(flutterActivity);
    when(spyFlutterActivity.getMetaData()).thenReturn(bundle);
    assertFalse(spyFlutterActivity.shouldHandleDeeplinking());
  }

  @Test
  public void itReturnsValueFromMetaDataWhenCallsShouldHandleDeepLinkingCase3()
      throws PackageManager.NameNotFoundException {
    Intent intent =
        FlutterActivity.withNewEngine()
            .backgroundMode(BackgroundMode.transparent)
            .build(RuntimeEnvironment.application);
    ActivityController<FlutterActivity> activityController =
        Robolectric.buildActivity(FlutterActivity.class, intent);
    FlutterActivity flutterActivity = activityController.get();
    // Creates an empty bundle.
    Bundle bundle = new Bundle();
    FlutterActivity spyFlutterActivity = spy(flutterActivity);
    when(spyFlutterActivity.getMetaData()).thenReturn(bundle);
    // Empty bundle should return false.
    assertFalse(spyFlutterActivity.shouldHandleDeeplinking());
  }

  @Test
  public void itCreatesCachedEngineIntentThatDoesNotDestroyTheEngine() {
    Intent intent =
        FlutterActivity.withCachedEngine("my_cached_engine")
            .destroyEngineWithActivity(false)
            .build(RuntimeEnvironment.application);
    ActivityController<FlutterActivity> activityController =
        Robolectric.buildActivity(FlutterActivity.class, intent);
    FlutterActivity flutterActivity = activityController.get();

    assertArrayEquals(new String[] {}, flutterActivity.getFlutterShellArgs().toArray());
    assertTrue(flutterActivity.shouldAttachEngineToActivity());
    assertEquals("my_cached_engine", flutterActivity.getCachedEngineId());
    assertFalse(flutterActivity.shouldDestroyEngineWithHost());
  }

  @Test
  public void itCreatesCachedEngineIntentThatDestroysTheEngine() {
    Intent intent =
        FlutterActivity.withCachedEngine("my_cached_engine")
            .destroyEngineWithActivity(true)
            .build(RuntimeEnvironment.application);
    ActivityController<FlutterActivity> activityController =
        Robolectric.buildActivity(FlutterActivity.class, intent);
    FlutterActivity flutterActivity = activityController.get();

    assertArrayEquals(new String[] {}, flutterActivity.getFlutterShellArgs().toArray());
    assertTrue(flutterActivity.shouldAttachEngineToActivity());
    assertEquals("my_cached_engine", flutterActivity.getCachedEngineId());
    assertTrue(flutterActivity.shouldDestroyEngineWithHost());
  }

  @Test
  public void itRegistersPluginsAtConfigurationTime() {
    FlutterActivity activity =
        Robolectric.buildActivity(FlutterActivityWithProvidedEngine.class).get();
    activity.onCreate(null);

    assertTrue(GeneratedPluginRegistrant.getRegisteredEngines().isEmpty());
    activity.configureFlutterEngine(activity.getFlutterEngine());

    List<FlutterEngine> registeredEngines = GeneratedPluginRegistrant.getRegisteredEngines();
    assertEquals(1, registeredEngines.size());
    assertEquals(activity.getFlutterEngine(), registeredEngines.get(0));
  }

  @Test
  public void itCanBeDetachedFromTheEngineAndStopSendingFurtherEvents() {
    FlutterActivityAndFragmentDelegate mockDelegate =
        mock(FlutterActivityAndFragmentDelegate.class);
    FlutterEngine mockEngine = mock(FlutterEngine.class);
    FlutterEngineCache.getInstance().put("my_cached_engine", mockEngine);

    Intent intent =
        FlutterActivity.withCachedEngine("my_cached_engine").build(RuntimeEnvironment.application);
    ActivityController<FlutterActivity> activityController =
        Robolectric.buildActivity(FlutterActivity.class, intent);
    FlutterActivity flutterActivity = activityController.get();
    flutterActivity.setDelegate(mockDelegate);
    flutterActivity.onStart();
    flutterActivity.onResume();

    verify(mockDelegate, times(1)).onStart();
    verify(mockDelegate, times(1)).onResume();

    flutterActivity.onPause();
    flutterActivity.detachFromFlutterEngine();
    verify(mockDelegate, times(1)).onPause();
    verify(mockDelegate, times(1)).onDestroyView();
    verify(mockDelegate, times(1)).onDetach();

    flutterActivity.onStop();
    flutterActivity.onDestroy();

    verify(mockDelegate, never()).onStop();
    // 1 time same as before.
    verify(mockDelegate, times(1)).onDestroyView();
    verify(mockDelegate, times(1)).onDetach();
  }

  @Test
  public void itRestoresPluginStateBeforePluginOnCreate() {
    FlutterLoader mockFlutterLoader = mock(FlutterLoader.class);
    FlutterJNI mockFlutterJni = mock(FlutterJNI.class);
    when(mockFlutterJni.isAttached()).thenReturn(true);
    FlutterEngine cachedEngine =
        new FlutterEngine(RuntimeEnvironment.application, mockFlutterLoader, mockFlutterJni);
    FakeFlutterPlugin fakeFlutterPlugin = new FakeFlutterPlugin();
    cachedEngine.getPlugins().add(fakeFlutterPlugin);
    FlutterEngineCache.getInstance().put("my_cached_engine", cachedEngine);

    Intent intent =
        FlutterActivity.withCachedEngine("my_cached_engine").build(RuntimeEnvironment.application);
    Robolectric.buildActivity(FlutterActivity.class, intent).setup();
    assertTrue(
        "Expected FakeFlutterPlugin onCreateCalled to be true", fakeFlutterPlugin.onCreateCalled);
  }

  static class FlutterActivityWithProvidedEngine extends FlutterActivity {
    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
      super.delegate = new FlutterActivityAndFragmentDelegate(this);
      super.delegate.setupFlutterEngine();
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

  // This is just a compile time check to ensure that it's possible for FlutterActivity subclasses
  // to provide their own intent builders which builds their own runtime types.
  static class FlutterActivityWithIntentBuilders extends FlutterActivity {

    public static NewEngineIntentBuilder withNewEngine() {
      return new NewEngineIntentBuilder(FlutterActivityWithIntentBuilders.class);
    }

    public static CachedEngineIntentBuilder withCachedEngine(@NonNull String cachedEngineId) {
      return new CachedEngineIntentBuilder(FlutterActivityWithIntentBuilders.class, cachedEngineId);
    }
  }

  private static final class FakeFlutterPlugin
      implements FlutterPlugin,
          ActivityAware,
          OnSaveInstanceStateListener,
          DefaultLifecycleObserver {

    private ActivityPluginBinding activityPluginBinding;
    private boolean stateRestored = false;
    private boolean onCreateCalled = false;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {}

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {}

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
      activityPluginBinding = binding;
      binding.addOnSaveStateListener(this);
      ((FlutterActivity) binding.getActivity()).getLifecycle().addObserver(this);
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
      onDetachedFromActivity();
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
      onAttachedToActivity(binding);
    }

    @Override
    public void onDetachedFromActivity() {
      ((FlutterActivity) activityPluginBinding.getActivity()).getLifecycle().removeObserver(this);
      activityPluginBinding.removeOnSaveStateListener(this);
      activityPluginBinding = null;
    }

    @Override
    public void onSaveInstanceState(@NonNull Bundle bundle) {}

    @Override
    public void onRestoreInstanceState(@Nullable Bundle bundle) {
      stateRestored = true;
    }

    @Override
    public void onCreate(@NonNull LifecycleOwner lifecycleOwner) {
      assertTrue("State was restored before onCreate", stateRestored);
      onCreateCalled = true;
    }
  }
}
