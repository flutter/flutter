// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package tests

import (
	"testing"

	"mojo/public/go/bindings"
	"mojo/public/go/system"
	"mojo/public/interfaces/bindings/tests/test_unions"
)

type Encodable interface {
	Encode(encoder *bindings.Encoder) error
}

func TestPodUnion(t *testing.T) {
	tests := []test_unions.PodUnion{
		&test_unions.PodUnionFInt8{8},
		&test_unions.PodUnionFInt16{16},
		&test_unions.PodUnionFUint64{64},
		&test_unions.PodUnionFBool{true},
		&test_unions.PodUnionFEnum{test_unions.AnEnum_Second},
	}

	for _, union := range tests {
		var wrapper, zeroWrapper test_unions.WrapperStruct
		wrapper.PodUnion = union
		check(t, &wrapper, &zeroWrapper)
	}
}

func TestHandleUnion(t *testing.T) {
	tests := []test_unions.HandleUnion{
		&test_unions.HandleUnionFHandle{system.Handle(&mockHandle{handle: 1})},
		&test_unions.HandleUnionFMessagePipe{system.MessagePipeHandle(&mockHandle{handle: 2})},
		&test_unions.HandleUnionFDataPipeConsumer{system.ConsumerHandle(&mockHandle{handle: 3})},
		&test_unions.HandleUnionFDataPipeProducer{system.ProducerHandle(&mockHandle{handle: 4})},
		&test_unions.HandleUnionFSharedBuffer{system.SharedBufferHandle(&mockHandle{handle: 5})},
	}

	for _, union := range tests {
		var wrapper, zeroWrapper test_unions.WrapperStruct
		wrapper.HandleUnion = union
		check(t, &wrapper, &zeroWrapper)
	}
}

func TestObjectUnion(t *testing.T) {
	tests := []test_unions.ObjectUnion{
		&test_unions.ObjectUnionFDummy{test_unions.DummyStruct{10}},
		&test_unions.ObjectUnionFArrayInt8{[]int8{1, 2, 3, 4}},
		&test_unions.ObjectUnionFMapInt8{map[string]int8{"hello": 1, "world": 2}},
		&test_unions.ObjectUnionFNullable{},
		&test_unions.ObjectUnionFPodUnion{&test_unions.PodUnionFInt8{8}},
		&test_unions.ObjectUnionFPodUnion{&test_unions.PodUnionFInt64{64}},
		&test_unions.ObjectUnionFPodUnion{&test_unions.PodUnionFBool{true}},
		&test_unions.ObjectUnionFPodUnion{&test_unions.PodUnionFEnum{test_unions.AnEnum_Second}},
	}

	for _, union := range tests {
		var wrapper, zeroWrapper test_unions.WrapperStruct
		wrapper.ObjectUnion = union
		check(t, &wrapper, &zeroWrapper)
	}
}

func encode(t *testing.T, value Encodable) ([]byte, []system.UntypedHandle, error) {
	encoder := bindings.NewEncoder()
	err := value.Encode(encoder)
	if err != nil {
		return nil, nil, err
	}

	bytes, handles, err := encoder.Data()
	if err != nil {
		return nil, nil, err
	}

	return bytes, handles, nil
}

func TestNonNullableNullInUnion(t *testing.T) {
	var wrapper test_unions.WrapperStruct
	fdummy := test_unions.ObjectUnionFDummy{test_unions.DummyStruct{10}}
	wrapper.ObjectUnion = &fdummy

	bytes, handles, _ := encode(t, &wrapper)
	bytes[16] = 0

	var decoded test_unions.WrapperStruct
	decoder := bindings.NewDecoder(bytes, handles)

	if err := decoded.Decode(decoder); err == nil {
		t.Fatalf("Null non-nullable should have failed validation.")
	}
}

func TestUnionInStruct(t *testing.T) {
	var ss, out test_unions.SmallStruct
	ss.PodUnion = &test_unions.PodUnionFInt8{10}
	check(t, &ss, &out)

	bytes, _, _ := encode(t, &ss)
	if int(bytes[8*2]) != 16 {
		t.Fatalf("Union does not start at the correct location in struct.")
	}
}

func TestUnionInArray(t *testing.T) {
	var ss, out test_unions.SmallStruct
	ss.PodUnionArray = &[]test_unions.PodUnion{
		&test_unions.PodUnionFInt8{8},
		&test_unions.PodUnionFInt16{16},
		&test_unions.PodUnionFUint64{64},
		&test_unions.PodUnionFBool{true},
		&test_unions.PodUnionFEnum{test_unions.AnEnum_Second},
	}
	check(t, &ss, &out)
}

func TestUnionInArrayNullNullable(t *testing.T) {
	var ss, out test_unions.SmallStruct
	ss.NullablePodUnionArray = &[]test_unions.PodUnion{
		nil,
		&test_unions.PodUnionFInt8{8},
		&test_unions.PodUnionFInt16{16},
		&test_unions.PodUnionFUint64{64},
		&test_unions.PodUnionFBool{true},
		&test_unions.PodUnionFEnum{test_unions.AnEnum_Second},
	}
	check(t, &ss, &out)
}

func TestUnionInArrayNonNullableNull(t *testing.T) {
	// Encoding should fail
	var ss test_unions.SmallStruct
	ss.PodUnionArray = &[]test_unions.PodUnion{
		nil,
		&test_unions.PodUnionFInt8{8},
		&test_unions.PodUnionFInt16{16},
		&test_unions.PodUnionFUint64{64},
		&test_unions.PodUnionFBool{true},
		&test_unions.PodUnionFEnum{test_unions.AnEnum_Second},
	}

	_, _, err := encode(t, &ss)
	if typedErr := err.(*bindings.ValidationError); typedErr.ErrorCode != bindings.UnexpectedNullUnion {
		t.Fatalf("Non-nullable null should have failed to encode.")
	}

	// Decoding should also fail
	ss.PodUnionArray = &[]test_unions.PodUnion{
		&test_unions.PodUnionFInt8{8},
		&test_unions.PodUnionFInt16{16},
		&test_unions.PodUnionFUint64{64},
		&test_unions.PodUnionFBool{true},
		&test_unions.PodUnionFEnum{test_unions.AnEnum_Second},
	}
	bytes, handles, _ := encode(t, &ss)

	// Set first union to null.
	bytes[8*10] = 0
	var decoded test_unions.SmallStruct
	decoder := bindings.NewDecoder(bytes, handles)
	err = decoded.Decode(decoder)
	if typedErr := err.(*bindings.ValidationError); typedErr.ErrorCode != bindings.UnexpectedNullUnion {
		t.Fatalf("Null non-nullable should have failed to decode.")
	}
}

func TestUnionInMap(t *testing.T) {
	var ss, out test_unions.SmallStruct
	ss.PodUnionMap = &map[string]test_unions.PodUnion{
		"eight":      &test_unions.PodUnionFInt8{8},
		"sixteen":    &test_unions.PodUnionFInt16{16},
		"sixty-four": &test_unions.PodUnionFUint64{64},
		"bool":       &test_unions.PodUnionFBool{true},
		"enum":       &test_unions.PodUnionFEnum{test_unions.AnEnum_Second},
	}
	check(t, &ss, &out)
}
