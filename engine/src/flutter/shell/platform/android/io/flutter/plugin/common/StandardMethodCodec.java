// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.common;

import io.flutter.plugin.common.StandardMessageCodec.ExposedByteArrayOutputStream;
import java.nio.ByteBuffer;

/**
 * A {@link MethodCodec} using the Flutter standard binary encoding.
 *
 * The standard codec is guaranteed to be compatible with the corresponding standard codec for
 * PlatformMethodChannels on the Flutter side. These parts of the Flutter SDK are evolved
 * synchronously.
 *
 * Values supported as method arguments and result payloads are those supported by
 * {@link StandardMessageCodec}.
 */
public final class StandardMethodCodec implements MethodCodec {
    // This codec must match the Dart codec of the same name in package flutter/services.
    public static final StandardMethodCodec INSTANCE = new StandardMethodCodec();

    private StandardMethodCodec() {
    }

    @Override
    public MethodCall decodeMethodCall(ByteBuffer methodCall) {
        final Object method = StandardMessageCodec.readValue(methodCall);
        final Object arguments = StandardMessageCodec.readValue(methodCall);
        if (method instanceof String) {
            return new MethodCall((String) method, arguments);
        }
        throw new IllegalArgumentException("Method call corrupted");
    }

    @Override
    public ByteBuffer encodeSuccessEnvelope(Object result) {
        final ExposedByteArrayOutputStream stream = new ExposedByteArrayOutputStream();
        stream.write(0);
        StandardMessageCodec.writeValue(stream, result);
        final ByteBuffer buffer = ByteBuffer.allocateDirect(stream.size());
        buffer.put(stream.buffer(), 0, stream.size());
        return buffer;
    }

    @Override
    public ByteBuffer encodeErrorEnvelope(String errorCode, String errorMessage,
        Object errorDetails) {
        final ExposedByteArrayOutputStream stream = new ExposedByteArrayOutputStream();
        stream.write(1);
        StandardMessageCodec.writeValue(stream, errorCode);
        StandardMessageCodec.writeValue(stream, errorMessage);
        StandardMessageCodec.writeValue(stream, errorDetails);
        final ByteBuffer buffer = ByteBuffer.allocateDirect(stream.size());
        buffer.put(stream.buffer(), 0, stream.size());
        return buffer;
    }
}
