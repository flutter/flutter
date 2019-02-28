// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.editing;

import android.content.Context;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.text.Editable;
import android.text.InputType;
import android.text.Selection;
import android.view.View;
import android.view.inputmethod.BaseInputConnection;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputConnection;
import android.view.inputmethod.InputMethodManager;

import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.systemchannels.TextInputChannel;
import io.flutter.view.FlutterView;

/**
 * Android implementation of the text input plugin.
 */
public class TextInputPlugin {
    @NonNull
    private final View mView;
    @NonNull
    private final InputMethodManager mImm;
    @NonNull
    private final TextInputChannel textInputChannel;
    private int mClient = 0;
    @Nullable
    private TextInputChannel.Configuration configuration;
    @Nullable
    private Editable mEditable;
    private boolean mRestartInputPending;
    @Nullable
    private InputConnection lastInputConnection;

    public TextInputPlugin(View view, @NonNull DartExecutor dartExecutor) {
        mView = view;
        mImm = (InputMethodManager) view.getContext().getSystemService(
                Context.INPUT_METHOD_SERVICE);

        textInputChannel = new TextInputChannel(dartExecutor);
        textInputChannel.setTextInputMethodHandler(new TextInputChannel.TextInputMethodHandler() {
            @Override
            public void show() {
                showTextInput(mView);
            }

            @Override
            public void hide() {
                hideTextInput(mView);
            }

            @Override
            public void setClient(int textInputClientId, TextInputChannel.Configuration configuration) {
                setTextInputClient(textInputClientId, configuration);
            }

            @Override
            public void setEditingState(TextInputChannel.TextEditState editingState) {
                setTextInputEditingState(mView, editingState);
            }

            @Override
            public void clearClient() {
                clearTextInputClient();
            }
        });
    }

    @NonNull
    public InputMethodManager getInputMethodManager() {
        return mImm;
    }

    private static int inputTypeFromTextInputType(
        TextInputChannel.InputType type,
        boolean obscureText,
        boolean autocorrect,
        TextInputChannel.TextCapitalization textCapitalization
    ) {
        if (type.type == TextInputChannel.TextInputType.DATETIME) {
            return InputType.TYPE_CLASS_DATETIME;
        } else if (type.type == TextInputChannel.TextInputType.NUMBER) {
            int textType = InputType.TYPE_CLASS_NUMBER;
            if (type.isSigned) {
                textType |= InputType.TYPE_NUMBER_FLAG_SIGNED;
            }
            if (type.isDecimal) {
                textType |= InputType.TYPE_NUMBER_FLAG_DECIMAL;
            }
            return textType;
        } else if (type.type == TextInputChannel.TextInputType.PHONE) {
            return InputType.TYPE_CLASS_PHONE;
        }

        int textType = InputType.TYPE_CLASS_TEXT;
        if (type.type == TextInputChannel.TextInputType.MULTILINE) {
            textType |= InputType.TYPE_TEXT_FLAG_MULTI_LINE;
        } else if (type.type == TextInputChannel.TextInputType.EMAIL_ADDRESS) {
            textType |= InputType.TYPE_TEXT_VARIATION_EMAIL_ADDRESS;
        } else if (type.type == TextInputChannel.TextInputType.URL) {
            textType |= InputType.TYPE_TEXT_VARIATION_URI;
        }

        if (obscureText) {
            // Note: both required. Some devices ignore TYPE_TEXT_FLAG_NO_SUGGESTIONS.
            textType |= InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS;
            textType |= InputType.TYPE_TEXT_VARIATION_PASSWORD;
        } else {
            if (autocorrect) textType |= InputType.TYPE_TEXT_FLAG_AUTO_CORRECT;
        }

        if (textCapitalization == TextInputChannel.TextCapitalization.CHARACTERS) {
            textType |= InputType.TYPE_TEXT_FLAG_CAP_CHARACTERS;
        } else if (textCapitalization == TextInputChannel.TextCapitalization.WORDS) {
            textType |= InputType.TYPE_TEXT_FLAG_CAP_WORDS;
        } else if (textCapitalization == TextInputChannel.TextCapitalization.SENTENCES) {
            textType |= InputType.TYPE_TEXT_FLAG_CAP_SENTENCES;
        }

        return textType;
    }

    public InputConnection createInputConnection(View view, EditorInfo outAttrs) {
        if (mClient == 0) {
            lastInputConnection = null;
            return lastInputConnection;
        }

        outAttrs.inputType = inputTypeFromTextInputType(
            configuration.inputType,
            configuration.obscureText,
            configuration.autocorrect,
            configuration.textCapitalization
        );
        outAttrs.imeOptions = EditorInfo.IME_FLAG_NO_FULLSCREEN;
        int enterAction;
        if (configuration.inputAction == null) {
            // If an explicit input action isn't set, then default to none for multi-line fields
            // and done for single line fields.
            enterAction = (InputType.TYPE_TEXT_FLAG_MULTI_LINE & outAttrs.inputType) != 0
                    ? EditorInfo.IME_ACTION_NONE
                    : EditorInfo.IME_ACTION_DONE;
        } else {
            enterAction = configuration.inputAction;
        }
        if (configuration.actionLabel != null) {
            outAttrs.actionLabel = configuration.actionLabel;
            outAttrs.actionId = enterAction;
        }
        outAttrs.imeOptions |= enterAction;

        InputConnectionAdaptor connection = new InputConnectionAdaptor(
            view,
            mClient,
            textInputChannel,
            mEditable
        );
        outAttrs.initialSelStart = Selection.getSelectionStart(mEditable);
        outAttrs.initialSelEnd = Selection.getSelectionEnd(mEditable);

        lastInputConnection = connection;
        return lastInputConnection;
    }

    @Nullable
    public InputConnection getLastInputConnection() {
        return lastInputConnection;
    }

    private void showTextInput(View view) {
        view.requestFocus();
        mImm.showSoftInput(view, 0);
    }

    private void hideTextInput(View view) {
        mImm.hideSoftInputFromWindow(view.getApplicationWindowToken(), 0);
    }

    private void setTextInputClient(int client, TextInputChannel.Configuration configuration) {
        mClient = client;
        this.configuration = configuration;
        mEditable = Editable.Factory.getInstance().newEditable("");

        // setTextInputClient will be followed by a call to setTextInputEditingState.
        // Do a restartInput at that time.
        mRestartInputPending = true;
    }

    private void applyStateToSelection(TextInputChannel.TextEditState state) {
        int selStart = state.selectionStart;
        int selEnd = state.selectionEnd;
        if (selStart >= 0 && selStart <= mEditable.length() && selEnd >= 0
                && selEnd <= mEditable.length()) {
            Selection.setSelection(mEditable, selStart, selEnd);
        } else {
            Selection.removeSelection(mEditable);
        }
    }

    private void setTextInputEditingState(View view, TextInputChannel.TextEditState state) {
        if (!mRestartInputPending && state.text.equals(mEditable.toString())) {
            applyStateToSelection(state);
            mImm.updateSelection(mView, Math.max(Selection.getSelectionStart(mEditable), 0),
                    Math.max(Selection.getSelectionEnd(mEditable), 0),
                    BaseInputConnection.getComposingSpanStart(mEditable),
                    BaseInputConnection.getComposingSpanEnd(mEditable));
        } else {
            mEditable.replace(0, mEditable.length(), state.text);
            applyStateToSelection(state);
            mImm.restartInput(view);
            mRestartInputPending = false;
        }
    }

    private void clearTextInputClient() {
        mClient = 0;
    }
}
