// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.bindings;

/**
 * A {@link MessageReceiver} that can also handle the handle the response message generated from the
 * given message.
 */
public interface MessageReceiverWithResponder extends MessageReceiver {

    /**
     * A variant on {@link #accept(Message)} that registers a {@link MessageReceiver}
     * (known as the responder) to handle the response message generated from the given message. The
     * responder's {@link #accept(Message)} method may be called as part of the call to
     * {@link #acceptWithResponder(Message, MessageReceiver)}, or some time after its
     * return.
     */
    boolean acceptWithResponder(Message message, MessageReceiver responder);
}
