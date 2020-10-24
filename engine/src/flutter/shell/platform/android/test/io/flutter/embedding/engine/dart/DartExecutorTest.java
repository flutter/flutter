package io.flutter.embedding.engine.dart;

import static junit.framework.TestCase.assertNotNull;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertThrows;
import static org.mockito.Matchers.anyInt;
import static org.mockito.Matchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.content.res.AssetManager;
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
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(RobolectricTestRunner.class)
public class DartExecutorTest {
  @Mock FlutterLoader mockFlutterLoader;

  @Before
  public void setUp() {
    FlutterInjector.reset();
    MockitoAnnotations.initMocks(this);
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
    ByteBuffer fakeMessage = mock(ByteBuffer.class);
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
}
