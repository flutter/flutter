package io.flutter.plugin.editing;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;
import static org.mockito.Matchers.any;
import static org.mockito.Matchers.anyInt;
import static org.mockito.Mockito.anyString;
import static org.mockito.Mockito.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.content.ClipboardManager;
import android.content.res.AssetManager;
import android.os.Bundle;
import android.text.Editable;
import android.text.Emoji;
import android.text.InputType;
import android.text.Selection;
import android.text.SpannableStringBuilder;
import android.view.KeyEvent;
import android.view.View;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.ExtractedText;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.systemchannels.TextInputChannel;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.JSONMethodCodec;
import io.flutter.plugin.common.MethodCall;
import io.flutter.util.FakeKeyEvent;
import java.nio.ByteBuffer;
import org.json.JSONArray;
import org.json.JSONException;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;
import org.robolectric.shadows.ShadowClipboardManager;

@Config(manifest = Config.NONE, shadows = ShadowClipboardManager.class)
@RunWith(RobolectricTestRunner.class)
public class InputConnectionAdaptorTest {
  // Verifies the method and arguments for a captured method call.
  private void verifyMethodCall(ByteBuffer buffer, String methodName, String[] expectedArgs)
      throws JSONException {
    buffer.rewind();
    MethodCall methodCall = JSONMethodCodec.INSTANCE.decodeMethodCall(buffer);
    assertEquals(methodName, methodCall.method);
    if (expectedArgs != null) {
      JSONArray args = methodCall.arguments();
      assertEquals(expectedArgs.length, args.length());
      for (int i = 0; i < args.length(); i++) {
        assertEquals(expectedArgs[i], args.get(i).toString());
      }
    }
  }

  @Test
  public void inputConnectionAdaptor_ReceivesEnter() throws NullPointerException {
    View testView = new View(RuntimeEnvironment.application);
    FlutterJNI mockFlutterJni = mock(FlutterJNI.class);
    DartExecutor dartExecutor = spy(new DartExecutor(mockFlutterJni, mock(AssetManager.class)));
    int inputTargetId = 0;
    TextInputChannel textInputChannel = new TextInputChannel(dartExecutor);
    Editable mEditable = Editable.Factory.getInstance().newEditable("");
    Editable spyEditable = spy(mEditable);
    EditorInfo outAttrs = new EditorInfo();
    outAttrs.inputType = InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_MULTI_LINE;

    InputConnectionAdaptor inputConnectionAdaptor =
        new InputConnectionAdaptor(
            testView, inputTargetId, textInputChannel, spyEditable, outAttrs);

    // Send an enter key and make sure the Editable received it.
    FakeKeyEvent keyEvent = new FakeKeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_ENTER);
    inputConnectionAdaptor.sendKeyEvent(keyEvent);
    verify(spyEditable, times(1)).insert(eq(0), anyString());
  }

  @Test
  public void testPerformContextMenuAction_selectAll() {
    int selStart = 5;
    Editable editable = sampleEditable(selStart, selStart);
    InputConnectionAdaptor adaptor = sampleInputConnectionAdaptor(editable);

    boolean didConsume = adaptor.performContextMenuAction(android.R.id.selectAll);

    assertTrue(didConsume);
    assertEquals(0, Selection.getSelectionStart(editable));
    assertEquals(editable.length(), Selection.getSelectionEnd(editable));
  }

  @Test
  public void testPerformContextMenuAction_cut() {
    ClipboardManager clipboardManager =
        RuntimeEnvironment.application.getSystemService(ClipboardManager.class);
    int selStart = 6;
    int selEnd = 11;
    Editable editable = sampleEditable(selStart, selEnd);
    CharSequence textToBeCut = editable.subSequence(selStart, selEnd);
    InputConnectionAdaptor adaptor = sampleInputConnectionAdaptor(editable);

    boolean didConsume = adaptor.performContextMenuAction(android.R.id.cut);

    assertTrue(didConsume);
    assertTrue(clipboardManager.hasText());
    assertEquals(textToBeCut, clipboardManager.getPrimaryClip().getItemAt(0).getText());
    assertFalse(editable.toString().contains(textToBeCut));
  }

  @Test
  public void testPerformContextMenuAction_copy() {
    ClipboardManager clipboardManager =
        RuntimeEnvironment.application.getSystemService(ClipboardManager.class);
    int selStart = 6;
    int selEnd = 11;
    Editable editable = sampleEditable(selStart, selEnd);
    InputConnectionAdaptor adaptor = sampleInputConnectionAdaptor(editable);

    assertFalse(clipboardManager.hasText());

    boolean didConsume = adaptor.performContextMenuAction(android.R.id.copy);

    assertTrue(didConsume);
    assertTrue(clipboardManager.hasText());
    assertEquals(
        editable.subSequence(selStart, selEnd),
        clipboardManager.getPrimaryClip().getItemAt(0).getText());
  }

  @Test
  public void testPerformContextMenuAction_paste() {
    ClipboardManager clipboardManager =
        RuntimeEnvironment.application.getSystemService(ClipboardManager.class);
    String textToBePasted = "deadbeef";
    clipboardManager.setText(textToBePasted);
    Editable editable = sampleEditable(0, 0);
    InputConnectionAdaptor adaptor = sampleInputConnectionAdaptor(editable);

    boolean didConsume = adaptor.performContextMenuAction(android.R.id.paste);

    assertTrue(didConsume);
    assertTrue(editable.toString().startsWith(textToBePasted));
  }

  @Test
  public void testPerformPrivateCommand_dataIsNull() throws JSONException {
    View testView = new View(RuntimeEnvironment.application);
    int client = 0;
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    DartExecutor dartExecutor = spy(new DartExecutor(mockFlutterJNI, mock(AssetManager.class)));
    TextInputChannel textInputChannel = new TextInputChannel(dartExecutor);
    Editable editable = sampleEditable(0, 0);
    InputConnectionAdaptor adaptor =
        new InputConnectionAdaptor(
            testView, client, textInputChannel, editable, null, mockFlutterJNI);
    adaptor.performPrivateCommand("actionCommand", null);

    ArgumentCaptor<String> channelCaptor = ArgumentCaptor.forClass(String.class);
    ArgumentCaptor<ByteBuffer> bufferCaptor = ArgumentCaptor.forClass(ByteBuffer.class);
    verify(dartExecutor, times(1))
        .send(
            channelCaptor.capture(),
            bufferCaptor.capture(),
            any(BinaryMessenger.BinaryReply.class));
    assertEquals("flutter/textinput", channelCaptor.getValue());
    verifyMethodCall(
        bufferCaptor.getValue(),
        "TextInputClient.performPrivateCommand",
        new String[] {"0", "{\"action\":\"actionCommand\"}"});
  }

  @Test
  public void testPerformPrivateCommand_dataIsByteArray() throws JSONException {
    View testView = new View(RuntimeEnvironment.application);
    int client = 0;
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    DartExecutor dartExecutor = spy(new DartExecutor(mockFlutterJNI, mock(AssetManager.class)));
    TextInputChannel textInputChannel = new TextInputChannel(dartExecutor);
    Editable editable = sampleEditable(0, 0);
    InputConnectionAdaptor adaptor =
        new InputConnectionAdaptor(
            testView, client, textInputChannel, editable, null, mockFlutterJNI);

    Bundle bundle = new Bundle();
    byte[] buffer = new byte[] {'a', 'b', 'c', 'd'};
    bundle.putByteArray("keyboard_layout", buffer);
    adaptor.performPrivateCommand("actionCommand", bundle);

    ArgumentCaptor<String> channelCaptor = ArgumentCaptor.forClass(String.class);
    ArgumentCaptor<ByteBuffer> bufferCaptor = ArgumentCaptor.forClass(ByteBuffer.class);
    verify(dartExecutor, times(1))
        .send(
            channelCaptor.capture(),
            bufferCaptor.capture(),
            any(BinaryMessenger.BinaryReply.class));
    assertEquals("flutter/textinput", channelCaptor.getValue());
    verifyMethodCall(
        bufferCaptor.getValue(),
        "TextInputClient.performPrivateCommand",
        new String[] {
          "0", "{\"data\":{\"keyboard_layout\":[97,98,99,100]},\"action\":\"actionCommand\"}"
        });
  }

  @Test
  public void testPerformPrivateCommand_dataIsByte() throws JSONException {
    View testView = new View(RuntimeEnvironment.application);
    int client = 0;
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    DartExecutor dartExecutor = spy(new DartExecutor(mockFlutterJNI, mock(AssetManager.class)));
    TextInputChannel textInputChannel = new TextInputChannel(dartExecutor);
    Editable editable = sampleEditable(0, 0);
    InputConnectionAdaptor adaptor =
        new InputConnectionAdaptor(
            testView, client, textInputChannel, editable, null, mockFlutterJNI);

    Bundle bundle = new Bundle();
    byte b = 3;
    bundle.putByte("keyboard_layout", b);
    adaptor.performPrivateCommand("actionCommand", bundle);

    ArgumentCaptor<String> channelCaptor = ArgumentCaptor.forClass(String.class);
    ArgumentCaptor<ByteBuffer> bufferCaptor = ArgumentCaptor.forClass(ByteBuffer.class);
    verify(dartExecutor, times(1))
        .send(
            channelCaptor.capture(),
            bufferCaptor.capture(),
            any(BinaryMessenger.BinaryReply.class));
    assertEquals("flutter/textinput", channelCaptor.getValue());
    verifyMethodCall(
        bufferCaptor.getValue(),
        "TextInputClient.performPrivateCommand",
        new String[] {"0", "{\"data\":{\"keyboard_layout\":3},\"action\":\"actionCommand\"}"});
  }

  @Test
  public void testPerformPrivateCommand_dataIsCharArray() throws JSONException {
    View testView = new View(RuntimeEnvironment.application);
    int client = 0;
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    DartExecutor dartExecutor = spy(new DartExecutor(mockFlutterJNI, mock(AssetManager.class)));
    TextInputChannel textInputChannel = new TextInputChannel(dartExecutor);
    Editable editable = sampleEditable(0, 0);
    InputConnectionAdaptor adaptor =
        new InputConnectionAdaptor(
            testView, client, textInputChannel, editable, null, mockFlutterJNI);

    Bundle bundle = new Bundle();
    char[] buffer = new char[] {'a', 'b', 'c', 'd'};
    bundle.putCharArray("keyboard_layout", buffer);
    adaptor.performPrivateCommand("actionCommand", bundle);

    ArgumentCaptor<String> channelCaptor = ArgumentCaptor.forClass(String.class);
    ArgumentCaptor<ByteBuffer> bufferCaptor = ArgumentCaptor.forClass(ByteBuffer.class);
    verify(dartExecutor, times(1))
        .send(
            channelCaptor.capture(),
            bufferCaptor.capture(),
            any(BinaryMessenger.BinaryReply.class));
    assertEquals("flutter/textinput", channelCaptor.getValue());
    verifyMethodCall(
        bufferCaptor.getValue(),
        "TextInputClient.performPrivateCommand",
        new String[] {
          "0",
          "{\"data\":{\"keyboard_layout\":[\"a\",\"b\",\"c\",\"d\"]},\"action\":\"actionCommand\"}"
        });
  }

  @Test
  public void testPerformPrivateCommand_dataIsChar() throws JSONException {
    View testView = new View(RuntimeEnvironment.application);
    int client = 0;
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    DartExecutor dartExecutor = spy(new DartExecutor(mockFlutterJNI, mock(AssetManager.class)));
    TextInputChannel textInputChannel = new TextInputChannel(dartExecutor);
    Editable editable = sampleEditable(0, 0);
    InputConnectionAdaptor adaptor =
        new InputConnectionAdaptor(
            testView, client, textInputChannel, editable, null, mockFlutterJNI);

    Bundle bundle = new Bundle();
    char b = 'a';
    bundle.putChar("keyboard_layout", b);
    adaptor.performPrivateCommand("actionCommand", bundle);

    ArgumentCaptor<String> channelCaptor = ArgumentCaptor.forClass(String.class);
    ArgumentCaptor<ByteBuffer> bufferCaptor = ArgumentCaptor.forClass(ByteBuffer.class);
    verify(dartExecutor, times(1))
        .send(
            channelCaptor.capture(),
            bufferCaptor.capture(),
            any(BinaryMessenger.BinaryReply.class));
    assertEquals("flutter/textinput", channelCaptor.getValue());
    verifyMethodCall(
        bufferCaptor.getValue(),
        "TextInputClient.performPrivateCommand",
        new String[] {"0", "{\"data\":{\"keyboard_layout\":\"a\"},\"action\":\"actionCommand\"}"});
  }

  @Test
  public void testPerformPrivateCommand_dataIsCharSequenceArray() throws JSONException {
    View testView = new View(RuntimeEnvironment.application);
    int client = 0;
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    DartExecutor dartExecutor = spy(new DartExecutor(mockFlutterJNI, mock(AssetManager.class)));
    TextInputChannel textInputChannel = new TextInputChannel(dartExecutor);
    Editable editable = sampleEditable(0, 0);
    InputConnectionAdaptor adaptor =
        new InputConnectionAdaptor(
            testView, client, textInputChannel, editable, null, mockFlutterJNI);

    Bundle bundle = new Bundle();
    CharSequence charSequence1 = new StringBuffer("abc");
    CharSequence charSequence2 = new StringBuffer("efg");
    CharSequence[] value = {charSequence1, charSequence2};
    bundle.putCharSequenceArray("keyboard_layout", value);
    adaptor.performPrivateCommand("actionCommand", bundle);

    ArgumentCaptor<String> channelCaptor = ArgumentCaptor.forClass(String.class);
    ArgumentCaptor<ByteBuffer> bufferCaptor = ArgumentCaptor.forClass(ByteBuffer.class);
    verify(dartExecutor, times(1))
        .send(
            channelCaptor.capture(),
            bufferCaptor.capture(),
            any(BinaryMessenger.BinaryReply.class));
    assertEquals("flutter/textinput", channelCaptor.getValue());
    verifyMethodCall(
        bufferCaptor.getValue(),
        "TextInputClient.performPrivateCommand",
        new String[] {
          "0", "{\"data\":{\"keyboard_layout\":[\"abc\",\"efg\"]},\"action\":\"actionCommand\"}"
        });
  }

  @Test
  public void testPerformPrivateCommand_dataIsCharSequence() throws JSONException {
    View testView = new View(RuntimeEnvironment.application);
    int client = 0;
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    DartExecutor dartExecutor = spy(new DartExecutor(mockFlutterJNI, mock(AssetManager.class)));
    TextInputChannel textInputChannel = new TextInputChannel(dartExecutor);
    Editable editable = sampleEditable(0, 0);
    InputConnectionAdaptor adaptor =
        new InputConnectionAdaptor(
            testView, client, textInputChannel, editable, null, mockFlutterJNI);

    Bundle bundle = new Bundle();
    CharSequence charSequence = new StringBuffer("abc");
    bundle.putCharSequence("keyboard_layout", charSequence);
    adaptor.performPrivateCommand("actionCommand", bundle);

    ArgumentCaptor<String> channelCaptor = ArgumentCaptor.forClass(String.class);
    ArgumentCaptor<ByteBuffer> bufferCaptor = ArgumentCaptor.forClass(ByteBuffer.class);
    verify(dartExecutor, times(1))
        .send(
            channelCaptor.capture(),
            bufferCaptor.capture(),
            any(BinaryMessenger.BinaryReply.class));
    assertEquals("flutter/textinput", channelCaptor.getValue());
    verifyMethodCall(
        bufferCaptor.getValue(),
        "TextInputClient.performPrivateCommand",
        new String[] {
          "0", "{\"data\":{\"keyboard_layout\":\"abc\"},\"action\":\"actionCommand\"}"
        });
  }

  @Test
  public void testPerformPrivateCommand_dataIsFloat() throws JSONException {
    View testView = new View(RuntimeEnvironment.application);
    int client = 0;
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    DartExecutor dartExecutor = spy(new DartExecutor(mockFlutterJNI, mock(AssetManager.class)));
    TextInputChannel textInputChannel = new TextInputChannel(dartExecutor);
    Editable editable = sampleEditable(0, 0);
    InputConnectionAdaptor adaptor =
        new InputConnectionAdaptor(
            testView, client, textInputChannel, editable, null, mockFlutterJNI);

    Bundle bundle = new Bundle();
    float value = 0.5f;
    bundle.putFloat("keyboard_layout", value);
    adaptor.performPrivateCommand("actionCommand", bundle);

    ArgumentCaptor<String> channelCaptor = ArgumentCaptor.forClass(String.class);
    ArgumentCaptor<ByteBuffer> bufferCaptor = ArgumentCaptor.forClass(ByteBuffer.class);
    verify(dartExecutor, times(1))
        .send(
            channelCaptor.capture(),
            bufferCaptor.capture(),
            any(BinaryMessenger.BinaryReply.class));
    assertEquals("flutter/textinput", channelCaptor.getValue());
    verifyMethodCall(
        bufferCaptor.getValue(),
        "TextInputClient.performPrivateCommand",
        new String[] {"0", "{\"data\":{\"keyboard_layout\":0.5},\"action\":\"actionCommand\"}"});
  }

  @Test
  public void testPerformPrivateCommand_dataIsFloatArray() throws JSONException {
    View testView = new View(RuntimeEnvironment.application);
    int client = 0;
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    DartExecutor dartExecutor = spy(new DartExecutor(mockFlutterJNI, mock(AssetManager.class)));
    TextInputChannel textInputChannel = new TextInputChannel(dartExecutor);
    Editable editable = sampleEditable(0, 0);
    InputConnectionAdaptor adaptor =
        new InputConnectionAdaptor(
            testView, client, textInputChannel, editable, null, mockFlutterJNI);

    Bundle bundle = new Bundle();
    float[] value = {0.5f, 0.6f};
    bundle.putFloatArray("keyboard_layout", value);
    adaptor.performPrivateCommand("actionCommand", bundle);

    ArgumentCaptor<String> channelCaptor = ArgumentCaptor.forClass(String.class);
    ArgumentCaptor<ByteBuffer> bufferCaptor = ArgumentCaptor.forClass(ByteBuffer.class);
    verify(dartExecutor, times(1))
        .send(
            channelCaptor.capture(),
            bufferCaptor.capture(),
            any(BinaryMessenger.BinaryReply.class));
    assertEquals("flutter/textinput", channelCaptor.getValue());
    verifyMethodCall(
        bufferCaptor.getValue(),
        "TextInputClient.performPrivateCommand",
        new String[] {
          "0", "{\"data\":{\"keyboard_layout\":[0.5,0.6]},\"action\":\"actionCommand\"}"
        });
  }

  @Test
  public void testSendKeyEvent_shiftKeyUpCancelsSelection() {
    int selStart = 5;
    int selEnd = 10;
    Editable editable = sampleEditable(selStart, selEnd);
    InputConnectionAdaptor adaptor = sampleInputConnectionAdaptor(editable);

    KeyEvent shiftKeyUp = new KeyEvent(KeyEvent.ACTION_UP, KeyEvent.KEYCODE_SHIFT_LEFT);
    boolean didConsume = adaptor.sendKeyEvent(shiftKeyUp);

    assertTrue(didConsume);
    assertEquals(selEnd, Selection.getSelectionStart(editable));
    assertEquals(selEnd, Selection.getSelectionEnd(editable));
  }

  @Test
  public void testSendKeyEvent_leftKeyMovesCaretLeft() {
    int selStart = 5;
    Editable editable = sampleEditable(selStart, selStart);
    InputConnectionAdaptor adaptor = sampleInputConnectionAdaptor(editable);

    KeyEvent leftKeyDown = new KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_DPAD_LEFT);
    boolean didConsume = adaptor.sendKeyEvent(leftKeyDown);

    assertTrue(didConsume);
    assertEquals(selStart - 1, Selection.getSelectionStart(editable));
    assertEquals(selStart - 1, Selection.getSelectionEnd(editable));
  }

  @Test
  public void testSendKeyEvent_leftKeyMovesCaretLeftComplexEmoji() {
    int selStart = 75;
    Editable editable = sampleEditable(selStart, selStart, SAMPLE_EMOJI_TEXT);
    InputConnectionAdaptor adaptor = sampleInputConnectionAdaptor(editable);

    KeyEvent downKeyDown = new KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_DPAD_LEFT);
    boolean didConsume;

    // Normal Character
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 74);

    // Non-Spacing Mark
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 73);
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 72);

    // Keycap
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 69);

    // Keycap with invalid base
    adaptor.setSelection(68, 68);
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 66);
    adaptor.setSelection(67, 67);
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 66);

    // Zero Width Joiner
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 55);

    // Zero Width Joiner with invalid base
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 53);
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 52);
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 51);

    // ----- Start Emoji Tag Sequence with invalid base testing ----
    // Delete base tag
    adaptor.setSelection(39, 39);
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 37);

    // Delete the sequence
    adaptor.setSelection(49, 49);
    for (int i = 0; i < 6; i++) {
      didConsume = adaptor.sendKeyEvent(downKeyDown);
      assertTrue(didConsume);
    }
    assertEquals(Selection.getSelectionStart(editable), 37);
    // ----- End Emoji Tag Sequence with invalid base testing ----

    // Emoji Tag Sequence
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 23);

    // Variation Selector with invalid base
    adaptor.setSelection(22, 22);
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 21);
    adaptor.setSelection(22, 22);
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 21);

    // Variation Selector
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 19);

    // Emoji Modifier
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 16);

    // Emoji Modifier with invalid base
    adaptor.setSelection(14, 14);
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 13);
    adaptor.setSelection(14, 14);
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 13);

    // Line Feed
    adaptor.setSelection(12, 12);
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 11);

    // Carriage Return
    adaptor.setSelection(12, 12);
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 11);

    // Carriage Return and Line Feed
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 9);

    // Regional Indicator Symbol odd
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 7);

    // Regional Indicator Symbol even
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 3);

    // Simple Emoji
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 1);

    // First CodePoint
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 0);
  }

  @Test
  public void testSendKeyEvent_leftKeyExtendsSelectionLeft() {
    int selStart = 5;
    int selEnd = 40;
    Editable editable = sampleEditable(selStart, selEnd);
    InputConnectionAdaptor adaptor = sampleInputConnectionAdaptor(editable);

    KeyEvent leftKeyDown = new KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_DPAD_LEFT);
    boolean didConsume = adaptor.sendKeyEvent(leftKeyDown);

    assertTrue(didConsume);
    assertEquals(selStart, Selection.getSelectionStart(editable));
    assertEquals(selEnd - 1, Selection.getSelectionEnd(editable));
  }

  @Test
  public void testSendKeyEvent_shiftLeftKeyStartsSelectionLeft() {
    int selStart = 5;
    Editable editable = sampleEditable(selStart, selStart);
    InputConnectionAdaptor adaptor = sampleInputConnectionAdaptor(editable);

    KeyEvent shiftLeftKeyDown =
        new KeyEvent(
            0, 0, KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_DPAD_LEFT, 0, KeyEvent.META_SHIFT_ON);
    boolean didConsume = adaptor.sendKeyEvent(shiftLeftKeyDown);

    assertTrue(didConsume);
    assertEquals(selStart, Selection.getSelectionStart(editable));
    assertEquals(selStart - 1, Selection.getSelectionEnd(editable));
  }

  @Test
  public void testSendKeyEvent_rightKeyMovesCaretRight() {
    int selStart = 5;
    Editable editable = sampleEditable(selStart, selStart);
    InputConnectionAdaptor adaptor = sampleInputConnectionAdaptor(editable);

    KeyEvent rightKeyDown = new KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_DPAD_RIGHT);
    boolean didConsume = adaptor.sendKeyEvent(rightKeyDown);

    assertTrue(didConsume);
    assertEquals(selStart + 1, Selection.getSelectionStart(editable));
    assertEquals(selStart + 1, Selection.getSelectionEnd(editable));
  }

  @Test
  public void testSendKeyEvent_rightKeyMovesCaretRightComplexRegion() {
    int selStart = 0;
    // Seven region indicator characters. The first six should be considered as
    // three region indicators, and the final seventh character should be
    // considered to be on its own because it has no partner.
    String SAMPLE_REGION_TEXT = "🇷🇷🇷🇷🇷🇷🇷";
    Editable editable = sampleEditable(selStart, selStart, SAMPLE_REGION_TEXT);
    InputConnectionAdaptor adaptor = sampleInputConnectionAdaptor(editable);

    KeyEvent downKeyDown = new KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_DPAD_RIGHT);
    boolean didConsume;

    // The cursor moves over two region indicators at a time.
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 4);
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 8);
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 12);

    // When there is only one region indicator left with no pair, the cursor
    // moves over that single region indicator.
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 14);

    // If the cursor is placed in the middle of a region indicator pair, it
    // moves over only the second half of the pair.
    adaptor.setSelection(6, 6);
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 8);
  }

  @Test
  public void testSendKeyEvent_rightKeyMovesCaretRightComplexEmoji() {
    int selStart = 0;
    Editable editable = sampleEditable(selStart, selStart, SAMPLE_EMOJI_TEXT);
    InputConnectionAdaptor adaptor = sampleInputConnectionAdaptor(editable);

    KeyEvent downKeyDown = new KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_DPAD_RIGHT);
    boolean didConsume;

    // First CodePoint
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 1);

    // Simple Emoji
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 3);

    // Regional Indicator Symbol even
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 7);

    // Regional Indicator Symbol odd
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 9);

    // Carriage Return
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 10);

    // Line Feed and Carriage Return
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 12);

    // Line Feed
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 13);

    // Modified Emoji
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 16);

    // Emoji Modifier
    adaptor.setSelection(14, 14);
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 16);

    // Emoji Modifier with invalid base
    adaptor.setSelection(18, 18);
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 19);

    // Variation Selector
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 21);

    // Variation Selector with invalid base
    adaptor.setSelection(22, 22);
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 23);

    // Emoji Tag Sequence
    for (int i = 0; i < 7; i++) {
      didConsume = adaptor.sendKeyEvent(downKeyDown);
      assertTrue(didConsume);
      assertEquals(Selection.getSelectionStart(editable), 25 + 2 * i);
    }
    assertEquals(Selection.getSelectionStart(editable), 37);

    // ----- Start Emoji Tag Sequence with invalid base testing ----
    // Pass the sequence
    adaptor.setSelection(39, 39);
    for (int i = 0; i < 6; i++) {
      didConsume = adaptor.sendKeyEvent(downKeyDown);
      assertTrue(didConsume);
      assertEquals(Selection.getSelectionStart(editable), 41 + 2 * i);
    }
    assertEquals(Selection.getSelectionStart(editable), 51);
    // ----- End Emoji Tag Sequence with invalid base testing ----

    // Zero Width Joiner with invalid base
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 52);
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 53);
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 55);

    // Zero Width Joiner
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 66);

    // Keycap with invalid base
    adaptor.setSelection(67, 67);
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 68);
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 69);

    // Keycap
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 72);

    // Non-Spacing Mark
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 73);
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 74);

    // Normal Character
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 75);
  }

  @Test
  public void testSendKeyEvent_rightKeyExtendsSelectionRight() {
    int selStart = 5;
    int selEnd = 40;
    Editable editable = sampleEditable(selStart, selEnd);
    InputConnectionAdaptor adaptor = sampleInputConnectionAdaptor(editable);

    KeyEvent rightKeyDown = new KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_DPAD_RIGHT);
    boolean didConsume = adaptor.sendKeyEvent(rightKeyDown);

    assertTrue(didConsume);
    assertEquals(selStart, Selection.getSelectionStart(editable));
    assertEquals(selEnd + 1, Selection.getSelectionEnd(editable));
  }

  @Test
  public void testSendKeyEvent_shiftRightKeyStartsSelectionRight() {
    int selStart = 5;
    Editable editable = sampleEditable(selStart, selStart);
    InputConnectionAdaptor adaptor = sampleInputConnectionAdaptor(editable);

    KeyEvent shiftRightKeyDown =
        new KeyEvent(
            0, 0, KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_DPAD_RIGHT, 0, KeyEvent.META_SHIFT_ON);
    boolean didConsume = adaptor.sendKeyEvent(shiftRightKeyDown);

    assertTrue(didConsume);
    assertEquals(selStart, Selection.getSelectionStart(editable));
    assertEquals(selStart + 1, Selection.getSelectionEnd(editable));
  }

  @Test
  public void testSendKeyEvent_upKeyMovesCaretUp() {
    int selStart = SAMPLE_TEXT.indexOf('\n') + 4;
    Editable editable = sampleEditable(selStart, selStart);
    InputConnectionAdaptor adaptor = sampleInputConnectionAdaptor(editable);

    KeyEvent upKeyDown = new KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_DPAD_UP);
    boolean didConsume = adaptor.sendKeyEvent(upKeyDown);

    assertTrue(didConsume);
    // Checks the caret moved left (to some previous character). Selection.moveUp() behaves
    // different in tests than on a real device, we can't verify the exact position.
    assertTrue(Selection.getSelectionStart(editable) < selStart);
  }

  @Test
  public void testSendKeyEvent_downKeyMovesCaretDown() {
    int selStart = 4;
    Editable editable = sampleEditable(selStart, selStart);
    InputConnectionAdaptor adaptor = sampleInputConnectionAdaptor(editable);

    KeyEvent downKeyDown = new KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_DPAD_DOWN);
    boolean didConsume = adaptor.sendKeyEvent(downKeyDown);

    assertTrue(didConsume);
    // Checks the caret moved right (to some following character). Selection.moveDown() behaves
    // different in tests than on a real device, we can't verify the exact position.
    assertTrue(Selection.getSelectionStart(editable) > selStart);
  }

  @Test
  public void testMethod_getExtractedText() {
    int selStart = 5;
    Editable editable = sampleEditable(selStart, selStart);
    InputConnectionAdaptor adaptor = sampleInputConnectionAdaptor(editable);

    ExtractedText extractedText = adaptor.getExtractedText(null, 0);

    assertEquals(extractedText.text, SAMPLE_TEXT);
    assertEquals(extractedText.selectionStart, selStart);
    assertEquals(extractedText.selectionEnd, selStart);
  }

  @Test
  public void inputConnectionAdaptor_RepeatFilter() throws NullPointerException {
    View testView = new View(RuntimeEnvironment.application);
    FlutterJNI mockFlutterJni = mock(FlutterJNI.class);
    DartExecutor dartExecutor = spy(new DartExecutor(mockFlutterJni, mock(AssetManager.class)));
    int inputTargetId = 0;
    TestTextInputChannel textInputChannel = new TestTextInputChannel(dartExecutor);
    Editable mEditable = Editable.Factory.getInstance().newEditable("");
    Editable spyEditable = spy(mEditable);
    EditorInfo outAttrs = new EditorInfo();
    outAttrs.inputType = InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_MULTI_LINE;

    InputConnectionAdaptor inputConnectionAdaptor =
        new InputConnectionAdaptor(
            testView, inputTargetId, textInputChannel, spyEditable, outAttrs);

    inputConnectionAdaptor.beginBatchEdit();
    assertEquals(textInputChannel.updateEditingStateInvocations, 0);
    inputConnectionAdaptor.setComposingText("I do not fear computers. I fear the lack of them.", 1);
    assertEquals(textInputChannel.text, null);
    assertEquals(textInputChannel.updateEditingStateInvocations, 0);
    inputConnectionAdaptor.endBatchEdit();
    assertEquals(textInputChannel.updateEditingStateInvocations, 1);
    assertEquals(textInputChannel.text, "I do not fear computers. I fear the lack of them.");

    inputConnectionAdaptor.beginBatchEdit();
    assertEquals(textInputChannel.updateEditingStateInvocations, 1);
    inputConnectionAdaptor.endBatchEdit();
    assertEquals(textInputChannel.updateEditingStateInvocations, 1);

    inputConnectionAdaptor.beginBatchEdit();
    assertEquals(textInputChannel.text, "I do not fear computers. I fear the lack of them.");
    assertEquals(textInputChannel.updateEditingStateInvocations, 1);
    inputConnectionAdaptor.setSelection(3, 4);
    assertEquals(textInputChannel.updateEditingStateInvocations, 1);
    assertEquals(textInputChannel.selectionStart, 49);
    assertEquals(textInputChannel.selectionEnd, 49);
    inputConnectionAdaptor.endBatchEdit();
    assertEquals(textInputChannel.updateEditingStateInvocations, 2);
    assertEquals(textInputChannel.selectionStart, 3);
    assertEquals(textInputChannel.selectionEnd, 4);
  }

  @Test
  public void testSendKeyEvent_delKeyDeletesBackward() {
    int selStart = 29;
    Editable editable = sampleEditable(selStart, selStart, SAMPLE_RTL_TEXT);
    InputConnectionAdaptor adaptor = sampleInputConnectionAdaptor(editable);

    KeyEvent downKeyDown = new KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_DEL);

    for (int i = 0; i < 9; i++) {
      boolean didConsume = adaptor.sendKeyEvent(downKeyDown);
      assertTrue(didConsume);
    }
    assertEquals(Selection.getSelectionStart(editable), 19);

    for (int i = 0; i < 9; i++) {
      boolean didConsume = adaptor.sendKeyEvent(downKeyDown);
      assertTrue(didConsume);
    }
    assertEquals(Selection.getSelectionStart(editable), 10);
  }

  @Test
  public void testSendKeyEvent_delKeyDeletesBackwardComplexEmojis() {
    int selStart = 75;
    Editable editable = sampleEditable(selStart, selStart, SAMPLE_EMOJI_TEXT);
    InputConnectionAdaptor adaptor = sampleInputConnectionAdaptor(editable);

    KeyEvent downKeyDown = new KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_DEL);
    boolean didConsume;

    // Normal Character
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 74);

    // Non-Spacing Mark
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 73);
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 72);

    // Keycap
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 69);

    // Keycap with invalid base
    adaptor.setSelection(68, 68);
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 66);
    adaptor.setSelection(67, 67);
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 66);

    // Zero Width Joiner
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 55);

    // Zero Width Joiner with invalid base
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 53);
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 52);
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 51);

    // ----- Start Emoji Tag Sequence with invalid base testing ----
    // Delete base tag
    adaptor.setSelection(39, 39);
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 37);

    // Delete the sequence
    adaptor.setSelection(49, 49);
    for (int i = 0; i < 6; i++) {
      didConsume = adaptor.sendKeyEvent(downKeyDown);
      assertTrue(didConsume);
    }
    assertEquals(Selection.getSelectionStart(editable), 37);
    // ----- End Emoji Tag Sequence with invalid base testing ----

    // Emoji Tag Sequence
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 23);

    // Variation Selector with invalid base
    adaptor.setSelection(22, 22);
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 21);
    adaptor.setSelection(22, 22);
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 21);

    // Variation Selector
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 19);

    // Emoji Modifier
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 16);

    // Emoji Modifier with invalid base
    adaptor.setSelection(14, 14);
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 13);
    adaptor.setSelection(14, 14);
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 13);

    // Line Feed
    adaptor.setSelection(12, 12);
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 11);

    // Carriage Return
    adaptor.setSelection(12, 12);
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 11);

    // Carriage Return and Line Feed
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 9);

    // Regional Indicator Symbol odd
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 7);

    // Regional Indicator Symbol even
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 3);

    // Simple Emoji
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 1);

    // First CodePoint
    didConsume = adaptor.sendKeyEvent(downKeyDown);
    assertTrue(didConsume);
    assertEquals(Selection.getSelectionStart(editable), 0);
  }

  private static final String SAMPLE_TEXT =
      "Lorem ipsum dolor sit amet," + "\nconsectetur adipiscing elit.";

  private static final String SAMPLE_EMOJI_TEXT =
      "a" // First CodePoint
          + "😂" // Simple Emoji
          + "🇮🇷" // Regional Indicator Symbol even
          + "🇷" // Regional Indicator Symbol odd
          + "\r\n" // Carriage Return and Line Feed
          + "\r\n"
          + "✋🏿" // Emoji Modifier
          + "✋🏿"
          + "⚠️" // Variant Selector
          + "⚠️"
          + "🏴󠁧󠁢󠁥󠁮󠁧󠁿" // Emoji Tag Sequence
          + "🏴󠁧󠁢󠁥󠁮󠁧󠁿"
          + "a‍👨" // Zero Width Joiner
          + "👨‍👩‍👧‍👦"
          + "5️⃣" // Keycap
          + "5️⃣"
          + "عَ" // Non-Spacing Mark
          + "a"; // Normal Character

  private static final String SAMPLE_RTL_TEXT = "متن ساختگی" + "\nبرای تستfor test😊";

  private static Editable sampleEditable(int selStart, int selEnd) {
    SpannableStringBuilder sample = new SpannableStringBuilder(SAMPLE_TEXT);
    Selection.setSelection(sample, selStart, selEnd);
    return sample;
  }

  private static Editable sampleEditable(int selStart, int selEnd, String text) {
    SpannableStringBuilder sample = new SpannableStringBuilder(text);
    Selection.setSelection(sample, selStart, selEnd);
    return sample;
  }

  private static InputConnectionAdaptor sampleInputConnectionAdaptor(Editable editable) {
    View testView = new View(RuntimeEnvironment.application);
    int client = 0;
    TextInputChannel textInputChannel = mock(TextInputChannel.class);
    FlutterJNI mockFlutterJNI = mock(FlutterJNI.class);
    when(mockFlutterJNI.nativeFlutterTextUtilsIsEmoji(anyInt()))
        .thenAnswer((invocation) -> Emoji.isEmoji((int) invocation.getArguments()[0]));
    when(mockFlutterJNI.nativeFlutterTextUtilsIsEmojiModifier(anyInt()))
        .thenAnswer((invocation) -> Emoji.isEmojiModifier((int) invocation.getArguments()[0]));
    when(mockFlutterJNI.nativeFlutterTextUtilsIsEmojiModifierBase(anyInt()))
        .thenAnswer((invocation) -> Emoji.isEmojiModifierBase((int) invocation.getArguments()[0]));
    when(mockFlutterJNI.nativeFlutterTextUtilsIsVariationSelector(anyInt()))
        .thenAnswer(
            (invocation) -> {
              int codePoint = (int) invocation.getArguments()[0];
              return 0xFE0E <= codePoint && codePoint <= 0xFE0F;
            });
    when(mockFlutterJNI.nativeFlutterTextUtilsIsRegionalIndicator(anyInt()))
        .thenAnswer(
            (invocation) -> Emoji.isRegionalIndicatorSymbol((int) invocation.getArguments()[0]));
    return new InputConnectionAdaptor(
        testView, client, textInputChannel, editable, null, mockFlutterJNI);
  }

  private class TestTextInputChannel extends TextInputChannel {
    public TestTextInputChannel(DartExecutor dartExecutor) {
      super(dartExecutor);
    }

    public int inputClientId;
    public String text;
    public int selectionStart;
    public int selectionEnd;
    public int composingStart;
    public int composingEnd;
    public int updateEditingStateInvocations = 0;

    @Override
    public void updateEditingState(
        int inputClientId,
        String text,
        int selectionStart,
        int selectionEnd,
        int composingStart,
        int composingEnd) {
      this.inputClientId = inputClientId;
      this.text = text;
      this.selectionStart = selectionStart;
      this.selectionEnd = selectionEnd;
      this.composingStart = composingStart;
      this.composingEnd = composingEnd;
      updateEditingStateInvocations++;
    }
  }
}
