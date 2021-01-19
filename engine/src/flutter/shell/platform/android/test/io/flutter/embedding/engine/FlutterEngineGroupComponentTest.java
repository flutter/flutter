// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine;

import static org.junit.Assert.assertEquals;
import static org.mockito.Mockito.any;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.when;

import android.content.Context;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.dart.DartExecutor.DartEntrypoint;
import io.flutter.embedding.engine.loader.FlutterLoader;
import io.flutter.plugins.GeneratedPluginRegistrant;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;

// It's a component test because it tests both FlutterEngineGroup and FlutterEngine.
@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class FlutterEngineGroupComponentTest {
  @Mock FlutterJNI flutterJNI;
  FlutterEngineGroup engineGroupUnderTest;
  FlutterEngine firstEngineUnderTest;
  boolean jniAttached;

  @Before
  public void setUp() {
    MockitoAnnotations.initMocks(this);
    jniAttached = false;
    when(flutterJNI.isAttached()).thenAnswer(invocation -> jniAttached);
    doAnswer(invocation -> jniAttached = true).when(flutterJNI).attachToNative(false);
    GeneratedPluginRegistrant.clearRegisteredEngines();

    firstEngineUnderTest =
        spy(
            new FlutterEngine(
                RuntimeEnvironment.application,
                mock(FlutterLoader.class),
                flutterJNI,
                /*dartVmArgs=*/ new String[] {},
                /*automaticallyRegisterPlugins=*/ false));
    when(firstEngineUnderTest.getDartExecutor()).thenReturn(mock(DartExecutor.class));
    engineGroupUnderTest =
        new FlutterEngineGroup() {
          @Override
          FlutterEngine createEngine(Context context) {
            return firstEngineUnderTest;
          }
        };
  }

  @After
  public void tearDown() {
    GeneratedPluginRegistrant.clearRegisteredEngines();
    engineGroupUnderTest = null;
    firstEngineUnderTest = null;
  }

  @Test
  public void listensToEngineDestruction() {
    FlutterEngine firstEngine =
        engineGroupUnderTest.createAndRunEngine(
            RuntimeEnvironment.application, mock(DartEntrypoint.class));
    assertEquals(1, engineGroupUnderTest.activeEngines.size());

    firstEngine.destroy();
    assertEquals(0, engineGroupUnderTest.activeEngines.size());
  }

  @Test
  public void canRecreateEngines() {
    FlutterEngine firstEngine =
        engineGroupUnderTest.createAndRunEngine(
            RuntimeEnvironment.application, mock(DartEntrypoint.class));
    assertEquals(1, engineGroupUnderTest.activeEngines.size());

    firstEngine.destroy();
    assertEquals(0, engineGroupUnderTest.activeEngines.size());

    FlutterEngine secondEngine =
        engineGroupUnderTest.createAndRunEngine(
            RuntimeEnvironment.application, mock(DartEntrypoint.class));
    assertEquals(1, engineGroupUnderTest.activeEngines.size());
    // They happen to be equal in our test since we mocked it to be so.
    assertEquals(firstEngine, secondEngine);
  }

  @Test
  public void canSpawnMoreEngines() {
    FlutterEngine firstEngine =
        engineGroupUnderTest.createAndRunEngine(
            RuntimeEnvironment.application, mock(DartEntrypoint.class));
    assertEquals(1, engineGroupUnderTest.activeEngines.size());

    doReturn(mock(FlutterEngine.class))
        .when(firstEngine)
        .spawn(any(Context.class), any(DartEntrypoint.class));

    FlutterEngine secondEngine =
        engineGroupUnderTest.createAndRunEngine(
            RuntimeEnvironment.application, mock(DartEntrypoint.class));
    assertEquals(2, engineGroupUnderTest.activeEngines.size());

    firstEngine.destroy();
    assertEquals(1, engineGroupUnderTest.activeEngines.size());

    // Now the second spawned engine is the only one left and it will be called to spawn the next
    // engine in the chain.
    when(secondEngine.spawn(any(Context.class), any(DartEntrypoint.class)))
        .thenReturn(mock(FlutterEngine.class));

    FlutterEngine thirdEngine =
        engineGroupUnderTest.createAndRunEngine(
            RuntimeEnvironment.application, mock(DartEntrypoint.class));
    assertEquals(2, engineGroupUnderTest.activeEngines.size());
  }
}
