// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.loader;

import static junit.framework.TestCase.assertFalse;
import static junit.framework.TestCase.assertTrue;

import io.flutter.FlutterInjector;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class FlutterLoaderTest {
  @Before
  public void setUp() {
    FlutterInjector.reset();
  }

  @Test
  public void itReportsUninitializedAfterCreating() {
    FlutterLoader flutterLoader = new FlutterLoader();
    assertFalse(flutterLoader.initialized());
  }

  @Test
  public void itReportsInitializedAfterInitializing() {
    FlutterInjector.setInstance(new FlutterInjector.Builder().setShouldLoadNative(false).build());
    FlutterLoader flutterLoader = new FlutterLoader();

    assertFalse(flutterLoader.initialized());
    flutterLoader.startInitialization(RuntimeEnvironment.application);
    flutterLoader.ensureInitializationComplete(RuntimeEnvironment.application, null);
    assertTrue(flutterLoader.initialized());
    FlutterInjector.reset();
  }
}
