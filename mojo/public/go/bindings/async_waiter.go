// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package bindings

import (
	"fmt"
	"runtime"
	"sync"
	"sync/atomic"

	"mojo/public/go/system"
)

var defaultWaiter *asyncWaiterImpl
var once sync.Once

// GetAsyncWaiter returns a default implementation of |AsyncWaiter| interface.
func GetAsyncWaiter() AsyncWaiter {
	once.Do(func() {
		defaultWaiter = newAsyncWaiter()
	})
	return defaultWaiter
}

// AsyncWaitId is an id returned by |AsyncWait()| used to cancel it.
type AsyncWaitId uint64

// WaitResponse is a struct sent to a channel waiting for |AsyncWait()| to
// finish. It contains the same information as if |Wait()| was called on a
// handle.
type WaitResponse struct {
	Result system.MojoResult
	State  system.MojoHandleSignalsState
}

// AsyncWaiter defines an interface for asynchronously waiting (and cancelling
// asynchronous waits) on a handle.
type AsyncWaiter interface {
	// AsyncWait asynchronously waits on a given handle until a signal
	// indicated by |signals| is satisfied or it becomes known that no
	// signal indicated by |signals| will ever be satisified. The wait
	// response will be sent to |responseChan|.
	//
	// |handle| must not be closed or transferred until the wait response
	// is received from |responseChan|.
	AsyncWait(handle system.Handle, signals system.MojoHandleSignals, responseChan chan<- WaitResponse) AsyncWaitId

	// CancelWait cancels an outstanding async wait (specified by |id|)
	// initiated by |AsyncWait()|. A response with Mojo result
	// |MOJO_RESULT_ABORTED| is sent to the corresponding |responseChan|.
	CancelWait(id AsyncWaitId)
}

// waitRequest is a struct sent to asyncWaiterWorker to add another handle to
// the list of waiting handles.
type waitRequest struct {
	handle  system.Handle
	signals system.MojoHandleSignals

	// Used for |CancelWait()| calls. The worker should issue IDs so that
	// you can't cancel the wait until the worker received the wait request.
	idChan chan<- AsyncWaitId

	// A channel end to send wait results.
	responseChan chan<- WaitResponse
}

// asyncWaiterWorker does the actual work, in its own goroutine. It calls
// |WaitMany()| on all provided handles. New handles a added via |waitChan|
// and removed via |cancelChan| messages. To wake the worker asyncWaiterImpl
// sends mojo messages to a dedicated message pipe, the other end of which has
// index 0 in all slices of the worker.
type asyncWaiterWorker struct {
	// |handles| and |signals| are used to make |WaitMany()| calls directly.
	// All these arrays should be operated simultaneously; i-th element
	// of each refers to i-th handle.
	handles      []system.Handle
	signals      []system.MojoHandleSignals
	asyncWaitIds []AsyncWaitId
	responses    []chan<- WaitResponse

	// Flag shared between waiterImpl and worker that is 1 iff the worker is
	// already notified by waiterImpl. The worker sets it to 0 as soon as
	// |WaitMany()| succeeds.
	isNotified *int32
	waitChan   <-chan waitRequest // should have a non-empty buffer
	cancelChan <-chan AsyncWaitId // should have a non-empty buffer
	ids        uint64             // is incremented each |AsyncWait()| call
}

// removeHandle removes handle at provided index without sending response by
// swapping all information associated with index-th handle with the last one
// and removing the last one.
func (w *asyncWaiterWorker) removeHandle(index int) {
	l := len(w.handles) - 1
	// Swap with the last and remove last.
	w.handles[index] = w.handles[l]
	w.handles = w.handles[0:l]
	w.signals[index] = w.signals[l]
	w.signals = w.signals[0:l]

	w.asyncWaitIds[index] = w.asyncWaitIds[l]
	w.asyncWaitIds = w.asyncWaitIds[0:l]
	w.responses[index] = w.responses[l]
	w.responses = w.responses[0:l]
}

// sendWaitResponseAndRemove send response to corresponding channel and removes
// index-th waiting handle.
func (w *asyncWaiterWorker) sendWaitResponseAndRemove(index int, result system.MojoResult, state system.MojoHandleSignalsState) {
	w.responses[index] <- WaitResponse{
		result,
		state,
	}
	w.removeHandle(index)
}

// respondToSatisfiedWaits responds to all wait requests that have at least
// one satisfied signal and removes them.
func (w *asyncWaiterWorker) respondToSatisfiedWaits(states []system.MojoHandleSignalsState) {
	// Don't touch handle at index 0 as it is the waking handle.
	for i := 1; i < len(states); {
		if (states[i].SatisfiedSignals & w.signals[i]) != 0 {
			// Respond and swap i-th with last and remove last.
			w.sendWaitResponseAndRemove(i, system.MOJO_RESULT_OK, states[i])
			// Swap i-th with last and remove last.
			states[i] = states[len(states)-1]
			states = states[:len(states)-1]
		} else {
			i++
		}
	}
}

// processIncomingRequests processes all queued async wait or cancel requests
// sent by asyncWaiterImpl.
func (w *asyncWaiterWorker) processIncomingRequests() {
	for {
		select {
		case request := <-w.waitChan:
			w.handles = append(w.handles, request.handle)
			w.signals = append(w.signals, request.signals)
			w.responses = append(w.responses, request.responseChan)

			w.ids++
			id := AsyncWaitId(w.ids)
			w.asyncWaitIds = append(w.asyncWaitIds, id)
			request.idChan <- id
		case AsyncWaitId := <-w.cancelChan:
			// Zero index is reserved for the waking message pipe handle.
			index := 0
			for i := 1; i < len(w.asyncWaitIds); i++ {
				if w.asyncWaitIds[i] == AsyncWaitId {
					index = i
					break
				}
			}
			// Do nothing if the id was not found as wait response may be
			// already sent if the async wait was successful.
			if index > 0 {
				w.sendWaitResponseAndRemove(index, system.MOJO_RESULT_ABORTED, system.MojoHandleSignalsState{})
			}
		default:
			return
		}
	}
}

// runLoop run loop of the asyncWaiterWorker. Blocks on |WaitMany()|. If the
// wait is interrupted by waking handle (index 0) then it means that the worker
// was woken by waiterImpl, so the worker processes incoming requests from
// waiterImpl; otherwise responses to corresponding wait request.
func (w *asyncWaiterWorker) runLoop() {
	for {
		result, index, states := system.GetCore().WaitMany(w.handles, w.signals, system.MOJO_DEADLINE_INDEFINITE)
		// Set flag to 0, so that the next incoming request to
		// waiterImpl would explicitly wake worker by sending a message
		// to waking message pipe.
		atomic.StoreInt32(w.isNotified, 0)
		if index == -1 {
			panic(fmt.Sprintf("error waiting on handles: %v", result))
			break
		}
		// Zero index means that the worker was signaled by asyncWaiterImpl.
		if index == 0 {
			if result != system.MOJO_RESULT_OK {
				panic(fmt.Sprintf("error waiting on waking handle: %v", result))
			}
			w.handles[0].(system.MessagePipeHandle).ReadMessage(system.MOJO_READ_MESSAGE_FLAG_NONE)
			w.processIncomingRequests()
		} else if result != system.MOJO_RESULT_OK {
			w.sendWaitResponseAndRemove(index, result, system.MojoHandleSignalsState{})
		} else {
			w.respondToSatisfiedWaits(states)
		}
	}
}

// asyncWaiterImpl is an implementation of |AsyncWaiter| interface.
// Runs a worker in a separate goroutine and comunicates with it by sending a
// message to |wakingHandle| to wake worker from |WaitMany()| call and
// sending request via |waitChan| and |cancelChan|.
type asyncWaiterImpl struct {
	wakingHandle system.MessagePipeHandle

	// Flag shared between waiterImpl and worker that is 1 iff the worker is
	// already notified by waiterImpl. The worker sets it to 0 as soon as
	// |WaitMany()| succeeds.
	isWorkerNotified *int32
	waitChan         chan<- waitRequest // should have a non-empty buffer
	cancelChan       chan<- AsyncWaitId // should have a non-empty buffer
}

func finalizeWorker(worker *asyncWaiterWorker) {
	// Close waking handle on worker side.
	worker.handles[0].Close()
}

func finalizeAsyncWaiter(waiter *asyncWaiterImpl) {
	waiter.wakingHandle.Close()
}

// newAsyncWaiter creates an asyncWaiterImpl and starts its worker goroutine.
func newAsyncWaiter() *asyncWaiterImpl {
	result, h0, h1 := system.GetCore().CreateMessagePipe(nil)
	if result != system.MOJO_RESULT_OK {
		panic(fmt.Sprintf("can't create message pipe %v", result))
	}
	waitChan := make(chan waitRequest, 10)
	cancelChan := make(chan AsyncWaitId, 10)
	isNotified := new(int32)
	worker := &asyncWaiterWorker{
		[]system.Handle{h1},
		[]system.MojoHandleSignals{system.MOJO_HANDLE_SIGNAL_READABLE},
		[]AsyncWaitId{0},
		[]chan<- WaitResponse{make(chan WaitResponse)},
		isNotified,
		waitChan,
		cancelChan,
		0,
	}
	runtime.SetFinalizer(worker, finalizeWorker)
	go worker.runLoop()
	waiter := &asyncWaiterImpl{
		wakingHandle:     h0,
		isWorkerNotified: isNotified,
		waitChan:         waitChan,
		cancelChan:       cancelChan,
	}
	runtime.SetFinalizer(waiter, finalizeAsyncWaiter)
	return waiter
}

// wakeWorker wakes the worker from |WaitMany()| call. This should be called
// after sending a message to |waitChan| or |cancelChan| to avoid deadlock.
func (w *asyncWaiterImpl) wakeWorker() {
	if atomic.CompareAndSwapInt32(w.isWorkerNotified, 0, 1) {
		result := w.wakingHandle.WriteMessage([]byte{0}, nil, system.MOJO_WRITE_MESSAGE_FLAG_NONE)
		if result != system.MOJO_RESULT_OK {
			panic("can't write to a message pipe")
		}
	}
}

func (w *asyncWaiterImpl) AsyncWait(handle system.Handle, signals system.MojoHandleSignals, responseChan chan<- WaitResponse) AsyncWaitId {
	idChan := make(chan AsyncWaitId, 1)
	w.waitChan <- waitRequest{
		handle,
		signals,
		idChan,
		responseChan,
	}
	w.wakeWorker()
	return <-idChan
}

func (w *asyncWaiterImpl) CancelWait(id AsyncWaitId) {
	w.cancelChan <- id
	w.wakeWorker()
}
