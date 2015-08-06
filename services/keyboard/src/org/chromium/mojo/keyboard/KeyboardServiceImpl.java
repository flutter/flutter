// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.keyboard;

import android.content.Context;
import android.text.InputType;
import android.view.inputmethod.InputMethodManager;

import org.chromium.mojo.system.MojoException;
import org.chromium.mojom.keyboard.KeyboardClient;
import org.chromium.mojom.keyboard.KeyboardService;
import org.chromium.mojom.keyboard.KeyboardType;

/**
 * Android implementation of Keyboard.
 */
public class KeyboardServiceImpl implements KeyboardService {
    // We have a unique ServiceImpl per connection.  However the state
    // for the keyboard instance is per-view.  However we don't have the
    // concept of per-view services, so we currently have a hack by which
    // we set the "active view" and its associated per-view keyboard state.
    private static KeyboardServiceState sViewState;
    private Context mContext;

    public KeyboardServiceImpl(Context context) {
        mContext = context;
    }

    public static void setViewState(KeyboardServiceState state) {
        if (sViewState != null) sViewState.close();
        sViewState = state;
    }

    private static int inputTypeFromKeyboardType(int keyboardType) {
        if (keyboardType == KeyboardType.DATETIME) return InputType.TYPE_CLASS_DATETIME;
        if (keyboardType == KeyboardType.NUMBER) return InputType.TYPE_CLASS_NUMBER;
        if (keyboardType == KeyboardType.PHONE) return InputType.TYPE_CLASS_PHONE;
        return InputType.TYPE_CLASS_TEXT;
    }

    @Override
    public void close() {
        if (sViewState == null) return;
        sViewState.close();
    }

    @Override
    public void onConnectionError(MojoException e) {}

    @Override
    public void show(KeyboardClient client, int keyboardType) {
        if (sViewState == null) return;
        sViewState.setClient(client, inputTypeFromKeyboardType(keyboardType));
        InputMethodManager imm =
                (InputMethodManager) mContext.getSystemService(Context.INPUT_METHOD_SERVICE);
        imm.restartInput(sViewState.getView());
        imm.showSoftInput(sViewState.getView(), InputMethodManager.SHOW_IMPLICIT);
    }

    @Override
    public void showByRequest() {
        if (sViewState == null) return;
        InputMethodManager imm =
                (InputMethodManager) mContext.getSystemService(Context.INPUT_METHOD_SERVICE);
        imm.showSoftInput(sViewState.getView(), 0);
    }

    @Override
    public void hide() {
        if (sViewState == null) return;
        InputMethodManager imm =
                (InputMethodManager) mContext.getSystemService(Context.INPUT_METHOD_SERVICE);
        imm.hideSoftInputFromWindow(sViewState.getView().getApplicationWindowToken(), 0);
        close();
    }
}
