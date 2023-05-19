package io.flutter.plugin.common;

import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

import android.content.res.AssetManager;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.embedding.engine.dart.DartExecutor;
import java.nio.ByteBuffer;
import java.nio.charset.Charset;
import java.util.Locale;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(AndroidJUnit4.class)
public class MethodChannelTest {
  @Test
  public void methodChannel_resizeChannelBuffer() {
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    DartExecutor dartExecutor = new DartExecutor(mockFlutterJNI, mock(AssetManager.class));
    String channel = "flutter/test";
    MethodChannel rawChannel = new MethodChannel(dartExecutor, channel);

    int newSize = 3;
    rawChannel.resizeChannelBuffer(newSize);

    Charset charset = Charset.forName("UTF-8");
    String messageString = String.format(Locale.US, "resize\r%s\r%d", channel, newSize);
    final byte[] bytes = messageString.getBytes(charset);
    ByteBuffer packet = ByteBuffer.allocateDirect(bytes.length);
    packet.put(bytes);

    // Verify that DartExecutor sent the correct message to FlutterJNI.
    verify(mockFlutterJNI, times(1))
        .dispatchPlatformMessage(
            eq(BasicMessageChannel.CHANNEL_BUFFERS_CHANNEL), eq(packet), anyInt(), anyInt());
  }
}
