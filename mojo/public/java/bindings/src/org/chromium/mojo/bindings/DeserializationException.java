// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.bindings;

/**
 * Error when deserializing a mojo message.
 */
public class DeserializationException extends RuntimeException {

    /**
     * Constructs a new deserialization exception with the specified detail message.
     */
    public DeserializationException(String message) {
        super(message);
    }

    /**
     * Constructs a new deserialization exception with the specified cause.
     */
    public DeserializationException(Exception cause) {
        super(cause);
    }

}
