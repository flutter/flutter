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
    private KeyboardViewState mState;
    private EditingState mEditingState;

    public InputConnectionAdaptor(View view, KeyboardViewState state) {
        super(view, true);
        assert state != null;
        mState = state;
        mEditingState = new EditingState();
    }

    private void updateEditingState() {
        Editable content = getEditable();
        mEditingState.text = content.toString();
        mEditingState.selectionBase = Selection.getSelectionStart(content);
        mEditingState.selectionExtent = Selection.getSelectionEnd(content);
        mEditingState.composingBase = BaseInputConnection.getComposingSpanStart(content);
        mEditingState.composingExtent = BaseInputConnection.getComposingSpanEnd(content);
        mState.getClient().updateEditingState(mEditingState);
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
        if (event.getAction() == KeyEvent.ACTION_UP)
            commitText(String.valueOf(event.getNumber()), 1);
        return result;
    }

    @Override
    public boolean performEditorAction(int actionCode) {
        mState.getClient().submit(SubmitAction.DONE);
        return true;
    }
}
