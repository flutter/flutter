// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.editing;

import android.text.Editable;
import android.text.Selection;
import android.view.inputmethod.BaseInputConnection;
import android.view.inputmethod.CompletionInfo;
import android.view.inputmethod.CorrectionInfo;
import android.view.inputmethod.EditorInfo;
import android.view.KeyEvent;
import android.view.View;

import org.chromium.mojom.editing.EditingState;
import org.chromium.mojom.editing.KeyboardClient;
import org.chromium.mojom.editing.SubmitAction;

/**
 * An adaptor between InputConnection and KeyboardClient.
 */
public class InputConnectionAdaptor extends BaseInputConnection {
    private KeyboardClient mClient;
    private EditingState mOutgoingState;

    public InputConnectionAdaptor(View view, KeyboardClient client) {
        super(view, true);
        assert client != null;
        mClient = client;
        mOutgoingState = new EditingState();
    }

    private void updateEditingState() {
        Editable content = getEditable();
        mOutgoingState.text = content.toString();
        mOutgoingState.selectionBase = Selection.getSelectionStart(content);
        mOutgoingState.selectionExtent = Selection.getSelectionEnd(content);
        mOutgoingState.composingBase = BaseInputConnection.getComposingSpanStart(content);
        mOutgoingState.composingExtent = BaseInputConnection.getComposingSpanEnd(content);
        mClient.updateEditingState(mOutgoingState);
    }

    @Override
    public boolean commitText(CharSequence text, int newCursorPosition) {
        boolean result = super.commitText(text, newCursorPosition);
        updateEditingState();
        return result;
    }

    @Override
    public boolean deleteSurroundingText(int beforeLength, int afterLength) {
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
        boolean result = super.setComposingText(text, newCursorPosition);
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
        boolean result = super.sendKeyEvent(event);
        if (event.getAction() == KeyEvent.ACTION_UP) {
            // Weird special case. This method is (sometimes) called for the backspace key in 2
            // situations:
            // 1. There is no selection. In that case, we want to delete the previous character.
            // 2. There is a selection. In that case, we want to delete the selection.
            //    event.getNumber() is 0, and commitText("", 1) will do what we want.
            if (event.getKeyCode() == KeyEvent.KEYCODE_DEL &&
                mOutgoingState.selectionBase == mOutgoingState.selectionExtent) {
              deleteSurroundingText(1, 0);
            } else {
              String text = event.getNumber() == 0 ? "" : String.valueOf(event.getNumber());
              commitText(text, 1);
            }
        }
        return result;
    }

    @Override
    public boolean performEditorAction(int actionCode) {
        mClient.submit(SubmitAction.DONE);
        return true;
    }
}
