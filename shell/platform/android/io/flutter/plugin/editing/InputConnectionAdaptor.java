// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.editing;

import android.content.Context;
import android.text.Editable;
import android.text.Selection;
import android.view.KeyEvent;
import android.view.View;
import android.view.inputmethod.BaseInputConnection;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputMethodManager;

import io.flutter.embedding.engine.systemchannels.TextInputChannel;
import io.flutter.plugin.common.ErrorLogResult;
import io.flutter.plugin.common.MethodChannel;

class InputConnectionAdaptor extends BaseInputConnection {
    private final View mFlutterView;
    private final int mClient;
    private final TextInputChannel textInputChannel;
    private final Editable mEditable;
    private int mBatchCount;
    private InputMethodManager mImm;

    private static final MethodChannel.Result logger =
        new ErrorLogResult("FlutterTextInput");

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

    @Override
    public boolean sendKeyEvent(KeyEvent event) {
        if (event.getAction() == KeyEvent.ACTION_DOWN) {
            if (event.getKeyCode() == KeyEvent.KEYCODE_DEL) {
                int selStart = Selection.getSelectionStart(mEditable);
                int selEnd = Selection.getSelectionEnd(mEditable);
                if (selEnd > selStart) {
                    // Delete the selection.
                    Selection.setSelection(mEditable, selStart);
                    mEditable.delete(selStart, selEnd);
                    updateEditingState();
                    return true;
                } else if (selStart > 0) {
                    // Delete to the left of the cursor.
                    int newSel = Math.max(selStart - 1, 0);
                    Selection.setSelection(mEditable, newSel);
                    mEditable.delete(newSel, selStart);
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
