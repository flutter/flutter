// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file contains types/constants and functions specific to buffers (and in
// particular shared buffers).
// TODO(vtl): Reorganize this file (etc.) to separate general buffer functions
// from (shared) buffer creation.
//
// Note: This header should be compilable as C.

#ifndef MOJO_PUBLIC_C_SYSTEM_BUFFER_H_
#define MOJO_PUBLIC_C_SYSTEM_BUFFER_H_

#include "mojo/public/c/system/macros.h"
#include "mojo/public/c/system/system_export.h"
#include "mojo/public/c/system/types.h"

// |MojoCreateSharedBufferOptions|: Used to specify creation parameters for a
// shared buffer to |MojoCreateSharedBuffer()|.
//   |uint32_t struct_size|: Set to the size of the
//       |MojoCreateSharedBufferOptions| struct. (Used to allow for future
//       extensions.)
//   |MojoCreateSharedBufferOptionsFlags flags|: Reserved for future use.
//       |MOJO_CREATE_SHARED_BUFFER_OPTIONS_FLAG_NONE|: No flags; default mode.
//
// TODO(vtl): Maybe add a flag to indicate whether the memory should be
// executable or not?
// TODO(vtl): Also a flag for discardable (ashmem-style) buffers.

typedef uint32_t MojoCreateSharedBufferOptionsFlags;

#ifdef __cplusplus
const MojoCreateSharedBufferOptionsFlags
    MOJO_CREATE_SHARED_BUFFER_OPTIONS_FLAG_NONE = 0;
#else
#define MOJO_CREATE_SHARED_BUFFER_OPTIONS_FLAG_NONE \
  ((MojoCreateSharedBufferOptionsFlags)0)
#endif

MOJO_STATIC_ASSERT(MOJO_ALIGNOF(int64_t) == 8, "int64_t has weird alignment");
struct MOJO_ALIGNAS(8) MojoCreateSharedBufferOptions {
  uint32_t struct_size;
  MojoCreateSharedBufferOptionsFlags flags;
};
MOJO_STATIC_ASSERT(sizeof(MojoCreateSharedBufferOptions) == 8,
                   "MojoCreateSharedBufferOptions has wrong size");

// |MojoDuplicateBufferHandleOptions|: Used to specify parameters in duplicating
// access to a shared buffer to |MojoDuplicateBufferHandle()|.
//   |uint32_t struct_size|: Set to the size of the
//       |MojoDuplicateBufferHandleOptions| struct. (Used to allow for future
//       extensions.)
//   |MojoDuplicateBufferHandleOptionsFlags flags|: Reserved for future use.
//       |MOJO_DUPLICATE_BUFFER_HANDLE_OPTIONS_FLAG_NONE|: No flags; default
//       mode.
//
// TODO(vtl): Add flags to remove writability (and executability)? Also, COW?

typedef uint32_t MojoDuplicateBufferHandleOptionsFlags;

#ifdef __cplusplus
const MojoDuplicateBufferHandleOptionsFlags
    MOJO_DUPLICATE_BUFFER_HANDLE_OPTIONS_FLAG_NONE = 0;
#else
#define MOJO_DUPLICATE_BUFFER_HANDLE_OPTIONS_FLAG_NONE \
  ((MojoDuplicateBufferHandleOptionsFlags)0)
#endif

struct MojoDuplicateBufferHandleOptions {
  uint32_t struct_size;
  MojoDuplicateBufferHandleOptionsFlags flags;
};
MOJO_STATIC_ASSERT(sizeof(MojoDuplicateBufferHandleOptions) == 8,
                   "MojoDuplicateBufferHandleOptions has wrong size");

// |MojoMapBufferFlags|: Used to specify different modes to |MojoMapBuffer()|.
//   |MOJO_MAP_BUFFER_FLAG_NONE| - No flags; default mode.

typedef uint32_t MojoMapBufferFlags;

#ifdef __cplusplus
const MojoMapBufferFlags MOJO_MAP_BUFFER_FLAG_NONE = 0;
#else
#define MOJO_MAP_BUFFER_FLAG_NONE ((MojoMapBufferFlags)0)
#endif

#ifdef __cplusplus
extern "C" {
#endif

// Note: See the comment in functions.h about the meaning of the "optional"
// label for pointer parameters.

// Creates a buffer of size |num_bytes| bytes that can be shared between
// applications (by duplicating the handle -- see |MojoDuplicateBufferHandle()|
// -- and passing it over a message pipe). To access the buffer, one must call
// |MojoMapBuffer()|.
//
// |options| may be set to null for a shared buffer with the default options.
//
// On success, |*shared_buffer_handle| will be set to the handle for the shared
// buffer. (On failure, it is not modified.)
//
// Note: While more than |num_bytes| bytes may apparently be
// available/visible/readable/writable, trying to use those extra bytes is
// undefined behavior.
//
// Returns:
//   |MOJO_RESULT_OK| on success.
//   |MOJO_RESULT_INVALID_ARGUMENT| if some argument was invalid (e.g.,
//       |*options| is invalid).
//   |MOJO_RESULT_RESOURCE_EXHAUSTED| if a process/system/quota/etc. limit has
//       been reached (e.g., if the requested size was too large, or if the
//       maximum number of handles was exceeded).
//   |MOJO_RESULT_UNIMPLEMENTED| if an unsupported flag was set in |*options|.
MOJO_SYSTEM_EXPORT MojoResult MojoCreateSharedBuffer(
    const struct MojoCreateSharedBufferOptions* options,  // Optional.
    uint64_t num_bytes,                                   // In.
    MojoHandle* shared_buffer_handle);                    // Out.

// Duplicates the handle |buffer_handle| to a buffer. This creates another
// handle (returned in |*new_buffer_handle| on success), which can then be sent
// to another application over a message pipe, while retaining access to the
// |buffer_handle| (and any mappings that it may have).
//
// |options| may be set to null to duplicate the buffer handle with the default
// options.
//
// On success, |*shared_buffer_handle| will be set to the handle for the new
// buffer handle. (On failure, it is not modified.)
//
// Returns:
//   |MOJO_RESULT_OK| on success.
//   |MOJO_RESULT_INVALID_ARGUMENT| if some argument was invalid (e.g.,
//       |buffer_handle| is not a valid buffer handle or |*options| is invalid).
//   |MOJO_RESULT_UNIMPLEMENTED| if an unsupported flag was set in |*options|.
MOJO_SYSTEM_EXPORT MojoResult MojoDuplicateBufferHandle(
    MojoHandle buffer_handle,
    const struct MojoDuplicateBufferHandleOptions* options,  // Optional.
    MojoHandle* new_buffer_handle);                          // Out.

// Maps the part (at offset |offset| of length |num_bytes|) of the buffer given
// by |buffer_handle| into memory, with options specified by |flags|. |offset +
// num_bytes| must be less than or equal to the size of the buffer. On success,
// |*buffer| points to memory with the requested part of the buffer. (On
// failure, it is not modified.)
//
// A single buffer handle may have multiple active mappings (possibly depending
// on the buffer type). The permissions (e.g., writable or executable) of the
// returned memory may depend on the properties of the buffer and properties
// attached to the buffer handle as well as |flags|.
//
// Note: Though data outside the specified range may apparently be
// available/visible/readable/writable, trying to use those extra bytes is
// undefined behavior.
//
// Returns:
//   |MOJO_RESULT_OK| on success.
//   |MOJO_RESULT_INVALID_ARGUMENT| if some argument was invalid (e.g.,
//       |buffer_handle| is not a valid buffer handle or the range specified by
//       |offset| and |num_bytes| is not valid).
//   |MOJO_RESULT_RESOURCE_EXHAUSTED| if the mapping operation itself failed
//       (e.g., due to not having appropriate address space available).
MOJO_SYSTEM_EXPORT MojoResult MojoMapBuffer(MojoHandle buffer_handle,
                                            uint64_t offset,
                                            uint64_t num_bytes,
                                            void** buffer,  // Out.
                                            MojoMapBufferFlags flags);

// Unmaps a buffer pointer that was mapped by |MojoMapBuffer()|. |buffer| must
// have been the result of |MojoMapBuffer()| (not some other pointer inside
// the mapped memory), and the entire mapping will be removed (partial unmapping
// is not supported). A mapping may only be unmapped once.
//
// Returns:
//   |MOJO_RESULT_OK| on success.
//   |MOJO_RESULT_INVALID_ARGUMENT| if |buffer| is invalid (e.g., is not the
//       result of |MojoMapBuffer()| or has already been unmapped).
MOJO_SYSTEM_EXPORT MojoResult MojoUnmapBuffer(void* buffer);  // In.

#ifdef __cplusplus
}  // extern "C"
#endif

#endif  // MOJO_PUBLIC_C_SYSTEM_BUFFER_H_
