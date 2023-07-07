// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import static org.junit.Assert.assertArrayEquals;
import static org.junit.Assert.fail;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.content.res.AssetManager;
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterAssets;
import io.flutter.plugins.webviewflutter.FlutterAssetManager.PluginBindingFlutterAssetManager;
import java.io.IOException;
import org.junit.Before;
import org.junit.Test;
import org.mockito.Mock;

public class PluginBindingFlutterAssetManagerTest {
  @Mock AssetManager mockAssetManager;
  @Mock FlutterAssets mockFlutterAssets;

  PluginBindingFlutterAssetManager tesPluginBindingFlutterAssetManager;

  @Before
  public void setUp() {
    mockAssetManager = mock(AssetManager.class);
    mockFlutterAssets = mock(FlutterAssets.class);

    tesPluginBindingFlutterAssetManager =
        new PluginBindingFlutterAssetManager(mockAssetManager, mockFlutterAssets);
  }

  @Test
  public void list() {
    try {
      when(mockAssetManager.list("test/path"))
          .thenReturn(new String[] {"index.html", "styles.css"});
      String[] actualFilePaths = tesPluginBindingFlutterAssetManager.list("test/path");
      verify(mockAssetManager).list("test/path");
      assertArrayEquals(new String[] {"index.html", "styles.css"}, actualFilePaths);
    } catch (IOException ex) {
      fail();
    }
  }

  @Test
  public void registrar_getAssetFilePathByName() {
    tesPluginBindingFlutterAssetManager.getAssetFilePathByName("sample_movie.mp4");
    verify(mockFlutterAssets).getAssetFilePathByName("sample_movie.mp4");
  }
}
