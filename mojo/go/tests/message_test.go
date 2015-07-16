// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package tests

import (
	"testing"

	"mojo/public/go/bindings"
)

func checkMessageEncoding(t *testing.T, header, payload bindings.MessageHeader) {
	var encodedMessage, decodedMessage *bindings.Message
	var err error
	var decodedHeader, decodedPayload bindings.MessageHeader

	if encodedMessage, err = bindings.EncodeMessage(header, &payload); err != nil {
		t.Fatalf("Failed encoding message: %v", err)
	}

	if decodedMessage, err = bindings.ParseMessage(encodedMessage.Bytes, nil); err != nil {
		t.Fatalf("Failed decoding message header: %v", err)
	}
	if decodedHeader = decodedMessage.Header; decodedHeader != header {
		t.Fatalf("Unexpected header decoded: got %v, want %v", decodedHeader, header)
	}
	if err = decodedMessage.DecodePayload(&decodedPayload); err != nil {
		t.Fatalf("Failed decoding message payload: %v", err)
	}
	if decodedPayload != payload {
		t.Fatalf("Unexpected header with request id decoded: got %v, want %v", decodedPayload, payload)
	}
}

// TestMessageHeader tests that headers are identical after being
// encoded/decoded.
func TestMessageHeader(t *testing.T) {
	header := bindings.MessageHeader{2, 0, 0}
	headerWithId := bindings.MessageHeader{1, 2, 3}
	checkMessageEncoding(t, header, headerWithId)
	checkMessageEncoding(t, headerWithId, header)
	headerWithZeroId := bindings.MessageHeader{1, 2, 0}
	checkMessageEncoding(t, headerWithZeroId, header)
}
