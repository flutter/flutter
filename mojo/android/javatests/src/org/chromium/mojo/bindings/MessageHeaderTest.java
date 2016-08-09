// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.bindings;

import android.test.suitebuilder.annotation.SmallTest;

import junit.framework.TestCase;

import org.chromium.mojo.bindings.test.mojom.imported.Point;

/**
 * Testing internal classes of interfaces.
 */
public class MessageHeaderTest extends TestCase {

    /**
     * Testing that headers are identical after being serialized/deserialized.
     */
    @SmallTest
    public void testSimpleMessageHeader() {
        final int xValue = 1;
        final int yValue = 2;
        final int type = 6;
        Point p = new Point();
        p.x = xValue;
        p.y = yValue;
        ServiceMessage message = p.serializeWithHeader(null, new MessageHeader(type));

        MessageHeader header = message.getHeader();
        assertTrue(header.validateHeader(type, 0));
        assertEquals(type, header.getType());
        assertEquals(0, header.getFlags());

        Point p2 = Point.deserialize(message.getPayload());
        assertNotNull(p2);
        assertEquals(p.x, p2.x);
        assertEquals(p.y, p2.y);
    }

    /**
     * Testing that headers are identical after being serialized/deserialized.
     */
    @SmallTest
    public void testMessageWithRequestIdHeader() {
        final int xValue = 1;
        final int yValue = 2;
        final int type = 6;
        final long requestId = 0x1deadbeafL;
        Point p = new Point();
        p.x = xValue;
        p.y = yValue;
        ServiceMessage message = p.serializeWithHeader(null,
                new MessageHeader(type, MessageHeader.MESSAGE_EXPECTS_RESPONSE_FLAG, 0));
        message.setRequestId(requestId);

        MessageHeader header = message.getHeader();
        assertTrue(header.validateHeader(type, MessageHeader.MESSAGE_EXPECTS_RESPONSE_FLAG));
        assertEquals(type, header.getType());
        assertEquals(MessageHeader.MESSAGE_EXPECTS_RESPONSE_FLAG, header.getFlags());
        assertEquals(requestId, header.getRequestId());

        Point p2 = Point.deserialize(message.getPayload());
        assertNotNull(p2);
        assertEquals(p.x, p2.x);
        assertEquals(p.y, p2.y);
    }
}
