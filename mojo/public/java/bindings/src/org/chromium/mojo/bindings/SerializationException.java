// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.bindings;

/**
 * Error that can be thrown when serializing a mojo message.
 */
public class SerializationException extends RuntimeException {

    /**
     * Constructs a new serialization exception with the specified detail message.
     */
    public SerializationException(String message) {
        super(message);
    }

    /**
     * Constructs a new serialization exception with the specified cause.
     */
    public SerializationException(Exception cause) {
        super(cause);
    }

}
