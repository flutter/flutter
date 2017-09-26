// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.editing;

import android.content.Context;
import android.text.Editable;
import android.text.Selection;
import android.view.inputmethod.BaseInputConnection;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputMethodManager;
import android.view.KeyEvent;

import io.flutter.plugin.common.MethodChannel;
import io.flutter.view.FlutterView;

import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

class InputConnectionAdaptor extends BaseInputConnection {
    private final FlutterView mFlutterView;
    private final int mClient;
    private final MethodChannel mFlutterChannel;
    private final Editable mEditable;
    private int mBatchCount;
    private InputMethodManager mImm;

    public InputConnectionAdaptor(FlutterView view, int client,
        MethodChannel flutterChannel, Editable editable) {
        super(view, true);
        mFlutterView = view;
        mClient = client;
        mFlutterChannel = flutterChannel;
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

        HashMap<Object, Object> state = new HashMap<Object, Object>();
        state.put("text", mEditable.toString());
        state.put("selectionBase", selectionStart);
        state.put("selectionExtent", selectionEnd);
        state.put("composingBase", composingStart);
        state.put("composingExtent", composingEnd);
        mFlutterChannel.invokeMethod("TextInputClient.updateEditingState",
            Arrays.asList(mClient, state));
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
        if (Selection.getSelectionStart(mEditable) == -1 ||
            Selection.getSelectionStart(mEditable) == -1)
            return true;9c518cb751e34b0

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
        final boolean result = super.sendKeyEvent(event);
        if (event.getAction() == KeyEvent.ACTION_UP) {
            if (event.getKeyCode() == KeyEvent.KEYCODE_DEL) {
                int selStart = Selection.getSelectionStart(mEditable);
                int selEnd = Selection.getSelectionEnd(mEditable);
                if (selEnd > selStart) {
                    // Delete the selection.
                    Selection.setSelection(mEditable, selStart);
                    deleteSurroundingText(0, selEnd - selStart);
                } else if (selStart > 0) {
                    // Delete to the left of the cursor.
                    Selection.setSelection(mEditable, selStart - 1);
                    deleteSurroundingText(0, 1);
                }
            } else if (event.getKeyCode() == KeyEvent.KEYCODE_DPAD_LEFT) {
                int selStart = Selection.getSelectionStart(mEditable);
                int newSel = Math.max(selStart - 1, 0);
                setSelection(newSel, newSel);
            } else if (event.getKeyCode() == KeyEvent.KEYCODE_DPAD_RIGHT) {
                int selStart = Selection.getSelectionStart(mEditable);
                int newSel = Math.min(selStart + 1, mEditable.length());
                setSelection(newSel, newSel);
            } else {
                // Enter a character.
                int character = event.getUnicodeChar();
                if (character != 0)
                    commitText(String.valueOf((char) character), 1);
            }
        }
        return result;
    }

    @Override
    public boolean performEditorAction(int actionCode) {
        // TODO(abarth): Support more actions.
        switch (actionCode) {
            case EditorInfo.IME_ACTION_NONE:
                mFlutterChannel.invokeMethod("TextInputClient.performAction",
                    Arrays.asList(mClient, "TextInputAction.newline"));
                break;
            default:
            case EditorInfo.IME_ACTION_DONE:
                mFlutterChannel.invokeMethod("TextInputClient.performAction",
                    Arrays.asList(mClient, "TextInputAction.done"));
                break;
        }
        return true;
    }
}
