// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.editing;

import android.content.Context;
import android.view.inputmethod.InputMethodManager;

import org.chromium.mojo.system.MojoException;
import org.chromium.mojom.editing.EditingState;
import org.chromium.mojom.editing.Keyboard;
import org.chromium.mojom.editing.KeyboardClient;
import org.chromium.mojom.editing.KeyboardConfiguration;

/**
 * Android implementation of Keyboard.
 */
public class KeyboardImpl implements Keyboard {
    private KeyboardViewState mViewState;
    private Context mContext;

    public KeyboardImpl(Context context, KeyboardViewState state) {
        mContext = context;
        mViewState = state;
    }

    @Override
    public void close() {
        mViewState.close();
    }

    @Override
    public void onConnectionError(MojoException e) {}

    @Override
    public void setClient(KeyboardClient client, KeyboardConfiguration configuration) {
        mViewState.setClient(client, configuration);
    }

    @Override
    public void clearClient() {
        mViewState.close();
    }

    @Override
    public void setEditingState(EditingState state) {
        mViewState.setEditingState(state);
    }

    @Override
    public void show() {
        InputMethodManager imm =
                (InputMethodManager) mContext.getSystemService(Context.INPUT_METHOD_SERVICE);
        imm.showSoftInput(mViewState.getView(), 0);
    }

    @Override
    public void hide() {
        InputMethodManager imm =
                (InputMethodManager) mContext.getSystemService(Context.INPUT_METHOD_SERVICE);
        imm.hideSoftInputFromWindow(mViewState.getView().getApplicationWindowToken(), 0);
    }
}
