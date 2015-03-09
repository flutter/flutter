// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.keyboard;

import android.content.Context;
import android.view.View;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputConnection;
import android.view.inputmethod.InputMethodManager;

import org.chromium.mojo.system.Core;
import org.chromium.mojo.system.MessagePipeHandle;
import org.chromium.mojo.system.MojoException;
import org.chromium.mojom.keyboard.KeyboardClient;
import org.chromium.mojom.keyboard.KeyboardService;

/**
 * Android implementation of Keyboard.
 */
public class KeyboardServiceImpl implements KeyboardService {
    private static View sActiveView;
    private static KeyboardClient sActiveClient;

    private Context mContext;

    public KeyboardServiceImpl(Context context, Core core, MessagePipeHandle pipe) {
        mContext = context;

        KeyboardService.MANAGER.bind(this, pipe);
    }

    public static void setActiveView(View view) {
        sActiveView = view;
    }

    public static InputConnection createInputConnection(EditorInfo outAttrs) {
        if (sActiveClient == null)
            return null;
        return new InputConnectionAdaptor(sActiveView, sActiveClient, outAttrs);
    }

    @Override
    public void close() {}

    @Override
    public void onConnectionError(MojoException e) {}

    @Override
    public void show(KeyboardClient client) {
        sActiveClient = client;
        InputMethodManager imm =
                (InputMethodManager) mContext.getSystemService(Context.INPUT_METHOD_SERVICE);
        imm.restartInput(sActiveView);
        imm.showSoftInput(sActiveView, InputMethodManager.SHOW_IMPLICIT);
    }

    public void hide() {
        InputMethodManager imm =
                (InputMethodManager) mContext.getSystemService(Context.INPUT_METHOD_SERVICE);
        imm.hideSoftInputFromWindow(sActiveView.getApplicationWindowToken(), 0);
    }
}
