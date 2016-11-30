// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.editing;

import android.app.Activity;
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
import io.flutter.plugin.common.JSONMessageListener;
import io.flutter.view.FlutterView;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * Android implementation of the text input plugin.
 */
public class TextInputPlugin extends JSONMessageListener {
    private static final String TAG = "FlutterView";

    private final Activity mActivity;
    private int mClient = 0;
    private JSONObject mConfiguration;
    private JSONObject mLatestState;

    public TextInputPlugin(Activity activity) {
        mActivity = activity;
    }

    @Override
    public JSONObject onJSONMessage(FlutterView view, JSONObject message) throws JSONException {
        String method = message.getString("method");
        JSONArray args = message.getJSONArray("args");
        if (method.equals("TextInput.show")) {
            showTextInput(view);
        } else if (method.equals("TextInput.hide")) {
            hideTextInput(view);
        } else if (method.equals("TextInput.setClient")) {
            setTextInputClient(view, args.getInt(0), args.getJSONObject(1));
        } else if (method.equals("TextInput.setEditingState")) {
            setTextInputEditingState(view, args.getJSONObject(0));
        } else if (method.equals("TextInput.clearClient")) {
            clearTextInputClient();
        } else {
            // TODO(abarth): We should throw an exception here that gets
            // transmitted back to Dart.
        }
        return null;
    }

    private static int inputTypeFromTextInputType(String inputType) {
        if (inputType.equals("TextInputType.datetime"))
            return InputType.TYPE_CLASS_DATETIME;
        if (inputType.equals("TextInputType.number"))
            return InputType.TYPE_CLASS_NUMBER;
        if (inputType.equals("TextInputType.phone"))
            return InputType.TYPE_CLASS_PHONE;
        return InputType.TYPE_CLASS_TEXT;
    }

    public InputConnection createInputConnection(FlutterView view, EditorInfo outAttrs) {
        if (mClient == 0)
            return null;
        try {
            outAttrs.inputType = inputTypeFromTextInputType(mConfiguration.getString("inputType"));
            outAttrs.actionLabel = getStringOrNull(mConfiguration, "actionLabel");
            outAttrs.imeOptions = EditorInfo.IME_ACTION_DONE | EditorInfo.IME_FLAG_NO_FULLSCREEN;
            InputConnectionAdaptor connection = new InputConnectionAdaptor(view, mClient, this);
            if (mLatestState != null) {
                outAttrs.initialSelStart = mLatestState.getInt("selectionBase");
                outAttrs.initialSelEnd = mLatestState.getInt("selectionExtent");
                connection.getEditable().append(mLatestState.getString("text"));
                connection.setSelection(mLatestState.getInt("selectionBase"),
                                        mLatestState.getInt("selectionExtent"));
                connection.setComposingRegion(mLatestState.getInt("composingBase"),
                                              mLatestState.getInt("composingExtent"));
            } else {
                outAttrs.initialSelStart = 0;
                outAttrs.initialSelEnd = 0;
            }
            return connection;
        } catch (JSONException e) {
            Log.e(TAG, "Failed to create input connection", e);
        }
        return null;
    }

    private void showTextInput(FlutterView view) {
        InputMethodManager imm =
                (InputMethodManager) mActivity.getSystemService(Context.INPUT_METHOD_SERVICE);
        imm.showSoftInput(view, 0);
    }

    private void hideTextInput(FlutterView view) {
        InputMethodManager imm =
                (InputMethodManager) mActivity.getSystemService(Context.INPUT_METHOD_SERVICE);
        imm.hideSoftInputFromWindow(view.getApplicationWindowToken(), 0);
    }

    private void setTextInputClient(FlutterView view, int client, JSONObject configuration) throws JSONException {
        mLatestState = null;
        mClient = client;
        mConfiguration = configuration;
        InputMethodManager imm =
                (InputMethodManager) mActivity.getSystemService(Context.INPUT_METHOD_SERVICE);
        imm.restartInput(view);
    }

    private void setTextInputEditingState(FlutterView view, JSONObject state) throws JSONException {
        mLatestState = state;
        InputMethodManager imm =
                (InputMethodManager) mActivity.getSystemService(Context.INPUT_METHOD_SERVICE);
        imm.restartInput(view);
    }

    void setLatestEditingState(JSONObject state) {
        mLatestState = state;
    }
    
    private void clearTextInputClient() {
        mClient = 0;
    }
}
