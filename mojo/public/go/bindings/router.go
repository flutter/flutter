// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package bindings

import (
	"fmt"
	"sync"

	"mojo/public/go/system"
)

// MessageReadResult contains information returned after reading and parsing
// a message: a non-nil error of a valid message.
type MessageReadResult struct {
	Message *Message
	Error   error
}

// routeRequest is a request sent from Router to routerWorker.
type routeRequest struct {
	// The outgoing message with non-zero request id.
	message *Message
	// The channel to send respond for the message.
	responseChan chan<- MessageReadResult
}

// routerWorker sends messages that require a response and and routes responses
// to appropriate receivers. The work is done on a separate go routine.
type routerWorker struct {
	// The message pipe handle to send requests and receive responses.
	handle system.MessagePipeHandle
	// Map from request id to response channel.
	responders map[uint64]chan<- MessageReadResult
	// The channel of incoming requests that require responses.
	requestChan <-chan routeRequest
	// The channel that indicates that the worker should terminate.
	done <-chan struct{}
	// Implementation of async waiter.
	waiter   AsyncWaiter
	waitChan chan WaitResponse
	waitId   AsyncWaitId
}

// readOutstandingMessages reads and dispatches available messages in the
// message pipe until the messages is empty or there are no waiting responders.
// If the worker is currently waiting on the message pipe, returns immediately
// without an error.
func (w *routerWorker) readAndDispatchOutstandingMessages() error {
	if w.waitId != 0 {
		// Still waiting for a new message in the message pipe.
		return nil
	}
	for len(w.responders) > 0 {
		result, bytes, handles := w.handle.ReadMessage(system.MOJO_READ_MESSAGE_FLAG_NONE)
		if result == system.MOJO_RESULT_SHOULD_WAIT {
			w.waitId = w.waiter.AsyncWait(w.handle, system.MOJO_HANDLE_SIGNAL_READABLE, w.waitChan)
			return nil
		}
		if result != system.MOJO_RESULT_OK {
			return &ConnectionError{result}
		}
		message, err := ParseMessage(bytes, handles)
		if err != nil {
			return err
		}
		id := message.Header.RequestId
		w.responders[id] <- MessageReadResult{message, nil}
		delete(w.responders, id)
	}
	return nil
}

func (w *routerWorker) cancelIfWaiting() {
	if w.waitId != 0 {
		w.waiter.CancelWait(w.waitId)
		w.waitId = 0
	}
}

// runLoop is the main run loop of the worker. It processes incoming requests
// from Router and waits on a message pipe for new messages.
// Returns an error describing the cause of stopping.
func (w *routerWorker) runLoop() error {
	for {
		select {
		case waitResponse := <-w.waitChan:
			w.waitId = 0
			if waitResponse.Result != system.MOJO_RESULT_OK {
				return &ConnectionError{waitResponse.Result}
			}
		case request := <-w.requestChan:
			if err := WriteMessage(w.handle, request.message); err != nil {
				return err
			}
			if request.responseChan != nil {
				w.responders[request.message.Header.RequestId] = request.responseChan
			}
		case <-w.done:
			return errConnectionClosed
		}
		// Returns immediately without an error if still waiting for
		// a new message.
		if err := w.readAndDispatchOutstandingMessages(); err != nil {
			return err
		}
	}
}

// Router sends messages to a message pipe and routes responses back to senders
// of messages with non-zero request ids. The caller should issue unique request
// ids for each message given to the router.
type Router struct {
	// Mutex protecting requestChan from new requests in case the router is
	// closed and the handle.
	mu sync.Mutex
	// The message pipe handle to send requests and receive responses.
	handle system.MessagePipeHandle
	// Channel to communicate with worker.
	requestChan chan<- routeRequest

	// Makes sure that the done channel is closed once.
	closeOnce sync.Once
	// Channel to stop the worker.
	done chan<- struct{}
}

// NewRouter returns a new Router instance that sends and receives messages
// from a provided message pipe handle.
func NewRouter(handle system.MessagePipeHandle, waiter AsyncWaiter) *Router {
	requestChan := make(chan routeRequest, 10)
	doneChan := make(chan struct{})
	router := &Router{
		handle:      handle,
		requestChan: requestChan,
		done:        doneChan,
	}
	router.runWorker(&routerWorker{
		handle,
		make(map[uint64]chan<- MessageReadResult),
		requestChan,
		doneChan,
		waiter,
		make(chan WaitResponse, 1),
		0,
	})
	return router
}

// Close closes the router and the underlying message pipe. All new incoming
// requests are returned with an error.
func (r *Router) Close() {
	r.closeOnce.Do(func() {
		close(r.done)
	})
}

// Accept sends a message to the message pipe. The message should have a
// zero request id in header.
func (r *Router) Accept(message *Message) error {
	if message.Header.RequestId != 0 {
		return fmt.Errorf("message header should have a zero request ID")
	}
	r.mu.Lock()
	defer r.mu.Unlock()
	if !r.handle.IsValid() {
		return errConnectionClosed
	}
	r.requestChan <- routeRequest{message, nil}
	return nil
}

func (r *Router) runWorker(worker *routerWorker) {
	// Run worker on a separate go routine.
	go func() {
		// Get the reason why the worker stopped. The error means that
		// either the router is closed or there was an error reading
		// or writing to a message pipe. In both cases it will be
		// the reason why we can't process any more requests.
		err := worker.runLoop()
		worker.cancelIfWaiting()
		// Respond to all pending requests.
		for _, responseChan := range worker.responders {
			responseChan <- MessageReadResult{nil, err}
		}
		// Respond to incoming requests until we make sure that all
		// new requests return with an error before sending request
		// to responseChan.
		go func() {
			for responder := range worker.requestChan {
				responder.responseChan <- MessageReadResult{nil, err}
			}
		}()
		r.mu.Lock()
		r.handle.Close()
		// If we acquire the lock then no other go routine is waiting
		// to write to responseChan. All go routines that acquire the
		// lock after us will return before sending to responseChan as
		// the underlying handle is invalid (already closed).
		// We can safely close the requestChan.
		close(r.requestChan)
		r.mu.Unlock()
	}()
}

// AcceptWithResponse sends a message to the message pipe and returns a channel
// that will stream the result of reading corresponding response. The message
// should have a non-zero request id in header. It is responsibility of the
// caller to issue unique request ids for all given messages.
func (r *Router) AcceptWithResponse(message *Message) <-chan MessageReadResult {
	responseChan := make(chan MessageReadResult, 1)
	if message.Header.RequestId == 0 {
		responseChan <- MessageReadResult{nil, fmt.Errorf("message header should have a request ID")}
		return responseChan
	}
	r.mu.Lock()
	defer r.mu.Unlock()
	// Return an error before sending a request to requestChan if the router
	// is closed so that we can safely close responseChan once we close the
	// router.
	if !r.handle.IsValid() {
		responseChan <- MessageReadResult{nil, errConnectionClosed}
		return responseChan
	}
	r.requestChan <- routeRequest{message, responseChan}
	return responseChan
}
