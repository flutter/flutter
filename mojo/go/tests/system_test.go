// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package tests

import (
	"bytes"
	"testing"

	"mojo/public/go/system"
)

const (
	MOJO_HANDLE_SIGNAL_READWRITABLE = system.MojoHandleSignals(system.MOJO_HANDLE_SIGNAL_READABLE |
		system.MOJO_HANDLE_SIGNAL_WRITABLE)
	MOJO_HANDLE_SIGNAL_ALL = system.MojoHandleSignals(system.MOJO_HANDLE_SIGNAL_READABLE |
		system.MOJO_HANDLE_SIGNAL_WRITABLE |
		system.MOJO_HANDLE_SIGNAL_PEER_CLOSED)
)

func TestGetTimeTicksNow(t *testing.T) {
	x := core.GetTimeTicksNow()
	if x < 10 {
		t.Error("Invalid GetTimeTicksNow return value")
	}
}

func TestHandle(t *testing.T) {
	var handle system.SharedBufferHandle
	var r system.MojoResult

	if r, handle = core.CreateSharedBuffer(nil, 1); r != system.MOJO_RESULT_OK {
		t.Fatalf("CreateSharedBuffer failed:%v", r)
	}
	if !handle.IsValid() {
		t.Fatalf("CreateSharedBuffer returned invalid handle:%v", handle)
	}
	duplicate := handle
	if duplicate.NativeHandle() != handle.NativeHandle() {
		t.Fatalf("duplicate(%v) and handle(%v) point to different handles", duplicate.NativeHandle(), handle.NativeHandle())
	}
	releasedHandle := handle.ReleaseNativeHandle()
	if duplicate.IsValid() || handle.IsValid() {
		t.Fatalf("duplicate(%v) and handle(%v) should be invalid after releasing native handle", duplicate.NativeHandle(), handle.NativeHandle())
	}
	handle = core.AcquireNativeHandle(releasedHandle).ToSharedBufferHandle()
	if handle.NativeHandle() != releasedHandle || !handle.IsValid() {
		t.Fatalf("handle(%v) should be valid after AcquireNativeHandle", handle.NativeHandle())
	}
	untypedHandle := handle.ToUntypedHandle()
	if handle.IsValid() {
		t.Fatalf("handle(%v) should be invalid after call ToUntypedHandle", handle.NativeHandle())
	}
	handle = untypedHandle.ToSharedBufferHandle()
	if untypedHandle.IsValid() {
		t.Fatalf("untypedHandle(%v) should be invalid after call ToSharedBufferHandle", untypedHandle.NativeHandle())
	}
	if handle.NativeHandle() != releasedHandle {
		t.Fatalf("handle(%v) should be wrapping %v", handle.NativeHandle(), releasedHandle)
	}
	if r = handle.Close(); r != system.MOJO_RESULT_OK {
		t.Fatalf("Close on handle failed:%v", r)
	}
}

func TestMessagePipe(t *testing.T) {
	var h0, h1 system.MessagePipeHandle
	var r system.MojoResult
	var state system.MojoHandleSignalsState

	if r, h0, h1 = core.CreateMessagePipe(nil); r != system.MOJO_RESULT_OK {
		t.Fatalf("CreateMessagePipe failed:%v", r)
	}
	if !h0.IsValid() || !h1.IsValid() {
		t.Fatalf("CreateMessagePipe returned invalid handles h0:%v h1:%v", h0, h1)
	}

	r, state = h0.Wait(system.MOJO_HANDLE_SIGNAL_READABLE, 0)
	if r != system.MOJO_RESULT_DEADLINE_EXCEEDED {
		t.Fatalf("h0 should not be readable:%v", r)
	}
	if state.SatisfiedSignals != system.MOJO_HANDLE_SIGNAL_WRITABLE {
		t.Fatalf("state should be not be signaled readable after CreateMessagePipe:%v", state.SatisfiedSignals)
	}
	if state.SatisfiableSignals != MOJO_HANDLE_SIGNAL_ALL {
		t.Fatalf("state should allow all signals after CreateMessagePipe:%v", state.SatisfiableSignals)
	}

	r, state = h0.Wait(system.MOJO_HANDLE_SIGNAL_WRITABLE, system.MOJO_DEADLINE_INDEFINITE)
	if r != system.MOJO_RESULT_OK {
		t.Fatalf("h0 should be writable:%v", r)
	}
	if state.SatisfiedSignals != system.MOJO_HANDLE_SIGNAL_WRITABLE {
		t.Fatalf("state should be signaled writable after core.Wait:%v", state.SatisfiedSignals)
	}
	if state.SatisfiableSignals != MOJO_HANDLE_SIGNAL_ALL {
		t.Fatalf("state should allow all signals after core.Wait:%v", state.SatisfiableSignals)
	}

	if r, _, _ = h0.ReadMessage(system.MOJO_READ_MESSAGE_FLAG_NONE); r != system.MOJO_RESULT_SHOULD_WAIT {
		t.Fatalf("Read on h0 did not return wait:%v", r)
	}
	kHello := []byte("hello")
	if r = h1.WriteMessage(kHello, nil, system.MOJO_WRITE_MESSAGE_FLAG_NONE); r != system.MOJO_RESULT_OK {
		t.Fatalf("Failed WriteMessage on h1:%v", r)
	}

	r, state = h0.Wait(system.MOJO_HANDLE_SIGNAL_READABLE, system.MOJO_DEADLINE_INDEFINITE)
	if r != system.MOJO_RESULT_OK {
		t.Fatalf("h0 should be readable after WriteMessage to h1:%v", r)
	}
	if state.SatisfiedSignals != MOJO_HANDLE_SIGNAL_READWRITABLE {
		t.Fatalf("h0 should be signaled readable after WriteMessage to h1:%v", state.SatisfiedSignals)
	}
	if state.SatisfiableSignals != MOJO_HANDLE_SIGNAL_ALL {
		t.Fatalf("h0 should be readable/writable after WriteMessage to h1:%v", state.SatisfiableSignals)
	}
	if !state.SatisfiableSignals.IsReadable() || !state.SatisfiableSignals.IsWritable() || !state.SatisfiableSignals.IsClosed() {
		t.Fatalf("Helper functions are misbehaving")
	}

	r, msg, _ := h0.ReadMessage(system.MOJO_READ_MESSAGE_FLAG_NONE)
	if r != system.MOJO_RESULT_OK {
		t.Fatalf("Failed ReadMessage on h0:%v", r)
	}
	if !bytes.Equal(msg, kHello) {
		t.Fatalf("Invalid message expected:%s, got:%s", kHello, msg)
	}

	r, index, states := core.WaitMany([]system.Handle{h0}, []system.MojoHandleSignals{system.MOJO_HANDLE_SIGNAL_READABLE}, 10)
	if r != system.MOJO_RESULT_DEADLINE_EXCEEDED {
		t.Fatalf("h0 should not be readable after reading message:%v", r)
	}
	if index != -1 {
		t.Fatalf("should be no index after MOJO_RESULT_DEADLINE_EXCEEDED:%v", index)
	}
	if len(states) != 1 {
		t.Fatalf("states should be set after WaitMany:%v", states)
	}
	if states[0].SatisfiedSignals != system.MOJO_HANDLE_SIGNAL_WRITABLE {
		t.Fatalf("h0 should be signaled readable WaitMany:%v", states[0].SatisfiedSignals)
	}
	if states[0].SatisfiableSignals != MOJO_HANDLE_SIGNAL_ALL {
		t.Fatalf("h0 should be readable/writable after WaitMany:%v", states[0].SatisfiableSignals)
	}

	if r = h0.Close(); r != system.MOJO_RESULT_OK {
		t.Fatalf("Close on h0 failed:%v", r)
	}

	r, state = h1.Wait(MOJO_HANDLE_SIGNAL_READWRITABLE, system.MOJO_DEADLINE_INDEFINITE)
	if r != system.MOJO_RESULT_FAILED_PRECONDITION {
		t.Fatalf("h1 should not be readable/writable after Close(h0):%v", r)
	}
	if state.SatisfiedSignals != system.MOJO_HANDLE_SIGNAL_PEER_CLOSED {
		t.Fatalf("state should be signaled closed after Close(h0):%v", state.SatisfiedSignals)
	}
	if state.SatisfiableSignals != system.MOJO_HANDLE_SIGNAL_PEER_CLOSED {
		t.Fatalf("state should only be closable after Close(h0):%v", state.SatisfiableSignals)
	}

	if r = h1.Close(); r != system.MOJO_RESULT_OK {
		t.Fatalf("Close on h1 failed:%v", r)
	}
}

func TestDataPipe(t *testing.T) {
	var hp system.ProducerHandle
	var hc system.ConsumerHandle
	var r system.MojoResult

	if r, hp, hc = core.CreateDataPipe(nil); r != system.MOJO_RESULT_OK {
		t.Fatalf("CreateDataPipe failed:%v", r)
	}
	if !hp.IsValid() || !hc.IsValid() {
		t.Fatalf("CreateDataPipe returned invalid handles hp:%v hc:%v", hp, hc)
	}
	if r, _ = hc.Wait(system.MOJO_HANDLE_SIGNAL_READABLE, 0); r != system.MOJO_RESULT_DEADLINE_EXCEEDED {
		t.Fatalf("hc should not be readable:%v", r)
	}
	if r, _ = hp.Wait(system.MOJO_HANDLE_SIGNAL_WRITABLE, system.MOJO_DEADLINE_INDEFINITE); r != system.MOJO_RESULT_OK {
		t.Fatalf("hp should be writeable:%v", r)
	}

	// Test one-phase read/write.
	// Writing.
	kHello := []byte("hello")
	r, numBytes := hp.WriteData(kHello, system.MOJO_WRITE_DATA_FLAG_NONE)
	if r != system.MOJO_RESULT_OK || numBytes != len(kHello) {
		t.Fatalf("Failed WriteData on hp:%v numBytes:%d", r, numBytes)
	}
	// Reading.
	if r, _ = hc.Wait(system.MOJO_HANDLE_SIGNAL_READABLE, system.MOJO_DEADLINE_INDEFINITE); r != system.MOJO_RESULT_OK {
		t.Fatalf("hc should be readable after WriteData on hp:%v", r)
	}
	r, data := hc.ReadData(system.MOJO_READ_DATA_FLAG_NONE)
	if r != system.MOJO_RESULT_OK {
		t.Fatalf("Failed ReadData on hc:%v", r)
	}
	if !bytes.Equal(data, kHello) {
		t.Fatalf("Invalid data expected:%s, got:%s", kHello, data)
	}

	// Test two-phase read/write.
	// Writing.
	kHello = []byte("Hello, world!")
	r, buf := hp.BeginWriteData(len(kHello), system.MOJO_WRITE_DATA_FLAG_ALL_OR_NONE)
	if r != system.MOJO_RESULT_OK {
		t.Fatalf("Failed BeginWriteData on hp:%v numBytes:%d", r, len(kHello))
	}
	if len(buf) < len(kHello) {
		t.Fatalf("Buffer size(%d) should be at least %d", len(buf), len(kHello))
	}
	copy(buf, kHello)
	if r, _ := hp.WriteData(kHello, system.MOJO_WRITE_DATA_FLAG_NONE); r != system.MOJO_RESULT_BUSY {
		t.Fatalf("hp should be busy during a two-phase write: %v", r)
	}
	if r, _ = hc.Wait(system.MOJO_HANDLE_SIGNAL_READABLE, 0); r != system.MOJO_RESULT_DEADLINE_EXCEEDED {
		t.Fatalf("hc shouldn't be readable before EndWriteData on hp:%v", r)
	}
	if r := hp.EndWriteData(len(kHello)); r != system.MOJO_RESULT_OK {
		t.Fatalf("Failed EndWriteData on hp:%v", r)
	}
	// Reading.
	if r, _ = hc.Wait(system.MOJO_HANDLE_SIGNAL_READABLE, system.MOJO_DEADLINE_INDEFINITE); r != system.MOJO_RESULT_OK {
		t.Fatalf("hc should be readable after EndWriteData on hp:%v", r)
	}
	if r, buf = hc.BeginReadData(len(kHello), system.MOJO_READ_DATA_FLAG_ALL_OR_NONE); r != system.MOJO_RESULT_OK {
		t.Fatalf("Failed BeginReadData on hc:%v numBytes:%d", r, len(kHello))
	}
	if len(buf) != len(kHello) {
		t.Fatalf("Buffer size(%d) should be equal to %d", len(buf), len(kHello))
	}
	if r, _ := hc.ReadData(system.MOJO_READ_DATA_FLAG_NONE); r != system.MOJO_RESULT_BUSY {
		t.Fatalf("hc should be busy during a two-phase read: %v", r)
	}
	if !bytes.Equal(buf, kHello) {
		t.Fatalf("Invalid data expected:%s, got:%s", kHello, buf)
	}
	if r := hc.EndReadData(len(buf)); r != system.MOJO_RESULT_OK {
		t.Fatalf("Failed EndReadData on hc:%v", r)
	}

	if r = hp.Close(); r != system.MOJO_RESULT_OK {
		t.Fatalf("Close on hp failed:%v", r)
	}
	if r, _ = hc.Wait(system.MOJO_HANDLE_SIGNAL_READABLE, system.MOJO_DEADLINE_INDEFINITE); r != system.MOJO_RESULT_FAILED_PRECONDITION {
		t.Fatalf("hc should not be readable after hp closed:%v", r)
	}
	if r = hc.Close(); r != system.MOJO_RESULT_OK {
		t.Fatalf("Close on hc failed:%v", r)
	}
}

func TestSharedBuffer(t *testing.T) {
	var h0, h1 system.SharedBufferHandle
	var buf []byte
	var r system.MojoResult

	if r, h0 = core.CreateSharedBuffer(nil, 100); r != system.MOJO_RESULT_OK {
		t.Fatalf("CreateSharedBuffer failed:%v", r)
	}
	if !h0.IsValid() {
		t.Fatalf("CreateSharedBuffer returned an invalid handle h0:%v", h0)
	}
	if r, buf = h0.MapBuffer(0, 100, system.MOJO_MAP_BUFFER_FLAG_NONE); r != system.MOJO_RESULT_OK {
		t.Fatalf("MapBuffer failed to map buffer with h0:%v", r)
	}
	if len(buf) != 100 || cap(buf) != 100 {
		t.Fatalf("Buffer length(%d) and capacity(%d) should be %d", len(buf), cap(buf), 100)
	}
	buf[50] = 'x'
	if r, h1 = h0.DuplicateBufferHandle(nil); r != system.MOJO_RESULT_OK {
		t.Fatalf("DuplicateBufferHandle of h0 failed:%v", r)
	}
	if !h1.IsValid() {
		t.Fatalf("DuplicateBufferHandle returned an invalid handle h1:%v", h1)
	}
	if r = h0.Close(); r != system.MOJO_RESULT_OK {
		t.Fatalf("Close on h0 failed:%v", r)
	}
	buf[51] = 'y'
	if r = h1.UnmapBuffer(buf); r != system.MOJO_RESULT_OK {
		t.Fatalf("UnmapBuffer failed:%v", r)
	}
	if r, buf = h1.MapBuffer(50, 50, system.MOJO_MAP_BUFFER_FLAG_NONE); r != system.MOJO_RESULT_OK {
		t.Fatalf("MapBuffer failed to map buffer with h1:%v", r)
	}
	if len(buf) != 50 || cap(buf) != 50 {
		t.Fatalf("Buffer length(%d) and capacity(%d) should be %d", len(buf), cap(buf), 50)
	}
	if buf[0] != 'x' || buf[1] != 'y' {
		t.Fatalf("Failed to validate shared buffer. expected:x,y got:%s,%s", buf[0], buf[1])
	}
	if r = h1.UnmapBuffer(buf); r != system.MOJO_RESULT_OK {
		t.Fatalf("UnmapBuffer failed:%v", r)
	}
	if r = h1.Close(); r != system.MOJO_RESULT_OK {
		t.Fatalf("Close on h1 failed:%v", r)
	}
}
