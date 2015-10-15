// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.keyboard;

import android.text.Editable;
import android.text.InputType;
import android.text.Selection;
import android.text.SpannableStringBuilder;
import android.view.View;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputConnection;

import org.chromium.mojom.keyboard.KeyboardClient;

/**
 * Per-View keyboard state.
 */
public class KeyboardServiceState {
    private View mView;
    private KeyboardClient mActiveClient;
    private int mRequestedInputType;
    private Editable mActiveEditable;

    public KeyboardServiceState(View view) {
        mView = view;
        mActiveClient = null;
        mRequestedInputType = InputType.TYPE_CLASS_TEXT;
        mActiveEditable = null;
    }

    public InputConnection createInputConnection(EditorInfo outAttrs) {
        if (mActiveClient == null) return null;
        outAttrs.inputType = mRequestedInputType;
        return new InputConnectionAdaptor(mView, mActiveClient, mActiveEditable, outAttrs);
    }

    public void setClient(KeyboardClient client, int inputType) {
        if (mActiveClient != null) mActiveClient.close();
        mActiveClient = client;
        mRequestedInputType = inputType;
        mActiveEditable = new SpannableStringBuilder();
    }

    public View getView() {
        return mView;
    }

    public void close() {
        if (mActiveClient == null) return;
        mActiveClient.close();
        mActiveClient = null;
        mActiveEditable = null;
    }

    public void setText(String text) {
        mActiveEditable.replace(0, mActiveEditable.length(), text);
    }

    public void setSelection(int start, int end) {
        Selection.setSelection(mActiveEditable, start, end);
    }
}
