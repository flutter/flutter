// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.editing;

import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.text.DynamicLayout;
import android.text.Editable;
import android.text.InputType;
import android.text.Layout;
import android.text.Selection;
import android.text.TextPaint;
import android.text.method.TextKeyListener;
import android.view.KeyEvent;
import android.view.View;
import android.view.inputmethod.BaseInputConnection;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.ExtractedText;
import android.view.inputmethod.ExtractedTextRequest;
import android.view.inputmethod.InputMethodManager;
import io.flutter.Log;
import io.flutter.embedding.engine.systemchannels.TextInputChannel;

class InputConnectionAdaptor extends BaseInputConnection {
  private final View mFlutterView;
  private final int mClient;
  private final TextInputChannel textInputChannel;
  private final Editable mEditable;
  private final EditorInfo mEditorInfo;
  private int mBatchCount;
  private InputMethodManager mImm;
  private final Layout mLayout;

  private boolean mRepeatCheckNeeded = false;
  private TextEditingValue mLastSentTextEditngValue;
  // Data class used to get and store the last-sent values via updateEditingState to
  // the  framework. These are then compared against to prevent redundant messages
  // with the same data before any valid operations were made to the contents.
  private class TextEditingValue {
    public int selectionStart;
    public int selectionEnd;
    public int composingStart;
    public int composingEnd;
    public String text;

    public TextEditingValue(Editable editable) {
      selectionStart = Selection.getSelectionStart(editable);
      selectionEnd = Selection.getSelectionEnd(editable);
      composingStart = BaseInputConnection.getComposingSpanStart(editable);
      composingEnd = BaseInputConnection.getComposingSpanEnd(editable);
      text = editable.toString();
    }

    @Override
    public boolean equals(Object o) {
      if (o == this) {
        return true;
      }
      if (!(o instanceof TextEditingValue)) {
        return false;
      }
      TextEditingValue value = (TextEditingValue) o;
      return selectionStart == value.selectionStart
          && selectionEnd == value.selectionEnd
          && composingStart == value.composingStart
          && composingEnd == value.composingEnd
          && text.equals(value.text);
    }

    @Override
    public int hashCode() {
      final int prime = 31;
      int result = 1;
      result = prime * result + selectionStart;
      result = prime * result + selectionEnd;
      result = prime * result + composingStart;
      result = prime * result + composingEnd;
      result = prime * result + text.hashCode();
      return result;
    }
  }

  @SuppressWarnings("deprecation")
  public InputConnectionAdaptor(
      View view,
      int client,
      TextInputChannel textInputChannel,
      Editable editable,
      EditorInfo editorInfo) {
    super(view, true);
    mFlutterView = view;
    mClient = client;
    this.textInputChannel = textInputChannel;
    mEditable = editable;
    mEditorInfo = editorInfo;
    mBatchCount = 0;
    // We create a dummy Layout with max width so that the selection
    // shifting acts as if all text were in one line.
    mLayout =
        new DynamicLayout(
            mEditable,
            new TextPaint(),
            Integer.MAX_VALUE,
            Layout.Alignment.ALIGN_NORMAL,
            1.0f,
            0.0f,
            false);
    mImm = (InputMethodManager) view.getContext().getSystemService(Context.INPUT_METHOD_SERVICE);
  }

  // Send the current state of the editable to Flutter.
  private void updateEditingState() {
    // If the IME is in the middle of a batch edit, then wait until it completes.
    if (mBatchCount > 0) return;

    TextEditingValue currentValue = new TextEditingValue(mEditable);

    // Return if this data has already been sent and no meaningful changes have
    // occurred to mark this as dirty. This prevents duplicate remote updates of
    // the same data, which can break formatters that change the length of the
    // contents.
    if (mRepeatCheckNeeded && currentValue.equals(mLastSentTextEditngValue)) {
      return;
    }

    mImm.updateSelection(
        mFlutterView,
        currentValue.selectionStart,
        currentValue.selectionEnd,
        currentValue.composingStart,
        currentValue.composingEnd);

    textInputChannel.updateEditingState(
        mClient,
        currentValue.text,
        currentValue.selectionStart,
        currentValue.selectionEnd,
        currentValue.composingStart,
        currentValue.composingEnd);

    mRepeatCheckNeeded = true;
    mLastSentTextEditngValue = currentValue;
  }

  // This should be called whenever a change could have been made to
  // the value of mEditable, which will make any call of updateEditingState()
  // ineligible for repeat checking as we do not want to skip sending real changes
  // to the framework.
  public void markDirty() {
    // Disable updateEditngState's repeat-update check
    mRepeatCheckNeeded = false;
  }

  @Override
  public Editable getEditable() {
    return mEditable;
  }

  @Override
  public boolean beginBatchEdit() {
    mBatchCount++;
    return super.beginBatchEdit();
  }

  @Override
  public boolean endBatchEdit() {
    boolean result = super.endBatchEdit();
    mBatchCount--;
    updateEditingState();
    return result;
  }

  @Override
  public boolean commitText(CharSequence text, int newCursorPosition) {
    boolean result = super.commitText(text, newCursorPosition);
    markDirty();
    return result;
  }

  @Override
  public boolean deleteSurroundingText(int beforeLength, int afterLength) {
    if (Selection.getSelectionStart(mEditable) == -1) return true;

    boolean result = super.deleteSurroundingText(beforeLength, afterLength);
    markDirty();
    return result;
  }

  @Override
  public boolean deleteSurroundingTextInCodePoints(int beforeLength, int afterLength) {
    boolean result = super.deleteSurroundingTextInCodePoints(beforeLength, afterLength);
    markDirty();
    return result;
  }

  @Override
  public boolean setComposingRegion(int start, int end) {
    boolean result = super.setComposingRegion(start, end);
    markDirty();
    return result;
  }

  @Override
  public boolean setComposingText(CharSequence text, int newCursorPosition) {
    boolean result;
    if (text.length() == 0) {
      result = super.commitText(text, newCursorPosition);
    } else {
      result = super.setComposingText(text, newCursorPosition);
    }
    markDirty();
    return result;
  }

  @Override
  public boolean finishComposingText() {
    boolean result = super.finishComposingText();
    markDirty();
    return result;
  }

  // TODO(garyq): Implement a more feature complete version of getExtractedText
  @Override
  public ExtractedText getExtractedText(ExtractedTextRequest request, int flags) {
    ExtractedText extractedText = new ExtractedText();
    extractedText.selectionStart = Selection.getSelectionStart(mEditable);
    extractedText.selectionEnd = Selection.getSelectionEnd(mEditable);
    extractedText.text = mEditable.toString();
    return extractedText;
  }

  @Override
  public boolean clearMetaKeyStates(int states) {
    boolean result = super.clearMetaKeyStates(states);
    markDirty();
    return result;
  }

  @Override
  public boolean setSelection(int start, int end) {
    boolean result = super.setSelection(start, end);
    markDirty();
    updateEditingState();
    return result;
  }

  // Sanitizes the index to ensure the index is within the range of the
  // contents of editable.
  private static int clampIndexToEditable(int index, Editable editable) {
    int clamped = Math.max(0, Math.min(editable.length(), index));
    if (clamped != index) {
      Log.d(
          "flutter",
          "Text selection index was clamped ("
              + index
              + "->"
              + clamped
              + ") to remain in bounds. This may not be your fault, as some keyboards may select outside of bounds.");
    }
    return clamped;
  }

  @Override
  public boolean sendKeyEvent(KeyEvent event) {
    markDirty();
    if (event.getAction() == KeyEvent.ACTION_DOWN) {
      if (event.getKeyCode() == KeyEvent.KEYCODE_DEL) {
        int selStart = clampIndexToEditable(Selection.getSelectionStart(mEditable), mEditable);
        int selEnd = clampIndexToEditable(Selection.getSelectionEnd(mEditable), mEditable);
        if (selEnd > selStart) {
          // Delete the selection.
          Selection.setSelection(mEditable, selStart);
          mEditable.delete(selStart, selEnd);
          updateEditingState();
          return true;
        } else if (selStart > 0) {
          if (TextKeyListener.getInstance().onKeyDown(null, mEditable, event.getKeyCode(), event)) {
            updateEditingState();
            return true;
          }
          return false;
        }
      } else if (event.getKeyCode() == KeyEvent.KEYCODE_DPAD_LEFT) {
        int selStart = Selection.getSelectionStart(mEditable);
        int selEnd = Selection.getSelectionEnd(mEditable);
        if (selStart == selEnd && !event.isShiftPressed()) {
          int newSel = Math.max(selStart - 1, 0);
          setSelection(newSel, newSel);
        } else {
          int newSelEnd = Math.max(selEnd - 1, 0);
          setSelection(selStart, newSelEnd);
        }
        return true;
      } else if (event.getKeyCode() == KeyEvent.KEYCODE_DPAD_RIGHT) {
        int selStart = Selection.getSelectionStart(mEditable);
        int selEnd = Selection.getSelectionEnd(mEditable);
        if (selStart == selEnd && !event.isShiftPressed()) {
          int newSel = Math.min(selStart + 1, mEditable.length());
          setSelection(newSel, newSel);
        } else {
          int newSelEnd = Math.min(selEnd + 1, mEditable.length());
          setSelection(selStart, newSelEnd);
        }
        return true;
      } else if (event.getKeyCode() == KeyEvent.KEYCODE_DPAD_UP) {
        int selStart = Selection.getSelectionStart(mEditable);
        int selEnd = Selection.getSelectionEnd(mEditable);
        if (selStart == selEnd && !event.isShiftPressed()) {
          Selection.moveUp(mEditable, mLayout);
          int newSelStart = Selection.getSelectionStart(mEditable);
          setSelection(newSelStart, newSelStart);
        } else {
          Selection.extendUp(mEditable, mLayout);
          int newSelStart = Selection.getSelectionStart(mEditable);
          int newSelEnd = Selection.getSelectionEnd(mEditable);
          setSelection(newSelStart, newSelEnd);
        }
        return true;
      } else if (event.getKeyCode() == KeyEvent.KEYCODE_DPAD_DOWN) {
        int selStart = Selection.getSelectionStart(mEditable);
        int selEnd = Selection.getSelectionEnd(mEditable);
        if (selStart == selEnd && !event.isShiftPressed()) {
          Selection.moveDown(mEditable, mLayout);
          int newSelStart = Selection.getSelectionStart(mEditable);
          setSelection(newSelStart, newSelStart);
        } else {
          Selection.extendDown(mEditable, mLayout);
          int newSelStart = Selection.getSelectionStart(mEditable);
          int newSelEnd = Selection.getSelectionEnd(mEditable);
          setSelection(newSelStart, newSelEnd);
        }
        return true;
        // When the enter key is pressed on a non-multiline field, consider it a
        // submit instead of a newline.
      } else if ((event.getKeyCode() == KeyEvent.KEYCODE_ENTER
              || event.getKeyCode() == KeyEvent.KEYCODE_NUMPAD_ENTER)
          && (InputType.TYPE_TEXT_FLAG_MULTI_LINE & mEditorInfo.inputType) == 0) {
        performEditorAction(mEditorInfo.imeOptions & EditorInfo.IME_MASK_ACTION);
        return true;
      } else {
        // Enter a character.
        int character = event.getUnicodeChar();
        if (character != 0) {
          int selStart = Math.max(0, Selection.getSelectionStart(mEditable));
          int selEnd = Math.max(0, Selection.getSelectionEnd(mEditable));
          int selMin = Math.min(selStart, selEnd);
          int selMax = Math.max(selStart, selEnd);
          if (selMin != selMax) mEditable.delete(selMin, selMax);
          mEditable.insert(selMin, String.valueOf((char) character));
          setSelection(selMin + 1, selMin + 1);
        }
        return true;
      }
    }
    if (event.getAction() == KeyEvent.ACTION_UP
        && (event.getKeyCode() == KeyEvent.KEYCODE_SHIFT_LEFT
            || event.getKeyCode() == KeyEvent.KEYCODE_SHIFT_RIGHT)) {
      int selEnd = Selection.getSelectionEnd(mEditable);
      setSelection(selEnd, selEnd);
      return true;
    }
    return false;
  }

  @Override
  public boolean performContextMenuAction(int id) {
    markDirty();
    if (id == android.R.id.selectAll) {
      setSelection(0, mEditable.length());
      return true;
    } else if (id == android.R.id.cut) {
      int selStart = Selection.getSelectionStart(mEditable);
      int selEnd = Selection.getSelectionEnd(mEditable);
      if (selStart != selEnd) {
        int selMin = Math.min(selStart, selEnd);
        int selMax = Math.max(selStart, selEnd);
        CharSequence textToCut = mEditable.subSequence(selMin, selMax);
        ClipboardManager clipboard =
            (ClipboardManager)
                mFlutterView.getContext().getSystemService(Context.CLIPBOARD_SERVICE);
        ClipData clip = ClipData.newPlainText("text label?", textToCut);
        clipboard.setPrimaryClip(clip);
        mEditable.delete(selMin, selMax);
        setSelection(selMin, selMin);
      }
      return true;
    } else if (id == android.R.id.copy) {
      int selStart = Selection.getSelectionStart(mEditable);
      int selEnd = Selection.getSelectionEnd(mEditable);
      if (selStart != selEnd) {
        CharSequence textToCopy =
            mEditable.subSequence(Math.min(selStart, selEnd), Math.max(selStart, selEnd));
        ClipboardManager clipboard =
            (ClipboardManager)
                mFlutterView.getContext().getSystemService(Context.CLIPBOARD_SERVICE);
        clipboard.setPrimaryClip(ClipData.newPlainText("text label?", textToCopy));
      }
      return true;
    } else if (id == android.R.id.paste) {
      ClipboardManager clipboard =
          (ClipboardManager) mFlutterView.getContext().getSystemService(Context.CLIPBOARD_SERVICE);
      ClipData clip = clipboard.getPrimaryClip();
      if (clip != null) {
        CharSequence textToPaste = clip.getItemAt(0).coerceToText(mFlutterView.getContext());
        int selStart = Math.max(0, Selection.getSelectionStart(mEditable));
        int selEnd = Math.max(0, Selection.getSelectionEnd(mEditable));
        int selMin = Math.min(selStart, selEnd);
        int selMax = Math.max(selStart, selEnd);
        if (selMin != selMax) mEditable.delete(selMin, selMax);
        mEditable.insert(selMin, textToPaste);
        int newSelStart = selMin + textToPaste.length();
        setSelection(newSelStart, newSelStart);
      }
      return true;
    }
    return false;
  }

  @Override
  public boolean performEditorAction(int actionCode) {
    markDirty();
    switch (actionCode) {
      case EditorInfo.IME_ACTION_NONE:
        textInputChannel.newline(mClient);
        break;
      case EditorInfo.IME_ACTION_UNSPECIFIED:
        textInputChannel.unspecifiedAction(mClient);
        break;
      case EditorInfo.IME_ACTION_GO:
        textInputChannel.go(mClient);
        break;
      case EditorInfo.IME_ACTION_SEARCH:
        textInputChannel.search(mClient);
        break;
      case EditorInfo.IME_ACTION_SEND:
        textInputChannel.send(mClient);
        break;
      case EditorInfo.IME_ACTION_NEXT:
        textInputChannel.next(mClient);
        break;
      case EditorInfo.IME_ACTION_PREVIOUS:
        textInputChannel.previous(mClient);
        break;
      default:
      case EditorInfo.IME_ACTION_DONE:
        textInputChannel.done(mClient);
        break;
    }
    return true;
  }
}
