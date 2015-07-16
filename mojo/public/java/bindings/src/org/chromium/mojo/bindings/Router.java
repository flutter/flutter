// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.mojo.bindings;

import org.chromium.mojo.system.MessagePipeHandle;

/**
 * A {@link Router} will handle mojo message and forward those to a {@link Connector}. It deals with
 * parsing of headers and adding of request ids in order to be able to match a response to a
 * request.
 */
public interface Router extends MessageReceiverWithResponder, HandleOwner<MessagePipeHandle> {

    /**
     * Start listening for incoming messages.
     */
    public void start();

    /**
     * Set the {@link MessageReceiverWithResponder} that will deserialize and use the message
     * received from the pipe.
     */
    public void setIncomingMessageReceiver(MessageReceiverWithResponder incomingMessageReceiver);

    /**
     * Set the handle that will be notified of errors on the message pipe.
     */
    public void setErrorHandler(ConnectionErrorHandler errorHandler);
}
