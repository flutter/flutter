// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.loader;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertThrows;

import androidx.test.ext.junit.runners.AndroidJUnit4;
import org.junit.Test;
import org.junit.runner.RunWith;

@RunWith(AndroidJUnit4.class)
public class FlutterLoaderReproduce180047Test {

  @Test
  public void testFindAppBundlePathThrowsIllegalStateExceptionWhenUninitialized() {
    FlutterLoader flutterLoader = new FlutterLoader();
    IllegalStateException exception =
        assertThrows(
            IllegalStateException.class,
            () -> {
              flutterLoader.findAppBundlePath();
            });
    assertEquals(
        "findAppBundlePath must be called after startInitialization", exception.getMessage());
  }

  @Test
  public void testGetLookupKeyForAssetThrowsIllegalStateExceptionWhenUninitialized() {
    FlutterLoader flutterLoader = new FlutterLoader();
    IllegalStateException exception =
        assertThrows(
            IllegalStateException.class,
            () -> {
              flutterLoader.getLookupKeyForAsset("some_asset");
            });
    assertEquals(
        "getLookupKeyForAsset must be called after startInitialization", exception.getMessage());
  }

  @Test
  public void testAutomaticallyRegisterPluginsThrowsIllegalStateExceptionWhenUninitialized() {
    FlutterLoader flutterLoader = new FlutterLoader();
    IllegalStateException exception =
        assertThrows(
            IllegalStateException.class,
            () -> {
              flutterLoader.automaticallyRegisterPlugins();
            });
    assertEquals(
        "automaticallyRegisterPlugins must be called after startInitialization",
        exception.getMessage());
  }
}
