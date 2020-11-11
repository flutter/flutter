package io.flutter.embedding.android;

import static android.content.ComponentCallbacks2.*;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;
import static org.mockito.Matchers.any;
import static org.mockito.Matchers.eq;
import static org.mockito.Matchers.notNull;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import androidx.annotation.NonNull;
import androidx.lifecycle.Lifecycle;
import io.flutter.FlutterInjector;
import io.flutter.embedding.android.FlutterActivityAndFragmentDelegate.Host;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterEngineCache;
import io.flutter.embedding.engine.FlutterShellArgs;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.loader.FlutterLoader;
import io.flutter.embedding.engine.plugins.activity.ActivityControlSurface;
import io.flutter.embedding.engine.renderer.FlutterRenderer;
import io.flutter.embedding.engine.systemchannels.AccessibilityChannel;
import io.flutter.embedding.engine.systemchannels.KeyEventChannel;
import io.flutter.embedding.engine.systemchannels.LifecycleChannel;
import io.flutter.embedding.engine.systemchannels.LocalizationChannel;
import io.flutter.embedding.engine.systemchannels.MouseCursorChannel;
import io.flutter.embedding.engine.systemchannels.NavigationChannel;
import io.flutter.embedding.engine.systemchannels.SettingsChannel;
import io.flutter.embedding.engine.systemchannels.SystemChannel;
import io.flutter.embedding.engine.systemchannels.TextInputChannel;
import io.flutter.plugin.localization.LocalizationPlugin;
import io.flutter.plugin.platform.PlatformViewsController;
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
public class FlutterActivityAndFragmentDelegateTest {
  private FlutterEngine mockFlutterEngine;
  private FlutterActivityAndFragmentDelegate.Host mockHost;

  @Before
  public void setup() {
    FlutterInjector.reset();
    // Create a mocked FlutterEngine for the various interactions required by the delegate
    // being tested.
    mockFlutterEngine = mockFlutterEngine();

    // Create a mocked Host, which is required by the delegate being tested.
    mockHost = mock(FlutterActivityAndFragmentDelegate.Host.class);
    when(mockHost.getContext()).thenReturn(RuntimeEnvironment.application);
    when(mockHost.getActivity()).thenReturn(Robolectric.setupActivity(Activity.class));
    when(mockHost.getLifecycle()).thenReturn(mock(Lifecycle.class));
    when(mockHost.getFlutterShellArgs()).thenReturn(new FlutterShellArgs(new String[] {}));
    when(mockHost.getDartEntrypointFunctionName()).thenReturn("main");
    when(mockHost.getAppBundlePath()).thenReturn("/fake/path");
    when(mockHost.getInitialRoute()).thenReturn("/");
    when(mockHost.getRenderMode()).thenReturn(RenderMode.surface);
    when(mockHost.getTransparencyMode()).thenReturn(TransparencyMode.transparent);
    when(mockHost.provideFlutterEngine(any(Context.class))).thenReturn(mockFlutterEngine);
    when(mockHost.shouldAttachEngineToActivity()).thenReturn(true);
    when(mockHost.shouldHandleDeeplinking()).thenReturn(false);
    when(mockHost.shouldDestroyEngineWithHost()).thenReturn(true);
  }

  @Test
  public void itSendsLifecycleEventsToFlutter() {
    // ---- Test setup ----
    // Create the real object that we're testing.
    FlutterActivityAndFragmentDelegate delegate = new FlutterActivityAndFragmentDelegate(mockHost);

    // We're testing lifecycle behaviors, which require/expect that certain methods have already
    // been executed by the time they run. Therefore, we run those expected methods first.
    delegate.onAttach(RuntimeEnvironment.application);
    delegate.onCreateView(null, null, null);

    // --- Execute the behavior under test ---
    // By the time an Activity/Fragment is started, we don't expect any lifecycle messages
    // to have been sent to Flutter.
    delegate.onStart();
    verify(mockFlutterEngine.getLifecycleChannel(), never()).appIsResumed();
    verify(mockFlutterEngine.getLifecycleChannel(), never()).appIsPaused();
    verify(mockFlutterEngine.getLifecycleChannel(), never()).appIsInactive();
    verify(mockFlutterEngine.getLifecycleChannel(), never()).appIsDetached();

    // When the Activity/Fragment is resumed, a resumed message should have been sent to Flutter.
    delegate.onResume();
    verify(mockFlutterEngine.getLifecycleChannel(), times(1)).appIsResumed();
    verify(mockFlutterEngine.getLifecycleChannel(), never()).appIsInactive();
    verify(mockFlutterEngine.getLifecycleChannel(), never()).appIsPaused();
    verify(mockFlutterEngine.getLifecycleChannel(), never()).appIsDetached();

    // When the Activity/Fragment is paused, an inactive message should have been sent to Flutter.
    delegate.onPause();
    verify(mockFlutterEngine.getLifecycleChannel(), times(1)).appIsResumed();
    verify(mockFlutterEngine.getLifecycleChannel(), times(1)).appIsInactive();
    verify(mockFlutterEngine.getLifecycleChannel(), never()).appIsPaused();
    verify(mockFlutterEngine.getLifecycleChannel(), never()).appIsDetached();

    // When the Activity/Fragment is stopped, a paused message should have been sent to Flutter.
    // Notice that Flutter uses the term "paused" in a different way, and at a different time
    // than the Android OS.
    delegate.onStop();
    verify(mockFlutterEngine.getLifecycleChannel(), times(1)).appIsResumed();
    verify(mockFlutterEngine.getLifecycleChannel(), times(1)).appIsInactive();
    verify(mockFlutterEngine.getLifecycleChannel(), times(1)).appIsPaused();
    verify(mockFlutterEngine.getLifecycleChannel(), never()).appIsDetached();

    // When activity detaches, a detached message should have been sent to Flutter.
    delegate.onDetach();
    verify(mockFlutterEngine.getLifecycleChannel(), times(1)).appIsResumed();
    verify(mockFlutterEngine.getLifecycleChannel(), times(1)).appIsInactive();
    verify(mockFlutterEngine.getLifecycleChannel(), times(1)).appIsPaused();
    verify(mockFlutterEngine.getLifecycleChannel(), times(1)).appIsDetached();
  }

  @Test
  public void itDefersToTheHostToProvideFlutterEngine() {
    // ---- Test setup ----
    // Create the real object that we're testing.
    FlutterActivityAndFragmentDelegate delegate = new FlutterActivityAndFragmentDelegate(mockHost);

    // --- Execute the behavior under test ---
    // The FlutterEngine is created in onAttach().
    delegate.onAttach(RuntimeEnvironment.application);

    // Verify that the host was asked to provide a FlutterEngine.
    verify(mockHost, times(1)).provideFlutterEngine(any(Context.class));

    // Verify that the delegate's FlutterEngine is our mock FlutterEngine.
    assertEquals(
        "The delegate failed to use the host's FlutterEngine.",
        mockFlutterEngine,
        delegate.getFlutterEngine());
  }

  @Test
  public void itUsesCachedEngineWhenProvided() {
    // ---- Test setup ----
    // Place a FlutterEngine in the static cache.
    FlutterEngine cachedEngine = mockFlutterEngine();
    FlutterEngineCache.getInstance().put("my_flutter_engine", cachedEngine);

    // Adjust fake host to request cached engine.
    when(mockHost.getCachedEngineId()).thenReturn("my_flutter_engine");

    // Create the real object that we're testing.
    FlutterActivityAndFragmentDelegate delegate = new FlutterActivityAndFragmentDelegate(mockHost);

    // --- Execute the behavior under test ---
    // The FlutterEngine is obtained in onAttach().
    delegate.onAttach(RuntimeEnvironment.application);
    delegate.onCreateView(null, null, null);
    delegate.onStart();
    delegate.onResume();

    // --- Verify that the cached engine was used ---
    // Verify that the non-cached engine was not used.
    verify(mockFlutterEngine.getDartExecutor(), never())
        .executeDartEntrypoint(any(DartExecutor.DartEntrypoint.class));

    // We should never instruct a cached engine to execute Dart code - it should already be
    // executing it.
    verify(cachedEngine.getDartExecutor(), never())
        .executeDartEntrypoint(any(DartExecutor.DartEntrypoint.class));

    // If the cached engine is being used, it should have sent a resumed lifecycle event.
    verify(cachedEngine.getLifecycleChannel(), times(1)).appIsResumed();
  }

  @Test(expected = IllegalStateException.class)
  public void itThrowsExceptionIfCachedEngineDoesNotExist() {
    // ---- Test setup ----
    // Adjust fake host to request cached engine that does not exist.
    when(mockHost.getCachedEngineId()).thenReturn("my_flutter_engine");

    // Create the real object that we're testing.
    FlutterActivityAndFragmentDelegate delegate = new FlutterActivityAndFragmentDelegate(mockHost);

    // --- Execute the behavior under test ---
    // The FlutterEngine existence is verified in onAttach()
    delegate.onAttach(RuntimeEnvironment.application);

    // Expect IllegalStateException.
  }

  @Test
  public void itGivesHostAnOpportunityToConfigureFlutterEngine() {
    // ---- Test setup ----
    // Create the real object that we're testing.
    FlutterActivityAndFragmentDelegate delegate = new FlutterActivityAndFragmentDelegate(mockHost);

    // --- Execute the behavior under test ---
    // The FlutterEngine is created in onAttach().
    delegate.onAttach(RuntimeEnvironment.application);

    // Verify that the host was asked to configure our FlutterEngine.
    verify(mockHost, times(1)).configureFlutterEngine(mockFlutterEngine);
  }

  @Test
  public void itGivesHostAnOpportunityToConfigureFlutterSurfaceView() {
    // ---- Test setup ----
    // Create the real object that we're testing.
    FlutterActivityAndFragmentDelegate delegate = new FlutterActivityAndFragmentDelegate(mockHost);

    // --- Execute the behavior under test ---
    delegate.onAttach(RuntimeEnvironment.application);
    delegate.onCreateView(null, null, null);

    // Verify that the host was asked to configure a FlutterSurfaceView.
    verify(mockHost, times(1)).onFlutterSurfaceViewCreated(notNull(FlutterSurfaceView.class));
  }

  @Test
  public void itGivesHostAnOpportunityToConfigureFlutterTextureView() {
    // ---- Test setup ----
    Host customMockHost = mock(Host.class);
    when(customMockHost.getContext()).thenReturn(RuntimeEnvironment.application);
    when(customMockHost.getActivity()).thenReturn(Robolectric.setupActivity(Activity.class));
    when(customMockHost.getLifecycle()).thenReturn(mock(Lifecycle.class));
    when(customMockHost.getFlutterShellArgs()).thenReturn(new FlutterShellArgs(new String[] {}));
    when(customMockHost.getDartEntrypointFunctionName()).thenReturn("main");
    when(customMockHost.getAppBundlePath()).thenReturn("/fake/path");
    when(customMockHost.getInitialRoute()).thenReturn("/");
    when(customMockHost.getRenderMode()).thenReturn(RenderMode.texture);
    when(customMockHost.getTransparencyMode()).thenReturn(TransparencyMode.transparent);
    when(customMockHost.provideFlutterEngine(any(Context.class))).thenReturn(mockFlutterEngine);
    when(customMockHost.shouldAttachEngineToActivity()).thenReturn(true);
    when(customMockHost.shouldDestroyEngineWithHost()).thenReturn(true);

    // Create the real object that we're testing.
    FlutterActivityAndFragmentDelegate delegate =
        new FlutterActivityAndFragmentDelegate(customMockHost);

    // --- Execute the behavior under test ---
    delegate.onAttach(RuntimeEnvironment.application);
    delegate.onCreateView(null, null, null);

    // Verify that the host was asked to configure a FlutterTextureView.
    verify(customMockHost, times(1)).onFlutterTextureViewCreated(notNull(FlutterTextureView.class));
  }

  @Test
  public void itGivesHostAnOpportunityToCleanUpFlutterEngine() {
    // ---- Test setup ----
    // Create the real object that we're testing.
    FlutterActivityAndFragmentDelegate delegate = new FlutterActivityAndFragmentDelegate(mockHost);

    // --- Execute the behavior under test ---
    // The FlutterEngine is created in onAttach().
    delegate.onAttach(RuntimeEnvironment.application);
    delegate.onDetach();

    // Verify that the host was asked to configure our FlutterEngine.
    verify(mockHost, times(1)).cleanUpFlutterEngine(mockFlutterEngine);
  }

  @Test
  public void itSendsInitialRouteToFlutter() {
    // ---- Test setup ----
    // Set initial route on our fake Host.
    when(mockHost.getInitialRoute()).thenReturn("/my/route");

    // Create the real object that we're testing.
    FlutterActivityAndFragmentDelegate delegate = new FlutterActivityAndFragmentDelegate(mockHost);

    // --- Execute the behavior under test ---
    // The initial route is sent in onStart().
    delegate.onAttach(RuntimeEnvironment.application);
    delegate.onCreateView(null, null, null);
    delegate.onStart();

    // Verify that the navigation channel was given our initial route.
    verify(mockFlutterEngine.getNavigationChannel(), times(1)).setInitialRoute("/my/route");
  }

  @Test
  public void itExecutesDartEntrypointProvidedByHost() {
    // ---- Test setup ----
    // Set Dart entrypoint parameters on fake host.
    when(mockHost.getAppBundlePath()).thenReturn("/my/bundle/path");
    when(mockHost.getDartEntrypointFunctionName()).thenReturn("myEntrypoint");

    // Create the DartEntrypoint that we expect to be executed.
    DartExecutor.DartEntrypoint dartEntrypoint =
        new DartExecutor.DartEntrypoint("/my/bundle/path", "myEntrypoint");

    // Create the real object that we're testing.
    FlutterActivityAndFragmentDelegate delegate = new FlutterActivityAndFragmentDelegate(mockHost);

    // --- Execute the behavior under test ---
    // Dart is executed in onStart().
    delegate.onAttach(RuntimeEnvironment.application);
    delegate.onCreateView(null, null, null);
    delegate.onStart();

    // Verify that the host's Dart entrypoint was used.
    verify(mockFlutterEngine.getDartExecutor(), times(1)).executeDartEntrypoint(eq(dartEntrypoint));
  }

  @Test
  public void itUsesDefaultFlutterLoaderAppBundlePathWhenUnspecified() {
    // ---- Test setup ----
    FlutterLoader mockFlutterLoader = mock(FlutterLoader.class);
    when(mockFlutterLoader.findAppBundlePath()).thenReturn("default_flutter_assets/path");
    FlutterInjector.setInstance(
        new FlutterInjector.Builder().setFlutterLoader(mockFlutterLoader).build());

    // Set Dart entrypoint parameters on fake host.
    when(mockHost.getAppBundlePath()).thenReturn(null);
    when(mockHost.getDartEntrypointFunctionName()).thenReturn("myEntrypoint");

    // Create the DartEntrypoint that we expect to be executed.
    DartExecutor.DartEntrypoint dartEntrypoint =
        new DartExecutor.DartEntrypoint("default_flutter_assets/path", "myEntrypoint");

    // Create the real object that we're testing.
    FlutterActivityAndFragmentDelegate delegate = new FlutterActivityAndFragmentDelegate(mockHost);

    // --- Execute the behavior under test ---
    // Dart is executed in onStart().
    delegate.onAttach(RuntimeEnvironment.application);
    delegate.onCreateView(null, null, null);
    delegate.onStart();

    // Verify that the host's Dart entrypoint was used.
    verify(mockFlutterEngine.getDartExecutor(), times(1)).executeDartEntrypoint(eq(dartEntrypoint));
  }

  // "Attaching" to the surrounding Activity refers to Flutter being able to control
  // system chrome and other Activity-level details. If Flutter is not attached to the
  // surrounding Activity, it cannot control those details. This includes plugins.
  @Test
  public void itAttachesFlutterToTheActivityIfDesired() {
    // ---- Test setup ----
    // Declare that the host wants Flutter to attach to the surrounding Activity.
    when(mockHost.shouldAttachEngineToActivity()).thenReturn(true);

    // Create the real object that we're testing.
    FlutterActivityAndFragmentDelegate delegate = new FlutterActivityAndFragmentDelegate(mockHost);

    // --- Execute the behavior under test ---
    // Flutter is attached to the surrounding Activity in onAttach.
    delegate.onAttach(RuntimeEnvironment.application);

    // Verify that the ActivityControlSurface was told to attach to an Activity.
    verify(mockFlutterEngine.getActivityControlSurface(), times(1))
        .attachToActivity(any(ExclusiveAppComponent.class), any(Lifecycle.class));

    // Flutter is detached from the surrounding Activity in onDetach.
    delegate.onDetach();

    // Verify that the ActivityControlSurface was told to detach from the Activity.
    verify(mockFlutterEngine.getActivityControlSurface(), times(1)).detachFromActivity();
  }

  // "Attaching" to the surrounding Activity refers to Flutter being able to control
  // system chrome and other Activity-level details. If Flutter is not attached to the
  // surrounding Activity, it cannot control those details. This includes plugins.
  @Test
  public void itDoesNotAttachFlutterToTheActivityIfNotDesired() {
    // ---- Test setup ----
    // Declare that the host does NOT want Flutter to attach to the surrounding Activity.
    when(mockHost.shouldAttachEngineToActivity()).thenReturn(false);

    // Create the real object that we're testing.
    FlutterActivityAndFragmentDelegate delegate = new FlutterActivityAndFragmentDelegate(mockHost);

    // --- Execute the behavior under test ---
    // Flutter is attached to the surrounding Activity in onAttach.
    delegate.onAttach(RuntimeEnvironment.application);

    // Verify that the ActivityControlSurface was NOT told to attach to an Activity.
    verify(mockFlutterEngine.getActivityControlSurface(), never())
        .attachToActivity(any(Activity.class), any(Lifecycle.class));

    // Flutter is detached from the surrounding Activity in onDetach.
    delegate.onDetach();

    // Verify that the ActivityControlSurface was NOT told to detach from the Activity.
    verify(mockFlutterEngine.getActivityControlSurface(), never()).detachFromActivity();
  }

  @Test
  public void itSendsPopRouteMessageToFlutterWhenHardwareBackButtonIsPressed() {
    // Create the real object that we're testing.
    FlutterActivityAndFragmentDelegate delegate = new FlutterActivityAndFragmentDelegate(mockHost);

    // --- Execute the behavior under test ---
    // The FlutterEngine is setup in onAttach().
    delegate.onAttach(RuntimeEnvironment.application);

    // Emulate the host and inform our delegate that the back button was pressed.
    delegate.onBackPressed();

    // Verify that the navigation channel tried to send a message to Flutter.
    verify(mockFlutterEngine.getNavigationChannel(), times(1)).popRoute();
  }

  @Test
  public void itForwardsOnRequestPermissionsResultToFlutterEngine() {
    // Create the real object that we're testing.
    FlutterActivityAndFragmentDelegate delegate = new FlutterActivityAndFragmentDelegate(mockHost);

    // --- Execute the behavior under test ---
    // The FlutterEngine is setup in onAttach().
    delegate.onAttach(RuntimeEnvironment.application);

    // Emulate the host and call the method that we expect to be forwarded.
    delegate.onRequestPermissionsResult(0, new String[] {}, new int[] {});

    // Verify that the call was forwarded to the engine.
    verify(mockFlutterEngine.getActivityControlSurface(), times(1))
        .onRequestPermissionsResult(any(Integer.class), any(String[].class), any(int[].class));
  }

  @Test
  public void
      itSendsInitialRouteFromIntentOnStartIfNoInitialRouteFromActivityAndShouldHandleDeeplinking() {
    Intent intent = FlutterActivity.createDefaultIntent(RuntimeEnvironment.application);
    intent.setData(Uri.parse("http://myApp/custom/route"));

    ActivityController<FlutterActivity> activityController =
        Robolectric.buildActivity(FlutterActivity.class, intent);
    FlutterActivity flutterActivity = activityController.get();

    when(mockHost.getActivity()).thenReturn(flutterActivity);
    when(mockHost.getInitialRoute()).thenReturn(null);
    when(mockHost.shouldHandleDeeplinking()).thenReturn(true);
    // Create the real object that we're testing.
    FlutterActivityAndFragmentDelegate delegate = new FlutterActivityAndFragmentDelegate(mockHost);

    // --- Execute the behavior under test ---
    // The FlutterEngine is setup in onAttach().
    delegate.onAttach(RuntimeEnvironment.application);
    // Emulate app start.
    delegate.onStart();

    // Verify that the navigation channel was given the initial route message.
    verify(mockFlutterEngine.getNavigationChannel(), times(1))
        .setInitialRoute("http://myApp/custom/route");
  }

  @Test
  public void itSendsdefaultInitialRouteOnStartIfNotDeepLinkingFromIntent() {
    // Creates an empty intent without launch uri.
    Intent intent = FlutterActivity.createDefaultIntent(RuntimeEnvironment.application);

    ActivityController<FlutterActivity> activityController =
        Robolectric.buildActivity(FlutterActivity.class, intent);
    FlutterActivity flutterActivity = activityController.get();

    when(mockHost.getActivity()).thenReturn(flutterActivity);
    when(mockHost.getInitialRoute()).thenReturn(null);
    when(mockHost.shouldHandleDeeplinking()).thenReturn(true);
    // Create the real object that we're testing.
    FlutterActivityAndFragmentDelegate delegate = new FlutterActivityAndFragmentDelegate(mockHost);

    // --- Execute the behavior under test ---
    // The FlutterEngine is setup in onAttach().
    delegate.onAttach(RuntimeEnvironment.application);
    // Emulate app start.
    delegate.onStart();

    // Verify that the navigation channel was given the default initial route message.
    verify(mockFlutterEngine.getNavigationChannel(), times(1)).setInitialRoute("/");
  }

  @Test
  public void itSendsPushRouteMessageWhenOnNewIntent() {
    when(mockHost.shouldHandleDeeplinking()).thenReturn(true);
    // Create the real object that we're testing.
    FlutterActivityAndFragmentDelegate delegate = new FlutterActivityAndFragmentDelegate(mockHost);

    // --- Execute the behavior under test ---
    // The FlutterEngine is setup in onAttach().
    delegate.onAttach(RuntimeEnvironment.application);

    Intent mockIntent = mock(Intent.class);
    when(mockIntent.getData()).thenReturn(Uri.parse("http://myApp/custom/route"));
    // Emulate the host and call the method that we expect to be forwarded.
    delegate.onNewIntent(mockIntent);

    // Verify that the navigation channel was given the push route message.
    verify(mockFlutterEngine.getNavigationChannel(), times(1))
        .pushRoute("http://myApp/custom/route");
  }

  @Test
  public void itForwardsOnNewIntentToFlutterEngine() {
    // Create the real object that we're testing.
    FlutterActivityAndFragmentDelegate delegate = new FlutterActivityAndFragmentDelegate(mockHost);

    // --- Execute the behavior under test ---
    // The FlutterEngine is setup in onAttach().
    delegate.onAttach(RuntimeEnvironment.application);

    // Emulate the host and call the method that we expect to be forwarded.
    delegate.onNewIntent(mock(Intent.class));

    // Verify that the call was forwarded to the engine.
    verify(mockFlutterEngine.getActivityControlSurface(), times(1)).onNewIntent(any(Intent.class));
  }

  @Test
  public void itForwardsOnActivityResultToFlutterEngine() {
    // Create the real object that we're testing.
    FlutterActivityAndFragmentDelegate delegate = new FlutterActivityAndFragmentDelegate(mockHost);

    // --- Execute the behavior under test ---
    // The FlutterEngine is setup in onAttach().
    delegate.onAttach(RuntimeEnvironment.application);

    // Emulate the host and call the method that we expect to be forwarded.
    delegate.onActivityResult(0, 0, null);

    // Verify that the call was forwarded to the engine.
    verify(mockFlutterEngine.getActivityControlSurface(), times(1))
        .onActivityResult(any(Integer.class), any(Integer.class), any(Intent.class));
  }

  @Test
  public void itForwardsOnUserLeaveHintToFlutterEngine() {
    // Create the real object that we're testing.
    FlutterActivityAndFragmentDelegate delegate = new FlutterActivityAndFragmentDelegate(mockHost);

    // --- Execute the behavior under test ---
    // The FlutterEngine is setup in onAttach().
    delegate.onAttach(RuntimeEnvironment.application);

    // Emulate the host and call the method that we expect to be forwarded.
    delegate.onUserLeaveHint();

    // Verify that the call was forwarded to the engine.
    verify(mockFlutterEngine.getActivityControlSurface(), times(1)).onUserLeaveHint();
  }

  @Test
  public void itNotifiesDartExecutorAndSendsMessageOverSystemChannelWhenToldToTrimMemory() {
    // Create the real object that we're testing.
    FlutterActivityAndFragmentDelegate delegate = new FlutterActivityAndFragmentDelegate(mockHost);

    // --- Execute the behavior under test ---
    // The FlutterEngine is setup in onAttach().
    delegate.onAttach(RuntimeEnvironment.application);

    // Emulate the host and call the method that we expect to be forwarded.
    delegate.onTrimMemory(TRIM_MEMORY_RUNNING_MODERATE);
    delegate.onTrimMemory(TRIM_MEMORY_RUNNING_LOW);
    delegate.onTrimMemory(TRIM_MEMORY_RUNNING_CRITICAL);
    delegate.onTrimMemory(TRIM_MEMORY_BACKGROUND);
    delegate.onTrimMemory(TRIM_MEMORY_COMPLETE);
    delegate.onTrimMemory(TRIM_MEMORY_MODERATE);
    delegate.onTrimMemory(TRIM_MEMORY_UI_HIDDEN);

    // Verify that the call was forwarded to the engine.
    verify(mockFlutterEngine.getDartExecutor(), times(7)).notifyLowMemoryWarning();
    verify(mockFlutterEngine.getSystemChannel(), times(1)).sendMemoryPressureWarning();
  }

  @Test
  public void itNotifiesDartExecutorAndSendsMessageOverSystemChannelWhenInformedOfLowMemory() {
    // Create the real object that we're testing.
    FlutterActivityAndFragmentDelegate delegate = new FlutterActivityAndFragmentDelegate(mockHost);

    // --- Execute the behavior under test ---
    // The FlutterEngine is setup in onAttach().
    delegate.onAttach(RuntimeEnvironment.application);

    // Emulate the host and call the method that we expect to be forwarded.
    delegate.onLowMemory();

    // Verify that the call was forwarded to the engine.
    verify(mockFlutterEngine.getDartExecutor(), times(1)).notifyLowMemoryWarning();
    verify(mockFlutterEngine.getSystemChannel(), times(1)).sendMemoryPressureWarning();
  }

  @Test
  public void itDestroysItsOwnEngineIfHostRequestsIt() {
    // ---- Test setup ----
    // Adjust fake host to request engine destruction.
    when(mockHost.shouldDestroyEngineWithHost()).thenReturn(true);

    // Create the real object that we're testing.
    FlutterActivityAndFragmentDelegate delegate = new FlutterActivityAndFragmentDelegate(mockHost);

    // --- Execute the behavior under test ---
    // Push the delegate through all lifecycle methods all the way to destruction.
    delegate.onAttach(RuntimeEnvironment.application);
    delegate.onCreateView(null, null, null);
    delegate.onStart();
    delegate.onResume();
    delegate.onPause();
    delegate.onStop();
    delegate.onDestroyView();
    delegate.onDetach();

    // --- Verify that the cached engine was destroyed ---
    verify(mockFlutterEngine, times(1)).destroy();
  }

  @Test
  public void itDoesNotDestroyItsOwnEngineWhenHostSaysNotTo() {
    // ---- Test setup ----
    // Adjust fake host to request engine destruction.
    when(mockHost.shouldDestroyEngineWithHost()).thenReturn(false);

    // Create the real object that we're testing.
    FlutterActivityAndFragmentDelegate delegate = new FlutterActivityAndFragmentDelegate(mockHost);

    // --- Execute the behavior under test ---
    // Push the delegate through all lifecycle methods all the way to destruction.
    delegate.onAttach(RuntimeEnvironment.application);
    delegate.onCreateView(null, null, null);
    delegate.onStart();
    delegate.onResume();
    delegate.onPause();
    delegate.onStop();
    delegate.onDestroyView();
    delegate.onDetach();

    // --- Verify that the cached engine was destroyed ---
    verify(mockFlutterEngine, never()).destroy();
  }

  @Test
  public void itDestroysCachedEngineWhenHostRequestsIt() {
    // ---- Test setup ----
    // Place a FlutterEngine in the static cache.
    FlutterEngine cachedEngine = mockFlutterEngine();
    FlutterEngineCache.getInstance().put("my_flutter_engine", cachedEngine);

    // Adjust fake host to request cached engine.
    when(mockHost.getCachedEngineId()).thenReturn("my_flutter_engine");

    // Adjust fake host to request engine destruction.
    when(mockHost.shouldDestroyEngineWithHost()).thenReturn(true);

    // Create the real object that we're testing.
    FlutterActivityAndFragmentDelegate delegate = new FlutterActivityAndFragmentDelegate(mockHost);

    // --- Execute the behavior under test ---
    // Push the delegate through all lifecycle methods all the way to destruction.
    delegate.onAttach(RuntimeEnvironment.application);
    delegate.onCreateView(null, null, null);
    delegate.onStart();
    delegate.onResume();
    delegate.onPause();
    delegate.onStop();
    delegate.onDestroyView();
    delegate.onDetach();

    // --- Verify that the cached engine was destroyed ---
    verify(cachedEngine, times(1)).destroy();
    assertNull(FlutterEngineCache.getInstance().get("my_flutter_engine"));
  }

  @Test
  public void itDoesNotDestroyCachedEngineWhenHostSaysNotTo() {
    // ---- Test setup ----
    // Place a FlutterEngine in the static cache.
    FlutterEngine cachedEngine = mockFlutterEngine();
    FlutterEngineCache.getInstance().put("my_flutter_engine", cachedEngine);

    // Adjust fake host to request cached engine.
    when(mockHost.getCachedEngineId()).thenReturn("my_flutter_engine");

    // Adjust fake host to request engine retention.
    when(mockHost.shouldDestroyEngineWithHost()).thenReturn(false);

    // Create the real object that we're testing.
    FlutterActivityAndFragmentDelegate delegate = new FlutterActivityAndFragmentDelegate(mockHost);

    // --- Execute the behavior under test ---
    // Push the delegate through all lifecycle methods all the way to destruction.
    delegate.onAttach(RuntimeEnvironment.application);
    delegate.onCreateView(null, null, null);
    delegate.onStart();
    delegate.onResume();
    delegate.onPause();
    delegate.onStop();
    delegate.onDestroyView();
    delegate.onDetach();

    // --- Verify that the cached engine was NOT destroyed ---
    verify(cachedEngine, never()).destroy();
  }

  /**
   * Creates a mock {@link FlutterEngine}.
   *
   * <p>The heuristic for deciding what to mock in the given {@link FlutterEngine} is that we should
   * mock the minimum number of necessary methods and associated objects. Maintaining developers
   * should add more mock behavior as required for tests, but should avoid mocking things that are
   * not required for the correct execution of tests.
   */
  @NonNull
  private FlutterEngine mockFlutterEngine() {
    // The use of SettingsChannel by the delegate requires some behavior of its own, so it is
    // explicitly mocked with some internal behavior.
    SettingsChannel fakeSettingsChannel = mock(SettingsChannel.class);
    SettingsChannel.MessageBuilder fakeMessageBuilder = mock(SettingsChannel.MessageBuilder.class);
    when(fakeMessageBuilder.setPlatformBrightness(any(SettingsChannel.PlatformBrightness.class)))
        .thenReturn(fakeMessageBuilder);
    when(fakeMessageBuilder.setTextScaleFactor(any(Float.class))).thenReturn(fakeMessageBuilder);
    when(fakeMessageBuilder.setUse24HourFormat(any(Boolean.class))).thenReturn(fakeMessageBuilder);
    when(fakeSettingsChannel.startMessage()).thenReturn(fakeMessageBuilder);

    // Mock FlutterEngine and all of its required direct calls.
    FlutterEngine engine = mock(FlutterEngine.class);
    when(engine.getAccessibilityChannel()).thenReturn(mock(AccessibilityChannel.class));
    when(engine.getActivityControlSurface()).thenReturn(mock(ActivityControlSurface.class));
    when(engine.getDartExecutor()).thenReturn(mock(DartExecutor.class));
    when(engine.getKeyEventChannel()).thenReturn(mock(KeyEventChannel.class));
    when(engine.getLifecycleChannel()).thenReturn(mock(LifecycleChannel.class));
    when(engine.getLocalizationChannel()).thenReturn(mock(LocalizationChannel.class));
    when(engine.getLocalizationPlugin()).thenReturn(mock(LocalizationPlugin.class));
    when(engine.getMouseCursorChannel()).thenReturn(mock(MouseCursorChannel.class));
    when(engine.getNavigationChannel()).thenReturn(mock(NavigationChannel.class));
    when(engine.getPlatformViewsController()).thenReturn(mock(PlatformViewsController.class));
    when(engine.getRenderer()).thenReturn(mock(FlutterRenderer.class));
    when(engine.getSettingsChannel()).thenReturn(fakeSettingsChannel);
    when(engine.getSystemChannel()).thenReturn(mock(SystemChannel.class));
    when(engine.getTextInputChannel()).thenReturn(mock(TextInputChannel.class));

    return engine;
  }
}
