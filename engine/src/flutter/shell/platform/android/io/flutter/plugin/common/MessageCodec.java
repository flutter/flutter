// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugin.common;

import java.nio.ByteBuffer;

/**
 * A message encoding/decoding mechanism.
 *
 * Both operations throw {@link IllegalArgumentException}, if conversion fails.
 */
public interface MessageCodec<T> {
    /**
     * Encodes the specified message into binary.
     *
     * @param message the T message, possibly null.
     * @return a ByteBuffer containing the encoding between position 0 and
     * the current position, or null, if message is null.
     */
    ByteBuffer encodeMessage(T message);

    /**
     * Decodes the specified message from binary.
     *
     * @param message the {@link ByteBuffer} message, possibly null.
     * @return a T value representation of the bytes between the given buffer's current
     * position and its limit, or null, if message is null.
     */
    T decodeMessage(ByteBuffer message);
}
