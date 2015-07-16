// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package native_cgo

//#include "mojo/public/c/system/core.h"
// // These functions are used to 8-byte align C structs.
// MojoResult CreateSharedBuffer(struct MojoCreateSharedBufferOptions* options,
//     uint64_t num_bytes, MojoHandle* handle) {
//   struct MojoCreateSharedBufferOptions aligned_options;
//   if (options != NULL) {
//     aligned_options = *options;
//     return MojoCreateSharedBuffer(&aligned_options, num_bytes, handle);
//   } else {
//     return MojoCreateSharedBuffer(NULL, num_bytes, handle);
//   }
// }
//
// MojoResult DuplicateBufferHandle(MojoHandle handle,
//     struct MojoDuplicateBufferHandleOptions* options, MojoHandle* duplicate) {
//   struct MojoDuplicateBufferHandleOptions aligned_options;
//   if (options != NULL) {
//     aligned_options = *options;
//     return MojoDuplicateBufferHandle(handle, &aligned_options, duplicate);
//   } else {
//     return MojoDuplicateBufferHandle(handle, NULL, duplicate);
//   }
// }
//
// MojoResult CreateDataPipe(struct MojoCreateDataPipeOptions* options,
//     MojoHandle* producer, MojoHandle* consumer) {
//   struct MojoCreateDataPipeOptions aligned_options;
//   if (options != NULL) {
//     aligned_options = *options;
//     return MojoCreateDataPipe(&aligned_options, producer, consumer);
//   } else {
//     return MojoCreateDataPipe(NULL, producer, consumer);
//   }
// }
//
// MojoResult CreateMessagePipe(struct MojoCreateMessagePipeOptions* options,
//     MojoHandle* handle0, MojoHandle* handle1) {
//   struct MojoCreateMessagePipeOptions aligned_options = *options;
//   if (options != NULL) {
//     aligned_options = *options;
//     return MojoCreateMessagePipe(&aligned_options, handle0, handle1);
//   } else {
//     return MojoCreateMessagePipe(NULL, handle0, handle1);
//   }
// }
//
import "C"
import (
	"reflect"
	"unsafe"
)

// CGoSystem provides an implementation of the system.System interface based on CGO
type CGoSystem struct{}

func (c *CGoSystem) CreateSharedBuffer(flags uint32, numBytes uint64) (uint32, uint32) {
	var opts *C.struct_MojoCreateSharedBufferOptions
	opts = &C.struct_MojoCreateSharedBufferOptions{
		C.uint32_t(unsafe.Sizeof(*opts)),
		C.MojoCreateSharedBufferOptionsFlags(flags),
	}
	var cHandle C.MojoHandle
	r := C.CreateSharedBuffer(opts, C.uint64_t(numBytes), &cHandle)
	return uint32(r), uint32(cHandle)
}

func (c *CGoSystem) DuplicateBufferHandle(handle uint32, flags uint32) (uint32, uint32) {
	var opts *C.struct_MojoDuplicateBufferHandleOptions
	opts = &C.struct_MojoDuplicateBufferHandleOptions{
		C.uint32_t(unsafe.Sizeof(*opts)),
		C.MojoDuplicateBufferHandleOptionsFlags(flags),
	}
	var cDuplicateHandle C.MojoHandle
	r := C.DuplicateBufferHandle(C.MojoHandle(handle), opts, &cDuplicateHandle)
	return uint32(r), uint32(cDuplicateHandle)
}

func (c *CGoSystem) MapBuffer(handle uint32, offset, numBytes uint64, flags uint32) (result uint32, buf []byte) {
	var bufPtr unsafe.Pointer
	r := C.MojoMapBuffer(C.MojoHandle(handle), C.uint64_t(offset), C.uint64_t(numBytes), &bufPtr, C.MojoMapBufferFlags(flags))
	if r != C.MOJO_RESULT_OK {
		return uint32(r), nil
	}
	return uint32(r), unsafeByteSlice(bufPtr, int(numBytes))
}

func (c *CGoSystem) UnmapBuffer(buf []byte) (result uint32) {
	return uint32(C.MojoUnmapBuffer(unsafe.Pointer(&buf[0])))
}

func createDataPipeWithCOptions(opts *C.struct_MojoCreateDataPipeOptions) (result uint32, producerHandle, consumerHandle uint32) {
	var cProducerHandle, cConsumerHandle C.MojoHandle
	r := C.CreateDataPipe(opts, &cProducerHandle, &cConsumerHandle)
	return uint32(r), uint32(cProducerHandle), uint32(cConsumerHandle)
}

func (c *CGoSystem) CreateDataPipe(flags, elementNumBytes, capacityNumBytes uint32) (result uint32, producerHandle, consumerHandle uint32) {
	var opts *C.struct_MojoCreateDataPipeOptions
	opts = &C.struct_MojoCreateDataPipeOptions{
		C.uint32_t(unsafe.Sizeof(*opts)),
		C.MojoCreateDataPipeOptionsFlags(flags),
		C.uint32_t(elementNumBytes),
		C.uint32_t(capacityNumBytes),
	}
	return createDataPipeWithCOptions(opts)
}

func (c *CGoSystem) CreateDataPipeWithDefaultOptions() (result uint32, producerHandle, consumerHandle uint32) {
	// A nil options pointer in the C interface means use the default values.
	return createDataPipeWithCOptions(nil)
}

func (c *CGoSystem) WriteData(producerHandle uint32, buf []byte, flags uint32) (result uint32, bytesWritten uint32) {
	numBytes := C.uint32_t(len(buf))
	r := C.MojoWriteData(C.MojoHandle(producerHandle), unsafe.Pointer(&buf[0]), &numBytes, C.MojoWriteDataFlags(flags))
	return uint32(r), uint32(numBytes)
}

func (c *CGoSystem) BeginWriteData(producerHandle uint32, numBytes uint32, flags uint32) (result uint32, buf []byte) {
	var buffer unsafe.Pointer
	bufferNumBytes := C.uint32_t(numBytes)
	r := C.MojoBeginWriteData(C.MojoHandle(producerHandle), &buffer, &bufferNumBytes, C.MojoWriteDataFlags(flags))
	if r != C.MOJO_RESULT_OK {
		return uint32(r), nil
	}
	return uint32(r), unsafeByteSlice(buffer, int(bufferNumBytes))
}

func (c *CGoSystem) EndWriteData(producerHandle uint32, numBytesWritten uint32) (result uint32) {
	return uint32(C.MojoEndWriteData(C.MojoHandle(producerHandle), C.uint32_t(numBytesWritten)))
}

func (c *CGoSystem) ReadData(consumerHandle uint32, flags uint32) (result uint32, buf []byte) {
	var numBytes C.uint32_t
	if r := C.MojoReadData(C.MojoHandle(consumerHandle), nil, &numBytes, C.MOJO_READ_DATA_FLAG_QUERY); r != C.MOJO_RESULT_OK {
		return uint32(r), nil
	}
	buf = make([]byte, int(numBytes))
	r := C.MojoReadData(C.MojoHandle(consumerHandle), unsafe.Pointer(&buf[0]), &numBytes, C.MojoReadDataFlags(flags))
	buf = buf[0:int(numBytes)]
	return uint32(r), buf
}

func (c *CGoSystem) BeginReadData(consumerHandle uint32, numBytes uint32, flags uint32) (result uint32, buf []byte) {
	var buffer unsafe.Pointer
	bufferNumBytes := C.uint32_t(numBytes)
	r := C.MojoBeginReadData(C.MojoHandle(consumerHandle), &buffer, &bufferNumBytes, C.MojoReadDataFlags(flags))
	if r != C.MOJO_RESULT_OK {
		return uint32(r), nil
	}
	return uint32(r), unsafeByteSlice(buffer, int(bufferNumBytes))
}

func (c *CGoSystem) EndReadData(consumerHandle uint32, numBytesRead uint32) (result uint32) {
	return uint32(C.MojoEndReadData(C.MojoHandle(consumerHandle), C.uint32_t(numBytesRead)))
}

func (c *CGoSystem) GetTimeTicksNow() (timestamp uint64) {
	return uint64(C.MojoGetTimeTicksNow())
}

func (c *CGoSystem) Close(handle uint32) (result uint32) {
	return uint32(C.MojoClose(C.MojoHandle(handle)))
}

func (c *CGoSystem) Wait(handle uint32, signals uint32, deadline uint64) (result uint32, satisfiedSignals, satisfiableSignals uint32) {
	var cState C.struct_MojoHandleSignalsState
	r := C.MojoWait(C.MojoHandle(handle), C.MojoHandleSignals(signals), C.MojoDeadline(deadline), &cState)
	return uint32(r), uint32(cState.satisfied_signals), uint32(cState.satisfiable_signals)
}

func (c *CGoSystem) WaitMany(handles []uint32, signals []uint32, deadline uint64) (uint32, int, []uint32, []uint32) {
	if len(handles) == 0 {
		r := C.MojoWaitMany(nil, nil, 0, C.MojoDeadline(deadline), nil, nil)
		return uint32(r), -1, nil, nil
	}
	if len(handles) != len(signals) {
		panic("number of handles and signals must match")
	}
	index := ^C.uint32_t(0) // -1
	cHandles := (*C.MojoHandle)(unsafe.Pointer(&handles[0]))
	cSignals := (*C.MojoHandleSignals)(unsafe.Pointer(&signals[0]))
	cStates := make([]C.struct_MojoHandleSignalsState, len(handles))
	r := C.MojoWaitMany(cHandles, cSignals, C.uint32_t(len(handles)), C.MojoDeadline(deadline), &index, &cStates[0])
	var satisfied, satisfiable []uint32
	if r != C.MOJO_RESULT_INVALID_ARGUMENT && r != C.MOJO_RESULT_RESOURCE_EXHAUSTED {
		satisfied = make([]uint32, len(handles))
		satisfiable = make([]uint32, len(handles))
		for i := 0; i < len(handles); i++ {
			satisfied[i] = uint32(cStates[i].satisfied_signals)
			satisfiable[i] = uint32(cStates[i].satisfiable_signals)
		}
	}
	return uint32(r), int(int32(index)), satisfied, satisfiable
}

func (c *CGoSystem) CreateMessagePipe(flags uint32) (uint32, uint32, uint32) {
	var handle0, handle1 C.MojoHandle
	var opts *C.struct_MojoCreateMessagePipeOptions
	opts = &C.struct_MojoCreateMessagePipeOptions{
		C.uint32_t(unsafe.Sizeof(*opts)),
		C.MojoCreateMessagePipeOptionsFlags(flags),
	}
	r := C.CreateMessagePipe(opts, &handle0, &handle1)
	return uint32(r), uint32(handle0), uint32(handle1)
}

func (c *CGoSystem) WriteMessage(handle uint32, bytes []byte, handles []uint32, flags uint32) (result uint32) {
	var bytesPtr unsafe.Pointer
	if len(bytes) != 0 {
		bytesPtr = unsafe.Pointer(&bytes[0])
	}
	var handlesPtr *C.MojoHandle
	if len(handles) != 0 {
		handlesPtr = (*C.MojoHandle)(unsafe.Pointer(&handles[0]))
	}
	return uint32(C.MojoWriteMessage(C.MojoHandle(handle), bytesPtr, C.uint32_t(len(bytes)), handlesPtr, C.uint32_t(len(handles)), C.MojoWriteMessageFlags(flags)))
}

func (c *CGoSystem) ReadMessage(handle uint32, flags uint32) (result uint32, buf []byte, handles []uint32) {
	var numBytes, numHandles C.uint32_t
	cHandle := C.MojoHandle(handle)
	cFlags := C.MojoReadMessageFlags(flags)
	if r := C.MojoReadMessage(cHandle, nil, &numBytes, nil, &numHandles, cFlags); r != C.MOJO_RESULT_RESOURCE_EXHAUSTED {
		return uint32(r), nil, nil
	}
	var bufPtr unsafe.Pointer
	if numBytes != 0 {
		buf = make([]byte, int(numBytes))
		bufPtr = unsafe.Pointer(&buf[0])
	}
	var handlesPtr *C.MojoHandle
	if numHandles != 0 {
		handles = make([]uint32, int(numHandles))
		handlesPtr = (*C.MojoHandle)(unsafe.Pointer(&handles[0]))
	}
	r := C.MojoReadMessage(cHandle, bufPtr, &numBytes, handlesPtr, &numHandles, cFlags)
	return uint32(r), buf, handles
}

func newUnsafeSlice(ptr unsafe.Pointer, length int) unsafe.Pointer {
	header := &reflect.SliceHeader{
		Data: uintptr(ptr),
		Len:  length,
		Cap:  length,
	}
	return unsafe.Pointer(header)
}

func unsafeByteSlice(ptr unsafe.Pointer, length int) []byte {
	return *(*[]byte)(newUnsafeSlice(ptr, length))
}
