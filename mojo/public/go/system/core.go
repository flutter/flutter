// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package system

import (
	"runtime"
	"sync"
)

// core is an instance of the Mojo system APIs implementation.
var core coreImpl

// Core is an interface giving access to the base operations.
// See |src/mojo/public/c/system/core.h| for the underlying api.
type Core interface {
	// AcquireNativeHandle acquires a handle from the native side. The handle
	// will be owned by the returned object and must not be closed outside of
	// it.
	AcquireNativeHandle(handle MojoHandle) UntypedHandle

	// GetTimeTicksNow returns a monotonically increasing platform dependent
	// tick count representing "right now". Resolution depends on the system
	// configuration.
	GetTimeTicksNow() MojoTimeTicks

	// WaitMany behaves as if Wait were called on each handle/signal pair
	// simultaneously and completing when the first Wait would complete.
	// Notes about return values:
	//   |index| can be -1 if the error returned was not caused by a
	//       particular handle. For example, the error MOJO_RESULT_DEADLINE_EXCEEDED
	//       is not related to a particular handle.
	//   |states| can be nil if the signal array could not be returned. This can
	//       happen with errors such as MOJO_RESULT_INVALID_ARGUMENT.
	WaitMany(handles []Handle, signals []MojoHandleSignals, deadline MojoDeadline) (result MojoResult, index int, states []MojoHandleSignalsState)

	// CreateDataPipe creates a data pipe which is a unidirectional
	// communication channel for unframed data. On success, returns a
	// handle to the producer and consumer of the data pipe.
	CreateDataPipe(opts *DataPipeOptions) (MojoResult, ProducerHandle, ConsumerHandle)

	// CreateMessagePipe creates a message pipe which is a bidirectional
	// communication channel for framed data (i.e., messages). Messages
	// can contain plain data and/or Mojo handles. On success, it returns
	// handles to the two endpoints of the message pipe.
	CreateMessagePipe(opts *MessagePipeOptions) (MojoResult, MessagePipeHandle, MessagePipeHandle)

	// CreateSharedBuffer creates a buffer of size numBytes that can be
	// shared between applications. One must call MapBuffer to access
	// the buffer.
	CreateSharedBuffer(opts *SharedBufferOptions, numBytes uint64) (MojoResult, SharedBufferHandle)
}

// coreImpl is an implementation of the Mojo system APIs.
type coreImpl struct {
	// Protects from making parallel non-blocking mojo cgo calls.
	mu sync.Mutex
}

// GetCore returns singleton instance of the Mojo system APIs implementation.
//
// The implementation uses cgo to call native mojo APIs implementation. Each cgo
// call uses a separate thread for execution. To limit the number of used
// threads all non-blocking system calls (i.e. all system calls except |Wait|
// and |WaitMany|) on this implementation and on handles returned by this
// implementation are protected by a mutex so that if you make two parallel
// system calls one will wait for another to finish before executing.
// However, |Wait| and |WaitMany| are not protected by a mutex and each parallel
// call will use a separate thread. To reduce number of threads used for |Wait|
// calls prefer to use |WaitMany|.
func GetCore() Core {
	return &core
}

func (impl *coreImpl) AcquireNativeHandle(mojoHandle MojoHandle) UntypedHandle {
	handle := &untypedHandleImpl{baseHandle{impl, mojoHandle}}
	runtime.SetFinalizer(handle, finalizeHandle)
	return handle
}

func (impl *coreImpl) GetTimeTicksNow() MojoTimeTicks {
	impl.mu.Lock()
	r := sysImpl.GetTimeTicksNow()
	impl.mu.Unlock()
	return MojoTimeTicks(r)
}

func (impl *coreImpl) WaitMany(handles []Handle, signals []MojoHandleSignals, deadline MojoDeadline) (MojoResult, int, []MojoHandleSignalsState) {
	if len(handles) == 0 {
		r, _, _, _ := sysImpl.WaitMany(nil, nil, uint64(deadline))
		return MojoResult(r), -1, nil
	}
	rawHandles := make([]uint32, len(handles))
	rawSignals := make([]uint32, len(signals))
	for i := 0; i < len(handles); i++ {
		rawHandles[i] = uint32(handles[i].NativeHandle())
		rawSignals[i] = uint32(signals[i])
	}
	r, index, rawSatisfiedSignals, rawSatisfiableSignals := sysImpl.WaitMany(rawHandles, rawSignals, uint64(deadline))
	if MojoResult(r) == MOJO_RESULT_INVALID_ARGUMENT || MojoResult(r) == MOJO_RESULT_RESOURCE_EXHAUSTED {
		return MojoResult(r), index, nil
	}
	signalsStates := make([]MojoHandleSignalsState, len(handles))
	for i := 0; i < len(handles); i++ {
		signalsStates[i].SatisfiedSignals = MojoHandleSignals(rawSatisfiedSignals[i])
		signalsStates[i].SatisfiableSignals = MojoHandleSignals(rawSatisfiableSignals[i])
	}
	return MojoResult(r), index, signalsStates
}

func (impl *coreImpl) CreateDataPipe(opts *DataPipeOptions) (MojoResult, ProducerHandle, ConsumerHandle) {

	var r uint32
	var p, c uint32
	impl.mu.Lock()
	if opts == nil {
		r, p, c = sysImpl.CreateDataPipeWithDefaultOptions()
	} else {
		r, p, c = sysImpl.CreateDataPipe(uint32(opts.Flags), uint32(opts.ElemSize), uint32(opts.Capacity))
	}
	impl.mu.Unlock()
	return MojoResult(r), impl.AcquireNativeHandle(MojoHandle(p)).ToProducerHandle(), impl.AcquireNativeHandle(MojoHandle(c)).ToConsumerHandle()
}

func (impl *coreImpl) CreateMessagePipe(opts *MessagePipeOptions) (MojoResult, MessagePipeHandle, MessagePipeHandle) {

	var flags uint32
	if opts != nil {
		flags = uint32(opts.Flags)
	}
	impl.mu.Lock()
	r, handle0, handle1 := sysImpl.CreateMessagePipe(flags)
	impl.mu.Unlock()
	return MojoResult(r), impl.AcquireNativeHandle(MojoHandle(handle0)).ToMessagePipeHandle(), impl.AcquireNativeHandle(MojoHandle(handle1)).ToMessagePipeHandle()
}

func (impl *coreImpl) CreateSharedBuffer(opts *SharedBufferOptions, numBytes uint64) (MojoResult, SharedBufferHandle) {
	var flags uint32
	if opts != nil {
		flags = uint32(opts.Flags)
	}
	impl.mu.Lock()
	r, handle := sysImpl.CreateSharedBuffer(flags, numBytes)
	impl.mu.Unlock()
	return MojoResult(r), impl.AcquireNativeHandle(MojoHandle(handle)).ToSharedBufferHandle()
}
