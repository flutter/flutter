// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.raw_keyboard;

import android.util.Log;
import android.view.KeyEvent;
import android.view.View;

import java.util.ArrayList;

import org.chromium.mojo.bindings.ConnectionErrorHandler;
import org.chromium.mojo.system.MojoException;
import org.chromium.mojom.raw_keyboard.RawKeyboardListener;
import org.chromium.mojom.raw_keyboard.RawKeyboardService;
import org.chromium.mojom.sky.InputEvent;
import org.chromium.mojom.sky.EventType;
import org.chromium.mojom.sky.KeyData;

/**
 * Per-View raw keyboard state.
 */
public class RawKeyboardServiceState implements View.OnKeyListener {
    private static final String TAG = "RawKeyboardServiceState";

    private ArrayList<RawKeyboardListener.Proxy> mListeners = new ArrayList<RawKeyboardListener.Proxy>();

    public RawKeyboardServiceState() {
    }

    public void addListener(final RawKeyboardListener.Proxy listener) {
        mListeners.add(listener);
        listener.getProxyHandler().setErrorHandler(new ConnectionErrorHandler() {
            @Override
            public void onConnectionError(MojoException e) {
                mListeners.remove(listener);
            }
        });
    }

    public void close() {
    }

    @Override
    public boolean onKey(View v, int keyCode, KeyEvent nativeEvent) {
         if (mListeners.isEmpty())
             return false;
         InputEvent event = new InputEvent();
         switch (nativeEvent.getAction()) {
           case KeyEvent.ACTION_DOWN:
               event.type = EventType.KEY_PRESSED;
               break;
           case KeyEvent.ACTION_UP:
               event.type = EventType.KEY_RELEASED;
               break;
           default:
               Log.w(TAG, "Unknown key event received");
               return false;
         }
         KeyData keyData = new KeyData();
         keyData.flags = nativeEvent.getFlags();
         keyData.scanCode = nativeEvent.getScanCode();
         keyData.metaState = nativeEvent.getMetaState();
         keyData.keyCode = keyCode;
         event.keyData = keyData;
         for (RawKeyboardListener listener : mListeners)
             listener.onKey(event);
         return true;
    }
}
