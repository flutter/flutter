// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package tests

import (
	"bytes"
	"encoding/binary"
	"math"
	"testing"
)

func verifyInputParser(t *testing.T, s string, expected []byte, handlesCount int) {
	parser := &inputParser{}
	b, h := parser.Parse(s)
	if !bytes.Equal(b, expected) {
		t.Fatalf("unexpected byte slice after parsing %v: expected %v, got %v", s, expected, b)
	}
	if len(h) != handlesCount {
		t.Fatalf("unexpected handles count after parsing %v: expected %v, got %v", s, handlesCount, len(h))
	}
}

func TestInputParser(t *testing.T) {
	var buf []byte
	buf = make([]byte, 1+2+4+8+1+1)
	buf[0] = 0x10
	binary.LittleEndian.PutUint16(buf[1:], 65535)
	binary.LittleEndian.PutUint32(buf[3:], 65536)
	binary.LittleEndian.PutUint64(buf[7:], 0xFFFFFFFFFFFFFFFF)
	buf[15] = 0
	buf[16] = 0xFF
	verifyInputParser(t, "[u1]0x10 [u2]65535 [u4]65536 [u8]0xFFFFFFFFFFFFFFFF 0 0Xff", buf, 0)

	buf = make([]byte, 8+1+2+4)
	binary.LittleEndian.PutUint64(buf[0:], math.MaxUint64-0x800+1)
	buf[8] = math.MaxUint8 - 128 + 1
	binary.LittleEndian.PutUint16(buf[9:], 0)
	binary.LittleEndian.PutUint32(buf[11:], math.MaxUint32-40+1)
	verifyInputParser(t, "[s8]-0x800 [s1]-128\t[s2]+0 [s4]-40", buf, 0)

	buf = make([]byte, 1+1+1)
	buf[0] = 11
	buf[1] = 0x80
	buf[2] = 0
	verifyInputParser(t, "[b]00001011 [b]10000000  \r [b]00000000", buf, 0)

	buf = make([]byte, 4+8)
	binary.LittleEndian.PutUint32(buf[0:], math.Float32bits(+.3e9))
	binary.LittleEndian.PutUint64(buf[4:], math.Float64bits(-10.03))
	verifyInputParser(t, "[f]+.3e9 [d]-10.03", buf, 0)

	buf = make([]byte, 4+1+8+1)
	binary.LittleEndian.PutUint32(buf[0:], 14)
	buf[4] = 0
	binary.LittleEndian.PutUint64(buf[5:], 9)
	buf[13] = 0
	verifyInputParser(t, "[dist4]foo 0 [dist8]bar 0 [anchr]foo [anchr]bar", buf, 0)

	buf = make([]byte, 8)
	binary.LittleEndian.PutUint64(buf[0:], 2)
	verifyInputParser(t, "[handles]50 [u8]2", buf, 50)
}
