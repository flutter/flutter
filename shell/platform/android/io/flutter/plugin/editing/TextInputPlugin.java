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
import io.flutter.plugin.platform.PlatformViewsController;

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
    @NonNull
    private InputTarget inputTarget = new InputTarget(InputTarget.Type.NO_TARGET, 0);
    @Nullable
    private TextInputChannel.Configuration configuration;
    @Nullable
    private Editable mEditable;
    private boolean mRestartInputPending;
    @Nullable
    private InputConnection lastInputConnection;
    @NonNull
    private PlatformViewsController platformViewsController;

    // When true following calls to createInputConnection will return the cached lastInputConnection if the input
    // target is a platform view. See the comments on lockPlatformViewInputConnection for more details.
    private boolean isInputConnectionLocked;

    public TextInputPlugin(View view, @NonNull DartExecutor dartExecutor, @NonNull PlatformViewsController platformViewsController) {
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
            public void setPlatformViewClient(int platformViewId) {
                setPlatformViewTextInputClient(platformViewId);
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

        this.platformViewsController = platformViewsController;
        this.platformViewsController.attachTextInputPlugin(this);
    }

    @NonNull
    public InputMethodManager getInputMethodManager() {
        return mImm;
    }

    /***
     * Use the current platform view input connection until unlockPlatformViewInputConnection is called.
     *
     * The current input connection instance is cached and any following call to @{link createInputConnection} returns
     * the cached connection until unlockPlatformViewInputConnection is called.
     *
     * This is a no-op if the current input target isn't a platform view.
     *
     * This is used to preserve an input connection when moving a platform view from one virtual display to another.
     */
    public void lockPlatformViewInputConnection() {
        if (inputTarget.type == InputTarget.Type.PLATFORM_VIEW) {
            isInputConnectionLocked = true;
        }
    }

    /**
     * Unlocks the input connection.
     *
     * See also: @{link lockPlatformViewInputConnection}.
     */
    public void unlockPlatformViewInputConnection() {
        isInputConnectionLocked = false;
    }

    /**
     * Detaches the text input plugin from the platform views controller.
     *
     * The TextInputPlugin instance should not be used after calling this.
     */
    public void destroy() {
        platformViewsController.detachTextInputPlugin();
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
        } else if (type.type == TextInputChannel.TextInputType.VISIBLE_PASSWORD) {
            textType |= InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD;
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
        if (inputTarget.type == InputTarget.Type.NO_TARGET) {
            lastInputConnection = null;
            return null;
        }

        if (inputTarget.type == InputTarget.Type.PLATFORM_VIEW) {
            if (isInputConnectionLocked) {
                return lastInputConnection;
            }
            lastInputConnection = platformViewsController.getPlatformViewById(inputTarget.id).onCreateInputConnection(outAttrs);
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
            inputTarget.id,
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

    /**
     * Clears a platform view text input client if it is the current input target.
     *
     * This is called when a platform view is disposed to make sure we're not hanging to a stale input
     * connection.
     */
    public void clearPlatformViewClient(int platformViewId) {
        if (inputTarget.type == InputTarget.Type.PLATFORM_VIEW && inputTarget.id == platformViewId) {
            inputTarget = new InputTarget(InputTarget.Type.NO_TARGET, 0);
            hideTextInput(mView);
            mImm.restartInput(mView);
            mRestartInputPending = false;
        }
    }

    private void showTextInput(View view) {
        view.requestFocus();
        mImm.showSoftInput(view, 0);
    }

    private void hideTextInput(View view) {
        // Note: a race condition may lead to us hiding the keyboard here just after a platform view has shown it.
        // This can only potentially happen when switching focus from a Flutter text field to a platform view's text
        // field(by text field here I mean anything that keeps the keyboard open).
        // See: https://github.com/flutter/flutter/issues/34169
        mImm.hideSoftInputFromWindow(view.getApplicationWindowToken(), 0);
    }

    private void setTextInputClient(int client, TextInputChannel.Configuration configuration) {
        inputTarget = new InputTarget(InputTarget.Type.FRAMEWORK_CLIENT, client);
        this.configuration = configuration;
        mEditable = Editable.Factory.getInstance().newEditable("");

        // setTextInputClient will be followed by a call to setTextInputEditingState.
        // Do a restartInput at that time.
        mRestartInputPending = true;
        unlockPlatformViewInputConnection();
    }

    private void setPlatformViewTextInputClient(int platformViewId) {
        // We need to make sure that the Flutter view is focused so that no imm operations get short circuited.
        // Not asking for focus here specifically manifested in a but on API 28 devices where the platform view's
        // request to show a keyboard was ignored.
        mView.requestFocus();
        inputTarget = new InputTarget(InputTarget.Type.PLATFORM_VIEW, platformViewId);
        mImm.restartInput(mView);
        mRestartInputPending = false;
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
        if (inputTarget.type == InputTarget.Type.PLATFORM_VIEW) {
            // Focus changes in the framework tree have no guarantees on the order focus nodes are notified. A node
            // that lost focus may be notified before or after a node that gained focus.
            // When moving the focus from a Flutter text field to an AndroidView, it is possible that the Flutter text
            // field's focus node will be notified that it lost focus after the AndroidView was notified that it gained
            // focus. When this happens the text field will send a clearTextInput command which we ignore.
            // By doing this we prevent the framework from clearing a platform view input client(the only way to do so
            // is to set a new framework text client). I don't see an obvious use case for "clearing" a platform views
            // text input client, and it may be error prone as we don't know how the platform view manages the input
            // connection and we probably shouldn't interfere.
            // If we ever want to allow the framework to clear a platform view text client we should probably consider
            // changing the focus manager such that focus nodes that lost focus are notified before focus nodes that
            // gained focus as part of the same focus event.
            return;
        }
        inputTarget = new InputTarget(InputTarget.Type.NO_TARGET, 0);
        unlockPlatformViewInputConnection();
    }

    static private class InputTarget {
        enum Type {
            NO_TARGET,
            // InputConnection is managed by the TextInputPlugin, and events are forwarded to the Flutter framework.
            FRAMEWORK_CLIENT,
            // InputConnection is managed by an embedded platform view.
            PLATFORM_VIEW
        }

        public InputTarget(@NonNull Type type, int id) {
            this.type = type;
            this.id = id;
        }

        @NonNull
        Type type;
        // The ID of the input target.
        //
        // For framework clients this is the framework input connection client ID.
        // For platform views this is the platform view's ID.
        int id;
    }
}
