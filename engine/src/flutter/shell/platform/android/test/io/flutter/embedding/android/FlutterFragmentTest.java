package io.flutter.embedding.android;

import static org.junit.Assert.assertArrayEquals;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import androidx.activity.OnBackPressedCallback;
import androidx.fragment.app.FragmentActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterEngineCache;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.embedding.engine.loader.FlutterLoader;
import java.util.concurrent.atomic.AtomicBoolean;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class FlutterFragmentTest {
  boolean isDelegateAttached;

  @Test
  public void itCreatesDefaultFragmentWithExpectedDefaults() {
    FlutterFragment fragment = FlutterFragment.createDefault();
    fragment.setDelegate(new FlutterActivityAndFragmentDelegate(fragment));

    assertEquals("main", fragment.getDartEntrypointFunctionName());
    assertNull(fragment.getDartEntrypointLibraryUri());
    assertEquals("/", fragment.getInitialRoute());
    assertArrayEquals(new String[] {}, fragment.getFlutterShellArgs().toArray());
    assertTrue(fragment.shouldAttachEngineToActivity());
    assertFalse(fragment.shouldHandleDeeplinking());
    assertNull(fragment.getCachedEngineId());
    assertTrue(fragment.shouldDestroyEngineWithHost());
    assertEquals(RenderMode.surface, fragment.getRenderMode());
    assertEquals(TransparencyMode.transparent, fragment.getTransparencyMode());
    assertFalse(fragment.shouldDelayFirstAndroidViewDraw());
  }

  @Test
  public void itCreatesNewEngineFragmentWithRequestedSettings() {
    FlutterFragment fragment =
        FlutterFragment.withNewEngine()
            .dartEntrypoint("custom_entrypoint")
            .dartLibraryUri("package:foo/bar.dart")
            .initialRoute("/custom/route")
            .shouldAttachEngineToActivity(false)
            .handleDeeplinking(true)
            .renderMode(RenderMode.texture)
            .transparencyMode(TransparencyMode.opaque)
            .build();
    fragment.setDelegate(new FlutterActivityAndFragmentDelegate(fragment));

    assertEquals("custom_entrypoint", fragment.getDartEntrypointFunctionName());
    assertEquals("package:foo/bar.dart", fragment.getDartEntrypointLibraryUri());
    assertEquals("/custom/route", fragment.getInitialRoute());
    assertArrayEquals(new String[] {}, fragment.getFlutterShellArgs().toArray());
    assertFalse(fragment.shouldAttachEngineToActivity());
    assertTrue(fragment.shouldHandleDeeplinking());
    assertNull(fragment.getCachedEngineId());
    assertTrue(fragment.shouldDestroyEngineWithHost());
    assertEquals(RenderMode.texture, fragment.getRenderMode());
    assertEquals(TransparencyMode.opaque, fragment.getTransparencyMode());
  }

  @Test
  public void itCreatesNewEngineFragmentThatDelaysFirstDrawWhenRequested() {
    FlutterFragment fragment =
        FlutterFragment.withNewEngine().shouldDelayFirstAndroidViewDraw(true).build();

    assertNotNull(fragment.shouldDelayFirstAndroidViewDraw());
  }

  @Test
  public void itCreatesCachedEngineFragmentWithExpectedDefaults() {
    FlutterFragment fragment = FlutterFragment.withCachedEngine("my_cached_engine").build();

    assertTrue(fragment.shouldAttachEngineToActivity());
    assertEquals("my_cached_engine", fragment.getCachedEngineId());
    assertFalse(fragment.shouldDestroyEngineWithHost());
    assertFalse(fragment.shouldDelayFirstAndroidViewDraw());
  }

  @Test
  public void itCreatesCachedEngineFragmentThatDestroysTheEngine() {
    FlutterFragment fragment =
        FlutterFragment.withCachedEngine("my_cached_engine")
            .destroyEngineWithFragment(true)
            .build();

    assertTrue(fragment.shouldAttachEngineToActivity());
    assertEquals("my_cached_engine", fragment.getCachedEngineId());
    assertTrue(fragment.shouldDestroyEngineWithHost());
  }

  @Test
  public void itCreatesCachedEngineFragmentThatDelaysFirstDrawWhenRequested() {
    FlutterFragment fragment =
        FlutterFragment.withCachedEngine("my_cached_engine")
            .shouldDelayFirstAndroidViewDraw(true)
            .build();

    assertNotNull(fragment.shouldDelayFirstAndroidViewDraw());
  }

  @Test
  public void itCanBeDetachedFromTheEngineAndStopSendingFurtherEvents() {
    FlutterActivityAndFragmentDelegate mockDelegate =
        mock(FlutterActivityAndFragmentDelegate.class);
    FlutterFragment fragment =
        FlutterFragment.withCachedEngine("my_cached_engine")
            .destroyEngineWithFragment(true)
            .build();

    isDelegateAttached = true;
    when(mockDelegate.isAttached()).thenAnswer(invocation -> isDelegateAttached);
    doAnswer(invocation -> isDelegateAttached = false).when(mockDelegate).onDetach();

    fragment.setDelegate(mockDelegate);
    fragment.onStart();
    fragment.onResume();
    fragment.onPostResume();

    verify(mockDelegate, times(1)).onStart();
    verify(mockDelegate, times(1)).onResume();
    verify(mockDelegate, times(1)).onPostResume();

    fragment.onPause();
    fragment.detachFromFlutterEngine();
    verify(mockDelegate, times(1)).onPause();
    verify(mockDelegate, times(1)).onDestroyView();
    verify(mockDelegate, times(1)).onDetach();

    fragment.onStop();
    verify(mockDelegate, never()).onStop();

    fragment.onStart();
    fragment.onResume();
    fragment.onPostResume();
    // No more events through to the delegate.
    verify(mockDelegate, times(1)).onStart();
    verify(mockDelegate, times(1)).onResume();
    verify(mockDelegate, times(1)).onPostResume();

    fragment.onDestroy();
    // 1 time same as before.
    verify(mockDelegate, times(1)).onDestroyView();
    verify(mockDelegate, times(1)).onDetach();
  }

  @Test
  public void itDoesNotReleaseEnginewhenDetachFromFlutterEngine() {
    FlutterActivityAndFragmentDelegate mockDelegate =
        mock(FlutterActivityAndFragmentDelegate.class);
    isDelegateAttached = true;
    when(mockDelegate.isAttached()).thenAnswer(invocation -> isDelegateAttached);
    doAnswer(invocation -> isDelegateAttached = false).when(mockDelegate).onDetach();

    FlutterFragment fragment =
        FlutterFragment.withCachedEngine("my_cached_engine")
            .destroyEngineWithFragment(true)
            .build();

    fragment.setDelegate(mockDelegate);
    fragment.onStart();
    fragment.onResume();
    fragment.onPostResume();
    fragment.onPause();

    assertTrue(mockDelegate.isAttached());
    fragment.detachFromFlutterEngine();
    verify(mockDelegate, times(1)).onDetach();
    verify(mockDelegate, never()).release();
    assertFalse(mockDelegate.isAttached());
  }

  @Test
  public void itReleaseEngineWhenOnDetach() {
    FlutterActivityAndFragmentDelegate mockDelegate =
        mock(FlutterActivityAndFragmentDelegate.class);
    isDelegateAttached = true;
    when(mockDelegate.isAttached()).thenAnswer(invocation -> isDelegateAttached);
    doAnswer(invocation -> isDelegateAttached = false).when(mockDelegate).onDetach();

    FlutterFragment fragment =
        FlutterFragment.withCachedEngine("my_cached_engine")
            .destroyEngineWithFragment(true)
            .build();

    fragment.setDelegate(mockDelegate);
    fragment.onStart();
    fragment.onResume();
    fragment.onPostResume();
    fragment.onPause();

    assertTrue(mockDelegate.isAttached());
    fragment.onDetach();
    verify(mockDelegate, times(1)).onDetach();
    verify(mockDelegate, times(1)).release();
    assertFalse(mockDelegate.isAttached());
  }

  @Test
  public void itDelegatesOnBackPressedAutomaticallyWhenEnabled() {
    // We need to mock FlutterJNI to avoid triggering native code.
    FlutterJNI flutterJNI = mock(FlutterJNI.class);
    when(flutterJNI.isAttached()).thenReturn(true);

    FlutterEngine flutterEngine =
        new FlutterEngine(
            RuntimeEnvironment.application, new FlutterLoader(), flutterJNI, null, false);
    FlutterEngineCache.getInstance().put("my_cached_engine", flutterEngine);

    FlutterFragment fragment =
        FlutterFragment.withCachedEngine("my_cached_engine")
            .shouldAutomaticallyHandleOnBackPressed(true)
            .build();
    FragmentActivity activity = Robolectric.setupActivity(FragmentActivity.class);
    activity
        .getSupportFragmentManager()
        .beginTransaction()
        .add(android.R.id.content, fragment)
        .commitNow();

    FlutterActivityAndFragmentDelegate mockDelegate =
        mock(FlutterActivityAndFragmentDelegate.class);
    isDelegateAttached = true;
    when(mockDelegate.isAttached()).thenAnswer(invocation -> isDelegateAttached);
    doAnswer(invocation -> isDelegateAttached = false).when(mockDelegate).onDetach();
    fragment.setDelegate(mockDelegate);

    activity.onBackPressed();

    verify(mockDelegate, times(1)).onBackPressed();
  }

  @Test
  public void itHandlesPopSystemNavigationAutomaticallyWhenEnabled() {
    // We need to mock FlutterJNI to avoid triggering native code.
    FlutterJNI flutterJNI = mock(FlutterJNI.class);
    when(flutterJNI.isAttached()).thenReturn(true);

    FlutterEngine flutterEngine =
        new FlutterEngine(
            RuntimeEnvironment.application, new FlutterLoader(), flutterJNI, null, false);
    FlutterEngineCache.getInstance().put("my_cached_engine", flutterEngine);

    FlutterFragment fragment =
        FlutterFragment.withCachedEngine("my_cached_engine")
            .shouldAutomaticallyHandleOnBackPressed(true)
            .build();
    FragmentActivity activity = Robolectric.setupActivity(FragmentActivity.class);
    activity
        .getSupportFragmentManager()
        .beginTransaction()
        .add(android.R.id.content, fragment)
        .commitNow();
    final AtomicBoolean onBackPressedCalled = new AtomicBoolean(false);
    OnBackPressedCallback callback =
        new OnBackPressedCallback(true) {
          @Override
          public void handleOnBackPressed() {
            onBackPressedCalled.set(true);
          }
        };
    activity.getOnBackPressedDispatcher().addCallback(callback);

    FlutterActivityAndFragmentDelegate mockDelegate =
        mock(FlutterActivityAndFragmentDelegate.class);
    fragment.setDelegate(mockDelegate);

    assertTrue(fragment.popSystemNavigator());

    verify(mockDelegate, never()).onBackPressed();
    assertTrue(onBackPressedCalled.get());
  }
}
