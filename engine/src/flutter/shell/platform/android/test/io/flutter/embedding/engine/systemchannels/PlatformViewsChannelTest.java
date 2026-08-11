package io.flutter.embedding.engine.systemchannels;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.StandardMethodCodec;
import java.nio.ByteBuffer;
import java.util.Map;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;

@RunWith(AndroidJUnit4.class)
public class PlatformViewsChannelTest {
  DartExecutor dartExecutor;
  BinaryMessenger binaryMessenger;
  PlatformViewsChannel platformViewsChannel;

  @Before
  public void setUp() {
    dartExecutor = mock(DartExecutor.class);
    binaryMessenger = dartExecutor;
    platformViewsChannel = new PlatformViewsChannel(dartExecutor);
  }

  @Test
  public void invokeFocusNext_invokesMethod() {
    platformViewsChannel.invokeFocusNext(1, 2);

    ArgumentCaptor<ByteBuffer> byteBufferArgumentCaptor = ArgumentCaptor.forClass(ByteBuffer.class);
    verify(binaryMessenger, times(1))
        .send(eq("flutter/platform_views"), byteBufferArgumentCaptor.capture(), any());

    ByteBuffer capturedMessage = byteBufferArgumentCaptor.getValue();
    capturedMessage.rewind();
    MethodCall call = StandardMethodCodec.INSTANCE.decodeMethodCall(capturedMessage);

    assertEquals("invokeFocusNext", call.method);
    Map<String, Object> arguments = call.arguments();
    assertNotNull(arguments);
    assertEquals(1, arguments.get("viewId"));
    assertEquals(2, arguments.get("direction"));
  }

  @Test
  public void requestFocus_callsHandler() {
    PlatformViewsChannel.PlatformViewsHandler mockHandler =
        mock(PlatformViewsChannel.PlatformViewsHandler.class);
    platformViewsChannel.setPlatformViewsHandler(mockHandler);

    ArgumentCaptor<BinaryMessenger.BinaryMessageHandler> handlerCaptor =
        ArgumentCaptor.forClass(BinaryMessenger.BinaryMessageHandler.class);
    verify(binaryMessenger, times(1))
        .setMessageHandler(eq("flutter/platform_views"), handlerCaptor.capture());

    BinaryMessenger.BinaryMessageHandler handler = handlerCaptor.getValue();
    MethodCall call = new MethodCall("requestFocus", 1);
    ByteBuffer message = StandardMethodCodec.INSTANCE.encodeMethodCall(call);

    BinaryMessenger.BinaryReply mockReply = mock(BinaryMessenger.BinaryReply.class);
    handler.onMessage(message, mockReply);

    verify(mockHandler, times(1)).requestFocus(1);

    // Verify success result was sent
    ArgumentCaptor<ByteBuffer> replyCaptor = ArgumentCaptor.forClass(ByteBuffer.class);
    verify(mockReply, times(1)).reply(replyCaptor.capture());
    ByteBuffer replyMessage = replyCaptor.getValue();
    replyMessage.rewind();
    // 0 represents success in StandardMethodCodec
    assertEquals(0, replyMessage.get());
  }
}
