// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.common;

import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;

/**
 * A {@link MessageCodec} using UTF-8 encoded String messages.
 */
public final class StringMessageCodec implements MessageCodec<String> {
    // This codec must match the Dart codec of the same name in package flutter/services.
    public static final StringMessageCodec INSTANCE = new StringMessageCodec();

    private StringMessageCodec() {
    }

    @Override
    public ByteBuffer encodeMessage(String message) {
        if (message == null) {
            return null;
        }
        // TODO(mravn): Avoid the extra copy below.
        final byte[] bytes = message.getBytes(StandardCharsets.UTF_8);
        final ByteBuffer buffer = ByteBuffer.allocateDirect(bytes.length);
        buffer.put(bytes);
        return buffer;
    }

    @Override
    public String decodeMessage(ByteBuffer message) {
        if (message == null) {
            return null;
        }
        final byte[] bytes;
        final int offset;
        final int length = message.remaining();
        if (message.hasArray()) {
            bytes = message.array();
            offset = message.arrayOffset();
        } else {
            // TODO(mravn): Avoid the extra copy below.
            bytes = new byte[length];
            message.get(bytes);
            offset = 0;
        }
        return new String(bytes, offset, length, StandardCharsets.UTF_8);
    }
}
