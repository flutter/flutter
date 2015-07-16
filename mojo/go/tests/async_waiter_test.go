// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package tests

import (
	"fmt"
	"sync"
	"testing"

	"mojo/public/go/bindings"
	"mojo/public/go/system"
)

func checkWait(handle system.Handle, signals system.MojoHandleSignals, expected system.MojoResult, wg *sync.WaitGroup) {
	wg.Add(1)
	responseChan := make(chan bindings.WaitResponse)
	bindings.GetAsyncWaiter().AsyncWait(handle, signals, responseChan)
	go func() {
		response := <-responseChan
		if expected != response.Result {
			panic(fmt.Sprintf("unexpected wait result: expected %v, got %v", expected, response.Result))
		}
		wg.Done()
	}()
}

func checkCancel(handle system.Handle, wg *sync.WaitGroup) {
	wg.Add(1)
	responseChan := make(chan bindings.WaitResponse)
	id := waiter.AsyncWait(handle, system.MOJO_HANDLE_SIGNAL_READABLE, responseChan)
	go func() {
		waiter.CancelWait(id)
		response := <-responseChan
		if expected := system.MOJO_RESULT_ABORTED; expected != response.Result {
			panic(fmt.Sprintf("unexpected wait result: expected %v, got %v", expected, response.Result))
		}
		wg.Done()
	}()
}

func TestAsyncWait(t *testing.T) {
	r, h0, h1 := core.CreateMessagePipe(nil)
	defer h0.Close()
	defer h1.Close()
	if r != system.MOJO_RESULT_OK {
		t.Fatalf("error creating a message pipe %v", r)
	}
	var wg sync.WaitGroup
	h0.WriteMessage([]byte{0}, nil, system.MOJO_WRITE_MESSAGE_FLAG_NONE)
	checkWait(h0, system.MOJO_HANDLE_SIGNAL_WRITABLE, system.MOJO_RESULT_OK, &wg)
	checkWait(h1, system.MOJO_HANDLE_SIGNAL_READABLE, system.MOJO_RESULT_OK, &wg)

	if r, h0, h1 = core.CreateMessagePipe(nil); r != system.MOJO_RESULT_OK {
		t.Fatalf("error creating a message pipe %v", r)
	}
	defer h1.Close()
	h0.Close()
	checkWait(h0, system.MOJO_HANDLE_SIGNAL_PEER_CLOSED, system.MOJO_RESULT_INVALID_ARGUMENT, &wg)
	checkWait(h1, system.MOJO_HANDLE_SIGNAL_PEER_CLOSED, system.MOJO_RESULT_OK, &wg)

	if r, h0, h1 = core.CreateMessagePipe(nil); r != system.MOJO_RESULT_OK {
		t.Fatalf("error creating a message pipe %v", r)
	}
	defer h1.Close()
	h0.Close()
	checkWait(h0, system.MOJO_HANDLE_SIGNAL_PEER_CLOSED, system.MOJO_RESULT_INVALID_ARGUMENT, &wg)
	checkWait(h1, system.MOJO_HANDLE_SIGNAL_READABLE, system.MOJO_RESULT_FAILED_PRECONDITION, &wg)
	wg.Wait()
}

func TestAsyncWaitCancel(t *testing.T) {
	r, h0, h1 := core.CreateMessagePipe(nil)
	defer h0.Close()
	defer h1.Close()
	if r != system.MOJO_RESULT_OK {
		t.Fatalf("error creating a message pipe %v", r)
	}
	var wg sync.WaitGroup
	checkCancel(h0, &wg)
	checkCancel(h1, &wg)

	if r, h0, h1 = core.CreateMessagePipe(nil); r != system.MOJO_RESULT_OK {
		t.Fatalf("error creating a message pipe %v", r)
	}
	defer h0.Close()
	defer h1.Close()
	checkCancel(h0, &wg)
	checkCancel(h1, &wg)
	wg.Wait()
}
