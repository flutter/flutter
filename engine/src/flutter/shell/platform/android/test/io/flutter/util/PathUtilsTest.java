// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.util;

import static io.flutter.Build.API_LEVELS;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import android.content.Context;
import android.os.Build;
import java.io.File;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;

@RunWith(RobolectricTestRunner.class)
public class PathUtilsTest {

  private static final String APP_DATA_PATH = "/data/data/package_name";

  @Test
  public void canGetFilesDir() {
    Context context = mock(Context.class);
    when(context.getFilesDir()).thenReturn(new File(APP_DATA_PATH + "/files"));
    assertEquals(APP_DATA_PATH + "/files", PathUtils.getFilesDir(context));
  }

  @Test
  public void canOnlyGetFilesPathWhenDiskFullAndFilesDirNotCreated() {
    Context context = mock(Context.class);
    when(context.getFilesDir()).thenReturn(null);
    if (Build.VERSION.SDK_INT >= API_LEVELS.API_24) {
      when(context.getDataDir()).thenReturn(new File(APP_DATA_PATH));
    } else {
      when(context.getApplicationInfo().dataDir).thenReturn(APP_DATA_PATH);
    }
    assertEquals(APP_DATA_PATH + "/files", PathUtils.getFilesDir(context));
  }

  @Test
  public void canGetFlutterDataDir() {
    Context context = mock(Context.class);
    when(context.getDir("flutter", Context.MODE_PRIVATE))
        .thenReturn(new File(APP_DATA_PATH + "/app_flutter"));
    assertEquals(APP_DATA_PATH + "/app_flutter", PathUtils.getDataDirectory(context));
  }

  @Test
  public void canOnlyGetFlutterDataPathWhenDiskFullAndFlutterDataDirNotCreated() {
    Context context = mock(Context.class);
    when(context.getDir("flutter", Context.MODE_PRIVATE)).thenReturn(null);
    if (Build.VERSION.SDK_INT >= API_LEVELS.API_24) {
      when(context.getDataDir()).thenReturn(new File(APP_DATA_PATH));
    } else {
      when(context.getApplicationInfo().dataDir).thenReturn(APP_DATA_PATH);
    }
    assertEquals(APP_DATA_PATH + "/app_flutter", PathUtils.getDataDirectory(context));
  }

  @Test
  public void canGetCacheDir() {
    Context context = mock(Context.class);
    when(context.getCacheDir()).thenReturn(new File(APP_DATA_PATH + "/cache"));
    when(context.getCodeCacheDir()).thenReturn(new File(APP_DATA_PATH + "/code_cache"));
    assertTrue(PathUtils.getCacheDirectory(context).startsWith(APP_DATA_PATH));
  }

  @Test
  public void canOnlyGetCachePathWhenDiskFullAndCacheDirNotCreated() {
    Context context = mock(Context.class);
    when(context.getCacheDir()).thenReturn(null);
    // Requires at least api 21.
    when(context.getCodeCacheDir()).thenReturn(null);
    // Requires at least api 24.
    when(context.getDataDir()).thenReturn(new File(APP_DATA_PATH));
    assertEquals(APP_DATA_PATH + "/cache", PathUtils.getCacheDirectory(context));
  }
}
