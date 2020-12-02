package io.flutter.embedding.engine.systemchannels;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;
import static org.mockito.Mockito.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

import android.annotation.TargetApi;
import android.view.KeyEvent;
import androidx.annotation.NonNull;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.JSONMessageCodec;
import io.flutter.util.FakeKeyEvent;
import java.nio.ByteBuffer;
import org.json.JSONException;
import org.json.JSONObject;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@Config(
    manifest = Config.NONE,
    shadows = {})
@RunWith(RobolectricTestRunner.class)
@TargetApi(24)
public class KeyEventChannelTest {

  private void sendReply(boolean handled, BinaryMessenger.BinaryReply messengerReply)
      throws JSONException {
    JSONObject reply = new JSONObject();
    reply.put("handled", true);
    ByteBuffer binaryReply = JSONMessageCodec.INSTANCE.encodeMessage(reply);
    assertNotNull(binaryReply);
    binaryReply.rewind();
    messengerReply.reply(binaryReply);
  }

  @Test
  public void keyDownEventIsSentToFramework() throws JSONException {
    BinaryMessenger fakeMessenger = mock(BinaryMessenger.class);
    KeyEventChannel keyEventChannel = new KeyEventChannel(fakeMessenger);
    final boolean[] handled = {false};
    final long[] handledId = {-1};
    keyEventChannel.setEventResponseHandler(
        new KeyEventChannel.EventResponseHandler() {
          public void onKeyEventHandled(@NonNull long id) {
            handled[0] = true;
            handledId[0] = id;
          }

          public void onKeyEventNotHandled(@NonNull long id) {
            handled[0] = false;
            handledId[0] = id;
          }
        });
    verify(fakeMessenger, times(0)).send(any(), any(), any());

    KeyEvent event = new FakeKeyEvent(KeyEvent.ACTION_DOWN, 65);
    KeyEventChannel.FlutterKeyEvent flutterKeyEvent =
        new KeyEventChannel.FlutterKeyEvent(event, null, 10);
    keyEventChannel.keyDown(flutterKeyEvent);
    ArgumentCaptor<ByteBuffer> byteBufferArgumentCaptor = ArgumentCaptor.forClass(ByteBuffer.class);
    ArgumentCaptor<BinaryMessenger.BinaryReply> replyArgumentCaptor =
        ArgumentCaptor.forClass(BinaryMessenger.BinaryReply.class);
    verify(fakeMessenger, times(1))
        .send(any(), byteBufferArgumentCaptor.capture(), replyArgumentCaptor.capture());
    ByteBuffer capturedMessage = byteBufferArgumentCaptor.getValue();
    capturedMessage.rewind();
    JSONObject message = (JSONObject) JSONMessageCodec.INSTANCE.decodeMessage(capturedMessage);
    assertNotNull(message);
    assertEquals("keydown", message.get("type"));

    // Simulate a reply, and see that it is handled.
    sendReply(true, replyArgumentCaptor.getValue());
    assertTrue(handled[0]);
    assertEquals(10, handledId[0]);
  }

  @Test
  public void keyUpEventIsSentToFramework() throws JSONException {
    BinaryMessenger fakeMessenger = mock(BinaryMessenger.class);
    KeyEventChannel keyEventChannel = new KeyEventChannel(fakeMessenger);
    final boolean[] handled = {false};
    final long[] handledId = {-1};
    keyEventChannel.setEventResponseHandler(
        new KeyEventChannel.EventResponseHandler() {
          public void onKeyEventHandled(long id) {
            handled[0] = true;
            handledId[0] = id;
          }

          public void onKeyEventNotHandled(long id) {
            handled[0] = false;
            handledId[0] = id;
          }
        });
    verify(fakeMessenger, times(0)).send(any(), any(), any());

    KeyEvent event = new FakeKeyEvent(KeyEvent.ACTION_UP, 65);
    KeyEventChannel.FlutterKeyEvent flutterKeyEvent =
        new KeyEventChannel.FlutterKeyEvent(event, null, 10);
    keyEventChannel.keyUp(flutterKeyEvent);
    ArgumentCaptor<ByteBuffer> byteBufferArgumentCaptor = ArgumentCaptor.forClass(ByteBuffer.class);
    ArgumentCaptor<BinaryMessenger.BinaryReply> replyArgumentCaptor =
        ArgumentCaptor.forClass(BinaryMessenger.BinaryReply.class);
    verify(fakeMessenger, times(1))
        .send(any(), byteBufferArgumentCaptor.capture(), replyArgumentCaptor.capture());
    ByteBuffer capturedMessage = byteBufferArgumentCaptor.getValue();
    capturedMessage.rewind();
    JSONObject message = (JSONObject) JSONMessageCodec.INSTANCE.decodeMessage(capturedMessage);
    assertNotNull(message);
    assertEquals("keyup", message.get("type"));

    // Simulate a reply, and see that it is handled.
    sendReply(true, replyArgumentCaptor.getValue());
    assertTrue(handled[0]);
    assertEquals(10, handledId[0]);
  }
}
