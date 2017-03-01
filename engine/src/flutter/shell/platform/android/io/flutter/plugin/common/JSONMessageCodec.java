// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.common;

import java.nio.ByteBuffer;
import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONTokener;

/**
 * A {@link MessageCodec} using UTF-8 encoded JSON messages.
 *
 * Supports the same Java values as {@link JSONObject#wrap(Object)}.
 */
public final class JSONMessageCodec implements MessageCodec<Object> {
    // This codec must match the Dart codec of the same name in package flutter/services.
    public static final JSONMessageCodec INSTANCE = new JSONMessageCodec();

    private JSONMessageCodec() {
    }

    @Override
    public ByteBuffer encodeMessage(Object message) {
        if (message == null) {
            return null;
        }
        return StringMessageCodec.INSTANCE.encodeMessage(JSONObject.wrap(message).toString());
    }

    @Override
    public Object decodeMessage(ByteBuffer message) {
        if (message == null) {
            return null;
        }
        try {
            final String json = StringMessageCodec.INSTANCE.decodeMessage(message);
            final JSONTokener tokener = new JSONTokener(json);
            final Object value = tokener.nextValue();
            if (tokener.more()) {
                throw new IllegalArgumentException("Invalid JSON");
            }
            return value;
        } catch (JSONException e) {
            throw new IllegalArgumentException("Invalid JSON", e);
        }
    }
}
