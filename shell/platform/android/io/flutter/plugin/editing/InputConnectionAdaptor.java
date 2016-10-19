// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.editing;

import android.text.Editable;
import android.text.Selection;
import android.util.Log;
import android.view.inputmethod.BaseInputConnection;
import android.view.inputmethod.CompletionInfo;
import android.view.inputmethod.CorrectionInfo;
import android.view.inputmethod.EditorInfo;
import android.view.KeyEvent;
import android.view.View;
import io.flutter.view.FlutterView;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

class InputConnectionAdaptor extends BaseInputConnection {
    static final String TAG = "FlutterView";
    static final String MESSAGE_NAME = "flutter/textinputclient";

    private FlutterView mView;
    private int mClient;
    private JSONObject mOutgoingState;

    public InputConnectionAdaptor(FlutterView view, int client) {
        super(view, true);
        mView = view;
        mClient = client;
        mOutgoingState = new JSONObject();
    }

    private void updateEditingState() {
        try {
            final Editable content = getEditable();
            mOutgoingState.put("text", content.toString());
            mOutgoingState.put("selectionBase", Selection.getSelectionStart(content));
            mOutgoingState.put("selectionExtent", Selection.getSelectionEnd(content));
            mOutgoingState.put("composingBase", BaseInputConnection.getComposingSpanStart(content));
            mOutgoingState.put("composingExtent", BaseInputConnection.getComposingSpanEnd(content));

            final JSONArray args = new JSONArray();
            args.put(0, mClient);
            args.put(1, mOutgoingState);
            final JSONObject message = new JSONObject();
            message.put("method", "TextInputClient.updateEditingState");
            message.put("args", args);
            mView.sendPlatformMessage(MESSAGE_NAME, message.toString(), null);
        } catch (JSONException e) {
            Log.e(TAG, "Unexpected error serializing editing state", e);
        }
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
                mOutgoingState.optInt("selectionBase", -1) == mOutgoingState.optInt("selectionExtent", -1)) {
                deleteSurroundingText(1, 0);
            } else {
                String text = event.getNumber() == 0 ? "" : String.valueOf(event.getNumber());
                commitText(text, 1);
            }
        }
        return result;
    }

    @Override
    public boolean performEditorAction(int actionCode) {
        try {
            // TODO(abarth): Support more actions.
            final JSONArray args = new JSONArray();
            args.put(0, mClient);
            args.put(1, "TextInputAction.done");
            final JSONObject message = new JSONObject();
            message.put("method", "TextInputClient.performAction");
            message.put("args", args);
            mView.sendPlatformMessage(MESSAGE_NAME, message.toString(), null);
            return true;
        } catch (JSONException e) {
            Log.e(TAG, "Unexpected error serializing editor action", e);
            return false;
        }
    }
}
