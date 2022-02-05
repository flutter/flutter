package io.flutter.embedding.engine.systemchannels;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;
import static org.mockito.Mockito.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.annotation.TargetApi;
import android.util.SparseArray;
import android.view.InputDevice;
import android.view.KeyEvent;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.JSONMessageCodec;
import io.flutter.util.FakeKeyEvent;
import java.nio.ByteBuffer;
import org.json.JSONException;
import org.json.JSONObject;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.robolectric.annotation.Config;
import org.robolectric.annotation.Implementation;
import org.robolectric.annotation.Implements;
import org.robolectric.annotation.Resetter;
import org.robolectric.shadow.api.Shadow;

@Config(manifest = Config.NONE)
@RunWith(AndroidJUnit4.class)
@TargetApi(24)
public class KeyEventChannelTest {

  KeyEvent keyEvent;
  @Mock BinaryMessenger fakeMessenger;
  boolean[] handled;
  KeyEventChannel keyEventChannel;

  private void sendReply(boolean handled, BinaryMessenger.BinaryReply messengerReply)
      throws JSONException {
    JSONObject reply = new JSONObject();
    reply.put("handled", true);
    ByteBuffer binaryReply = JSONMessageCodec.INSTANCE.encodeMessage(reply);
    assertNotNull(binaryReply);
    binaryReply.rewind();
    messengerReply.reply(binaryReply);
  }

  @Before
  public void setUp() {
    MockitoAnnotations.openMocks(this);
    keyEvent = new FakeKeyEvent(KeyEvent.ACTION_DOWN, 65);
    handled = new boolean[] {false};
    keyEventChannel = new KeyEventChannel(fakeMessenger);
  }

  @After
  public void tearDown() {
    ShadowInputDevice.reset();
  }

  @Test
  @Config(shadows = {ShadowInputDevice.class})
  public void keyDownEventIsSentToFramework() throws JSONException {
    final InputDevice device = mock(InputDevice.class);
    when(device.isVirtual()).thenReturn(false);
    when(device.getName()).thenReturn("keyboard");
    ShadowInputDevice.sDeviceIds = new int[] {0};
    ShadowInputDevice.addDevice(0, device);

    KeyEventChannel.FlutterKeyEvent flutterKeyEvent =
        new KeyEventChannel.FlutterKeyEvent(keyEvent, null);
    keyEventChannel.sendFlutterKeyEvent(
        flutterKeyEvent,
        false,
        (isHandled) -> {
          handled[0] = isHandled;
        });

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
  }

  @Test
  @Config(shadows = {ShadowInputDevice.class})
  public void keyUpEventIsSentToFramework() throws JSONException {
    final InputDevice device = mock(InputDevice.class);
    when(device.isVirtual()).thenReturn(false);
    when(device.getName()).thenReturn("keyboard");
    ShadowInputDevice.sDeviceIds = new int[] {0};
    ShadowInputDevice.addDevice(0, device);

    keyEvent = new FakeKeyEvent(KeyEvent.ACTION_UP, 65);
    KeyEventChannel.FlutterKeyEvent flutterKeyEvent =
        new KeyEventChannel.FlutterKeyEvent(keyEvent, null);
    keyEventChannel.sendFlutterKeyEvent(
        flutterKeyEvent,
        false,
        (isHandled) -> {
          handled[0] = isHandled;
        });

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
  }

  @Implements(InputDevice.class)
  public static class ShadowInputDevice extends org.robolectric.shadows.ShadowInputDevice {
    public static int[] sDeviceIds;
    private static SparseArray<InputDevice> sDeviceMap = new SparseArray<>();

    private int mDeviceId;

    @Implementation
    protected static int[] getDeviceIds() {
      return sDeviceIds;
    }

    @Implementation
    protected static InputDevice getDevice(int id) {
      return sDeviceMap.get(id);
    }

    public static void addDevice(int id, InputDevice device) {
      sDeviceMap.append(id, device);
    }

    @Resetter
    public static void reset() {
      sDeviceIds = null;
      sDeviceMap.clear();
    }

    @Implementation
    protected int getId() {
      return mDeviceId;
    }

    public static InputDevice makeInputDevicebyId(int id) {
      final InputDevice inputDevice = Shadow.newInstanceOf(InputDevice.class);
      final ShadowInputDevice shadowInputDevice = Shadow.extract(inputDevice);
      shadowInputDevice.setId(id);
      return inputDevice;
    }

    public void setId(int id) {
      mDeviceId = id;
    }
  }
}
