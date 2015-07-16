// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package tests

import (
	"testing"

	"mojo/public/go/bindings"
)

func TestPassMessagePipe(t *testing.T) {
	r, p := bindings.CreateMessagePipeForMojoInterface()
	r1, p1 := r, p
	handle := r1.PassMessagePipe()
	defer handle.Close()
	p1.Close()
	rhandle, phandle := r.PassMessagePipe(), p.PassMessagePipe()
	if rhandle.IsValid() || phandle.IsValid() {
		t.Fatal("message pipes should be invalid after PassMessagePipe() or Close()")
	}
	rhandle.Close()
	phandle.Close()
}
