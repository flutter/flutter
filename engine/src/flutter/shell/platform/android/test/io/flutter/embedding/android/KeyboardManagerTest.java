package io.flutter.embedding.android;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.mockito.Mockito.any;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

import android.view.KeyEvent;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.JSONMessageCodec;
import io.flutter.util.FakeKeyEvent;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.function.BiConsumer;
import java.util.function.Consumer;
import org.json.JSONException;
import org.json.JSONObject;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.mockito.invocation.InvocationOnMock;
import org.robolectric.annotation.Config;

@Config(manifest = Config.NONE)
@RunWith(AndroidJUnit4.class)
public class KeyboardManagerTest {
  /**
   * Records a message that {@link KeyboardManager} sends to outside.
   *
   * <p>A call record can originate from many sources, indicated by its {@link type}. Different
   * types will have different fields filled, leaving others empty.
   */
  static class CallRecord {
    static enum Type {
      /**
       * The channel responder sent a message through the key event channel.
       *
       * <p>This call record will have a non-null {@link channelData}, with an optional {@link
       * reply}.
       */
      kChannel,
    }

    /**
     * Construct an empty call record.
     *
     * <p>Use the static functions to constuct specific types instead.
     */
    private CallRecord() {}

    Type type;

    /**
     * The callback given by the keyboard manager.
     *
     * <p>It might be null, which probably means it is a synthesized event and requires no reply.
     * Otherwise, invoke this callback with whether the event is handled for the keyboard manager to
     * continue processing the key event.
     */
    public Consumer<Boolean> reply;
    /** The data for a call record of type {@link Type.kChannel}. */
    public ChannelCallData channelData;

    /** Construct a call record of type {@link Type.kChannel}. */
    static CallRecord channelCall(
        @NonNull ChannelCallData channelData, @Nullable Consumer<Boolean> reply) {
      final CallRecord record = new CallRecord();
      record.type = Type.kChannel;
      record.channelData = channelData;
      record.reply = reply;
      return record;
    }
  }

  /**
   * The data for a {@link CallRecord} of a channel message sent by the channel responder to the
   * framework.
   */
  static class ChannelCallData {
    ChannelCallData(@NonNull String channel, @NonNull JSONObject message) {
      this.channel = channel;
      this.message = message;
    }

    /** The channel that the message is sent on. */
    public String channel;
    /** The parsed JSON message object. */
    public JSONObject message;
  }

  /**
   * Build a response to a channel message sent by the channel responder.
   *
   * @param handled whether the event is handled.
   */
  static ByteBuffer buildResponseMessage(boolean handled) {
    JSONObject body = new JSONObject();
    try {
      body.put("handled", handled);
    } catch (JSONException e) {
      assertNull(e);
    }
    ByteBuffer binaryReply = JSONMessageCodec.INSTANCE.encodeMessage(body);
    binaryReply.rewind();
    return binaryReply;
  }

  /**
   * Used to configure how to process a channel message.
   *
   * <p>When the channel responder sends a channel message, this functional interface will be
   * invoked. Its first argument will be the detailed data. The second argument will be a nullable
   * reply callback, which should be called to mock the reply from the framework.
   */
  @FunctionalInterface
  static interface ChannelCallHandler extends BiConsumer<ChannelCallData, Consumer<Boolean>> {}

  static class KeyboardTester {
    public KeyboardTester() {
      respondToChannelCallsWith(false);
      respondToTextInputWith(false);

      BinaryMessenger mockMessenger = mock(BinaryMessenger.class);
      doAnswer(invocation -> onChannelMessage(invocation))
          .when(mockMessenger)
          .send(any(String.class), any(ByteBuffer.class));
      doAnswer(invocation -> onChannelMessage(invocation))
          .when(mockMessenger)
          .send(any(String.class), any(ByteBuffer.class), any(BinaryMessenger.BinaryReply.class));

      mockView = mock(KeyboardManager.ViewDelegate.class);
      doAnswer(invocation -> mockMessenger).when(mockView).getBinaryMessenger();
      doAnswer(invocation -> textInputResult)
          .when(mockView)
          .onTextInputKeyEvent(any(KeyEvent.class));
      doAnswer(
              invocation -> {
                KeyEvent event = invocation.getArgument(0);
                boolean handled = keyboardManager.handleEvent(event);
                assertEquals(handled, false);
                return null;
              })
          .when(mockView)
          .redispatch(any(KeyEvent.class));

      keyboardManager = new KeyboardManager(mockView);
    }

    public @Mock KeyboardManager.ViewDelegate mockView;
    public KeyboardManager keyboardManager;

    /** Set channel calls to respond immediately with the given response. */
    public void respondToChannelCallsWith(boolean handled) {
      channelHandler =
          (ChannelCallData data, Consumer<Boolean> reply) -> {
            if (reply != null) {
              reply.accept(handled);
            }
          };
    }

    /**
     * Record embedder calls to the given storage.
     *
     * <p>They are not responded to until the stored callbacks are manually called.
     */
    public void recordChannelCallsTo(@NonNull ArrayList<CallRecord> storage) {
      channelHandler =
          (ChannelCallData data, Consumer<Boolean> reply) -> {
            storage.add(CallRecord.channelCall(data, reply));
          };
    }

    /** Set text calls to respond with the given response. */
    public void respondToTextInputWith(boolean response) {
      textInputResult = response;
    }

    private ChannelCallHandler channelHandler;
    private Boolean textInputResult;

    private Object onChannelMessage(@NonNull InvocationOnMock invocation) {
      final String channel = invocation.getArgument(0);
      final ByteBuffer buffer = invocation.getArgument(1);
      buffer.rewind();
      final JSONObject jsonObject = (JSONObject) JSONMessageCodec.INSTANCE.decodeMessage(buffer);
      final BinaryMessenger.BinaryReply reply = invocation.getArgument(2);
      final Consumer<Boolean> jsonReply =
          reply == null
              ? null
              : handled -> {
                reply.reply(buildResponseMessage(handled));
              };
      channelHandler.accept(new ChannelCallData(channel, jsonObject), jsonReply);
      return null;
    }
  }

  /**
   * Assert that the channel call is an event that matches the given data.
   *
   * <p>For now this function only validates key code, but not scancode or characters.
   *
   * @param data the target data to be tested.
   * @param type the type of the data, usually "keydown" or "keyup".
   * @param keyCode the key code.
   */
  static void assertChannelEventEquals(
      @NonNull ChannelCallData data, @NonNull String type, @NonNull Integer keyCode) {
    final JSONObject message = data.message;
    assertEquals(data.channel, "flutter/keyevent");
    try {
      assertEquals(type, message.get("type"));
      assertEquals("android", message.get("keymap"));
      assertEquals(keyCode, message.get("keyCode"));
    } catch (JSONException e) {
      assertNull(e);
    }
  }

  @Before
  public void setUp() {
    MockitoAnnotations.openMocks(this);
  }

  // Tests start

  @Test
  public void respondsTrueWhenHandlingNewEvents() {
    final KeyboardTester tester = new KeyboardTester();
    final KeyEvent keyEvent = new FakeKeyEvent(KeyEvent.ACTION_DOWN, 65);
    final ArrayList<CallRecord> calls = new ArrayList<CallRecord>();

    tester.recordChannelCallsTo(calls);

    final boolean result = tester.keyboardManager.handleEvent(keyEvent);

    assertEquals(true, result);
    assertEquals(calls.size(), 1);
    assertChannelEventEquals(calls.get(0).channelData, "keydown", 65);

    // Don't send the key event to the text plugin if the only primary responder
    // hasn't responded.
    verify(tester.mockView, times(0)).onTextInputKeyEvent(any(KeyEvent.class));
    verify(tester.mockView, times(0)).redispatch(any(KeyEvent.class));
  }

  @Test
  public void primaryRespondersHaveTheHighestPrecedence() {
    final KeyboardTester tester = new KeyboardTester();
    final KeyEvent keyEvent = new FakeKeyEvent(KeyEvent.ACTION_DOWN, 65);
    final ArrayList<CallRecord> calls = new ArrayList<CallRecord>();

    tester.recordChannelCallsTo(calls);

    final boolean result = tester.keyboardManager.handleEvent(keyEvent);

    assertEquals(true, result);
    assertEquals(calls.size(), 1);
    assertChannelEventEquals(calls.get(0).channelData, "keydown", 65);

    // Don't send the key event to the text plugin if the only primary responder
    // hasn't responded.
    verify(tester.mockView, times(0)).onTextInputKeyEvent(any(KeyEvent.class));
    verify(tester.mockView, times(0)).redispatch(any(KeyEvent.class));

    // If a primary responder handles the key event the propagation stops.
    assertNotNull(calls.get(0).reply);
    calls.get(0).reply.accept(true);
    verify(tester.mockView, times(0)).onTextInputKeyEvent(any(KeyEvent.class));
    verify(tester.mockView, times(0)).redispatch(any(KeyEvent.class));
  }

  @Test
  public void textInputPluginHasTheSecondHighestPrecedence() {
    final KeyboardTester tester = new KeyboardTester();
    final KeyEvent keyEvent = new FakeKeyEvent(KeyEvent.ACTION_DOWN, 65);
    final ArrayList<CallRecord> calls = new ArrayList<CallRecord>();

    tester.recordChannelCallsTo(calls);

    final boolean result = tester.keyboardManager.handleEvent(keyEvent);

    assertEquals(true, result);
    assertEquals(calls.size(), 1);
    assertChannelEventEquals(calls.get(0).channelData, "keydown", 65);

    // Don't send the key event to the text plugin if the only primary responder
    // hasn't responded.
    verify(tester.mockView, times(0)).onTextInputKeyEvent(any(KeyEvent.class));
    verify(tester.mockView, times(0)).redispatch(any(KeyEvent.class));

    // If no primary responder handles the key event the propagates to the text
    // input plugin.
    assertNotNull(calls.get(0).reply);
    // Let text input plugin handle the key event.
    tester.respondToTextInputWith(true);
    calls.get(0).reply.accept(false);

    verify(tester.mockView, times(1)).onTextInputKeyEvent(keyEvent);
    verify(tester.mockView, times(0)).redispatch(any(KeyEvent.class));
  }

  @Test
  public void RedispatchKeyEventIfTextInputPluginFailsToHandle() {
    final KeyboardTester tester = new KeyboardTester();
    final KeyEvent keyEvent = new FakeKeyEvent(KeyEvent.ACTION_DOWN, 65);
    final ArrayList<CallRecord> calls = new ArrayList<CallRecord>();

    tester.recordChannelCallsTo(calls);

    final boolean result = tester.keyboardManager.handleEvent(keyEvent);

    assertEquals(true, result);
    assertEquals(calls.size(), 1);
    assertChannelEventEquals(calls.get(0).channelData, "keydown", 65);

    // Don't send the key event to the text plugin if the only primary responder
    // hasn't responded.
    verify(tester.mockView, times(0)).onTextInputKeyEvent(any(KeyEvent.class));
    verify(tester.mockView, times(0)).redispatch(any(KeyEvent.class));

    // Neither the primary responders nor text input plugin handles the event.
    tester.respondToTextInputWith(false);
    calls.get(0).reply.accept(false);

    verify(tester.mockView, times(1)).onTextInputKeyEvent(keyEvent);
    verify(tester.mockView, times(1)).redispatch(keyEvent);
  }

  @Test
  public void respondsFalseWhenHandlingRedispatchedEvents() {
    final KeyboardTester tester = new KeyboardTester();
    final ArrayList<CallRecord> calls = new ArrayList<CallRecord>();

    tester.recordChannelCallsTo(calls);

    final KeyEvent keyEvent = new FakeKeyEvent(KeyEvent.ACTION_DOWN, 65);
    final boolean result = tester.keyboardManager.handleEvent(keyEvent);

    assertEquals(true, result);
    assertEquals(calls.size(), 1);
    assertChannelEventEquals(calls.get(0).channelData, "keydown", 65);

    // Don't send the key event to the text plugin if the only primary responder
    // hasn't responded.
    verify(tester.mockView, times(0)).onTextInputKeyEvent(any(KeyEvent.class));
    verify(tester.mockView, times(0)).redispatch(any(KeyEvent.class));

    // Neither the primary responders nor text input plugin handles the event.
    tester.respondToTextInputWith(false);
    calls.get(0).reply.accept(false);

    verify(tester.mockView, times(1)).onTextInputKeyEvent(keyEvent);
    verify(tester.mockView, times(1)).redispatch(keyEvent);

    // It's redispatched to the keyboard manager, but no eventual key calls.
    assertEquals(calls.size(), 1);
  }
}
