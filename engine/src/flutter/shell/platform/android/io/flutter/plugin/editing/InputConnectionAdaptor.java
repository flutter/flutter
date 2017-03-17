// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.editing;

import android.text.Editable;
import android.text.Selection;
import android.view.inputmethod.BaseInputConnection;
import android.view.KeyEvent;

import io.flutter.plugin.common.FlutterMethodChannel;
import io.flutter.view.FlutterView;

import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

class InputConnectionAdaptor extends BaseInputConnection {
    private final int mClient;
    private final TextInputPlugin mPlugin;
    private final FlutterMethodChannel mFlutterChannel;
    private final Map<String, Object> mOutgoingState;

    public InputConnectionAdaptor(FlutterView view, int client,
        TextInputPlugin plugin, FlutterMethodChannel flutterChannel) {
        super(view, true);
        mClient = client;
        mPlugin = plugin;
        mFlutterChannel = flutterChannel;
        mOutgoingState = new HashMap<>();
    }

    private void updateEditingState() {
        final Editable content = getEditable();
        mOutgoingState.put("text", content.toString());
        mOutgoingState.put("selectionBase", Selection.getSelectionStart(content));
        mOutgoingState.put("selectionExtent", Selection.getSelectionEnd(content));
        mOutgoingState.put("composingBase", BaseInputConnection.getComposingSpanStart(content));
        mOutgoingState.put("composingExtent", BaseInputConnection.getComposingSpanEnd(content));
        mFlutterChannel.invokeMethod("TextInputClient.updateEditingState", Arrays
            .asList(mClient, mOutgoingState));
        mPlugin.setLatestEditingState(mOutgoingState);
    }

    @Override
    public boolean commitText(CharSequence text, int newCursorPosition) {
        final boolean result = super.commitText(text, newCursorPosition);
        updateEditingState();
        return result;
    }

    @Override
    public boolean deleteSurroundingText(int beforeLength, int afterLength) {
        final boolean result = super.deleteSurroundingText(beforeLength, afterLength);
        updateEditingState();
        return result;
    }

    @Override
    public boolean setComposingRegion(int start, int end) {
        final boolean result = super.setComposingRegion(start, end);
        updateEditingState();
        return result;
    }

    @Override
    public boolean setComposingText(CharSequence text, int newCursorPosition) {
        final boolean result = super.setComposingText(text, newCursorPosition);
        updateEditingState();
        return result;
    }

    @Override
    public boolean setSelection(int start, int end) {
        final boolean result = super.setSelection(start, end);
        updateEditingState();
        return result;
    }

    @Override
    public boolean sendKeyEvent(KeyEvent event) {
        final boolean result = super.sendKeyEvent(event);
        if (event.getAction() == KeyEvent.ACTION_UP) {
            // Weird special case. This method is (sometimes) called for the backspace key in 2
            // situations:
            // 1. There is no selection. In that case, we want to delete the previous character.
            // 2. There is a selection. In that case, we want to delete the selection.
            //    event.getNumber() is 0, and commitText("", 1) will do what we want.
            if (event.getKeyCode() == KeyEvent.KEYCODE_DEL &&
                optInt("selectionBase", -1) == optInt("selectionExtent", -1)) {
                deleteSurroundingText(1, 0);
            } else {
                String text = event.getNumber() == 0 ? "" : String.valueOf(event.getNumber());
                commitText(text, 1);
            }
        }
        return result;
    }

    private int optInt(String key, int defaultValue) {
        return mOutgoingState.containsKey(key) ? (Integer) mOutgoingState.get(key) : defaultValue;
    }

    @Override
    public boolean performEditorAction(int actionCode) {
        // TODO(abarth): Support more actions.
        mFlutterChannel.invokeMethod("TextInputClient.performAction",
            Arrays.asList(mClient, "TextInputAction.done"));
        return true;
    }
}
