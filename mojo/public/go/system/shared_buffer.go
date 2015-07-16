// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package system

import (
	"reflect"
	"unsafe"
)

// SharedBufferHandle is a handle for a buffer that can be shared between
// applications.
type SharedBufferHandle interface {
	Handle

	// DuplicateBufferHandle duplicates the handle to a buffer.
	DuplicateBufferHandle(opts *DuplicateBufferHandleOptions) (MojoResult, SharedBufferHandle)

	// MapBuffer maps the requested part of the shared buffer given by handle
	// into memory with specified flags. On success, it returns slice that
	// points to the requested shared buffer.
	MapBuffer(offset uint64, numBytes int, flags MojoMapBufferFlags) (MojoResult, []byte)

	// UnmapBuffer unmaps a buffer that was returned by MapBuffer.
	UnmapBuffer(buffer []byte) MojoResult
}

type sharedBuffer struct {
	// baseHandle should always be the first component of this struct,
	// see |finalizeHandle()| for more details.
	baseHandle
}

func (h *sharedBuffer) DuplicateBufferHandle(opts *DuplicateBufferHandleOptions) (MojoResult, SharedBufferHandle) {
	var flags uint32
	if opts != nil {
		flags = uint32(opts.Flags)
	}
	h.core.mu.Lock()
	r, dup := sysImpl.DuplicateBufferHandle(uint32(h.mojoHandle), flags)
	h.core.mu.Unlock()
	return MojoResult(r), core.AcquireNativeHandle(MojoHandle(dup)).ToSharedBufferHandle()
}

func (h *sharedBuffer) MapBuffer(offset uint64, numBytes int, flags MojoMapBufferFlags) (MojoResult, []byte) {
	h.core.mu.Lock()
	r, buf := sysImpl.MapBuffer(uint32(h.mojoHandle), offset, uint64(numBytes), uint32(flags))
	h.core.mu.Unlock()
	if r != 0 {
		return MojoResult(r), nil
	}

	return MojoResult(r), buf
}

func (h *sharedBuffer) UnmapBuffer(buffer []byte) MojoResult {
	h.core.mu.Lock()
	r := sysImpl.UnmapBuffer(buffer)
	h.core.mu.Unlock()
	return MojoResult(r)
}

func newUnsafeSlice(ptr unsafe.Pointer, length int) unsafe.Pointer {
	header := &reflect.SliceHeader{
		Data: uintptr(ptr),
		Len:  length,
		Cap:  length,
	}
	return unsafe.Pointer(header)
}

func unsafeByteSlice(ptr unsafe.Pointer, length int) []byte {
	return *(*[]byte)(newUnsafeSlice(ptr, length))
}
