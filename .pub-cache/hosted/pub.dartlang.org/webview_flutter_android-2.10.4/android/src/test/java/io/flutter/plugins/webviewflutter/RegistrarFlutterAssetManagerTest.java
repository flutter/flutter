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
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.plugins.webviewflutter.FlutterAssetManager.RegistrarFlutterAssetManager;
import java.io.IOException;
import org.junit.Before;
import org.junit.Test;
import org.mockito.Mock;

@SuppressWarnings("deprecation")
public class RegistrarFlutterAssetManagerTest {
  @Mock AssetManager mockAssetManager;
  @Mock Registrar mockRegistrar;

  RegistrarFlutterAssetManager testRegistrarFlutterAssetManager;

  @Before
  public void setUp() {
    mockAssetManager = mock(AssetManager.class);
    mockRegistrar = mock(Registrar.class);

    testRegistrarFlutterAssetManager =
        new RegistrarFlutterAssetManager(mockAssetManager, mockRegistrar);
  }

  @Test
  public void list() {
    try {
      when(mockAssetManager.list("test/path"))
          .thenReturn(new String[] {"index.html", "styles.css"});
      String[] actualFilePaths = testRegistrarFlutterAssetManager.list("test/path");
      verify(mockAssetManager).list("test/path");
      assertArrayEquals(new String[] {"index.html", "styles.css"}, actualFilePaths);
    } catch (IOException ex) {
      fail();
    }
  }

  @Test
  public void registrar_getAssetFilePathByName() {
    testRegistrarFlutterAssetManager.getAssetFilePathByName("sample_movie.mp4");
    verify(mockRegistrar).lookupKeyForAsset("sample_movie.mp4");
  }
}
