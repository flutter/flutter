// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.dart;

import static junit.framework.TestCase.assertNotNull;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.content.res.AssetManager;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.FlutterInjector;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.embedding.engine.dart.DartExecutor.DartEntrypoint;
import io.flutter.embedding.engine.loader.FlutterLoader;
import java.nio.ByteBuffer;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

@RunWith(AndroidJUnit4.class)
public class DartExecutorTest {
  @Mock FlutterLoader mockFlutterLoader;

  @Before
  public void setUp() {
    FlutterInjector.reset();
    MockitoAnnotations.openMocks(this);
  }

  @Test
  public void itSendsBinaryMessages() {
    // Setup test.
    FlutterJNI fakeFlutterJni = mock(FlutterJNI.class);

    // Create object under test.
    DartExecutor dartExecutor = new DartExecutor(fakeFlutterJni, mock(AssetManager.class));

    // Verify a BinaryMessenger exists.
    assertNotNull(dartExecutor.getBinaryMessenger());

    // Execute the behavior under test.
    ByteBuffer fakeMessage = ByteBuffer.allocate(0);
    dartExecutor.getBinaryMessenger().send("fake_channel", fakeMessage);

    // Verify that DartExecutor sent our message to FlutterJNI.
    verify(fakeFlutterJni, times(1))
        .dispatchPlatformMessage(eq("fake_channel"), eq(fakeMessage), anyInt(), anyInt());
  }

  @Test
  public void itNotifiesLowMemoryWarning() {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    when(mockFlutterJNI.isAttached()).thenReturn(true);

    DartExecutor dartExecutor = new DartExecutor(mockFlutterJNI, mock(AssetManager.class));
    dartExecutor.notifyLowMemoryWarning();
    verify(mockFlutterJNI, times(1)).notifyLowMemoryWarning();
  }

  @Test
  public void itThrowsWhenCreatingADefaultDartEntrypointWithAnUninitializedFlutterLoader() {
    assertThrows(
        AssertionError.class,
        () -> {
          DartEntrypoint.createDefault();
        });
  }

  @Test
  public void itHasReasonableDefaultsWhenFlutterLoaderIsInitialized() {
    when(mockFlutterLoader.initialized()).thenReturn(true);
    when(mockFlutterLoader.findAppBundlePath()).thenReturn("my/custom/path");
    FlutterInjector.setInstance(
        new FlutterInjector.Builder().setFlutterLoader(mockFlutterLoader).build());
    DartEntrypoint entrypoint = DartEntrypoint.createDefault();
    assertEquals(entrypoint.pathToBundle, "my/custom/path");
    assertEquals(entrypoint.dartEntrypointFunctionName, "main");
  }

  // ===========================================================================
  // REPRODUCTION TESTS: Make DartEntrypoint only optionally take a bundle path.
  // ===========================================================================

  @Test
  public void dartEntrypointCanBeConstructedWithoutBundlePath() {
    DartEntrypoint entrypoint = new DartEntrypoint("customMain");
    assertEquals(null, entrypoint.pathToBundle);
    assertEquals("customMain", entrypoint.dartEntrypointFunctionName);
    assertEquals(null, entrypoint.dartEntrypointLibrary);
  }

  @Test
  public void dartEntrypointWithLibraryCanBeConstructedWithoutBundlePath() {
    // Use the 3-arg constructor with null pathToBundle to avoid signature clash
    DartEntrypoint entrypoint = new DartEntrypoint(null, "customLibrary", "customMain");
    assertEquals(null, entrypoint.pathToBundle);
    assertEquals("customLibrary", entrypoint.dartEntrypointLibrary);
    assertEquals("customMain", entrypoint.dartEntrypointFunctionName);
  }

  @Test
  public void executeDartEntrypointResolvesBundlePathFromInjector() {
    when(mockFlutterLoader.initialized()).thenReturn(true);
    when(mockFlutterLoader.findAppBundlePath()).thenReturn("injector/resolved/path");
    FlutterInjector.setInstance(
        new FlutterInjector.Builder().setFlutterLoader(mockFlutterLoader).build());

    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    DartExecutor executor = new DartExecutor(mockFlutterJNI, mock(AssetManager.class));

    DartEntrypoint entrypoint = new DartEntrypoint("customMain");
    executor.executeDartEntrypoint(entrypoint);

    verify(mockFlutterJNI, times(1))
        .runBundleAndSnapshotFromLibrary(
            eq("injector/resolved/path"),
            eq("customMain"),
            eq(null),
            any(AssetManager.class),
            eq(null),
            eq(0L));
  }

  @Test
  public void executeDartEntrypointWithoutBundlePathThrowsWhenLoaderUninitialized() {
    when(mockFlutterLoader.initialized()).thenReturn(false);
    FlutterInjector.setInstance(
        new FlutterInjector.Builder().setFlutterLoader(mockFlutterLoader).build());

    DartEntrypoint entrypoint = new DartEntrypoint("customMain");
    DartExecutor executor = new DartExecutor(mock(FlutterJNI.class), mock(AssetManager.class));

    assertThrows(
        AssertionError.class,
        () -> {
          executor.executeDartEntrypoint(entrypoint);
        });
  }
}
