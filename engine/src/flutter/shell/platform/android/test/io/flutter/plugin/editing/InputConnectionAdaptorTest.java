package io.flutter.plugin.editing;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;
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
import io.flutter.util.FakeKeyEvent;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;
import org.robolectric.shadows.ShadowClipboardManager;

@Config(manifest = Config.NONE, shadows = ShadowClipboardManager.class)
@RunWith(RobolectricTestRunner.class)
public class InputConnectionAdaptorTest {
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
