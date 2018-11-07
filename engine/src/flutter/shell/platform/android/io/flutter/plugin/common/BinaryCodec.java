// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.common;

import java.nio.ByteBuffer;

/**
 * A {@link MessageCodec} using unencoded binary messages, represented as
 * {@link ByteBuffer}s.
 *
 * <p>This codec is guaranteed to be compatible with the corresponding
 * <a href="https://docs.flutter.io/flutter/services/BinaryCodec-class.html">BinaryCodec</a>
 * on the Dart side. These parts of the Flutter SDK are evolved synchronously.</p>
 *
 * <p>On the Dart side, messages are represented using {@code ByteData}.</p>
 */
public final class BinaryCodec implements MessageCodec<ByteBuffer> {
    // This codec must match the Dart codec of the same name in package flutter/services.
    public static final BinaryCodec INSTANCE = new BinaryCodec();

    private BinaryCodec() {
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
