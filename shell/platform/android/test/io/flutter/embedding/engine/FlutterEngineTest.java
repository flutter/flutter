package test.io.flutter.embedding.engine;

import io.flutter.plugins.GeneratedPluginRegistrant;
import java.util.List;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.embedding.engine.loader.FlutterLoader;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

@Config(manifest=Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class FlutterEngineTest {
  @Mock FlutterJNI flutterJNI;

  @Before
  public void setUp() {
    MockitoAnnotations.initMocks(this);
    when(flutterJNI.isAttached()).thenReturn(true);
    GeneratedPluginRegistrant.clearRegisteredEngines();
  }

  @After
  public void tearDown() {
    GeneratedPluginRegistrant.clearRegisteredEngines();
  }

  @Test
  public void itAutomaticallyRegistersPluginsByDefault() {
    assertTrue(GeneratedPluginRegistrant.getRegisteredEngines().isEmpty());
    FlutterEngine flutterEngine = new FlutterEngine(
        RuntimeEnvironment.application,
        mock(FlutterLoader.class),
        flutterJNI
    );

    List<FlutterEngine> registeredEngines = GeneratedPluginRegistrant.getRegisteredEngines();
    assertEquals(1, registeredEngines.size());
    assertEquals(flutterEngine, registeredEngines.get(0));
  }

  @Test
  public void itCanBeConfiguredToNotAutomaticallyRegisterPlugins() {
    new FlutterEngine(
        RuntimeEnvironment.application,
        mock(FlutterLoader.class),
        flutterJNI,
        /*dartVmArgs=*/new String[] {},
        /*automaticallyRegisterPlugins=*/false
    );

    assertTrue(GeneratedPluginRegistrant.getRegisteredEngines().isEmpty());
  }
}
