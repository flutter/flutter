// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.loader;

import static android.os.Looper.getMainLooper;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;
import static org.mockito.Mockito.anyInt;
import static org.mockito.Mockito.anyLong;
import static org.mockito.Mockito.anyString;
import static org.mockito.Mockito.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.robolectric.Shadows.shadowOf;

import android.app.ActivityManager;
import android.content.Context;
import androidx.test.core.app.ApplicationProvider;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.embedding.engine.FlutterJNI;
import java.util.Arrays;
import java.util.List;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;

@RunWith(AndroidJUnit4.class)
public class FlutterLoaderOldGenHeapSizeReproduceTest {
  private final Context ctx = ApplicationProvider.getApplicationContext();

  @Test
  public void itUsesMemoryClassForOldGenHeapSizeWhenLargeHeapDisabled() {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    FlutterLoader flutterLoader = new FlutterLoader(mockFlutterJNI);

    Context spyContext = spy(ctx);
    when(spyContext.getApplicationContext()).thenReturn(spyContext);

    // Ensure large heap is disabled
    spyContext.getApplicationInfo().flags &= ~android.content.pm.ApplicationInfo.FLAG_LARGE_HEAP;

    ActivityManager mockActivityManager = mock(ActivityManager.class);
    when(mockActivityManager.getMemoryClass()).thenReturn(128);
    when(mockActivityManager.getLargeMemoryClass()).thenReturn(512);
    when(spyContext.getSystemService(Context.ACTIVITY_SERVICE)).thenReturn(mockActivityManager);

    assertFalse(flutterLoader.initialized());
    flutterLoader.startInitialization(spyContext);
    flutterLoader.ensureInitializationComplete(spyContext, null);
    shadowOf(getMainLooper()).idle();

    ArgumentCaptor<String[]> shellArgsCaptor = ArgumentCaptor.forClass(String[].class);
    verify(mockFlutterJNI, times(1))
        .init(
            eq(spyContext),
            shellArgsCaptor.capture(),
            anyString(),
            anyString(),
            anyString(),
            anyLong(),
            anyInt());
    List<String> arguments = Arrays.asList(shellArgsCaptor.getValue());

    // This assertion should FAIL in the current implementation because the current implementation
    // sets the heap size to total physical memory / 2 (e.g. ActivityManager.MemoryInfo.totalMem /
    // 2)
    // instead of 128 (memory class).
    assertTrue(
        "Expected shell arguments to contain '--old-gen-heap-size=128', but got: " + arguments,
        arguments.contains("--old-gen-heap-size=128"));
  }

  @Test
  public void itUsesLargeMemoryClassForOldGenHeapSizeWhenLargeHeapEnabled() {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    FlutterLoader flutterLoader = new FlutterLoader(mockFlutterJNI);

    Context spyContext = spy(ctx);
    when(spyContext.getApplicationContext()).thenReturn(spyContext);

    // Ensure large heap is enabled
    spyContext.getApplicationInfo().flags |= android.content.pm.ApplicationInfo.FLAG_LARGE_HEAP;

    ActivityManager mockActivityManager = mock(ActivityManager.class);
    when(mockActivityManager.getMemoryClass()).thenReturn(128);
    when(mockActivityManager.getLargeMemoryClass()).thenReturn(512);
    when(spyContext.getSystemService(Context.ACTIVITY_SERVICE)).thenReturn(mockActivityManager);

    assertFalse(flutterLoader.initialized());
    flutterLoader.startInitialization(spyContext);
    flutterLoader.ensureInitializationComplete(spyContext, null);
    shadowOf(getMainLooper()).idle();

    ArgumentCaptor<String[]> shellArgsCaptor = ArgumentCaptor.forClass(String[].class);
    verify(mockFlutterJNI, times(1))
        .init(
            eq(spyContext),
            shellArgsCaptor.capture(),
            anyString(),
            anyString(),
            anyString(),
            anyLong(),
            anyInt());
    List<String> arguments = Arrays.asList(shellArgsCaptor.getValue());

    // This assertion should FAIL in the current implementation because the current implementation
    // sets the heap size to total physical memory / 2 (e.g. ActivityManager.MemoryInfo.totalMem /
    // 2)
    // instead of 512 (large memory class).
    assertTrue(
        "Expected shell arguments to contain '--old-gen-heap-size=512', but got: " + arguments,
        arguments.contains("--old-gen-heap-size=512"));
  }
}
