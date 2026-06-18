// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.android;

import static org.junit.Assert.assertNotNull;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import android.content.Context;
import android.content.Intent;
import androidx.test.core.app.ActivityScenario;
import androidx.test.core.app.ApplicationProvider;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.FlutterInjector;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterEngineCache;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.embedding.engine.loader.FlutterLoader;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;

@RunWith(AndroidJUnit4.class)
public class FlutterFragmentActivityReproductionTest {
  private final Context ctx = ApplicationProvider.getApplicationContext();

  @Before
  public void setUp() {
    FlutterInjector.reset();
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    when(mockFlutterJNI.isAttached()).thenReturn(true);
    FlutterJNI.Factory mockFlutterJNIFactory = mock(FlutterJNI.Factory.class);
    when(mockFlutterJNIFactory.provideFlutterJNI()).thenReturn(mockFlutterJNI);
    FlutterInjector.setInstance(
        new FlutterInjector.Builder().setFlutterJNIFactory(mockFlutterJNIFactory).build());
  }

  @After
  public void tearDown() {
    FlutterInjector.reset();
  }

  @Test
  public void testCachedEngineFallbackOnRecreation() {
    FlutterLoader mockFlutterLoader = mock(FlutterLoader.class);
    FlutterJNI mockFlutterJni = mock(FlutterJNI.class);
    when(mockFlutterJni.isAttached()).thenReturn(true);
    when(mockFlutterLoader.automaticallyRegisterPlugins()).thenReturn(false);

    FlutterEngine cachedEngine =
        new FlutterEngine(ctx, mockFlutterLoader, mockFlutterJni, new String[] {}, false);
    final String cachedEngineId = "reproduction_cached_engine";
    FlutterEngineCache.getInstance().put(cachedEngineId, cachedEngine);

    Intent intent = FlutterFragmentActivity.withCachedEngine(cachedEngineId).build(ctx);

    try (ActivityScenario<FlutterFragmentActivity> scenario = ActivityScenario.launch(intent)) {
      // Remove it from cache to simulate engine being destroyed/removed.
      FlutterEngineCache.getInstance().remove(cachedEngineId);

      // Recreate the activity.
      // With the bug, this will fail with IllegalStateException (wrapped).
      // With the fix, this should succeed.
      scenario.recreate();

      scenario.onActivity(
          activity -> {
            assertNotNull(activity.getFlutterEngine());
          });
    } finally {
      FlutterEngineCache.getInstance().remove(cachedEngineId);
      cachedEngine.destroy();
    }
  }
}
