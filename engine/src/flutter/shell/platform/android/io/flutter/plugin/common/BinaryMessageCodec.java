// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.common;

import java.nio.ByteBuffer;

/**
 * A {@link MessageCodec} using unencoded binary messages, represented as {@link ByteBuffer}s.
 */
public final class BinaryMessageCodec implements MessageCodec<ByteBuffer> {
    // This codec must match the Dart codec of the same name in package flutter/services.
    public static final BinaryMessageCodec INSTANCE = new BinaryMessageCodec();

    private BinaryMessageCodec() {
    }

    @Override
    public ByteBuffer encodeMessage(ByteBuffer message) {
        return message;
    }

    @Override
    public ByteBuffer decodeMessage(ByteBuffer message) {
        return message;
    }
}
