// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package system

// MessagePipeHandle is a handle for a bidirectional communication channel for
// framed data (i.e., messages). Messages can contain plain data and/or Mojo
// handles.
type MessagePipeHandle interface {
	Handle

	// ReadMessage reads a message from the message pipe endpoint with the
	// specified flags. Returns the message data and attached handles that were
	// received in the "next" message.
	ReadMessage(flags MojoReadMessageFlags) (MojoResult, []byte, []UntypedHandle)

	// WriteMessage writes message data and optional attached handles to
	// the message pipe endpoint given by handle. On success the attached
	// handles will no longer be valid (i.e.: the receiver will receive
	// equivalent but logically different handles).
	WriteMessage(bytes []byte, handles []UntypedHandle, flags MojoWriteMessageFlags) MojoResult
}

type messagePipe struct {
	// baseHandle should always be the first component of this struct,
	// see |finalizeHandle()| for more details.
	baseHandle
}

func (h *messagePipe) ReadMessage(flags MojoReadMessageFlags) (MojoResult, []byte, []UntypedHandle) {
	h.core.mu.Lock()
	r, buf, rawHandles := sysImpl.ReadMessage(uint32(h.mojoHandle), uint32(flags))
	h.core.mu.Unlock()
	if r != 0 {
		return MojoResult(r), nil, nil
	}

	handles := make([]UntypedHandle, len(rawHandles))
	for i := 0; i < len(handles); i++ {
		handles[i] = h.core.AcquireNativeHandle(MojoHandle(rawHandles[i]))
	}
	return MojoResult(r), buf, handles
}

func (h *messagePipe) WriteMessage(bytes []byte, handles []UntypedHandle, flags MojoWriteMessageFlags) MojoResult {

	var rawHandles []uint32
	if len(handles) != 0 {
		rawHandles = make([]uint32, len(handles))
		for i := 0; i < len(handles); i++ {
			rawHandles[i] = uint32(handles[i].ReleaseNativeHandle())
		}
	}
	h.core.mu.Lock()
	r := sysImpl.WriteMessage(uint32(h.mojoHandle), bytes, rawHandles, uint32(flags))
	h.core.mu.Unlock()
	return MojoResult(r)
}
