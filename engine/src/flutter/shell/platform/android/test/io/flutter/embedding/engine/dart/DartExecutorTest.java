package test.io.flutter.embedding.engine.dart;

import static junit.framework.TestCase.assertNotNull;
import static org.mockito.Matchers.anyInt;
import static org.mockito.Matchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

import android.content.res.AssetManager;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.embedding.engine.dart.DartExecutor;
import java.nio.ByteBuffer;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class DartExecutorTest {
  @Test
  public void itSendsBinaryMessages() {
    // Setup test.
    FlutterJNI fakeFlutterJni = mock(FlutterJNI.class);

    // Create object under test.
    DartExecutor dartExecutor = new DartExecutor(fakeFlutterJni, mock(AssetManager.class));

    // Verify a BinaryMessenger exists.
    assertNotNull(dartExecutor.getBinaryMessenger());

    // Execute the behavior under test.
    ByteBuffer fakeMessage = mock(ByteBuffer.class);
    dartExecutor.getBinaryMessenger().send("fake_channel", fakeMessage);

    // Verify that DartExecutor sent our message to FlutterJNI.
    verify(fakeFlutterJni, times(1))
        .dispatchPlatformMessage(eq("fake_channel"), eq(fakeMessage), anyInt(), anyInt());
  }
}
