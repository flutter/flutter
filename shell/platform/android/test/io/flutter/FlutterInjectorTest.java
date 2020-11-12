// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertThrows;

import io.flutter.embedding.engine.loader.FlutterLoader;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class FlutterInjectorTest {
  @Mock FlutterLoader mockFlutterLoader;

  @Before
  public void setUp() {
    // Since the intent is to have a convenient static class to use for production.
    FlutterInjector.reset();
    MockitoAnnotations.initMocks(this);
  }

  @Test
  public void itHasSomeReasonableDefaults() {
    // Implicitly builds when first accessed.
    FlutterInjector injector = FlutterInjector.instance();
    assertNotNull(injector.flutterLoader());
  }

  @Test
  public void canPartiallyOverride() {
    FlutterInjector.setInstance(
        new FlutterInjector.Builder().setFlutterLoader(mockFlutterLoader).build());
    FlutterInjector injector = FlutterInjector.instance();
    assertEquals(injector.flutterLoader(), mockFlutterLoader);
  }

  @Test()
  public void cannotBeChangedOnceRead() {
    FlutterInjector.instance();

    assertThrows(
        IllegalStateException.class,
        () -> {
          FlutterInjector.setInstance(
              new FlutterInjector.Builder().setFlutterLoader(mockFlutterLoader).build());
        });
  }
}
