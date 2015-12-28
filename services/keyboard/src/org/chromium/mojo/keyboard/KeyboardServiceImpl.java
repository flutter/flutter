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
    private KeyboardServiceState mViewState;
    private Context mContext;

    public KeyboardServiceImpl(Context context, KeyboardServiceState state) {
        mContext = context;
        mViewState = state;
    }

    private static int inputTypeFromKeyboardType(int keyboardType) {
        if (keyboardType == KeyboardType.DATETIME) return InputType.TYPE_CLASS_DATETIME;
        if (keyboardType == KeyboardType.NUMBER) return InputType.TYPE_CLASS_NUMBER;
        if (keyboardType == KeyboardType.PHONE) return InputType.TYPE_CLASS_PHONE;
        return InputType.TYPE_CLASS_TEXT;
    }

    @Override
    public void close() {
        mViewState.close();
    }

    @Override
    public void onConnectionError(MojoException e) {}

    @Override
    public void show(KeyboardClient client, int keyboardType) {
        mViewState.setClient(client, inputTypeFromKeyboardType(keyboardType));
        InputMethodManager imm =
                (InputMethodManager) mContext.getSystemService(Context.INPUT_METHOD_SERVICE);
        imm.restartInput(mViewState.getView());
        imm.showSoftInput(mViewState.getView(), InputMethodManager.SHOW_IMPLICIT);
    }

    @Override
    public void showByRequest() {
        InputMethodManager imm =
                (InputMethodManager) mContext.getSystemService(Context.INPUT_METHOD_SERVICE);
        imm.showSoftInput(mViewState.getView(), 0);
    }

    @Override
    public void hide() {
        InputMethodManager imm =
                (InputMethodManager) mContext.getSystemService(Context.INPUT_METHOD_SERVICE);
        imm.hideSoftInputFromWindow(mViewState.getView().getApplicationWindowToken(), 0);
        close();
    }

    @Override
    public void setText(String text) {
        InputMethodManager imm =
                (InputMethodManager) mContext.getSystemService(Context.INPUT_METHOD_SERVICE);
        imm.restartInput(mViewState.getView());
        mViewState.setText(text);
    }

    @Override
    public void setSelection(int start, int end) {
        mViewState.setSelection(start, end);
    }
}
