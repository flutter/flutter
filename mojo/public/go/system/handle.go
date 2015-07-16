// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package system

import (
	"log"
	"runtime"
)

// Handle is a generic handle for mojo objects.
type Handle interface {
	// Close closes the given handle.
	Close() MojoResult

	// IsValid returns whether the handle is valid. A handle is valid until it
	// has been explicitly closed or sent through a message pipe.
	IsValid() bool

	// NativeHandle returns the native handle backed by this handle.
	//
	// Note: try to avoid using this method as you lose ownership tracking.
	NativeHandle() MojoHandle

	// ReleaseNativeHandle releases the native handle backed by this handle.
	// The caller owns the handle and must close it.
	ReleaseNativeHandle() MojoHandle

	// ToUntypedHandle converts this handle into an UntypedHandle, invalidating
	// this handle.
	ToUntypedHandle() UntypedHandle

	// Wait waits on the handle until a signal indicated by signals is satisfied
	// or it becomes known that no signal indicated by signals will ever be
	// satisified or until deadline has passed.
	Wait(signals MojoHandleSignals, deadline MojoDeadline) (MojoResult, MojoHandleSignalsState)
}

// UntypedHandle is a a mojo handle of unknown type. This handle can be typed by
// using one of its methods, which will return a handle of the requested type
// and invalidate this object. No validation is made when the conversion
// operation is called.
type UntypedHandle interface {
	Handle

	// ToConsumerHandle returns the underlying handle as a ConsumerHandle
	// and invalidates this UntypedHandle representation.
	ToConsumerHandle() ConsumerHandle

	// ToProducerHandle returns the underlying handle as a ProducerHandle
	// and invalidates this UntypedHandle representation.
	ToProducerHandle() ProducerHandle

	// ToMessagePipeHandle returns the underlying handle as a MessagePipeHandle
	// and invalidates this UntypedHandle representation.
	ToMessagePipeHandle() MessagePipeHandle

	// ToSharedBufferHandle returns the underlying handle as a
	// SharedBufferHandle and invalidates this UntypedHandle representation.
	ToSharedBufferHandle() SharedBufferHandle
}

// finalizeHandle closes handles that becomes unreachable in runtime.
// We want to make sure that every mojo handle is closed, so we set this
// finalizer function on every handle object we create. If a handle object
// becomes invalidated (because the handle was closed or the underlying mojo
// handle has been passed to another handle object), we remove the finalizer.
//
// The finalizing mechanism works tricky: runtime.SetFinalizer can be called on
// an object allocated by calling new or by taking the address of a composite
// literal, so we can't set a finalizer on an embedded struct if the embedded
// struct has a non-zero offset related to the outmost struct.
//
// Type structure of handles is the following: there is a struct baseHandle,
// which serves as a "base class" for all the typed handles (i.e. sharedBuffer,
// untypedHandleImpl, dataPipeProducer, dataPipeConsumer and messagePipe). We
// express it by struct embedding. When we operate with handles, we create typed
// handles and set finalizers on them, while to invalidate a handle and remove
// finalizer we call methods on the embedded baseHandle struct. So in order for
// finalizers to work correct we need to make sure that baseHandle is the first
// component of typed handles.
func finalizeHandle(h Handle) {
	log.Println("Handle was not closed.")
	h.Close()
}

type baseHandle struct {
	core       *coreImpl
	mojoHandle MojoHandle
}

func (h *baseHandle) invalidate() {
	h.mojoHandle = MOJO_HANDLE_INVALID
	runtime.SetFinalizer(h, nil)
}

func (h *baseHandle) Close() MojoResult {
	mojoHandle := h.mojoHandle
	h.invalidate()
	h.core.mu.Lock()
	r := sysImpl.Close(uint32(mojoHandle))
	h.core.mu.Unlock()
	return MojoResult(r)
}

func (h *baseHandle) IsValid() bool {
	return h.mojoHandle != MOJO_HANDLE_INVALID
}

func (h *baseHandle) NativeHandle() MojoHandle {
	return h.mojoHandle
}

func (h *baseHandle) ReleaseNativeHandle() MojoHandle {
	mojoHandle := h.mojoHandle
	h.invalidate()
	return mojoHandle
}

func (h *baseHandle) ToUntypedHandle() UntypedHandle {
	handle := &untypedHandleImpl{*h}
	runtime.SetFinalizer(handle, finalizeHandle)
	h.invalidate()
	return handle
}

func (h *baseHandle) Wait(signals MojoHandleSignals, deadline MojoDeadline) (MojoResult, MojoHandleSignalsState) {
	r, satisfiedSignals, satisfiableSignals := sysImpl.Wait(uint32(h.mojoHandle), uint32(signals), uint64(deadline))
	state := MojoHandleSignalsState{
		SatisfiedSignals:   MojoHandleSignals(satisfiedSignals),
		SatisfiableSignals: MojoHandleSignals(satisfiableSignals),
	}
	return MojoResult(r), state
}

type untypedHandleImpl struct {
	// baseHandle should always be the first component of this struct,
	// see |finalizeHandle()| for more details.
	baseHandle
}

func (h *untypedHandleImpl) ToConsumerHandle() ConsumerHandle {
	handle := &dataPipeConsumer{h.baseHandle}
	runtime.SetFinalizer(handle, finalizeHandle)
	h.invalidate()
	return handle
}

func (h *untypedHandleImpl) ToProducerHandle() ProducerHandle {
	handle := &dataPipeProducer{h.baseHandle}
	runtime.SetFinalizer(handle, finalizeHandle)
	h.invalidate()
	return handle
}

func (h *untypedHandleImpl) ToMessagePipeHandle() MessagePipeHandle {
	handle := &messagePipe{h.baseHandle}
	runtime.SetFinalizer(handle, finalizeHandle)
	h.invalidate()
	return handle
}

func (h *untypedHandleImpl) ToSharedBufferHandle() SharedBufferHandle {
	handle := &sharedBuffer{h.baseHandle}
	runtime.SetFinalizer(handle, finalizeHandle)
	h.invalidate()
	return handle
}
