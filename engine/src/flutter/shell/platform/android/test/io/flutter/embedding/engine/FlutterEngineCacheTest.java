package io.flutter.embedding.engine;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;
import static org.mockito.Mockito.mock;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class FlutterEngineCacheTest {
  @Test
  public void itHoldsFlutterEngines() {
    // --- Test Setup ---
    FlutterEngine flutterEngine = mock(FlutterEngine.class);
    FlutterEngineCache cache = new FlutterEngineCache();

    // --- Execute Test ---
    cache.put("my_flutter_engine", flutterEngine);

    // --- Verify Results ---
    assertEquals(flutterEngine, cache.get("my_flutter_engine"));
  }

  @Test
  public void itQueriesFlutterEngineExistence() {
    // --- Test Setup ---
    FlutterEngine flutterEngine = mock(FlutterEngine.class);
    FlutterEngineCache cache = new FlutterEngineCache();

    // --- Execute Test ---
    assertFalse(cache.contains("my_flutter_engine"));

    cache.put("my_flutter_engine", flutterEngine);

    // --- Verify Results ---
    assertTrue(cache.contains("my_flutter_engine"));
  }

  @Test
  public void itRemovesFlutterEngines() {
    // --- Test Setup ---
    FlutterEngine flutterEngine = mock(FlutterEngine.class);
    FlutterEngineCache cache = new FlutterEngineCache();

    // --- Execute Test ---
    cache.put("my_flutter_engine", flutterEngine);
    cache.remove("my_flutter_engine");

    // --- Verify Results ---
    assertNull(cache.get("my_flutter_engine"));
  }
}
