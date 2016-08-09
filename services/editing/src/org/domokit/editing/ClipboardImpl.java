// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.editing;

import android.content.ClipboardManager;
import android.content.ClipData;
import android.content.ClipDescription;
import android.content.Context;
import android.view.inputmethod.InputMethodManager;

import org.chromium.mojo.system.MojoException;
import org.chromium.mojom.editing.ClipboardData;
import org.chromium.mojom.editing.Clipboard;

/**
 * Android implementation of Clipboard.
 */
public class ClipboardImpl implements Clipboard {
    private Context mContext;
    private static final String kTextPlainFormat = "text/plain";

    public ClipboardImpl(Context context) {
        mContext = context;
    }

    @Override
    public void close() {
    }

    @Override
    public void onConnectionError(MojoException e) {}

    @Override
    public void setClipboardData(ClipboardData incomingClip) {
        ClipboardManager clipboard =
            (ClipboardManager) mContext.getSystemService(Context.CLIPBOARD_SERVICE);
        ClipData clip = ClipData.newPlainText("text label?", incomingClip.text);
        clipboard.setPrimaryClip(clip);
    }

    @Override
    public void getClipboardData(String format, GetClipboardDataResponse callback) {
        ClipboardManager clipboard =
            (ClipboardManager) mContext.getSystemService(Context.CLIPBOARD_SERVICE);
        ClipData clip = clipboard.getPrimaryClip();
        if (clip == null) {
            callback.call(null);
            return;
        }

        if ((format == null || format.equals(kTextPlainFormat)) &&
            clip.getDescription().hasMimeType(ClipDescription.MIMETYPE_TEXT_PLAIN)) {
          ClipboardData clipResult = new ClipboardData();
          clipResult.text = clip.getItemAt(0).getText().toString();
          callback.call(clipResult);
          return;
        }

        // Unsupported or incompatible format.
        callback.call(null);
    }
}
