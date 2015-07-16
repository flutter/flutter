// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package tests

import (
	"encoding/binary"
	"fmt"
	"math"
	"strings"

	"mojo/go/system/embedder"
	"mojo/public/go/bindings"
	"mojo/public/go/system"
)

var core system.Core
var waiter bindings.AsyncWaiter

func init() {
	embedder.InitializeMojoEmbedder()
	core = system.GetCore()
	waiter = bindings.GetAsyncWaiter()
}

type mockHandle struct {
	bindings.InvalidHandle
	handle system.MojoHandle
}

func (h *mockHandle) IsValid() bool {
	return true
}

func (h *mockHandle) ReleaseNativeHandle() system.MojoHandle {
	return h.handle
}

func (h *mockHandle) ToUntypedHandle() system.UntypedHandle {
	return h
}

func (h *mockHandle) ToConsumerHandle() system.ConsumerHandle {
	return h
}

func (h *mockHandle) ToProducerHandle() system.ProducerHandle {
	return h
}

func (h *mockHandle) ToMessagePipeHandle() system.MessagePipeHandle {
	return h
}

func (h *mockHandle) ToSharedBufferHandle() system.SharedBufferHandle {
	return h
}

// inputParser parses validation tests input format as described in
// |mojo/public/cpp/bindings/tests/validation_test_input_parser.h|
type inputParser struct {
}

type dataItem struct {
	Type  string
	Value string
}

type pointerPlaceholder struct {
	Position int
	Size     int
}

func (p *inputParser) parseToDataItems(s string) []dataItem {
	var items []dataItem
	s = strings.TrimSpace(s)
	for len(s) > 0 {
		// Parsing data item type.
		var itemType string
		if s[0] == '[' {
			closeBracket := strings.Index(s, "]")
			if closeBracket == -1 {
				panic("unmatched left [")
			}
			itemType = strings.TrimSpace(s[1:closeBracket])
			s = strings.TrimSpace(s[closeBracket+1:])
		} else {
			itemType = "u1"
		}

		// Parsing data item value.
		itemEnd := strings.IndexAny(s, "[ \t\n\r")
		if itemEnd == -1 {
			items = append(items, dataItem{itemType, strings.TrimSpace(s)})
			s = ""
		} else {
			items = append(items, dataItem{itemType, strings.TrimSpace(s[:itemEnd])})
			s = strings.TrimSpace(s[itemEnd:])
		}
	}
	return items
}

// Parse parses a validation tests input string that has no comments.
// Panics if input has errors.
func (p *inputParser) Parse(s string) ([]byte, []system.UntypedHandle) {
	var bytes []byte
	var buf [8]byte
	// We need non-nil slice for comparing values with reflect.DeepEqual.
	handles := []system.UntypedHandle{}
	pointers := make(map[string]pointerPlaceholder)
	for _, item := range p.parseToDataItems(s) {
		switch item.Type {
		case "u1":
			var value uint8
			fmt.Sscan(item.Value, &value)
			bytes = append(bytes, byte(value))
		case "u2":
			var value uint16
			fmt.Sscan(item.Value, &value)
			binary.LittleEndian.PutUint16(buf[:2], value)
			bytes = append(bytes, buf[:2]...)
		case "u4":
			var value uint32
			fmt.Sscan(item.Value, &value)
			binary.LittleEndian.PutUint32(buf[:4], value)
			bytes = append(bytes, buf[:4]...)
		case "u8":
			var value uint64
			fmt.Sscan(item.Value, &value)
			binary.LittleEndian.PutUint64(buf[:8], value)
			bytes = append(bytes, buf[:8]...)
		case "s1":
			var value int8
			fmt.Sscan(item.Value, &value)
			bytes = append(bytes, byte(value))
		case "s2":
			var value int16
			fmt.Sscan(item.Value, &value)
			binary.LittleEndian.PutUint16(buf[:2], uint16(value))
			bytes = append(bytes, buf[:2]...)
		case "s4":
			var value int32
			fmt.Sscan(item.Value, &value)
			binary.LittleEndian.PutUint32(buf[:4], uint32(value))
			bytes = append(bytes, buf[:4]...)
		case "s8":
			var value int64
			fmt.Sscan(item.Value, &value)
			binary.LittleEndian.PutUint64(buf[:8], uint64(value))
			bytes = append(bytes, buf[:8]...)
		case "b":
			var value byte
			for i := 0; i < 8; i++ {
				value <<= 1
				if item.Value[i] == '1' {
					value++
				}
			}
			bytes = append(bytes, value)
		case "f":
			var value float32
			fmt.Sscan(item.Value, &value)
			binary.LittleEndian.PutUint32(buf[:4], math.Float32bits(value))
			bytes = append(bytes, buf[:4]...)
		case "d":
			var value float64
			fmt.Sscan(item.Value, &value)
			binary.LittleEndian.PutUint64(buf[:8], math.Float64bits(value))
			bytes = append(bytes, buf[:8]...)
		case "dist4":
			pointers[item.Value] = pointerPlaceholder{len(bytes), 4}
			bytes = append(bytes, buf[:4]...)
		case "dist8":
			pointers[item.Value] = pointerPlaceholder{len(bytes), 8}
			bytes = append(bytes, buf[:8]...)
		case "anchr":
			placeholder := pointers[item.Value]
			dist := len(bytes) - placeholder.Position
			switch placeholder.Size {
			case 4:
				binary.LittleEndian.PutUint32(bytes[placeholder.Position:], uint32(dist))
			case 8:
				binary.LittleEndian.PutUint64(bytes[placeholder.Position:], uint64(dist))
			}
			delete(pointers, item.Value)
		case "handles":
			var value int
			fmt.Sscan(item.Value, &value)
			handles = make([]system.UntypedHandle, value)
			for i, _ := range handles {
				handles[i] = &mockHandle{handle: system.MojoHandle(i + 1)}
			}
		default:
			panic(fmt.Sprintf("unsupported item type: %v", item.Type))
		}
	}
	if len(pointers) != 0 {
		panic(fmt.Sprintf("unmatched pointers: %v", pointers))
	}
	return bytes, handles
}
