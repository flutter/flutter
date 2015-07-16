// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package tests

import (
	"regexp"
	"sync"
	"testing"

	"mojo/public/go/bindings"
	"mojo/public/go/system"
)

func expectError(t *testing.T, expected string, err error) {
	if err == nil {
		t.Fatalf("unexpected nil error, expected %v", expected)
	}
	if ok, _ := regexp.MatchString(expected, err.Error()); !ok {
		t.Fatalf("unexpected error: expected %v, got %v", expected, err.Error())
	}
}

func encodeMessage(header bindings.MessageHeader, payload bindings.Payload) *bindings.Message {
	message, err := bindings.EncodeMessage(header, payload)
	if err != nil {
		panic(err)
	}
	return message
}

func TestAccept(t *testing.T) {
	r, h0, h1 := core.CreateMessagePipe(nil)
	defer h1.Close()
	if r != system.MOJO_RESULT_OK {
		t.Fatalf("can't create a message pipe: %v", r)
	}
	router := bindings.NewRouter(h0, bindings.GetAsyncWaiter())
	header := bindings.MessageHeader{0, 0, 0}
	if err := router.Accept(encodeMessage(header, &header)); err != nil {
		t.Fatal(err)
	}
	header = bindings.MessageHeader{0, bindings.MessageExpectsResponseFlag, 1}
	err := router.Accept(encodeMessage(header, &header))
	expectError(t, "message header should have a zero request ID", err)
	router.Close()
}

func TestAcceptWithResponse(t *testing.T) {
	r, h0, h1 := core.CreateMessagePipe(nil)
	defer h1.Close()
	if r != system.MOJO_RESULT_OK {
		t.Fatalf("can't create a message pipe: %v", r)
	}
	router := bindings.NewRouter(h0, bindings.GetAsyncWaiter())
	header := bindings.MessageHeader{0, bindings.MessageIsResponseFlag, 1}
	bindings.WriteMessage(h1, encodeMessage(header, &header))
	header = bindings.MessageHeader{0, bindings.MessageExpectsResponseFlag, 1}
	if result := <-router.AcceptWithResponse(encodeMessage(header, &header)); result.Error != nil {
		t.Fatal(result.Error)
	}
	header = bindings.MessageHeader{0, 0, 0}
	err := (<-router.AcceptWithResponse(encodeMessage(header, &header))).Error
	expectError(t, "message header should have a request ID", err)
	router.Close()
}

const numberOfRequests = 50

func TestAcceptWithResponseMultiple(t *testing.T) {
	r, h0, h1 := core.CreateMessagePipe(nil)
	defer h1.Close()
	if r != system.MOJO_RESULT_OK {
		t.Fatalf("can't create a message pipe: %v", r)
	}
	router := bindings.NewRouter(h0, bindings.GetAsyncWaiter())
	var wg sync.WaitGroup
	wg.Add(numberOfRequests + 1)
	// Serve requests.
	go func() {
		for i := 0; i < numberOfRequests; i++ {
			c := make(chan bindings.WaitResponse, 1)
			bindings.GetAsyncWaiter().AsyncWait(h1, system.MOJO_HANDLE_SIGNAL_READABLE, c)
			r, bytes, handles := h1.ReadMessage(system.MOJO_READ_MESSAGE_FLAG_NONE)
			if r != system.MOJO_RESULT_OK {
				t.Fatalf("can't read from a message pipe: %v", r)
			}
			r = h1.WriteMessage(bytes, handles, system.MOJO_WRITE_MESSAGE_FLAG_NONE)
			if r != system.MOJO_RESULT_OK {
				t.Fatalf("can't write to a message pipe: %v", r)
			}
		}
		wg.Done()
	}()
	// Send concurrent requests.
	for i := 0; i < numberOfRequests; i++ {
		go func(i int) {
			header := bindings.MessageHeader{0, bindings.MessageExpectsResponseFlag, uint64(i + 1)}
			err := (<-router.AcceptWithResponse(encodeMessage(header, &header))).Error
			if err != nil {
				panic(err)
			}
			wg.Done()
		}(i)
	}
	wg.Wait()
	router.Close()
}

func TestClose(t *testing.T) {
	r, h0, h1 := core.CreateMessagePipe(nil)
	defer h1.Close()
	if r != system.MOJO_RESULT_OK {
		t.Fatalf("can't create a message pipe: %v", r)
	}
	router := bindings.NewRouter(h0, bindings.GetAsyncWaiter())
	var wg sync.WaitGroup
	wg.Add(numberOfRequests*2 + 1)

	// Send requests from the same go routine.
	for i := 0; i < numberOfRequests; i++ {
		header := bindings.MessageHeader{0, bindings.MessageExpectsResponseFlag, uint64(i + 1)}
		c := router.AcceptWithResponse(encodeMessage(header, &header))
		go func() {
			if err := (<-c).Error; err == nil {
				panic("unexpected nil error")
			}
			wg.Done()
		}()
	}
	// Send requests from different go routines.
	for i := 0; i < numberOfRequests; i++ {
		go func(i int) {
			header := bindings.MessageHeader{0, bindings.MessageExpectsResponseFlag, uint64(i + 1)}
			err := (<-router.AcceptWithResponse(encodeMessage(header, &header))).Error
			if err == nil {
				panic("unexpected nil error")
			}
			wg.Done()
		}(i + numberOfRequests)
	}
	go func() {
		router.Close()
		wg.Done()
	}()
	wg.Wait()
}
