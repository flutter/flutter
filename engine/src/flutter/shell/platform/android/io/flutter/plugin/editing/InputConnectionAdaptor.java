// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.editing;

import android.annotation.SuppressLint;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.os.Build;
import android.provider.Settings;
import android.text.DynamicLayout;
import android.text.Editable;
import android.text.InputType;
import android.text.Layout;
import android.text.Selection;
import android.text.TextPaint;
import android.view.KeyEvent;
import android.view.View;
import android.view.inputmethod.BaseInputConnection;
import android.view.inputmethod.CursorAnchorInfo;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputMethodManager;
import android.view.inputmethod.InputMethodSubtype;
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

  // Used to determine if Samsung-specific hacks should be applied.
  private final boolean isSamsung;

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

    isSamsung = isSamsung();
  }

  // Send the current state of the editable to Flutter.
  private void updateEditingState() {
    // If the IME is in the middle of a batch edit, then wait until it completes.
    if (mBatchCount > 0) return;

    int selectionStart = Selection.getSelectionStart(mEditable);
    int selectionEnd = Selection.getSelectionEnd(mEditable);
    int composingStart = BaseInputConnection.getComposingSpanStart(mEditable);
    int composingEnd = BaseInputConnection.getComposingSpanEnd(mEditable);

    mImm.updateSelection(mFlutterView, selectionStart, selectionEnd, composingStart, composingEnd);

    textInputChannel.updateEditingState(
        mClient, mEditable.toString(), selectionStart, selectionEnd, composingStart, composingEnd);
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
    updateEditingState();
    return result;
  }

  @Override
  public boolean deleteSurroundingText(int beforeLength, int afterLength) {
    if (Selection.getSelectionStart(mEditable) == -1) return true;

    boolean result = super.deleteSurroundingText(beforeLength, afterLength);
    updateEditingState();
    return result;
  }

  @Override
  public boolean setComposingRegion(int start, int end) {
    boolean result = super.setComposingRegion(start, end);
    updateEditingState();
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
    updateEditingState();
    return result;
  }

  @Override
  public boolean finishComposingText() {
    boolean result = super.finishComposingText();

    // Apply Samsung hacks. Samsung caches composing region data strangely, causing text
    // duplication.
    if (isSamsung) {
      if (Build.VERSION.SDK_INT >= 21) {
        // Samsung keyboards don't clear the composing region on finishComposingText.
        // Update the keyboard with a reset/empty composing region. Critical on
        // Samsung keyboards to prevent punctuation duplication.
        CursorAnchorInfo.Builder builder = new CursorAnchorInfo.Builder();
        builder.setComposingText(/*composingTextStart*/ -1, /*composingText*/ "");
        CursorAnchorInfo anchorInfo = builder.build();
        mImm.updateCursorAnchorInfo(mFlutterView, anchorInfo);
      }
      // TODO(garyq): There is still a duplication case that comes from hiding+showing the keyboard.
      // The exact behavior to cause it has so far been hard to pinpoint and it happens far more
      // rarely than the original bug.

      // Temporarily indicate to the IME that the composing region selection should be reset.
      // The correct selection is then immediately set properly in the updateEditingState() call
      // in this method. This is a hack to trigger Samsung keyboard's internal cache to clear.
      // This prevents duplication on keyboard hide+show. See
      // https://github.com/flutter/flutter/issues/31512
      //
      // We only do this if the proper selection will be restored later, eg, when mBatchCount is 0.
      if (mBatchCount == 0) {
        mImm.updateSelection(
            mFlutterView,
            -1, /*selStart*/
            -1, /*selEnd*/
            -1, /*candidatesStart*/
            -1 /*candidatesEnd*/);
      }
    }

    updateEditingState();
    return result;
  }

  // Detect if the keyboard is a Samsung keyboard, where we apply Samsung-specific hacks to
  // fix critical bugs that make the keyboard otherwise unusable. See finishComposingText() for
  // more details.
  @SuppressLint("NewApi") // New API guard is inline, the linter can't see it.
  @SuppressWarnings("deprecation")
  private boolean isSamsung() {
    InputMethodSubtype subtype = mImm.getCurrentInputMethodSubtype();
    // Impacted devices all shipped with Android Lollipop or newer.
    if (subtype == null
        || Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP
        || !Build.MANUFACTURER.equals("samsung")) {
      return false;
    }
    String keyboardName =
        Settings.Secure.getString(
            mFlutterView.getContext().getContentResolver(), Settings.Secure.DEFAULT_INPUT_METHOD);
    // The Samsung keyboard is called "com.sec.android.inputmethod/.SamsungKeypad" but look
    // for "Samsung" just in case Samsung changes the name of the keyboard.
    return keyboardName.contains("Samsung");
  }

  @Override
  public boolean setSelection(int start, int end) {
    boolean result = super.setSelection(start, end);
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
          // Delete to the left/right of the cursor depending on direction of text.
          // TODO(garyq): Explore how to obtain per-character direction. The
          // isRTLCharAt() call below is returning blanket direction assumption
          // based on the first character in the line.
          boolean isRtl = mLayout.isRtlCharAt(mLayout.getLineForOffset(selStart));
          try {
            if (isRtl) {
              Selection.extendRight(mEditable, mLayout);
            } else {
              Selection.extendLeft(mEditable, mLayout);
            }
          } catch (IndexOutOfBoundsException e) {
            // On some Chinese devices (primarily Huawei, some Xiaomi),
            // on initial app startup before focus is lost, the
            // Selection.extendLeft and extendRight calls always extend
            // from the index of the initial contents of mEditable. This
            // try-catch will prevent crashing on Huawei devices by falling
            // back to a simple way of deletion, although this a hack and
            // will not handle emojis.
            Selection.setSelection(mEditable, selStart, selStart - 1);
          }
          int newStart = clampIndexToEditable(Selection.getSelectionStart(mEditable), mEditable);
          int newEnd = clampIndexToEditable(Selection.getSelectionEnd(mEditable), mEditable);
          Selection.setSelection(mEditable, Math.min(newStart, newEnd));
          // Min/Max the values since RTL selections will start at a higher
          // index than they end at.
          mEditable.delete(Math.min(newStart, newEnd), Math.max(newStart, newEnd));
          updateEditingState();
          return true;
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
