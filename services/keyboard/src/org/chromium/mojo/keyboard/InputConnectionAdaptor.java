// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.keyboard;

import android.text.InputType;
import android.view.View;
import android.view.inputmethod.BaseInputConnection;
import android.view.inputmethod.CompletionInfo;
import android.view.inputmethod.CorrectionInfo;
import android.view.inputmethod.EditorInfo;

import org.chromium.mojom.keyboard.CompletionData;
import org.chromium.mojom.keyboard.CorrectionData;
import org.chromium.mojom.keyboard.KeyboardClient;

/**
 * An adaptor between InputConnection and KeyboardClient.
 */
public class InputConnectionAdaptor extends BaseInputConnection {
    private KeyboardClient mClient;

    public InputConnectionAdaptor(View view, KeyboardClient client, EditorInfo outAttrs) {
        super(view, true);
        assert client != null;
        mClient = client;
        outAttrs.inputType = InputType.TYPE_CLASS_TEXT;
        outAttrs.initialSelStart = -1;
        outAttrs.initialSelEnd = -1;
    }

    @Override
    public boolean commitCompletion(CompletionInfo completion) {
        // TODO(abarth): Copy the data from |completion| to CompletionData.
        mClient.commitCompletion(new CompletionData());
        return super.commitCompletion(completion);
    }

    @Override
    public boolean commitCorrection(CorrectionInfo correction) {
        // TODO(abarth): Copy the data from |correction| to CompletionData.
        mClient.commitCorrection(new CorrectionData());
        return super.commitCorrection(correction);
    }

    @Override
    public boolean commitText(CharSequence text, int newCursorPosition) {
        mClient.commitText(text.toString(), newCursorPosition);
        return super.commitText(text, newCursorPosition);
    }

    @Override
    public boolean deleteSurroundingText(int beforeLength, int afterLength) {
        mClient.deleteSurroundingText(beforeLength, afterLength);
        return super.deleteSurroundingText(beforeLength, afterLength);
    }

    @Override
    public boolean setComposingRegion(int start, int end) {
        mClient.setComposingRegion(start, end);
        return super.setComposingRegion(start, end);
    }

    @Override
    public boolean setComposingText(CharSequence text, int newCursorPosition) {
        mClient.setComposingText(text.toString(), newCursorPosition);
        return super.setComposingText(text, newCursorPosition);
    }

    @Override
    public boolean setSelection(int start, int end) {
        mClient.setSelection(start, end);
        return super.setSelection(start, end);
    }
}
