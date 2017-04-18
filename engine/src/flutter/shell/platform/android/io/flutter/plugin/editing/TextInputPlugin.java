// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.editing;

import android.app.Activity;
import android.content.Context;
import android.text.InputType;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputConnection;
import android.view.inputmethod.InputMethodManager;

import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.JSONMethodCodec;
import io.flutter.plugin.common.JSONUtil;
import io.flutter.plugin.common.MethodCall;
import io.flutter.view.FlutterView;

import java.util.Map;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * Android implementation of the text input plugin.
 */
public class TextInputPlugin implements MethodCallHandler {

    private final Activity mActivity;
    private final FlutterView mView;
    private final MethodChannel mFlutterChannel;
    private int mClient = 0;
    private JSONObject mConfiguration;
    private JSONObject mLatestState;

    public TextInputPlugin(Activity activity, FlutterView view) {
        mActivity = activity;
        mView = view;
        mFlutterChannel = new MethodChannel(view, "flutter/textinput",
            JSONMethodCodec.INSTANCE);
        mFlutterChannel.setMethodCallHandler(this);
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        String method = call.method;
        Object args = call.arguments;
        try {
            if (method.equals("TextInput.show")) {
                showTextInput(mView);
                result.success(null);
            } else if (method.equals("TextInput.hide")) {
                hideTextInput(mView);
                result.success(null);
            } else if (method.equals("TextInput.setClient")) {
                final JSONArray argumentList = (JSONArray) args;
                setTextInputClient(mView, argumentList.getInt(0), argumentList.getJSONObject(1));
                result.success(null);
            } else if (method.equals("TextInput.setEditingState")) {
                setTextInputEditingState(mView, (JSONObject) args);
                result.success(null);
            } else if (method.equals("TextInput.clearClient")) {
                clearTextInputClient();
                result.success(null);
            } else {
                result.notImplemented();
            }
        } catch (JSONException e) {
            result.error("error", "JSON error: " + e.getMessage(), null);
        }
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

    public InputConnection createInputConnection(FlutterView view, EditorInfo outAttrs)
        throws JSONException {
        if (mClient == 0)
            return null;
        outAttrs.inputType = inputTypeFromTextInputType(mConfiguration.getString("inputType"));
        outAttrs.actionLabel = mConfiguration.getString("actionLabel");
        outAttrs.imeOptions = EditorInfo.IME_ACTION_DONE | EditorInfo.IME_FLAG_NO_FULLSCREEN;
        InputConnectionAdaptor connection = new InputConnectionAdaptor(view, mClient, this,
            mFlutterChannel);
        if (mLatestState != null) {
            int selectionBase = (Integer) mLatestState.get("selectionBase");
            int selectionExtent = (Integer) mLatestState.get("selectionExtent");
            outAttrs.initialSelStart = selectionBase;
            outAttrs.initialSelEnd = selectionExtent;
            connection.getEditable().append((String) mLatestState.get("text"));
            connection.setSelection(Math.max(selectionBase, 0),
                Math.max(selectionExtent, 0));
            connection.setComposingRegion((Integer) mLatestState.get("composingBase"),
                (Integer) mLatestState.get("composingExtent"));
        } else {
            outAttrs.initialSelStart = 0;
            outAttrs.initialSelEnd = 0;
        }
        return connection;
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

    private void setTextInputClient(FlutterView view, int client, JSONObject configuration) {
        mLatestState = null;
        mClient = client;
        mConfiguration = configuration;
        InputMethodManager imm =
            (InputMethodManager) mActivity.getSystemService(Context.INPUT_METHOD_SERVICE);
        imm.restartInput(view);
    }

    private void setTextInputEditingState(FlutterView view, JSONObject state) {
        mLatestState = state;
        InputMethodManager imm =
            (InputMethodManager) mActivity.getSystemService(Context.INPUT_METHOD_SERVICE);
        imm.restartInput(view);
    }

    void setLatestEditingState(Map<String, Object> state) {
        mLatestState = (JSONObject) JSONUtil.wrap(state);
    }

    private void clearTextInputClient() {
        mClient = 0;
    }
}
