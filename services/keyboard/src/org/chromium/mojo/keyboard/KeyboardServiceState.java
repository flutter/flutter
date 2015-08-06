// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.keyboard;

import android.text.InputType;
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

    public KeyboardServiceState(View view) {
        mView = view;
        mActiveClient = null;
        mRequestedInputType = InputType.TYPE_CLASS_TEXT;
    }

    public InputConnection createInputConnection(EditorInfo outAttrs) {
        if (mActiveClient == null) return null;
        outAttrs.inputType = mRequestedInputType;
        return new InputConnectionAdaptor(mView, mActiveClient, outAttrs);
    }

    public void setClient(KeyboardClient client, int inputType) {
        if (mActiveClient != null) mActiveClient.close();
        mActiveClient = client;
        mRequestedInputType = inputType;
    }

    public View getView() {
        return mView;
    }

    public void close() {
        if (mActiveClient == null) return;
        mActiveClient.close();
        mActiveClient = null;
    }
}
