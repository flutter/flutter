// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.android;

import static io.flutter.embedding.android.FlutterFragment.ARG_CACHED_ENGINE_ID;
import static io.flutter.embedding.android.FlutterFragment.ARG_DESTROY_ENGINE_WITH_FRAGMENT;
import static io.flutter.embedding.android.FlutterFragment.ARG_SHOULD_AUTOMATICALLY_HANDLE_ON_BACK_PRESSED;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.annotation.TargetApi;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.window.BackEvent;
import androidx.activity.BackEventCompat;
import androidx.activity.OnBackPressedDispatcher;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.test.core.app.ActivityScenario;
import androidx.test.core.app.ApplicationProvider;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.Build;
import io.flutter.FlutterInjector;
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterEngineCache;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.embedding.engine.loader.FlutterLoader;
import io.flutter.embedding.engine.systemchannels.PlatformChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.mockito.MockedStatic;
import org.robolectric.Robolectric;
import org.robolectric.android.controller.ActivityController;
import org.robolectric.annotation.Config;

@RunWith(AndroidJUnit4.class)
public class FlutterFragmentActivityTest {
  private final Context ctx = ApplicationProvider.getApplicationContext();
  private boolean isDelegateAttached;

  static class TestDelegateFactory implements FlutterActivityAndFragmentDelegate.DelegateFactory {
    final FlutterActivityAndFragmentDelegate delegate;

    TestDelegateFactory(FlutterActivityAndFragmentDelegate delegate) {
      this.delegate = delegate;
    }

    @Override
    public FlutterActivityAndFragmentDelegate createDelegate(
        FlutterActivityAndFragmentDelegate.Host host) {
      return delegate;
    }
  }

  private FlutterActivityAndFragmentDelegate installMockDelegate(FlutterFragment fragment) {
    FlutterActivityAndFragmentDelegate mockDelegate =
        mock(FlutterActivityAndFragmentDelegate.class);
    isDelegateAttached = true;
    when(mockDelegate.isAttached()).thenAnswer(invocation -> isDelegateAttached);
    doAnswer(invocation -> isDelegateAttached = false).when(mockDelegate).onDetach();
    fragment.setDelegateFactory(new TestDelegateFactory(mockDelegate));
    return mockDelegate;
  }

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
  public void createFlutterFragment_defaultRenderModeSurface() {
    final FlutterFragmentActivity activity = new FakeFlutterFragmentActivity();
    assertEquals(RenderMode.surface, activity.createFlutterFragment().getRenderMode());
  }

  @Test
  public void getInitialRoute_readsFromIntent() throws Exception {
    Intent intent =
        FlutterFragmentActivity.withNewEngine().initialRoute("/custom/route/intent").build(ctx);
    ActivityController<FlutterFragmentActivity> activityController =
        Robolectric.buildActivity(FlutterFragmentActivity.class, intent);
    FlutterFragmentActivity flutterActivity = activityController.get();

    FlutterFragmentActivity spyFlutterActivity = spy(flutterActivity);
    PackageManager mockPackageManager = mock(PackageManager.class);
    when(spyFlutterActivity.getPackageManager()).thenReturn(mockPackageManager);
    ApplicationInfo mockApplicationInfo = new ApplicationInfo();
    mockApplicationInfo.metaData = new Bundle();
    mockApplicationInfo.metaData.putString(
        "io.flutter.app.androidEngineShellArgs", "[\"--route=/custom/route/args\"]");
    when(mockPackageManager.getApplicationInfo(
            org.mockito.ArgumentMatchers.anyString(), org.mockito.ArgumentMatchers.anyInt()))
        .thenReturn(mockApplicationInfo);

    assertEquals("/custom/route/intent", spyFlutterActivity.getInitialRoute());
  }

  @Test
  public void getInitialRoute_readsFromCommandLineArgs() throws Exception {
    Intent intent = FlutterFragmentActivity.withNewEngine().build(ctx);
    intent.removeExtra(FlutterActivityLaunchConfigs.EXTRA_INITIAL_ROUTE);
    ActivityController<FlutterFragmentActivity> activityController =
        Robolectric.buildActivity(FlutterFragmentActivity.class, intent);
    FlutterFragmentActivity flutterActivity = activityController.get();

    FlutterFragmentActivity spyFlutterActivity = spy(flutterActivity);
    PackageManager mockPackageManager = mock(PackageManager.class);
    when(spyFlutterActivity.getPackageManager()).thenReturn(mockPackageManager);
    ApplicationInfo mockApplicationInfo = new ApplicationInfo();
    mockApplicationInfo.metaData = new Bundle();
    mockApplicationInfo.metaData.putString(
        "io.flutter.app.androidEngineShellArgs", "[\"--route=/custom/route\"]");
    when(mockPackageManager.getApplicationInfo(
            org.mockito.ArgumentMatchers.anyString(), org.mockito.ArgumentMatchers.anyInt()))
        .thenReturn(mockApplicationInfo);

    Bundle activityMetaData = new Bundle();
    activityMetaData.putString(
        FlutterActivityLaunchConfigs.INITIAL_ROUTE_META_DATA_KEY, "/fallback/route");
    doReturn(activityMetaData).when(spyFlutterActivity).getMetaData();

    assertEquals("/custom/route", spyFlutterActivity.getInitialRoute());
  }

  @Test
  public void getInitialRoute_readsFromActivityInfoFallback() throws Exception {
    Intent intent = FlutterFragmentActivity.withNewEngine().build(ctx);
    intent.removeExtra(FlutterActivityLaunchConfigs.EXTRA_INITIAL_ROUTE);
    ActivityController<FlutterFragmentActivity> activityController =
        Robolectric.buildActivity(FlutterFragmentActivity.class, intent);
    FlutterFragmentActivity flutterActivity = activityController.get();

    FlutterFragmentActivity spyFlutterActivity = spy(flutterActivity);

    PackageManager mockPackageManager = mock(PackageManager.class);
    when(spyFlutterActivity.getPackageManager()).thenReturn(mockPackageManager);
    ApplicationInfo mockApplicationInfo = new ApplicationInfo();
    when(mockPackageManager.getApplicationInfo(
            org.mockito.ArgumentMatchers.anyString(), org.mockito.ArgumentMatchers.anyInt()))
        .thenReturn(mockApplicationInfo);

    Bundle activityMetaData = new Bundle();
    activityMetaData.putString(
        FlutterActivityLaunchConfigs.INITIAL_ROUTE_META_DATA_KEY, "/fallback/route");
    doReturn(activityMetaData).when(spyFlutterActivity).getMetaData();

    assertEquals("/fallback/route", spyFlutterActivity.getInitialRoute());
  }

  @Test
  public void createFlutterFragment_defaultRenderModeTexture() {
    final FlutterFragmentActivity activity =
        new FakeFlutterFragmentActivity() {
          @Override
          protected BackgroundMode getBackgroundMode() {
            return BackgroundMode.transparent;
          }
        };
    assertEquals(RenderMode.texture, activity.createFlutterFragment().getRenderMode());
  }

  @Test
  public void createFlutterFragment_customRenderMode() {
    final FlutterFragmentActivity activity =
        new FakeFlutterFragmentActivity() {
          @Override
          protected RenderMode getRenderMode() {
            return RenderMode.texture;
          }
        };
    assertEquals(RenderMode.texture, activity.createFlutterFragment().getRenderMode());
  }

  @Test
  public void createFlutterFragment_customDartEntrypointLibraryUri() {
    final FlutterFragmentActivity activity =
        new FakeFlutterFragmentActivity() {
          @Override
          public String getDartEntrypointLibraryUri() {
            return "package:foo/bar.dart";
          }
        };
    assertEquals(
        "package:foo/bar.dart", activity.createFlutterFragment().getDartEntrypointLibraryUri());
  }

  @Test
  public void createFlutterFragment_passesEngineFlags() {
    Intent intent = new Intent();
    intent.putExtra("verbose-logging", true);
    final FlutterFragmentActivity activity =
        new FakeFlutterFragmentActivity() {
          @Override
          public Intent getIntent() {
            return intent;
          }
        };
    assertTrue(
        activity.createFlutterFragment().getFlutterEngineFlags().contains("--verbose-logging"));
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
    bundle.putBoolean(FlutterActivityLaunchConfigs.HANDLE_DEEPLINKING_META_DATA_KEY, true);
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
    bundle.putBoolean(FlutterActivityLaunchConfigs.HANDLE_DEEPLINKING_META_DATA_KEY, false);
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
    // Empty bundle should return true.
    assertTrue(spyFlutterActivity.shouldHandleDeeplinking());
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
  public void configureFlutterEngine_doesNotRegisterPluginsWhenRecoveredInjectedFragmentIsFound() {
    FlutterFragmentActivityWithProvidedEngine activity =
        spy(Robolectric.buildActivity(FlutterFragmentActivityWithProvidedEngine.class).get());

    FlutterFragment fragment = mock(FlutterFragment.class);
    when(fragment.isFlutterEngineInjected()).thenReturn(true);
    when(activity.retrieveExistingFlutterFragmentIfPossible()).thenReturn(fragment);

    FlutterEngine engine = mock(FlutterEngine.class);
    activity.configureFlutterEngine(engine);

    assertTrue(GeneratedPluginRegistrant.getRegisteredEngines().isEmpty());
  }

  @Test
  public void recreate_withCachedEngine_doesNotRegisterPlugins() {
    FlutterLoader mockFlutterLoader = mock(FlutterLoader.class);
    FlutterJNI mockFlutterJni = mock(FlutterJNI.class);
    when(mockFlutterJni.isAttached()).thenReturn(true);
    when(mockFlutterLoader.automaticallyRegisterPlugins()).thenReturn(false);

    FlutterEngine cachedEngine =
        new FlutterEngine(ctx, mockFlutterLoader, mockFlutterJni, new String[] {}, false);
    final String cachedEngineId = "recreate_cached_engine";
    FlutterEngineCache.getInstance().put(cachedEngineId, cachedEngine);
    Intent intent = FlutterFragmentActivity.withCachedEngine(cachedEngineId).build(ctx);

    try (ActivityScenario<FlutterFragmentActivity> scenario = ActivityScenario.launch(intent)) {
      scenario.onActivity(
          activity -> assertTrue(GeneratedPluginRegistrant.getRegisteredEngines().isEmpty()));

      scenario.recreate();

      scenario.onActivity(
          activity -> assertTrue(GeneratedPluginRegistrant.getRegisteredEngines().isEmpty()));
    } finally {
      FlutterEngineCache.getInstance().remove(cachedEngineId);
      cachedEngine.destroy();
    }
  }

  @Test
  @Config(minSdk = Build.API_LEVELS.API_34)
  @TargetApi(Build.API_LEVELS.API_34)
  public void whenUsingCachedEngine_predictiveBackStateIsSaved() {
    FlutterLoader mockFlutterLoader = mock(FlutterLoader.class);
    FlutterJNI mockFlutterJni = mock(FlutterJNI.class);
    when(mockFlutterJni.isAttached()).thenReturn(true);
    FlutterEngine cachedEngine = new FlutterEngine(ctx, mockFlutterLoader, mockFlutterJni);
    FlutterEngineCache.getInstance().put("my_cached_engine", cachedEngine);

    ActivityScenario<FlutterFragmentActivity> flutterFragmentActivityActivityScenario =
        ActivityScenario.launch(FlutterFragmentActivity.class);

    // Set to framework handling and then recreate the activity and check the state is preserved.
    flutterFragmentActivityActivityScenario.onActivity(
        activity -> {
          FlutterFragment flutterFragment = activity.retrieveExistingFlutterFragmentIfPossible();
          flutterFragment.setFrameworkHandlesBack(true);
          Bundle bundle = flutterFragment.getArguments();
          bundle.putString(ARG_CACHED_ENGINE_ID, "my_cached_engine");
          bundle.putBoolean(ARG_DESTROY_ENGINE_WITH_FRAGMENT, false);
          FlutterEngineCache.getInstance().put("my_cached_engine", cachedEngine);
          flutterFragment.setArguments(bundle);
        });

    flutterFragmentActivityActivityScenario.recreate();

    flutterFragmentActivityActivityScenario.onActivity(
        activity -> {
          assertTrue(
              activity
                  .retrieveExistingFlutterFragmentIfPossible()
                  .onBackPressedCallback
                  .isEnabled());
        });

    // Clean up.
    flutterFragmentActivityActivityScenario.close();
  }

  @Test
  @Config(minSdk = Build.API_LEVELS.API_34)
  @TargetApi(Build.API_LEVELS.API_34)
  public void onBackPressedCallsGetForwardedToFragment() {
    FlutterFragmentActivityWithProvidedEngine activity =
        spy(Robolectric.buildActivity(FlutterFragmentActivityWithProvidedEngine.class).get());

    FlutterFragment fragment = mock(FlutterFragment.class);
    when(activity.retrieveExistingFlutterFragmentIfPossible()).thenReturn(null, fragment);
    FlutterEngine engine = mock(FlutterEngine.class);
    when(fragment.getFlutterEngine()).thenReturn(engine);
    activity.onCreate(null);

    activity.onBackPressed();
    verify(fragment).onBackPressed();
  }

  @Test
  @Config(minSdk = Build.API_LEVELS.API_34)
  @TargetApi(Build.API_LEVELS.API_34)
  public void whenNotUsingCachedEngine_predictiveBackStateIsNotSaved() {
    ActivityScenario<FlutterActivity> flutterActivityScenario =
        ActivityScenario.launch(FlutterActivity.class);

    // Set to framework handling and then recreate the activity and check the state is preserved.
    flutterActivityScenario.onActivity(activity -> activity.setFrameworkHandlesBack(true));

    flutterActivityScenario.recreate();
    flutterActivityScenario.onActivity(activity -> assertFalse(activity.hasRegisteredBackCallback));

    // Clean up.
    flutterActivityScenario.close();
  }

  @Test
  public void createFlutterFragment_enablesShouldAutomaticallyHandleOnBackPressedByDefault() {
    final FlutterFragmentActivity newEngineActivity = new FakeFlutterFragmentActivity();
    assertTrue(
        newEngineActivity
            .createFlutterFragment()
            .getArguments()
            .getBoolean(ARG_SHOULD_AUTOMATICALLY_HANDLE_ON_BACK_PRESSED));

    final FlutterFragmentActivity cachedEngineActivity =
        new FakeFlutterFragmentActivity() {
          @Override
          public String getCachedEngineId() {
            return "my_cached_engine";
          }
        };
    assertTrue(
        cachedEngineActivity
            .createFlutterFragment()
            .getArguments()
            .getBoolean(ARG_SHOULD_AUTOMATICALLY_HANDLE_ON_BACK_PRESSED));

    final FlutterFragmentActivity engineGroupActivity =
        new FakeFlutterFragmentActivity() {
          @Override
          public String getCachedEngineGroupId() {
            return "my_cached_engine_group";
          }
        };
    assertTrue(
        engineGroupActivity
            .createFlutterFragment()
            .getArguments()
            .getBoolean(ARG_SHOULD_AUTOMATICALLY_HANDLE_ON_BACK_PRESSED));
  }

  @Test
  @Config(sdk = Build.API_LEVELS.API_33)
  @TargetApi(Build.API_LEVELS.API_33)
  public void itDelegatesOnBackPressedWithSetFrameworkHandlesBackForSdk33() {
    // At the root route (setFrameworkHandlesBack=false by default), dispatching back is not
    // intercepted by FlutterFragment and falls through to ComponentActivity's fallback
    // (Activity.onBackPressed()), which finishes the FlutterFragmentActivity.
    try (ActivityScenario<FlutterFragmentActivity> rootScenario =
        ActivityScenario.launch(FlutterFragmentActivity.class)) {
      rootScenario.onActivity(
          activity -> {
            FlutterFragment fragment = activity.retrieveExistingFlutterFragmentIfPossible();
            assertNotNull(fragment);
            assertFalse(fragment.onBackPressedCallback.isEnabled());

            FlutterActivityAndFragmentDelegate mockDelegate = installMockDelegate(fragment);

            activity.getOnBackPressedDispatcher().onBackPressed();
            verify(mockDelegate, never()).onBackPressed();
            assertTrue(activity.isFinishing());
          });
    }

    // When a route is pushed (setFrameworkHandlesBack=true), back is forwarded to the Flutter
    // delegate without finishing the activity; once popped back to root
    // (setFrameworkHandlesBack=false), the next back falls through and finishes the activity.
    try (ActivityScenario<FlutterFragmentActivity> pushedRouteScenario =
        ActivityScenario.launch(FlutterFragmentActivity.class)) {
      pushedRouteScenario.onActivity(
          activity -> {
            FlutterFragment fragment = activity.retrieveExistingFlutterFragmentIfPossible();
            assertNotNull(fragment);

            FlutterActivityAndFragmentDelegate mockDelegate = installMockDelegate(fragment);

            fragment.setFrameworkHandlesBack(true);
            assertTrue(fragment.onBackPressedCallback.isEnabled());
            activity.getOnBackPressedDispatcher().onBackPressed();
            verify(mockDelegate, times(1)).onBackPressed();
            assertFalse(activity.isFinishing());

            fragment.setFrameworkHandlesBack(false);
            assertFalse(fragment.onBackPressedCallback.isEnabled());
            activity.getOnBackPressedDispatcher().onBackPressed();
            verify(mockDelegate, times(1)).onBackPressed();
            assertTrue(activity.isFinishing());
          });
    }
  }

  @Test
  @Config(minSdk = Build.API_LEVELS.API_34)
  @TargetApi(Build.API_LEVELS.API_34)
  public void itDelegatesPredictiveBackGestureEventsWithSetFrameworkHandlesBackForSdk34OrHigher() {
    try (ActivityScenario<FlutterFragmentActivity> scenario =
        ActivityScenario.launch(FlutterFragmentActivity.class)) {
      scenario.onActivity(
          activity -> {
            FlutterFragment fragment = activity.retrieveExistingFlutterFragmentIfPossible();
            assertNotNull(fragment);
            assertFalse(fragment.onBackPressedCallback.isEnabled());

            // Verify that FlutterFragment's PlatformPlugin wiring
            // (SystemNavigator.setFrameworkHandlesBack
            // -> PlatformChannel -> PlatformPlugin -> FlutterFragment.setFrameworkHandlesBack)
            // directly controls fragment.onBackPressedCallback.isEnabled().
            FlutterEngine mockEngine = mock(FlutterEngine.class);
            PlatformChannel mockPlatformChannel = mock(PlatformChannel.class);
            when(mockEngine.getPlatformChannel()).thenReturn(mockPlatformChannel);
            ArgumentCaptor<PlatformChannel.PlatformMessageHandler> handlerCaptor =
                ArgumentCaptor.forClass(PlatformChannel.PlatformMessageHandler.class);
            fragment.providePlatformPlugin(activity, mockEngine);
            verify(mockPlatformChannel).setPlatformMessageHandler(handlerCaptor.capture());

            FlutterActivityAndFragmentDelegate mockDelegate = installMockDelegate(fragment);

            BackEventCompat mockBackEvent = mock(BackEventCompat.class);
            BackEvent mockPlatformBackEvent = mock(BackEvent.class);
            when(mockBackEvent.toBackEvent()).thenReturn(mockPlatformBackEvent);
            OnBackPressedDispatcher dispatcher = activity.getOnBackPressedDispatcher();

            // When setFrameworkHandlesBack is false (default at root route), in-flight predictive
            // back events are not forwarded to the Flutter delegate.
            dispatcher.dispatchOnBackStarted(mockBackEvent);
            dispatcher.dispatchOnBackProgressed(mockBackEvent);
            dispatcher.dispatchOnBackCancelled();
            verify(mockDelegate, never()).startBackGesture(any());
            verify(mockDelegate, never()).updateBackGestureProgress(any());
            verify(mockDelegate, never()).commitBackGesture();
            verify(mockDelegate, never()).cancelBackGesture();
            verify(mockDelegate, never()).onBackPressed();
            assertFalse(activity.isFinishing());

            // When a route is pushed and SystemNavigator.setFrameworkHandlesBack(true) is received,
            // predictive back gesture events are forwarded to the delegate for route transitions.
            handlerCaptor.getValue().setFrameworkHandlesBack(true);
            assertTrue(fragment.onBackPressedCallback.isEnabled());
            dispatcher.dispatchOnBackStarted(mockBackEvent);
            dispatcher.dispatchOnBackProgressed(mockBackEvent);
            dispatcher.onBackPressed();
            verify(mockDelegate, times(1)).startBackGesture(mockPlatformBackEvent);
            verify(mockDelegate, times(1)).updateBackGestureProgress(mockPlatformBackEvent);
            verify(mockDelegate, times(1)).commitBackGesture();
            verify(mockDelegate, never()).cancelBackGesture();
            verify(mockDelegate, never()).onBackPressed();
            assertFalse(activity.isFinishing());

            // Once popped back to the root route (setFrameworkHandlesBack(false)), subsequent
            // back gestures are not intercepted by the fragment callback and fall through to
            // ComponentActivity's fallback (Activity.onBackPressed()), finishing the activity.
            handlerCaptor.getValue().setFrameworkHandlesBack(false);
            assertFalse(fragment.onBackPressedCallback.isEnabled());
            dispatcher.dispatchOnBackStarted(mockBackEvent);
            dispatcher.dispatchOnBackProgressed(mockBackEvent);
            dispatcher.onBackPressed();
            verify(mockDelegate, times(1)).startBackGesture(any());
            verify(mockDelegate, times(1)).updateBackGestureProgress(any());
            verify(mockDelegate, times(1)).commitBackGesture();
            assertTrue(activity.isFinishing());
          });
    }
  }

  @Test
  @Config(minSdk = Build.API_LEVELS.API_34)
  @TargetApi(Build.API_LEVELS.API_34)
  public void itCancelsAndRestartsPredictiveBackGestureForSdk34OrHigher() {
    try (ActivityScenario<FlutterFragmentActivity> scenario =
        ActivityScenario.launch(FlutterFragmentActivity.class)) {
      scenario.onActivity(
          activity -> {
            FlutterFragment fragment = activity.retrieveExistingFlutterFragmentIfPossible();
            assertNotNull(fragment);

            FlutterActivityAndFragmentDelegate mockDelegate = installMockDelegate(fragment);

            fragment.setFrameworkHandlesBack(true);
            BackEventCompat mockBackEvent = mock(BackEventCompat.class);
            BackEvent mockPlatformBackEvent = mock(BackEvent.class);
            when(mockBackEvent.toBackEvent()).thenReturn(mockPlatformBackEvent);
            OnBackPressedDispatcher dispatcher = activity.getOnBackPressedDispatcher();

            // Start and progress a back swipe, then cancel it.
            dispatcher.dispatchOnBackStarted(mockBackEvent);
            dispatcher.dispatchOnBackProgressed(mockBackEvent);
            dispatcher.dispatchOnBackCancelled();
            verify(mockDelegate, times(1)).startBackGesture(mockPlatformBackEvent);
            verify(mockDelegate, times(1)).updateBackGestureProgress(mockPlatformBackEvent);
            verify(mockDelegate, times(1)).cancelBackGesture();
            verify(mockDelegate, never()).commitBackGesture();
            assertTrue(fragment.onBackPressedCallback.isEnabled());
            assertFalse(activity.isFinishing());

            // Starting a subsequent back swipe and committing it succeeds without being blocked.
            dispatcher.dispatchOnBackStarted(mockBackEvent);
            dispatcher.dispatchOnBackProgressed(mockBackEvent);
            dispatcher.onBackPressed();
            verify(mockDelegate, times(2)).startBackGesture(mockPlatformBackEvent);
            verify(mockDelegate, times(2)).updateBackGestureProgress(mockPlatformBackEvent);
            verify(mockDelegate, times(1)).cancelBackGesture();
            verify(mockDelegate, times(1)).commitBackGesture();
            assertFalse(activity.isFinishing());
          });
    }
  }

  @Test
  @Config(minSdk = Build.API_LEVELS.API_34)
  @TargetApi(Build.API_LEVELS.API_34)
  public void itHandlesPopSystemNavigationWithPredictiveBackCallbackEnabled() {
    try (ActivityScenario<FlutterFragmentActivity> scenario =
        ActivityScenario.launch(FlutterFragmentActivity.class)) {
      scenario.onActivity(
          activity -> {
            FlutterFragment fragment = activity.retrieveExistingFlutterFragmentIfPossible();
            assertNotNull(fragment);
            fragment.setFrameworkHandlesBack(true);

            FlutterActivityAndFragmentDelegate mockDelegate = installMockDelegate(fragment);

            assertTrue(fragment.onBackPressedCallback.isEnabled());
            assertFalse(activity.isFinishing());
            assertTrue(fragment.popSystemNavigator());

            // Inside a real FlutterFragmentActivity host on API 34+, popSystemNavigator()
            // temporarily disables the fragment's callback, dispatches back to
            // ComponentActivity's fallback (finishing the activity), and restores the fragment
            // callback's enabled state without re-entering commitBackGesture() or onBackPressed().
            assertTrue(activity.isFinishing());
            assertTrue(fragment.onBackPressedCallback.isEnabled());
            verify(mockDelegate, never()).commitBackGesture();
            verify(mockDelegate, never()).onBackPressed();
          });
    }
  }

  @Test
  public void getCachedEngineId_returnsIdWhenSelfSent() {
    Intent intent = FlutterFragmentActivity.withCachedEngine("my_cached_engine").build(ctx);
    ActivityController<FlutterFragmentActivity> activityController =
        Robolectric.buildActivity(FlutterFragmentActivity.class, intent);
    FlutterFragmentActivity flutterActivity = activityController.get();

    try (MockedStatic<IntentUtils> mockedIntentUtils = mockStatic(IntentUtils.class)) {
      mockedIntentUtils
          .when(
              () ->
                  IntentUtils.safeGetStringExtra(
                      any(), eq(FlutterActivityLaunchConfigs.EXTRA_CACHED_ENGINE_ID)))
          .thenReturn("my_cached_engine");
      assertEquals("my_cached_engine", flutterActivity.getCachedEngineId());
    }
  }

  @Test
  public void getCachedEngineId_returnsNullWhenNotSelfSent() {
    Intent intent = FlutterFragmentActivity.withCachedEngine("my_cached_engine").build(ctx);
    ActivityController<FlutterFragmentActivity> activityController =
        Robolectric.buildActivity(FlutterFragmentActivity.class, intent);
    FlutterFragmentActivity flutterActivity = activityController.get();

    try (MockedStatic<IntentUtils> mockedIntentUtils = mockStatic(IntentUtils.class)) {
      mockedIntentUtils
          .when(
              () ->
                  IntentUtils.safeGetStringExtra(
                      any(), eq(FlutterActivityLaunchConfigs.EXTRA_CACHED_ENGINE_ID)))
          .thenReturn(null);
      assertNull(flutterActivity.getCachedEngineId());
    }
  }

  @Test
  public void getCachedEngineGroupId_returnsIdWhenSelfSent() {
    Intent intent =
        FlutterFragmentActivity.withNewEngineInGroup("my_cached_engine_group")
            .dartEntrypoint("main")
            .build(ctx);
    ActivityController<FlutterFragmentActivity> activityController =
        Robolectric.buildActivity(FlutterFragmentActivity.class, intent);
    FlutterFragmentActivity flutterActivity = activityController.get();

    try (MockedStatic<IntentUtils> mockedIntentUtils = mockStatic(IntentUtils.class)) {
      mockedIntentUtils
          .when(
              () ->
                  IntentUtils.safeGetStringExtra(
                      any(), eq(FlutterActivityLaunchConfigs.EXTRA_CACHED_ENGINE_GROUP_ID)))
          .thenReturn("my_cached_engine_group");
      assertEquals("my_cached_engine_group", flutterActivity.getCachedEngineGroupId());
    }
  }

  @Test
  public void getCachedEngineGroupId_returnsNullWhenNotSelfSent() {
    Intent intent =
        FlutterFragmentActivity.withNewEngineInGroup("my_cached_engine_group")
            .dartEntrypoint("main")
            .build(ctx);
    ActivityController<FlutterFragmentActivity> activityController =
        Robolectric.buildActivity(FlutterFragmentActivity.class, intent);
    FlutterFragmentActivity flutterActivity = activityController.get();

    try (MockedStatic<IntentUtils> mockedIntentUtils = mockStatic(IntentUtils.class)) {
      mockedIntentUtils
          .when(
              () ->
                  IntentUtils.safeGetStringExtra(
                      any(), eq(FlutterActivityLaunchConfigs.EXTRA_CACHED_ENGINE_GROUP_ID)))
          .thenReturn(null);
      assertNull(flutterActivity.getCachedEngineGroupId());
    }
  }

  @Test
  public void getDartEntrypointFunctionName_returnsNameWhenSelfSent() {
    Intent intent =
        FlutterFragmentActivity.withNewEngine()
            .build(ctx)
            .putExtra(FlutterActivityLaunchConfigs.EXTRA_DART_ENTRYPOINT, "custom_entrypoint");
    ActivityController<FlutterFragmentActivity> activityController =
        Robolectric.buildActivity(FlutterFragmentActivity.class, intent);
    FlutterFragmentActivity flutterActivity = activityController.get();

    try (MockedStatic<IntentUtils> mockedIntentUtils = mockStatic(IntentUtils.class)) {
      mockedIntentUtils
          .when(
              () ->
                  IntentUtils.safeGetStringExtra(
                      any(), eq(FlutterActivityLaunchConfigs.EXTRA_DART_ENTRYPOINT)))
          .thenReturn("custom_entrypoint");
      assertEquals("custom_entrypoint", flutterActivity.getDartEntrypointFunctionName());
    }
  }

  @Test
  public void getDartEntrypointFunctionName_returnsDefaultWhenNotSelfSent() {
    Intent intent =
        FlutterFragmentActivity.withNewEngine()
            .build(ctx)
            .putExtra(FlutterActivityLaunchConfigs.EXTRA_DART_ENTRYPOINT, "custom_entrypoint");
    ActivityController<FlutterFragmentActivity> activityController =
        Robolectric.buildActivity(FlutterFragmentActivity.class, intent);
    FlutterFragmentActivity flutterActivity = activityController.get();

    try (MockedStatic<IntentUtils> mockedIntentUtils = mockStatic(IntentUtils.class)) {
      mockedIntentUtils
          .when(
              () ->
                  IntentUtils.safeGetStringExtra(
                      any(), eq(FlutterActivityLaunchConfigs.EXTRA_DART_ENTRYPOINT)))
          .thenReturn(null);
      assertEquals("main", flutterActivity.getDartEntrypointFunctionName());
    }
  }

  @Test
  public void getDartEntrypointArgs_returnsArgsWhenSelfSent() {
    Intent intent =
        FlutterFragmentActivity.withNewEngine()
            .dartEntrypointArgs(new ArrayList<String>(Arrays.asList("foo", "bar")))
            .build(ctx);
    ActivityController<FlutterFragmentActivity> activityController =
        Robolectric.buildActivity(FlutterFragmentActivity.class, intent);
    FlutterFragmentActivity flutterActivity = activityController.get();

    try (MockedStatic<IntentUtils> mockedIntentUtils = mockStatic(IntentUtils.class)) {
      mockedIntentUtils
          .when(
              () ->
                  IntentUtils.safeGetSerializableExtra(
                      any(), eq(FlutterActivityLaunchConfigs.EXTRA_DART_ENTRYPOINT_ARGS)))
          .thenReturn(new ArrayList<String>(Arrays.asList("foo", "bar")));
      assertEquals(Arrays.asList("foo", "bar"), flutterActivity.getDartEntrypointArgs());
    }
  }

  @Test
  public void getDartEntrypointArgs_returnsNullWhenNotSelfSent() {
    Intent intent =
        FlutterFragmentActivity.withNewEngine()
            .dartEntrypointArgs(new ArrayList<String>(Arrays.asList("foo", "bar")))
            .build(ctx);
    ActivityController<FlutterFragmentActivity> activityController =
        Robolectric.buildActivity(FlutterFragmentActivity.class, intent);
    FlutterFragmentActivity flutterActivity = activityController.get();

    try (MockedStatic<IntentUtils> mockedIntentUtils = mockStatic(IntentUtils.class)) {
      mockedIntentUtils
          .when(
              () ->
                  IntentUtils.safeGetSerializableExtra(
                      any(), eq(FlutterActivityLaunchConfigs.EXTRA_DART_ENTRYPOINT_ARGS)))
          .thenReturn(null);
      assertNull(flutterActivity.getDartEntrypointArgs());
    }
  }

  @Test
  public void getInitialRoute_returnsRouteWhenSelfSent() {
    Intent intent =
        FlutterFragmentActivity.withNewEngine().initialRoute("/custom/route").build(ctx);
    ActivityController<FlutterFragmentActivity> activityController =
        Robolectric.buildActivity(FlutterFragmentActivity.class, intent);
    FlutterFragmentActivity flutterActivity = activityController.get();

    try (MockedStatic<IntentUtils> mockedIntentUtils = mockStatic(IntentUtils.class)) {
      mockedIntentUtils
          .when(
              () ->
                  IntentUtils.safeGetStringExtra(
                      any(), eq(FlutterActivityLaunchConfigs.EXTRA_INITIAL_ROUTE)))
          .thenReturn("/custom/route");
      assertEquals("/custom/route", flutterActivity.getInitialRoute());
    }
  }

  @Test
  public void getInitialRoute_returnsNullWhenNotSelfSent() {
    Intent intent =
        FlutterFragmentActivity.withNewEngine().initialRoute("/custom/route").build(ctx);
    ActivityController<FlutterFragmentActivity> activityController =
        Robolectric.buildActivity(FlutterFragmentActivity.class, intent);
    FlutterFragmentActivity flutterActivity = activityController.get();

    try (MockedStatic<IntentUtils> mockedIntentUtils = mockStatic(IntentUtils.class)) {
      mockedIntentUtils
          .when(
              () ->
                  IntentUtils.safeGetStringExtra(
                      any(), eq(FlutterActivityLaunchConfigs.EXTRA_INITIAL_ROUTE)))
          .thenReturn(null);
      assertNull(flutterActivity.getInitialRoute());
    }
  }

  @Test
  public void getInitialRoute_returnsRouteFromMetaDataWhenNotSelfSent()
      throws PackageManager.NameNotFoundException {
    Intent intent =
        FlutterFragmentActivity.withNewEngine().initialRoute("/custom/route").build(ctx);
    ActivityController<FlutterFragmentActivity> activityController =
        Robolectric.buildActivity(FlutterFragmentActivity.class, intent);
    FlutterFragmentActivity flutterActivity = spy(activityController.get());

    Bundle bundle = new Bundle();
    bundle.putString(FlutterActivityLaunchConfigs.INITIAL_ROUTE_META_DATA_KEY, "/meta/route");
    when(flutterActivity.getMetaData()).thenReturn(bundle);

    try (MockedStatic<IntentUtils> mockedIntentUtils = mockStatic(IntentUtils.class)) {
      mockedIntentUtils
          .when(
              () ->
                  IntentUtils.safeGetStringExtra(
                      any(), eq(FlutterActivityLaunchConfigs.EXTRA_INITIAL_ROUTE)))
          .thenReturn(null);
      assertEquals("/meta/route", flutterActivity.getInitialRoute());
    }
  }

  @Test
  public void getDartEntrypointFunctionName_returnsNameFromMetaDataWhenNotSelfSent()
      throws PackageManager.NameNotFoundException {
    Intent intent =
        FlutterFragmentActivity.withNewEngine()
            .build(ctx)
            .putExtra(FlutterActivityLaunchConfigs.EXTRA_DART_ENTRYPOINT, "custom_entrypoint");
    ActivityController<FlutterFragmentActivity> activityController =
        Robolectric.buildActivity(FlutterFragmentActivity.class, intent);
    FlutterFragmentActivity flutterActivity = spy(activityController.get());

    Bundle bundle = new Bundle();
    bundle.putString(FlutterActivityLaunchConfigs.DART_ENTRYPOINT_META_DATA_KEY, "meta_entrypoint");
    when(flutterActivity.getMetaData()).thenReturn(bundle);

    try (MockedStatic<IntentUtils> mockedIntentUtils = mockStatic(IntentUtils.class)) {
      mockedIntentUtils
          .when(
              () ->
                  IntentUtils.safeGetStringExtra(
                      any(), eq(FlutterActivityLaunchConfigs.EXTRA_DART_ENTRYPOINT)))
          .thenReturn(null);
      assertEquals("meta_entrypoint", flutterActivity.getDartEntrypointFunctionName());
    }
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

    public static NewEngineInGroupIntentBuilder withNewEngineInGroup(
        @NonNull String engineGroupId) {
      return new NewEngineInGroupIntentBuilder(
          FlutterFragmentActivityWithIntentBuilders.class, engineGroupId);
    }
  }
}
