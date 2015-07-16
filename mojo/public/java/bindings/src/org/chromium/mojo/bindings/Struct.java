// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.bindings;

import org.chromium.mojo.system.Core;

/**
 * Base class for all mojo structs.
 */
public abstract class Struct {
    /**
     * The base size of the encoded struct.
     */
    private final int mEncodedBaseSize;

    /**
     * The version of the struct.
     */
    private final int mVersion;

    /**
     * Constructor.
     */
    protected Struct(int encodedBaseSize, int version) {
        mEncodedBaseSize = encodedBaseSize;
        mVersion = version;
    }

    /**
     * Returns the version of the struct. It is the max version of the struct in the mojom if it has
     * been created locally, and the version of the received struct if it has been deserialized.
     */
    public int getVersion() {
        return mVersion;
    }

    /**
     * Returns the serialization of the struct. This method can close Handles.
     *
     * @param core the |Core| implementation used to generate handles. Only used if the data
     *            structure being encoded contains interfaces, can be |null| otherwise.
     */
    public Message serialize(Core core) {
        Encoder encoder = new Encoder(core, mEncodedBaseSize);
        encode(encoder);
        return encoder.getMessage();
    }

    /**
     * Returns the serialization of the struct prepended with the given header.
     *
     * @param header the header to prepend to the returned message.
     * @param core the |Core| implementation used to generate handles. Only used if the |Struct|
     *            being encoded contains interfaces, can be |null| otherwise.
     */
    public ServiceMessage serializeWithHeader(Core core, MessageHeader header) {
        Encoder encoder = new Encoder(core, mEncodedBaseSize + header.getSize());
        header.encode(encoder);
        encode(encoder);
        return new ServiceMessage(encoder.getMessage(), header);
    }

    /**
     * Use the given encoder to serialize this data structure.
     */
    protected abstract void encode(Encoder encoder);
}
