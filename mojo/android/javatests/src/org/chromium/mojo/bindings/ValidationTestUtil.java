// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.bindings;

import org.chromium.base.CalledByNative;
import org.chromium.base.JNINamespace;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;

/**
 * Utility class for testing message validation. The file format used to describe a message is
 * described in The format is described in
 * mojo/public/cpp/bindings/tests/validation_test_input_parser.h
 */
@JNINamespace("mojo::android")
public class ValidationTestUtil {

    /**
     * Content of a '.data' file.
     */
    public static class Data {
        private final ByteBuffer mData;
        private final int mHandlesCount;
        private final String mErrorMessage;

        public ByteBuffer getData() {
            return mData;
        }

        public int getHandlesCount() {
            return mHandlesCount;
        }

        public String getErrorMessage() {
            return mErrorMessage;
        }

        private Data(ByteBuffer data, int handlesCount, String errorMessage) {
            this.mData = data;
            this.mHandlesCount = handlesCount;
            this.mErrorMessage = errorMessage;
        }
    }

    /**
     * Parse a '.data' file.
     */
    public static Data parseData(String dataAsString) {
        return nativeParseData(dataAsString);
    }

    private static native Data nativeParseData(String dataAsString);

    @CalledByNative
    private static Data buildData(ByteBuffer data, int handlesCount, String errorMessage) {
        ByteBuffer copiedData = null;
        if (data != null) {
            copiedData = ByteBuffer.allocateDirect(data.limit());
            copiedData.order(ByteOrder.LITTLE_ENDIAN);
            copiedData.put(data);
            copiedData.flip();
        }
        return new Data(copiedData, handlesCount, errorMessage);
    }
}
