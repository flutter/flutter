// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.editing;

import android.content.Context;
import android.text.Editable;
import android.text.InputType;
import android.text.Selection;
import android.view.inputmethod.BaseInputConnection;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputConnection;
import android.view.inputmethod.InputMethodManager;
import io.flutter.plugin.common.JSONMethodCodec;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.view.FlutterView;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * Android implementation of the text input plugin.
 */
public class TextInputPlugin implements MethodCallHandler {
    private final FlutterView mView;
    private final InputMethodManager mImm;
    private final MethodChannel mFlutterChannel;
    private int mClient = 0;
    private JSONObject mConfiguration;
    private Editable mEditable;
    private boolean mRestartInputPending;

    public TextInputPlugin(FlutterView view) {
        mView = view;
        mImm = (InputMethodManager) view.getContext().getSystemService(
                Context.INPUT_METHOD_SERVICE);
        mFlutterChannel = new MethodChannel(view, "flutter/textinput", JSONMethodCodec.INSTANCE);
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

    private static int inputTypeFromTextInputType(JSONObject type, boolean obscureText,
            boolean autocorrect, String textCapitalization) throws JSONException {
        String inputType = type.getString("name");
        if (inputType.equals("TextInputType.datetime")) return InputType.TYPE_CLASS_DATETIME;
        if (inputType.equals("TextInputType.number")) {
            int textType = InputType.TYPE_CLASS_NUMBER;
            if (type.optBoolean("signed")) textType |= InputType.TYPE_NUMBER_FLAG_SIGNED;
            if (type.optBoolean("decimal")) textType |= InputType.TYPE_NUMBER_FLAG_DECIMAL;
            return textType;
        }
        if (inputType.equals("TextInputType.phone")) return InputType.TYPE_CLASS_PHONE;

        int textType = InputType.TYPE_CLASS_TEXT;
        if (inputType.equals("TextInputType.multiline"))
            textType |= InputType.TYPE_TEXT_FLAG_MULTI_LINE;
        else if (inputType.equals("TextInputType.emailAddress"))
            textType |= InputType.TYPE_TEXT_VARIATION_EMAIL_ADDRESS;
        else if (inputType.equals("TextInputType.url"))
            textType |= InputType.TYPE_TEXT_VARIATION_URI;
        if (obscureText) {
            // Note: both required. Some devices ignore TYPE_TEXT_FLAG_NO_SUGGESTIONS.
            textType |= InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS;
            textType |= InputType.TYPE_TEXT_VARIATION_PASSWORD;
        } else {
            if (autocorrect) textType |= InputType.TYPE_TEXT_FLAG_AUTO_CORRECT;
        }
        if (textCapitalization.equals("TextCapitalization.characters")) {
            textType |= InputType.TYPE_TEXT_FLAG_CAP_CHARACTERS;
        } else if (textCapitalization.equals("TextCapitalization.words")) {
            textType |= InputType.TYPE_TEXT_FLAG_CAP_WORDS;
        } else if (textCapitalization.equals("TextCapitalization.sentences")) {
            textType |= InputType.TYPE_TEXT_FLAG_CAP_SENTENCES;
        }
        return textType;
    }

    private static int inputActionFromTextInputAction(String inputAction) {
        switch (inputAction) {
            case "TextInputAction.newline":
                return EditorInfo.IME_ACTION_NONE;
            case "TextInputAction.none":
                return EditorInfo.IME_ACTION_NONE;
            case "TextInputAction.unspecified":
                return EditorInfo.IME_ACTION_UNSPECIFIED;
            case "TextInputAction.done":
                return EditorInfo.IME_ACTION_DONE;
            case "TextInputAction.go":
                return EditorInfo.IME_ACTION_GO;
            case "TextInputAction.search":
                return EditorInfo.IME_ACTION_SEARCH;
            case "TextInputAction.send":
                return EditorInfo.IME_ACTION_SEND;
            case "TextInputAction.next":
                return EditorInfo.IME_ACTION_NEXT;
            case "TextInputAction.previous":
                return EditorInfo.IME_ACTION_PREVIOUS;
            default:
                // Present default key if bad input type is given.
                return EditorInfo.IME_ACTION_UNSPECIFIED;
        }
    }

    public InputConnection createInputConnection(FlutterView view, EditorInfo outAttrs)
            throws JSONException {
        if (mClient == 0) return null;

        outAttrs.inputType = inputTypeFromTextInputType(mConfiguration.getJSONObject("inputType"),
                mConfiguration.optBoolean("obscureText"),
                mConfiguration.optBoolean("autocorrect", true),
                mConfiguration.getString("textCapitalization"));
        outAttrs.imeOptions = EditorInfo.IME_FLAG_NO_FULLSCREEN;
        int enterAction;
        if (mConfiguration.isNull("inputAction")) {
            // If an explicit input action isn't set, then default to none for multi-line fields
            // and done for single line fields.
            enterAction = (InputType.TYPE_TEXT_FLAG_MULTI_LINE & outAttrs.inputType) != 0
                    ? EditorInfo.IME_ACTION_NONE
                    : EditorInfo.IME_ACTION_DONE;
        } else {
            enterAction = inputActionFromTextInputAction(mConfiguration.getString("inputAction"));
        }
        if (!mConfiguration.isNull("actionLabel")) {
            outAttrs.actionLabel = mConfiguration.getString("actionLabel");
            outAttrs.actionId = enterAction;
        }
        outAttrs.imeOptions |= enterAction;

        InputConnectionAdaptor connection =
                new InputConnectionAdaptor(view, mClient, mFlutterChannel, mEditable);
        outAttrs.initialSelStart = Selection.getSelectionStart(mEditable);
        outAttrs.initialSelEnd = Selection.getSelectionEnd(mEditable);

        return connection;
    }

    private void showTextInput(FlutterView view) {
        mImm.showSoftInput(view, 0);
    }

    private void hideTextInput(FlutterView view) {
        mImm.hideSoftInputFromWindow(view.getApplicationWindowToken(), 0);
    }

    private void setTextInputClient(FlutterView view, int client, JSONObject configuration) {
        mClient = client;
        mConfiguration = configuration;
        mEditable = Editable.Factory.getInstance().newEditable("");

        // setTextInputClient will be followed by a call to setTextInputEditingState.
        // Do a restartInput at that time.
        mRestartInputPending = true;
    }

    private void applyStateToSelection(JSONObject state) throws JSONException {
        int selStart = state.getInt("selectionBase");
        int selEnd = state.getInt("selectionExtent");
        if (selStart >= 0 && selStart <= mEditable.length() && selEnd >= 0
                && selEnd <= mEditable.length()) {
            Selection.setSelection(mEditable, selStart, selEnd);
        } else {
            Selection.removeSelection(mEditable);
        }
    }

    private void setTextInputEditingState(FlutterView view, JSONObject state) throws JSONException {
        if (!mRestartInputPending && state.getString("text").equals(mEditable.toString())) {
            applyStateToSelection(state);
            mImm.updateSelection(mView, Math.max(Selection.getSelectionStart(mEditable), 0),
                    Math.max(Selection.getSelectionEnd(mEditable), 0),
                    BaseInputConnection.getComposingSpanStart(mEditable),
                    BaseInputConnection.getComposingSpanEnd(mEditable));
        } else {
            mEditable.replace(0, mEditable.length(), state.getString("text"));
            applyStateToSelection(state);
            mImm.restartInput(view);
            mRestartInputPending = false;
        }
    }

    private void clearTextInputClient() {
        mClient = 0;
    }
}
