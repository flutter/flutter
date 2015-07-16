// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package bindings

import (
	"fmt"
	"mojo/public/go/system"
)

// MessagePipeHandleOwner owns a message pipe handle, it can only pass it
// invalidating itself or close it.
type MessagePipeHandleOwner struct {
	handle system.MessagePipeHandle
}

// PassMessagePipe passes ownership of the underlying message pipe handle to
// the newly created handle object, invalidating the underlying handle object
// in the process.
func (o *MessagePipeHandleOwner) PassMessagePipe() system.MessagePipeHandle {
	if o.handle == nil {
		return &InvalidHandle{}
	}
	return o.handle.ToUntypedHandle().ToMessagePipeHandle()
}

// Close closes the underlying handle.
func (o *MessagePipeHandleOwner) Close() {
	if o.handle != nil {
		o.handle.Close()
	}
}

// NewMessagePipeHandleOwner creates |MessagePipeHandleOwner| that owns the
// provided message pipe handle.
func NewMessagePipeHandleOwner(handle system.MessagePipeHandle) MessagePipeHandleOwner {
	return MessagePipeHandleOwner{handle}
}

// InterfaceRequest represents a request from a remote client for an
// implementation of mojo interface over a specified message pipe. The
// implementor of the interface should remove the message pipe by calling
// PassMessagePipe() and attach it to the implementation.
type InterfaceRequest struct {
	MessagePipeHandleOwner
}

// InterfacePointer owns a message pipe handle with an implementation of mojo
// interface attached to the other end of the message pipe. The client of the
// interface should remove the message pipe by calling PassMessagePipe() and
// attach it to the proxy.
type InterfacePointer struct {
	MessagePipeHandleOwner
}

// CreateMessagePipeForInterface creates a message pipe with interface request
// on one end and interface pointer on the other end. The interface request
// should be attached to appropriate mojo interface implementation and
// the interface pointer should be attached to mojo interface proxy.
func CreateMessagePipeForMojoInterface() (InterfaceRequest, InterfacePointer) {
	r, h0, h1 := system.GetCore().CreateMessagePipe(nil)
	if r != system.MOJO_RESULT_OK {
		panic(fmt.Sprintf("can't create a message pipe: %v", r))
	}
	return InterfaceRequest{MessagePipeHandleOwner{h0}}, InterfacePointer{MessagePipeHandleOwner{h1}}
}
