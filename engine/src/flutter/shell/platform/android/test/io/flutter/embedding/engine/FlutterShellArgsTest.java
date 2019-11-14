package test.io.flutter.embedding.engine;

import android.content.Intent;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

import io.flutter.embedding.engine.FlutterShellArgs;

import static org.junit.Assert.assertEquals;

@Config(manifest=Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class FlutterShellArgsTest {
  @Test
  public void itProcessesDartFlags() {
    // Setup the test.
    Intent intent = new Intent();
    intent.putExtra("dart-flags", "--observe --no-hot --no-pub");

    // Execute the behavior under test.
    FlutterShellArgs args = FlutterShellArgs.fromIntent(intent);

    // Verify results.
    assertEquals(1, args.toArray().length);
    assertEquals("--dart-flags=--observe --no-hot --no-pub", args.toArray()[0]);
  }
}
