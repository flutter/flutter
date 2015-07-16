// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package tests

import (
	"reflect"
	"testing"

	"mojo/public/go/bindings"
	"mojo/public/go/system"
	"mojo/public/interfaces/bindings/tests/rect"
	test "mojo/public/interfaces/bindings/tests/serialization_test_structs"
	"mojo/public/interfaces/bindings/tests/test_structs"
)

func check(t *testing.T, value, zeroValue bindings.Payload) {
	message, err := bindings.EncodeMessage(bindings.MessageHeader{}, value)
	if err != nil {
		t.Fatalf("error encoding value %v: %v", value, err)
	}
	decodedMessage, err := bindings.ParseMessage(message.Bytes, message.Handles)
	if err != nil {
		t.Fatalf("error decoding message header from bytes %v for tested value %v: %v", message.Bytes, value, err)
	}
	if err = decodedMessage.DecodePayload(zeroValue); err != nil {
		t.Fatalf("error decoding message payload from bytes %v for tested value %v: %v", message.Payload, value, err)
	}
	if !reflect.DeepEqual(value, zeroValue) {
		t.Fatalf("unexpected value after decoding: expected %v, got %v", value, zeroValue)
	}
}

func TestSerializationTestStructs(t *testing.T) {
	check(t, &test.Struct1{1}, &test.Struct1{})
	check(t, &test.Struct2{&mockHandle{handle: 1}}, &test.Struct2{})
	check(t, &test.Struct3{test.Struct1{2}}, &test.Struct3{})
	check(t, &test.Struct4{[]test.Struct1{test.Struct1{1}, test.Struct1{2}}}, &test.Struct4{})
	check(t, &test.Struct5{[2]test.Struct1{test.Struct1{1}, test.Struct1{2}}}, &test.Struct5{})
	check(t, &test.Struct6{"hello, world!"}, &test.Struct6{})

	check(t, &test.StructOfNullables{nil, nil, nil}, &test.StructOfNullables{})
	handle := system.Handle(&mockHandle{handle: 1})
	s := "hello, world"
	check(t, &test.StructOfNullables{&handle, nil, nil}, &test.StructOfNullables{})
	check(t, &test.StructOfNullables{&handle, &test.Struct1{3}, nil}, &test.StructOfNullables{})
	check(t, &test.StructOfNullables{&handle, &test.Struct1{3}, &s}, &test.StructOfNullables{})
	check(t, &test.StructOfNullables{&handle, nil, &s}, &test.StructOfNullables{})
}

func TestStructs(t *testing.T) {
	s1 := "hello, world!"
	s2 := "world, hello!"
	handle := system.Handle(&mockHandle{handle: 1})
	messagePipeHandle := system.MessagePipeHandle(&mockHandle{handle: 2})
	consumerHandle := system.ConsumerHandle(&mockHandle{handle: 3})
	producerHandle := system.ProducerHandle(&mockHandle{handle: 4})
	sharedBufferHandle := system.SharedBufferHandle(&mockHandle{handle: 5})
	value := bindings.Payload(&test_structs.NoDefaultFieldValues{
		F0:  true,                        // bool
		F1:  -2,                          // int8
		F2:  3,                           // uint8
		F3:  -4000,                       // int16
		F4:  5000,                        // uint16
		F5:  -6000000,                    // int32
		F6:  7000000,                     // uint32
		F7:  -8000000000000,              // int64
		F8:  9000000000000,               // uint64
		F9:  1e-45,                       // float
		F10: -1e45,                       // double
		F11: s1,                          // string
		F12: &s2,                         // string?
		F13: messagePipeHandle,           // handle<message_pipe>
		F14: consumerHandle,              // handle<data_pipe_consumer>
		F15: producerHandle,              // handle<data_pipe_producer>
		F16: &messagePipeHandle,          // handle<message_pipe>?
		F17: &consumerHandle,             // handle<data_pipe_consumer>?
		F18: &producerHandle,             // handle<data_pipe_producer>?
		F19: handle,                      // handle
		F20: &handle,                     // handle?
		F21: sharedBufferHandle,          // handle<shared_buffer>
		F22: &sharedBufferHandle,         // handle<shared_buffer>?
		F23: []string{s1, s2},            // array<string>
		F24: []*string{&s1, &s2},         // array<string?>
		F25: &[]string{s1, s2},           // array<string>?
		F26: &[]*string{&s1, &s2},        // array<string?>?
		F27: test_structs.EmptyStruct{},  // EmptyStruct
		F28: &test_structs.EmptyStruct{}, // EmptyStruct?
	})
	check(t, value, &test_structs.NoDefaultFieldValues{})

	value = &test_structs.ScopedConstants{
		test_structs.ScopedConstants_EType_E0,
		test_structs.ScopedConstants_EType_E1,
		test_structs.ScopedConstants_EType_E2,
		test_structs.ScopedConstants_EType_E3,
		test_structs.ScopedConstants_EType_E4,
		10,
		25,
	}
	check(t, value, &test_structs.ScopedConstants{})

	value = &test_structs.MapKeyTypes{
		F0:  map[bool]bool{false: true, true: false},
		F1:  map[int8]int8{15: -45, -42: 50},
		F2:  map[uint8]uint8{15: 45, 42: 50},
		F3:  map[int16]int16{-15: 45, -42: 50},
		F4:  map[uint16]uint16{15: 45, 42: 50},
		F5:  map[int32]int32{15: -45, 42: 50},
		F6:  map[uint32]uint32{15: 45, 42: 50},
		F7:  map[int64]int64{15: 45, 42: -50},
		F8:  map[uint64]uint64{15: 45, 42: 50},
		F9:  map[float32]float32{1.5: 2.5, 3.5: 1e-9},
		F10: map[float64]float64{1.5: 2.5, 3.5: 1e-9},
		F11: map[string]string{s1: s2, s2: s1},
	}
	check(t, value, &test_structs.MapKeyTypes{})

	value = &test_structs.MapValueTypes{
		F0: map[string][]string{
			s1: []string{s1, s2},
			s2: []string{s2, s1},
		},
		F1: map[string]*[]string{
			s1: &[]string{s1, s2},
			s2: &[]string{s2, s1},
		},
		F2: map[string][]*string{
			s1: []*string{&s1, &s2},
			s2: []*string{&s2, &s1},
		},
		F3: map[string][2]string{
			s1: [2]string{s1, s2},
			s2: [2]string{s2, s1},
		},
		F4: map[string][]*[2]string{
			s1: []*[2]string{&[2]string{s1, s2}},
			s2: []*[2]string{&[2]string{s1, s2}},
		},
		F5: map[string][1][2]string{
			s1: [1][2]string{[2]string{s1, s2}},
			s2: [1][2]string{[2]string{s1, s2}},
		},
		F6: map[string]*rect.Rect{
			s1: &rect.Rect{},
			s2: &rect.Rect{3, 4, 5, 6},
		},
		F7: map[string]map[string]string{
			s1: map[string]string{s1: s1, s2: s2},
			s2: map[string]string{s1: s2, s2: s1},
		},
		F8: map[string][]map[string]string{
			s1: []map[string]string{
				map[string]string{s1: s1, s2: s2},
				map[string]string{s1: s2, s2: s1},
			},
			s2: []map[string]string{
				map[string]string{s1: s1, s2: s2},
				map[string]string{s1: s2, s2: s1},
			},
		},
		F9: map[string]system.Handle{
			s1: handle,
			s2: handle,
		},
		F10: map[string][]system.Handle{
			s1: []system.Handle{handle},
			s2: []system.Handle{},
		},
		F11: map[string]map[string]system.Handle{
			s1: map[string]system.Handle{s1: handle},
			s2: map[string]system.Handle{s2: handle},
		},
  }
	check(t, value, &test_structs.MapValueTypes{})

	value = &test_structs.BitArrayValues{
		F0: [1]bool{true},
		F1: [7]bool{true, false, true, false, true, false, true},
		F2: [9]bool{true, true, true, false, false, false, true, true, true},
		F3: []bool{true, false, true, false},
		F4: [][]bool{[]bool{true}},
		F5: []*[]bool{
			&[]bool{true, false, true},
			&[]bool{false, true},
		},
		F6: []*[2]bool{
			&[2]bool{false, false},
			&[2]bool{false, true},
			&[2]bool{true, false},
			&[2]bool{true, true},
		},
	}
	check(t, value, &test_structs.BitArrayValues{})
}
