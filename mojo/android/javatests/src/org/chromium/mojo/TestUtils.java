// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.Random;

/**
 * Utilities methods for tests.
 */
public final class TestUtils {

    private static final Random RANDOM = new Random();

    /**
     * Returns a new direct ByteBuffer of the given size with random (but reproducible) data.
     */
    public static ByteBuffer newRandomBuffer(int size) {
        byte bytes[] = new byte[size];
        RANDOM.setSeed(size);
        RANDOM.nextBytes(bytes);
        ByteBuffer data = ByteBuffer.allocateDirect(size);
        data.order(ByteOrder.LITTLE_ENDIAN);
        data.put(bytes);
        data.flip();
        return data;
    }

}
