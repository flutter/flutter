// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.editing;

import android.content.Context;
import android.text.DynamicLayout;
import android.text.Editable;
import android.text.Layout;
import android.text.Layout.Directions;
import android.text.Selection;
import android.text.TextPaint;
import android.view.KeyEvent;
import android.view.View;
import android.view.inputmethod.BaseInputConnection;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputMethodManager;

import io.flutter.embedding.engine.systemchannels.TextInputChannel;
import io.flutter.Log;
import io.flutter.plugin.common.ErrorLogResult;
import io.flutter.plugin.common.MethodChannel;

class InputConnectionAdaptor extends BaseInputConnection {
    private final View mFlutterView;
    private final int mClient;
    private final TextInputChannel textInputChannel;
    private final Editable mEditable;
    private int mBatchCount;
    private InputMethodManager mImm;
    private final Layout mLayout;

    @SuppressWarnings("deprecation")
    public InputConnectionAdaptor(
        View view,
        int client,
        TextInputChannel textInputChannel,
        Editable editable
    ) {
        super(view, true);
        mFlutterView = view;
        mClient = client;
        this.textInputChannel = textInputChannel;
        mEditable = editable;
        mBatchCount = 0;
        // We create a dummy Layout with max width so that the selection
        // shifting acts as if all text were in one line.
        mLayout = new DynamicLayout(mEditable, new TextPaint(), Integer.MAX_VALUE, Layout.Alignment.ALIGN_NORMAL, 1.0f, 0.0f, false);
        mImm = (InputMethodManager) view.getContext().getSystemService(Context.INPUT_METHOD_SERVICE);
    }

    // Send the current state of the editable to Flutter.
    private void updateEditingState() {
        // If the IME is in the middle of a batch edit, then wait until it completes.
        if (mBatchCount > 0)
            return;

        int selectionStart = Selection.getSelectionStart(mEditable);
        int selectionEnd = Selection.getSelectionEnd(mEditable);
        int composingStart = BaseInputConnection.getComposingSpanStart(mEditable);
        int composingEnd = BaseInputConnection.getComposingSpanEnd(mEditable);

        mImm.updateSelection(mFlutterView,
                             selectionStart, selectionEnd,
                             composingStart, composingEnd);

        textInputChannel.updateEditingState(
            mClient,
            mEditable.toString(),
            selectionStart,
            selectionEnd,
            composingStart,
            composingEnd
        );
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
        if (Selection.getSelectionStart(mEditable) == -1)
            return true;

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
            Log.d("flutter", "Text selection index was clamped ("
                + index + "->" + clamped
                + ") to remain in bounds. This may not be your fault, as some keyboards may select outside of bounds."
            );
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
                int newSel = Math.max(selStart - 1, 0);
                setSelection(newSel, newSel);
                return true;
            } else if (event.getKeyCode() == KeyEvent.KEYCODE_DPAD_RIGHT) {
                int selStart = Selection.getSelectionStart(mEditable);
                int newSel = Math.min(selStart + 1, mEditable.length());
                setSelection(newSel, newSel);
                return true;
            } else {
                // Enter a character.
                int character = event.getUnicodeChar();
                if (character != 0) {
                    int selStart = Math.max(0, Selection.getSelectionStart(mEditable));
                    int selEnd = Math.max(0, Selection.getSelectionEnd(mEditable));
                    if (selEnd != selStart)
                        mEditable.delete(selStart, selEnd);
                    mEditable.insert(selStart, String.valueOf((char) character));
                    setSelection(selStart + 1, selStart + 1);
                    updateEditingState();
                }
                return true;
            }
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
