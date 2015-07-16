// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package system

// ConsumerHandle is a handle for the consumer part of a data pipe.
type ConsumerHandle interface {
	Handle

	// ReadData reads data from the data pipe consumer handle with the
	// given flags. On success, returns the data that was read.
	ReadData(flags MojoReadDataFlags) (MojoResult, []byte)

	// BeginReadData begins a two-phase read from the data pipe consumer.
	// On success, returns a slice from which the caller can read up to its
	// length bytes of data. If flags has |MOJO_READ_DATA_FLAG_ALL_OR_NONE|
	// set, then the slice length will be at least as large as |numBytes|,
	// which must also be a multiple of the element size (otherwise the
	// caller must check the length of the slice).
	//
	// During a two-phase read, this handle is *not* readable. E.g., read
	// from this handle will return |MOJO_RESULT_BUSY|.
	//
	// Once the caller has finished reading data from the slice, it should
	// call |EndReadData()| to specify the amount read and to complete the
	// two-phase read.
	BeginReadData(numBytes int, flags MojoReadDataFlags) (MojoResult, []byte)

	// EndReadData ends a two-phase read from the data pipe consumer that
	// was begun by a call to |BeginReadData()| on the same handle.
	// |numBytesRead| should indicate the amount of data actually read; it
	// must be less than or equal to the length of the slice returned by
	// |BeginReadData()| and must be a multiple of the element size.
	//
	// On failure, the two-phase read (if any) is ended (so the handle may
	// become readable again) but no data is "removed" from the data pipe.
	EndReadData(numBytesRead int) MojoResult
}

// ProducerHandle is a handle for the producer part of a data pipe.
type ProducerHandle interface {
	Handle

	// WriteData writes data to the data pipe producer handle with the
	// given flags. On success, returns the number of bytes that were
	// actually written.
	WriteData(data []byte, flags MojoWriteDataFlags) (MojoResult, int)

	// BeginWriteData begins a two-phase write to the data pipe producer.
	// On success, returns a slice to which the caller can write. If flags
	// has |MOJO_READ_DATA_FLAG_ALL_OR_NONE| set, then the slice length will
	// be at least as large as |numBytes|, which must also be a multiple of
	// the element size (otherwise the caller must check the length of the
	// slice).
	//
	// During a two-phase write, this handle is *not* writable. E.g., write
	// to this handle will return |MOJO_RESULT_BUSY|.
	//
	// Once the caller has finished writing data to the buffer, it should
	// call |EndWriteData()| to specify the amount written and to complete
	// the two-phase write.
	BeginWriteData(numBytes int, flags MojoWriteDataFlags) (MojoResult, []byte)

	// EndWriteData ends a two-phase write to the data pipe producer that
	// was begun by a call to |BeginWriteData()| on the same handle.
	// |numBytesWritten| should indicate the amount of data actually
	// written; it must be less than or equal to the length of the slice
	// returned by |BeginWriteData()| and must be a multiple of the element
	// size. The slice returned from |BeginWriteData()| must have been
	// filled with exactly |numBytesWritten| bytes of data.
	//
	// On failure, the two-phase write (if any) is ended (so the handle may
	// become writable again, if there's space available) but no data
	// written to the slice is "put into" the data pipe.
	EndWriteData(numBytesWritten int) MojoResult
}

type dataPipeConsumer struct {
	// baseHandle should always be the first component of this struct,
	// see |finalizeHandle()| for more details.
	baseHandle
}

func (h *dataPipeConsumer) ReadData(flags MojoReadDataFlags) (MojoResult, []byte) {
	h.core.mu.Lock()
	r, buf := sysImpl.ReadData(uint32(h.mojoHandle), uint32(flags))
	h.core.mu.Unlock()
	return MojoResult(r), buf
}

func (h *dataPipeConsumer) BeginReadData(numBytes int, flags MojoReadDataFlags) (MojoResult, []byte) {
	h.core.mu.Lock()
	r, buf := sysImpl.BeginReadData(uint32(h.mojoHandle), uint32(numBytes), uint32(flags))
	h.core.mu.Unlock()
	return MojoResult(r), buf
}

func (h *dataPipeConsumer) EndReadData(numBytesRead int) MojoResult {
	h.core.mu.Lock()
	r := sysImpl.EndReadData(uint32(h.mojoHandle), uint32(numBytesRead))
	h.core.mu.Unlock()
	return MojoResult(r)
}

type dataPipeProducer struct {
	// baseHandle should always be the first component of this struct,
	// see |finalizeHandle()| for more details.
	baseHandle
}

func (h *dataPipeProducer) WriteData(data []byte, flags MojoWriteDataFlags) (MojoResult, int) {
	h.core.mu.Lock()
	r, bytesWritten := sysImpl.WriteData(uint32(h.mojoHandle), data, uint32(flags))
	h.core.mu.Unlock()
	return MojoResult(r), int(bytesWritten)
}

func (h *dataPipeProducer) BeginWriteData(numBytes int, flags MojoWriteDataFlags) (MojoResult, []byte) {
	h.core.mu.Lock()
	r, buf := sysImpl.BeginWriteData(uint32(h.mojoHandle), uint32(numBytes), uint32(flags))
	h.core.mu.Unlock()
	return MojoResult(r), buf
}

func (h *dataPipeProducer) EndWriteData(numBytesWritten int) MojoResult {
	h.core.mu.Lock()
	r := sysImpl.EndWriteData(uint32(h.mojoHandle), uint32(numBytesWritten))
	h.core.mu.Unlock()
	return MojoResult(r)
}
