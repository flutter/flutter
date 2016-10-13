// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.editing;

import android.content.Context;
import android.text.Editable;
import android.text.InputType;
import android.text.Selection;
import android.text.SpannableStringBuilder;
import android.util.Log;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputConnection;
import android.view.inputmethod.InputMethodManager;
import android.view.View;

import org.chromium.mojom.editing.EditingState;
import org.chromium.mojom.editing.KeyboardClient;
import org.chromium.mojom.editing.KeyboardConfiguration;
import org.chromium.mojom.editing.KeyboardType;

/**
 * Per-View keyboard state.
 */
public class KeyboardViewState {
    private View mView;
    private KeyboardClient mClient;
    private KeyboardConfiguration mConfiguration;
    private EditingState mIncomingState;

    public KeyboardViewState(View view) {
        mView = view;
        mClient = null;
    }

    public void setClient(KeyboardClient client, KeyboardConfiguration configuration) {
        if (mClient != null)
            mClient.close();
        mIncomingState = null;
        mClient = client;
        mConfiguration = configuration;
        InputMethodManager imm =
                (InputMethodManager) mView.getContext().getSystemService(Context.INPUT_METHOD_SERVICE);
        imm.restartInput(mView);
    }

    public void setEditingState(EditingState state) {
        mIncomingState = state;
        InputMethodManager imm =
                (InputMethodManager) mView.getContext().getSystemService(Context.INPUT_METHOD_SERVICE);
        imm.restartInput(mView);
    }

    private static int inputTypeFromKeyboardType(int keyboardType) {
        if (keyboardType == KeyboardType.DATETIME)
            return InputType.TYPE_CLASS_DATETIME;
        if (keyboardType == KeyboardType.NUMBER)
            return InputType.TYPE_CLASS_NUMBER;
        if (keyboardType == KeyboardType.PHONE)
            return InputType.TYPE_CLASS_PHONE;
        return InputType.TYPE_CLASS_TEXT;
    }

    public InputConnection createInputConnection(EditorInfo outAttrs) {
        if (mClient == null)
            return null;
        outAttrs.inputType = inputTypeFromKeyboardType(mConfiguration.type);
        outAttrs.actionLabel = mConfiguration.actionLabel;
        outAttrs.imeOptions = EditorInfo.IME_ACTION_DONE | EditorInfo.IME_FLAG_NO_FULLSCREEN;
        InputConnectionAdaptor connection = new InputConnectionAdaptor(mView, mClient);
        if (mIncomingState != null) {
            outAttrs.initialSelStart = mIncomingState.selectionBase;
            outAttrs.initialSelEnd = mIncomingState.selectionExtent;
            connection.getEditable().append(mIncomingState.text);
            connection.setSelection(mIncomingState.selectionBase,
                                    mIncomingState.selectionExtent);
            connection.setComposingRegion(mIncomingState.composingBase,
                                          mIncomingState.composingExtent);
        } else {
            outAttrs.initialSelStart = 0;
            outAttrs.initialSelEnd = 0;
        }
        return connection;
    }

    public View getView() {
        return mView;
    }

    public void close() {
        if (mClient == null)
            return;
        mClient.close();
        mClient = null;
    }
}
